import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import yaml from 'js-yaml'
import { unified } from 'unified'
import remarkParse from 'remark-parse'
import { visit } from 'unist-util-visit'

const repositoryRoot = fileURLToPath(new URL('../', import.meta.url))
const defaultSource = path.join(repositoryRoot, 'knowledge-vault')
const defaultOutput = path.join(repositoryRoot, 'knowledge-web', 'content')

// Deliberately conservative: v1 publishes Markdown only, never vault assets or HTML.
export async function exportPublic(source, output) {
  source = await fs.realpath(source)
  output = path.resolve(output)
  if (output === source || output.startsWith(source + path.sep) || source.startsWith(output + path.sep)) throw Error('Source and output must be separate')
  const notes = []
  async function walk(dir) {
    for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
      if (entry.name.startsWith('.') || entry.name === 'templates') continue
      const full = path.join(dir, entry.name)
      if (entry.isSymbolicLink()) throw Error('Symlinks are not exportable')
      if (entry.isDirectory()) await walk(full)
      else if (entry.name.endsWith('.md')) {
        const text = await fs.readFile(full, 'utf8')
        const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)
        const meta = match ? yaml.load(match[1], { schema: yaml.JSON_SCHEMA }) : {}
        const name = path.relative(source, full).split(path.sep).join('/')
        if (!meta || typeof meta !== 'object' || Array.isArray(meta)) throw Error('Invalid frontmatter: ' + name)
        notes.push({ name, meta, body: match ? text.slice(match[0].length) : text })
      }
    }
  }
  await walk(source)
  const selected = notes.filter(n => n.meta.visibility === 'public')
  if (!selected.some(n => n.name === 'index.md')) throw Error('An explicitly public index.md is required')
  // Match the pinned Quartz 4.5.2 path rules before any output is replaced.
  const slugs = new Map()
  for (const note of selected) {
    const slug = note.name.slice(0, -3).replace(/\s/g, '-').replace(/&/g, '-and-')
      .replace(/%/g, '-percent').replace(/[?#]/g, '').replace(/_index$/, 'index')
    const previous = slugs.get(slug)
    if (previous) throw Error(`Public URL collision: ${previous} and ${note.name}`)
    slugs.set(slug, note.name)
  }
  function resolveLink(raw, from) {
    let target = decodeURIComponent(raw).split(/[?#]/)[0].replace(/\\/g, '/')
    if (!target) return
    if (/^(https?:|mailto:)/i.test(target)) return
    if (/^[a-z][a-z\d+.-]*:|^\/\//i.test(target)) throw Error('Unsupported URL in ' + from)
    target = target.replace(/\.md$/, '')
    const relative = path.posix.normalize(path.posix.join(path.posix.dirname(from), target))
    const matches = notes.filter(n => {
      const stem = n.name.slice(0, -3)
      return stem === target || stem === relative || (!target.includes('/') && path.posix.basename(stem) === target)
    })
    if (matches.length !== 1 || matches[0].meta.visibility !== 'public') throw Error('Private, missing, ambiguous, or asset link in ' + from)
  }
  for (const note of selected) {
    for (const match of note.body.matchAll(/!?\[\[([^\]]+)\]\]/g)) resolveLink(match[1].split('|')[0], note.name)
    const tree = unified().use(remarkParse).parse(note.body)
    visit(tree, node => {
      if (node.type === 'html') throw Error('Raw HTML is not supported in public exports: ' + note.name)
      if (node.type === 'image' || node.type === 'imageReference') throw Error('Images require a future reviewed asset pipeline: ' + note.name)
      if (node.type === 'link' || node.type === 'definition') resolveLink(node.url, note.name)
    })
  }
  // Output is dedicated generated storage; refuse to replace arbitrary directories.
  const marker = path.join(output, '.saleh-public-export')
  try {
    const stat = await fs.lstat(output)
    if (stat.isSymbolicLink() || !stat.isDirectory()) throw Error('Unsafe export destination')
    await fs.access(marker)
  } catch (error) {
    if (error.code !== 'ENOENT') throw error
    try { await fs.access(output); throw Error('Destination exists without export marker') } catch (e) { if (e.code !== 'ENOENT') throw e }
  }
  const staging = await fs.mkdtemp(output + '.tmp-')
  try {
    for (const note of selected) {
      const meta = { visibility: 'public', publish: true }
      for (const key of ['title', 'created', 'updated', 'tags']) if (note.meta[key] !== undefined) meta[key] = note.meta[key]
      const dest = path.join(staging, note.name)
      await fs.mkdir(path.dirname(dest), { recursive: true })
      await fs.writeFile(dest, '---\n' + yaml.dump(meta) + '---\n' + note.body)
    }
    await fs.writeFile(path.join(staging, '.saleh-public-export'), 'Generated; do not edit.\n')
    await fs.rm(output, { recursive: true, force: true })
    await fs.rename(staging, output)
  } finally { await fs.rm(staging, { recursive: true, force: true }) }
  return selected.length
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try { console.log(`Exported ${await exportPublic(process.argv[2] ?? defaultSource, process.argv[3] ?? defaultOutput)} public notes`) }
  catch (error) { console.error(error.message); process.exitCode = 1 }
}
