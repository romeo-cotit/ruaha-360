#!/usr/bin/env node
import { execFileSync } from 'node:child_process'

const url = execFileSync('node', ['scripts/db-url.mjs'], { encoding: 'utf8' })
const query = `
select 'crop' as kind, id::text, name_en, name_sw from crop
union all select 'equipment_category', id::text, name_en, name_sw from equipment_category
union all select 'equipment', id::text, name_en, name_sw from equipment
order by 1, 3`
const output = execFileSync('psql', [url, '-X', '-A', '-t', '-F', '\t', '-v', 'ON_ERROR_STOP=1', '-c', query], { encoding: 'utf8' })
const rows = output.trim().split('\n').filter(Boolean).map(line => {
  const [kind, id, english, swahili] = line.split('\t')
  return { kind, id, english, swahili, missing: !swahili?.trim() || swahili.trim() === english.trim() }
})
const counts = Object.groupBy(rows, row => row.kind)
for (const [kind, group] of Object.entries(counts)) {
  const missing = group.filter(row => row.missing)
  process.stdout.write(`${kind}: ${group.length} rows; ${missing.length} missing or identical Swahili labels\n`)
  for (const row of missing) process.stdout.write(`  ${row.id} ${row.english}\n`)
}
