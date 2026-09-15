import { exportPublic } from './export-public.mjs'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
const web = fileURLToPath(new URL('../repos/knowledge-web/', import.meta.url))
const vault = fileURLToPath(new URL('../repos/knowledge-vault/', import.meta.url))
try {
  console.log(`Exported ${await exportPublic(vault, web + 'content')} public notes`)
  const result = spawnSync('npx', ['quartz', 'build'], { cwd: web, stdio: 'inherit' })
  if (result.error) throw result.error
  process.exitCode = result.status ?? 1
} catch (error) { console.error(error.message); process.exitCode = 1 }
