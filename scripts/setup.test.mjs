import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import { spawnSync } from 'node:child_process'

async function makeRoot(t) {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'saleh-setup-test-'))
  t.after(() => fs.rm(root, { recursive: true, force: true }))
  await fs.mkdir(path.join(root, 'scripts'), { recursive: true })
  await fs.copyFile(new URL('./setup.sh', import.meta.url), path.join(root, 'scripts/setup.sh'))
  await fs.mkdir(path.join(root, 'config'), { recursive: true })
  for (const file of ['quartz.config.ts', 'quartz.layout.ts', 'quartz.package.json', 'quartz.package-lock.json']) {
    await fs.writeFile(path.join(root, 'config', file), 'Configured ' + file)
  }
  // Minimal vault starter template for --create-vault tests.
  await fs.mkdir(path.join(root, 'knowledge/vault-starter'), { recursive: true })
  await fs.writeFile(path.join(root, 'knowledge/vault-starter/index.md'), 'starter')
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
  // Stub real git init for --create-vault (creates .git dir).
  await fs.writeFile(path.join(bin, 'git-real'), '#!/bin/sh\nexit 0\n', { mode: 0o755 })
  return { root, bin }
}

function run(root, bin, args = [], fail = '0') {
  return spawnSync('sh', [path.join(root, 'scripts/setup.sh'), ...args], {
    env: { ...process.env, PATH: bin + path.delimiter + process.env.PATH, FAIL_SETUP: fail }, encoding: 'utf8',
  })
}

test('missing vault stops with instructions and never silently creates one', async t => {
  const { root, bin } = await makeRoot(t)
  await fs.mkdir(path.join(root, 'repos/knowledge-web/.git'), { recursive: true })
  for (const file of ['quartz.config.ts', 'quartz.layout.ts', 'package.json', 'package-lock.json']) {
    await fs.writeFile(path.join(root, 'repos/knowledge-web', file), 'x')
  }
  const result = run(root, bin)
  assert.notEqual(result.status, 0)
  assert.match(result.stderr, /never auto-created|not found/i)
  await assert.rejects(fs.access(path.join(root, 'repos/knowledge-vault')))
})

test('interrupted publisher setup is retryable and preserves an existing vault', async t => {
  const { root, bin } = await makeRoot(t)
  await fs.mkdir(path.join(root, 'repos/knowledge-vault/.git'), { recursive: true })
  await fs.writeFile(path.join(root, 'repos/knowledge-vault/personal.md'), 'Keep my note')
  assert.notEqual(run(root, bin, [], '1').status, 0)
  await assert.rejects(fs.access(path.join(root, 'repos/knowledge-web')))
  assert.ok(!(await fs.readdir(root)).some(name => name.startsWith('.setup.')))
  const retry = run(root, bin, [], '0')
  assert.equal(retry.status, 0, retry.stderr)
  assert.equal(await fs.readFile(path.join(root, 'repos/knowledge-web/quartz.config.ts'), 'utf8'), 'Configured quartz.config.ts')
  assert.equal(await fs.readFile(path.join(root, 'repos/knowledge-vault/personal.md'), 'utf8'), 'Keep my note')
  await fs.writeFile(path.join(root, 'repos/knowledge-web/personal.txt'), 'Keep publisher edits')
  assert.equal(run(root, bin, [], '0').status, 0)
  assert.equal(await fs.readFile(path.join(root, 'repos/knowledge-web/personal.txt'), 'utf8'), 'Keep publisher edits')
})
