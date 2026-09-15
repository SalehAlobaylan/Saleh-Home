import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { spawnSync } from 'node:child_process'

const root = fileURLToPath(new URL('../', import.meta.url))
const children = ['salehspace', 'salehalobaylan', 'knowledge-vault', 'knowledge-web', 'personal-docs']

function git(args) {
  const result = spawnSync('git', args, { cwd: root, encoding: 'utf8' })
  assert.equal(result.status, 0, `git ${args.join(' ')} failed: ${result.stderr}`)
  return result.stdout
}

test('status.sh reports every workspace repository locally', () => {
  const result = spawnSync('sh', [path.join(root, 'scripts/status.sh')], { encoding: 'utf8' })
  assert.equal(result.status, 0, result.stderr)
  for (const name of ['saleh-home', ...children]) {
    assert.ok(result.stdout.includes(name), `status.sh missing repo: ${name}`)
  }
  assert.ok(!result.stdout.includes('not configured'), 'all workspace repos must be present')
  assert.ok(result.stdout.includes('branch: main'), 'repos must report their branch')
})

test('all five children are registered gitlinks with intact histories', () => {
  const status = git(['submodule', 'status', '--recursive'])
  for (const name of children) {
    const line = status.split('\n').find(l => l.includes(`repos/${name}`))
    assert.ok(line, `submodule status missing: repos/${name}`)
    assert.ok(!line.startsWith('-') && !line.startsWith('+'), `submodule not initialized or out of sync: ${line}`)
  }
  const modules = git(['config', '-f', '.gitmodules', '--get-regexp', '^submodule\\..*\\.path$'])
  for (const name of children) {
    assert.ok(modules.includes(`repos/${name}`), `.gitmodules missing path: repos/${name}`)
  }
})

test('each child resolves HEAD through its own gitdir', async () => {
  for (const name of children) {
    const dir = path.join(root, 'repos', name)
    const stat = await fs.lstat(path.join(dir, '.git'))
    assert.ok(stat.isDirectory() || stat.isFile(), `repos/${name} has no .git`)
    const sha = git(['-C', dir, 'rev-parse', 'HEAD']).trim()
    assert.match(sha, /^[0-9a-f]{40}$/, `repos/${name} has no valid HEAD`)
  }
})
