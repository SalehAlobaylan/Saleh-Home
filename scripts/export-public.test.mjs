import { test } from 'node:test'
import assert from 'node:assert/strict'
import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import { exportPublic } from './export-public.mjs'

test('related metadata cannot expose private note names', async t => {
 const f = await fixture(t)
 await f.put('index.md', '---\nvisibility: public\nrelated: [Private]\n---\nHome')
 await exportPublic(f.source, f.output)
 const result = await fs.readFile(path.join(f.output, 'index.md'), 'utf8')
 assert.ok(!result.includes('related:') && !result.includes('Private'))
})

test('Quartz URL collisions fail before replacing the previous export', async t => {
 const f = await fixture(t)
 await exportPublic(f.source, f.output)
 for (const [first, second] of [['Cache Invalidation', 'Cache-Invalidation'], ['A&B', 'A-and-B'], ['_index', 'index']]) {
  await f.put(first + '.md', '---\nvisibility: public\n---\nFirst')
  if (second !== 'index') await f.put(second + '.md', '---\nvisibility: public\n---\nSecond')
  await assert.rejects(exportPublic(f.source, f.output), /Public URL collision/)
  assert.ok((await fs.readFile(path.join(f.output, 'index.md'), 'utf8')).includes('[[Public]]'))
  await fs.unlink(path.join(f.source, first + '.md'))
  if (second !== 'index') await fs.unlink(path.join(f.source, second + '.md'))
 }
})
async function fixture(t) {
 const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'saleh-test-'))
 t.after(() => fs.rm(dir, { recursive: true, force: true }))
 const source = path.join(dir, 'vault'), output = path.join(dir, 'content')
 await fs.mkdir(source)
 const put = (name, text) => fs.writeFile(path.join(source, name), text)
 await put('index.md', '---\nvisibility: public\nsecret: DO_NOT_EXPORT\n---\n[[Public]]')
 await put('Public.md', '---\nvisibility: public\n---\n[[index]]')
 await put('Private.md', '---\nvisibility: private\n---\nSECRET_SENTINEL')
 return { source, output, put }
}
test('exports only opted-in notes, strips private properties, and removes stale pages', async t => {
 const f = await fixture(t)
 await f.put('Missing.md', 'No metadata')
 await f.put('Truthy.md', '---\nvisibility: true\n---\nNo')
 assert.equal(await exportPublic(f.source, f.output), 2)
 assert.deepEqual((await fs.readdir(f.output)).sort(), ['.saleh-public-export', 'Public.md', 'index.md'])
 assert.ok(!(await fs.readFile(path.join(f.output, 'index.md'), 'utf8')).includes('DO_NOT_EXPORT'))
 await f.put('index.md', '---\nvisibility: public\n---\nHome')
 await f.put('Public.md', '---\nvisibility: private\n---\nPrivate now')
 await exportPublic(f.source, f.output)
 await assert.rejects(fs.access(path.join(f.output, 'Public.md')))
})
for (const body of ['[[Private]]','![[Private]]','[[Private#Heading|Friendly]]','[x](Private.md)','[x][ref]\n\n[ref]: Private.md','[[Missing]]','![[attachment.png]]','![x](https://example.com/x.png)','<iframe src="private.html"></iframe>','[x](file:///secret)']) {
 test('rejects unsafe reference: ' + body, async t => {
  const f = await fixture(t)
  await f.put('index.md', '---\nvisibility: public\n---\n' + body)
  await assert.rejects(exportPublic(f.source, f.output))
  await assert.rejects(fs.access(f.output))
 })
}
test('rejects malformed YAML and symlinks', async t => {
 const f=await fixture(t)
 await f.put('Broken.md','---\nvisibility: public\nvisibility: private\n---\n')
 await assert.rejects(exportPublic(f.source,f.output))
 await fs.unlink(path.join(f.source,'Broken.md'))
 await fs.symlink(path.join(f.source,'Private.md'),path.join(f.source,'Link.md'))
 await assert.rejects(exportPublic(f.source,f.output))
})
test('failed validation preserves prior export and refuses unrelated destination', async t => {
 const f=await fixture(t)
 await fs.mkdir(f.output)
 await f.put('index.md','---\nvisibility: public\n---\nHome')
 await assert.rejects(exportPublic(f.source,f.output), /marker/)
 await fs.rmdir(f.output)
 await exportPublic(f.source,f.output)
 await f.put('index.md','---\nvisibility: public\n---\n[[Private]]')
 await assert.rejects(exportPublic(f.source,f.output))
 assert.ok((await fs.readFile(path.join(f.output,'index.md'),'utf8')).includes('Home'))
})
