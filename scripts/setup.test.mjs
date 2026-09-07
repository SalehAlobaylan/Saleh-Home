import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import { spawnSync } from 'node:child_process'

test('interrupted publisher setup is retryable and preserves an existing vault', async t => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'saleh-setup-test-'))
  t.after(() => fs.rm(root, { recursive: true, force: true }))
  await fs.mkdir(path.join(root, 'scripts'))
  await fs.copyFile(new URL('./setup.sh', import.meta.url), path.join(root, 'scripts/setup.sh'))
  await fs.mkdir(path.join(root, 'knowledge-vault/.git'), { recursive: true })
  await fs.writeFile(path.join(root, 'knowledge-vault/personal.md'), 'Keep my note')
  await fs.mkdir(path.join(root, 'config'))
  for (const file of ['quartz.config.ts', 'quartz.layout.ts', 'quartz.package.json', 'quartz.package-lock.json']) {
    await fs.writeFile(path.join(root, 'config', file), 'Configured ' + file)
  }
  const bin = path.join(root, 'bin')
  await fs.mkdir(bin)
  // Stub network/package operations; exercise the real setup shell and filesystem.
  await fs.writeFile(path.join(bin, 'git'), `#!/bin/sh
if [ "$1" = clone ]; then
  for destination do :; done
  mkdir -p "$destination/.git" "$destination/content"
  echo upstream > "$destination/quartz.config.ts"
  exit 0
fi
case "$3" in
  rev-parse) echo 4923affa7722dfc751f1074348e6dad214fe0c08 ;;
  switch) if [ "$FAIL_SETUP" = 1 ]; then exit 1; fi ;;
esac
`, { mode: 0o755 })
  await fs.writeFile(path.join(bin, 'npm'), '#!/bin/sh\nexit 0\n', { mode: 0o755 })
  const run = fail => spawnSync('sh', [path.join(root, 'scripts/setup.sh')], {
    env: { ...process.env, PATH: bin + path.delimiter + process.env.PATH, FAIL_SETUP: fail }, encoding: 'utf8',
  })
  assert.notEqual(run('1').status, 0)
  await assert.rejects(fs.access(path.join(root, 'knowledge-web')))
  assert.ok(!(await fs.readdir(root)).some(name => name.startsWith('.setup.')))
  const retry = run('0')
  assert.equal(retry.status, 0, retry.stderr)
  assert.equal(await fs.readFile(path.join(root, 'knowledge-web/quartz.config.ts'), 'utf8'), 'Configured quartz.config.ts')
  assert.equal(await fs.readFile(path.join(root, 'knowledge-vault/personal.md'), 'utf8'), 'Keep my note')
  await fs.writeFile(path.join(root, 'knowledge-web/personal.txt'), 'Keep publisher edits')
  assert.equal(run('0').status, 0)
  assert.equal(await fs.readFile(path.join(root, 'knowledge-web/personal.txt'), 'utf8'), 'Keep publisher edits')
})
