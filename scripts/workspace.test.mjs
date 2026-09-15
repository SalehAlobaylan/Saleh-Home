import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import yaml from 'js-yaml'

const root = fileURLToPath(new URL('../', import.meta.url))

test('repository registry reflects the submodule workspace', async () => {
  const text = await fs.readFile(path.join(root, 'config/repositories.yaml'), 'utf8')
  const data = yaml.load(text)
  const repos = data.repositories
  for (const key of ['saleh-home', 'salehspace', 'salehalobaylan', 'knowledge-vault', 'knowledge-web', 'personal-docs']) {
    assert.ok(repos[key], `missing registry entry: ${key}`)
  }
  assert.equal(repos.salehspace.local_path, 'repos/salehspace')
  assert.equal(repos['salehalobaylan'].local_path, 'repos/salehalobaylan')
  assert.equal(repos['knowledge-vault'].local_path, 'repos/knowledge-vault')
  assert.equal(repos['knowledge-web'].local_path, 'repos/knowledge-web')
  assert.equal(repos['personal-docs'].local_path, 'repos/personal-docs')
  assert.equal(repos.salehspace.submodule, true)
  assert.equal(repos['salehalobaylan'].submodule, true)
  assert.equal(repos['knowledge-vault'].submodule, true)
  assert.equal(repos['knowledge-web'].submodule, true)
  assert.equal(repos['personal-docs'].submodule, true)
  // All remotes are real — never fabricate URLs for future entries.
  assert.equal(repos['knowledge-vault'].repository, 'SalehAlobaylan/knowledge-vault')
  assert.equal(repos['knowledge-web'].repository, 'SalehAlobaylan/knowledge-web')
  assert.equal(repos['personal-docs'].repository, 'SalehAlobaylan/personal-docs')
  // Registry is documentation only, never a security gate.
  assert.ok(!JSON.stringify(repos).includes('token'))
})

test('.gitmodules tracks all workspace remotes; .gitignore keeps submodule paths visible', async () => {
  const modules = await fs.readFile(path.join(root, '.gitmodules'), 'utf8')
  for (const [p, r] of [['repos/salehspace', 'SalehAlobaylan/salehspace'], ['repos/salehalobaylan', 'SalehAlobaylan/SalehAlobaylan'], ['repos/knowledge-vault', 'SalehAlobaylan/knowledge-vault'], ['repos/knowledge-web', 'SalehAlobaylan/knowledge-web'], ['repos/personal-docs', 'SalehAlobaylan/personal-docs']]) {
    assert.ok(modules.includes(p), `missing submodule path: ${p}`)
    assert.ok(modules.includes(r), `missing submodule remote: ${r}`)
  }
  assert.ok(!modules.includes('token'))
  const ignore = await fs.readFile(path.join(root, '.gitignore'), 'utf8')
  assert.ok(!ignore.split('\n').some(line => line.trim() === '/knowledge-vault/' || line.trim() === '/knowledge-web/'))
  const activeRules = ignore.split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('#'))
  assert.ok(!activeRules.some(rule => rule.includes('repos/')))
})

test('knowledge export defaults use repos/ paths', async () => {
  const exporter = await fs.readFile(path.join(root, 'scripts/export-public.mjs'), 'utf8')
  assert.ok(exporter.includes("'repos', 'knowledge-vault'") || exporter.includes('"repos"'))
  assert.ok(exporter.includes('knowledge-web'))
  const build = await fs.readFile(path.join(root, 'scripts/build.mjs'), 'utf8')
  assert.ok(build.includes('repos/knowledge-web'))
  assert.ok(build.includes('repos/knowledge-vault'))
  const starter = await fs.stat(path.join(root, 'knowledge/vault-starter/index.md'))
  assert.ok(starter.isFile())
})
