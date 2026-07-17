# capacities-cli extensions for jot plugin

Three additions needed before the jot plugin can drop the Capacities MCP entirely.

---

## 1. `--field key=value` on `cap create`

### Why

`cap create` currently only accepts `--desc` and `--tags`. Several capture types need
additional frontmatter fields at creation time:

- **Blip** — `ring`, `quadrant`, `link`, `related`
- **Video/Weblink** — `iframeUrl`, `category`
- **Article** — `iframeUrl`

Without this flag, jot would need a follow-up `cap update` per field, which means
two round-trips and an objectId threading problem.

### What to build

Add a repeatable `-f` / `--field` option to `cap create` that accepts `key=value` pairs
and injects them as additional frontmatter lines.

```
cap create --type Blip --title "uv" \
  --desc "Fast Python package manager" \
  --tags "PythonTools,BuildTooling" \
  --field ring=Trial \
  --field quadrant=Tool \
  --field "link=https://github.com/astral-sh/uv"
```

### Implementation (create.ts)

```typescript
// add to registerCreate():
.option('-f, --field <key=value>', 'extra frontmatter field (repeatable)', collect, [])

// collect helper (add near top of file):
const collect = (v: string, acc: string[]) => [...acc, v]

// in runCreate(), after the existing desc/tags lines:
for (const f of (opts.field ?? []) as string[]) {
  const eq = f.indexOf('=')
  if (eq > 0) {
    const k = f.slice(0, eq)
    const v = f.slice(eq + 1)
    frontmatterLines.push(`${k}: ${v}`)
  }
}
```

Values are written verbatim into YAML — caller is responsible for quoting if the value
contains special characters (jot agents will handle this).

### Test

Add a unit test that passes `--field ring=Trial --field quadrant=Tool` and asserts
both lines appear in the markdown sent to the API.

---

## 2. `cap daily-note <markdown>`

### Why

Session captures in jot map to Capacities' daily note. The Capacities SDK exposes a
`saveToDailyNote` endpoint. This is the only MCP call that has no current CLI equivalent.

### What to build

New command that appends a markdown string to today's daily note.

```
cap daily-note "## Session: 2026-07-16\n\n**Goal:** ...\n\n**Learnings:** ..."
```

### Implementation (src/commands/daily-note.ts — new file)

```typescript
import { Command } from 'commander'
import { resolveSpace } from './_space.ts'
import { createClient } from '../client.ts'
import { handleApiError } from '../errors.ts'
import { printLine, type CommandOptions } from '../output.ts'

export async function runDailyNote(markdown: string, opts: CommandOptions): Promise<void> {
  const space = await resolveSpace(opts.space)
  const client = createClient(space)
  await (client as any).dailyNote.save({ markdown })
  printLine('Saved to daily note', opts)
}

export function registerDailyNote(program: Command): void {
  program
    .command('daily-note <markdown>')
    .description("Append markdown to today's daily note")
    .action(async (markdown: string) => {
      await runDailyNote(markdown, program.opts()).catch(handleApiError)
    })
}
```

Check the `@capacities/api` SDK for the exact method name — it may be
`client.space.dailyNote.save(...)` or similar. The MCP currently calls
`saveToDailyNote({ markdown })`.

### Register in src/index.ts

```typescript
import { registerDailyNote } from './commands/daily-note.ts'
// ...
registerDailyNote(program)
```

### Test

Mock the SDK daily note endpoint and assert the markdown string is passed through
unchanged (newlines and all).

---

## 3. `cap validate --type <type>` + `cap create --markdown -`

### Why

The MCP's biggest problem was that the agent assembled a markdown blob, sent it blind,
and hoped for the best. There was no feedback loop — wrong field names, wrong enum
values (e.g. `trial` instead of `Trial`), missing required fields all silently produced
broken objects.

`cap validate` adds a dry-run layer. The jot agent builds the frontmatter, validates it
against the live type structure (cached 24h), gets back a normalized/completed version,
inspects it, then creates with confidence. Two-phase: **prepare → commit**.

### What to build

**`cap validate --type <type>`** — reads frontmatter YAML from stdin, validates and
normalizes it against the type's structure, writes corrected frontmatter to stdout.
Exit 0 = valid (with warnings for optional missing fields). Exit 1 = invalid (missing
required fields or unknown field names).

```bash
# jot agent builds frontmatter, validates it:
cat <<EOF | cap validate --type Blip
---
title: uv
description: Fast Python package manager
ring: trial
quadrant: tools
tags: [PythonTools, BuildTooling]
link: https://github.com/astral-sh/uv
EOF
```

Returns:
```yaml
---
type: Blip
title: uv
description: Fast Python package manager
ring: Trial
quadrant: Tool
tags: [PythonTools, BuildTooling]
link: https://github.com/astral-sh/uv
---
# ✓ ring normalized: trial → Trial
# ✓ quadrant normalized: tools → Tool
# ✓ 6/6 fields valid
```

**`cap create --markdown -`** — reads a full frontmatter+body markdown blob from stdin
instead of building it from flags. Lets the validated output pipe straight into create:

```bash
cat <<EOF | cap validate --type Blip | cap create --type Blip --markdown -
---
title: uv
ring: trial
...
EOF
```

Or for jot agents that build the markdown in a variable:
```bash
echo "$markdown" | cap validate --type Blip --fix > /tmp/validated.md
# agent reads /tmp/validated.md, confirms it looks right
cap create --type Blip --markdown /tmp/validated.md
```

### Fill-first, error-last

`cap validate` tries to produce a complete, correct frontmatter blob. It only fails
(exit 1) when it genuinely cannot fill a field — i.e. the value must come from the
caller and there is no safe default or inference.

**What it fills automatically:**

| Field | How |
|---|---|
| `type:` | Always injected from `--type` arg if missing |
| `ring` casing | `trial` → `Trial`, `assess` → `Assess`, `adopt` → `Adopt`, `hold` → `Hold` |
| `quadrant` casing | `tool` → `Tool`, `technique` → `Technique`, `platform` → `Platform`, `language` → `Language` |
| `category` on Weblink | Infer from URL: `youtube.com` / `youtu.be` → `Video`, `vimeo.com` → `Video`, everything else → `Article` |
| `iframeUrl` on Weblink | Copy from `link` if `iframeUrl` is missing and `link` is present |
| Tag format | Strip surrounding quotes; bare identifiers only |
| Unknown field casing | Fuzzy-match to nearest known field name (edit distance ≤ 2) and rename with a warning — e.g. `Ring: trial` → `ring: Trial` |

**What triggers exit 1 (can't fill, caller must provide):**

- `title` missing — no safe default
- `iframeUrl` missing on Weblink AND no `link` to copy from
- `--type` value not found in the space's structure list

**Error output format**

Errors go to stderr. stdout always contains the best frontmatter the command could
produce (partial is fine — lets the caller see what was filled and what wasn't).

```
✗ title: required for Blip — not provided and cannot be inferred
  add to frontmatter:  title: <your title here>

✗ iframeUrl: required for Weblink — no link field to copy from
  add to frontmatter:  iframeUrl: https://...
  or:                  link: https://...  (will be copied to iframeUrl)

⚠ Ring → ring (field name had wrong case, corrected)
⚠ quadrant: "tools" is not a valid value — nearest match is "Tool" (corrected)
  valid values: Tool | Technique | Platform | Language

⚠ publisher: unknown field for Blip (kept — Capacities may accept it)
  known fields: title, description, ring, quadrant, link, tags, related

✓ category inferred as Video from iframeUrl host (youtube.com)
✓ iframeUrl copied from link
✓ type: Blip injected
```

**`--json` flag for agent consumption**

```json
{
  "valid": false,
  "corrected": "---\ntype: Blip\ntitle: \nring: Trial\n---",
  "errors": [
    { "field": "title", "code": "REQUIRED", "message": "required for Blip — not provided" }
  ],
  "warnings": [
    { "field": "ring", "code": "NORMALIZED", "from": "trial", "to": "Trial" }
  ],
  "filled": ["type", "category", "iframeUrl"]
}
```

Jot agents use `--json` so they can read `errors[]` programmatically and ask the
user for missing values rather than showing raw stderr.

### Implementation sketch (src/commands/validate.ts — new file)

The implementation has three phases: **parse → fill → check**.

```typescript
import { Command } from 'commander'
import { resolveSpace } from './_space.ts'
import { fetchWithCache, TTL } from '../cache.ts'
import { createClient } from '../client.ts'
import { handleApiError, CapacitiesError, ExitCode } from '../errors.ts'
import { printJson } from '../output.ts'
import * as readline from 'node:readline/promises'

const ENUMS: Record<string, Record<string, string>> = {
  ring:     { assess: 'Assess', trial: 'Trial', adopt: 'Adopt', hold: 'Hold' },
  quadrant: { tool: 'Tool', technique: 'Technique', platform: 'Platform', language: 'Language' },
}

const VIDEO_HOSTS = ['youtube.com', 'youtu.be', 'vimeo.com']

// simple edit-distance for field name fuzzy match
function editDistance(a: string, b: string): number {
  const dp = Array.from({ length: a.length + 1 }, (_, i) =>
    Array.from({ length: b.length + 1 }, (_, j) => i === 0 ? j : j === 0 ? i : 0))
  for (let i = 1; i <= a.length; i++)
    for (let j = 1; j <= b.length; j++)
      dp[i][j] = a[i-1] === b[j-1] ? dp[i-1][j-1]
        : 1 + Math.min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
  return dp[a.length][b.length]
}

type ValidationResult = {
  valid: boolean
  corrected: string
  errors: { field: string; code: string; message: string }[]
  warnings: { field: string; code: string; from?: string; to?: string; message: string }[]
  filled: string[]
}

export async function runValidate(typeName: string, opts: { space?: string; json?: boolean }): Promise<void> {
  // Phase 0: read stdin
  const rl = readline.createInterface({ input: process.stdin })
  const lines: string[] = []
  for await (const line of rl) lines.push(line)
  const raw = lines.join('\n')

  // Phase 0b: resolve type (cached 24h)
  const space = await resolveSpace(opts.space)
  const client = createClient(space)
  type StructuresResp = { structures: { id: string; title: string }[] }
  const structs = await fetchWithCache<StructuresResp>(space.name, 'structures.json', TTL.STRUCTURES,
    () => client.space.structures() as Promise<StructuresResp>)
  if (!structs.structures.find(s => s.title === typeName))
    throw new CapacitiesError(ExitCode.NOT_FOUND, `Unknown type "${typeName}". Run: cap search --type help`)

  // Phase 1: parse frontmatter
  const fmMatch = raw.match(/^---\n([\s\S]*?)\n---/)
  const fmLines = (fmMatch?.[1] ?? '').split('\n')
  const body = fmMatch ? raw.slice(fmMatch[0].length) : raw

  const result: ValidationResult = { valid: true, corrected: '', errors: [], warnings: [], filled: [] }
  const fields: Record<string, string> = {}

  // parse key: value lines
  for (const line of fmLines) {
    const m = line.match(/^(\S+):\s*(.*)$/)
    if (!m) continue
    const [, k, v] = m
    fields[k] = v.trim()
  }

  // Phase 2: fill what we can

  // inject type
  if (!fields['type']) { fields['type'] = typeName; result.filled.push('type') }

  // fuzzy-fix field name casing (e.g. Ring → ring, QuadRant → quadrant)
  for (const k of Object.keys(fields)) {
    const lower = k.toLowerCase()
    if (k !== lower && ENUMS[lower]) {
      result.warnings.push({ field: k, code: 'FIELD_CASE', message: `${k} → ${lower} (field name corrected)` })
      fields[lower] = fields[k]; delete fields[k]
    }
    // fuzzy match unknown fields to known enum keys
    if (!ENUMS[lower]) {
      for (const known of Object.keys(ENUMS)) {
        if (editDistance(lower, known) <= 2) {
          result.warnings.push({ field: k, code: 'FIELD_FUZZY', message: `"${k}" looks like "${known}" — corrected` })
          fields[known] = fields[k]; delete fields[k]; break
        }
      }
    }
  }

  // normalize enum values
  for (const [enumKey, table] of Object.entries(ENUMS)) {
    if (!fields[enumKey]) continue
    const norm = table[fields[enumKey].toLowerCase()]
    if (norm && norm !== fields[enumKey]) {
      result.warnings.push({ field: enumKey, code: 'NORMALIZED', from: fields[enumKey], to: norm,
        message: `${enumKey}: "${fields[enumKey]}" → "${norm}"` })
      fields[enumKey] = norm
    } else if (!norm) {
      result.warnings.push({ field: enumKey, code: 'UNKNOWN_VALUE',
        message: `${enumKey}: "${fields[enumKey]}" is not a recognized value. Valid: ${Object.values(table).join(' | ')}` })
    }
  }

  // Weblink-specific fills
  if (typeName === 'Weblink' || typeName === 'MediaWebResource') {
    if (!fields['iframeUrl'] && fields['link']) {
      fields['iframeUrl'] = fields['link']
      result.filled.push('iframeUrl')
      result.warnings.push({ field: 'iframeUrl', code: 'COPIED_FROM_LINK', message: 'iframeUrl copied from link' })
    }
    if (!fields['category'] && fields['iframeUrl']) {
      try {
        const host = new URL(fields['iframeUrl']).hostname.replace('www.', '')
        fields['category'] = VIDEO_HOSTS.includes(host) ? 'Video' : 'Article'
        result.filled.push('category')
        result.warnings.push({ field: 'category', code: 'INFERRED',
          message: `category inferred as ${fields['category']} from URL host (${host})` })
      } catch { /* invalid URL, skip */ }
    }
  }

  // strip tag quotes
  if (fields['tags']) {
    const cleaned = fields['tags'].replace(/['"]/g, '')
    if (cleaned !== fields['tags']) {
      result.warnings.push({ field: 'tags', code: 'TAG_FORMAT', message: 'tags: quotes stripped' })
      fields['tags'] = cleaned
    }
  }

  // Phase 3: check required fields
  const REQUIRED: Record<string, string[]> = {
    Blip: ['title'], Weblink: ['title', 'iframeUrl'], MediaWebResource: ['title', 'iframeUrl'],
    RootPage: ['title'], Task: ['title'], Personality: ['title'],
  }
  for (const req of (REQUIRED[typeName] ?? ['title'])) {
    if (!fields[req] || fields[req] === '') {
      result.valid = false
      result.errors.push({ field: req, code: 'REQUIRED',
        message: `${req}: required for ${typeName} — not provided and cannot be inferred` })
    }
  }

  // assemble corrected frontmatter
  const fmOut = Object.entries(fields).map(([k, v]) => `${k}: ${v}`).join('\n')
  result.corrected = `---\n${fmOut}\n---${body}`

  // output
  if (opts.json) {
    printJson(result, opts)
  } else {
    process.stdout.write(result.corrected + '\n')
    for (const w of result.warnings) process.stderr.write(`⚠ ${w.message}\n`)
    for (const e of result.errors)   process.stderr.write(`✗ ${e.message}\n  add to frontmatter: ${e.field}: <value>\n`)
    for (const f of result.filled)   process.stderr.write(`✓ ${f} filled automatically\n`)
  }

  if (!result.valid) process.exit(1)
}

export function registerValidate(program: Command): void {
  program
    .command('validate')
    .description('Validate, fill, and normalize frontmatter from stdin against a Capacities type')
    .requiredOption('-t, --type <type>', 'object type to validate against')
    .action(async (cmdOpts: { type: string }) => {
      await runValidate(cmdOpts.type, { ...program.opts(), ...cmdOpts }).catch(handleApiError)
    })
}
```

**`--markdown` on `cap create`** — add alongside the existing `--field` flag:

```typescript
.option('--markdown <path>', 'read full markdown blob from file path or "-" for stdin')

// in runCreate(), before building frontmatter:
if (opts.markdown) {
  const src = opts.markdown === '-' ? await readStdin() : await fs.readFile(opts.markdown, 'utf8')
  // send src directly as the markdown argument, skip frontmatterLines assembly
  const result = await (client.object.markdown as any).create({ structureId: objectType, markdown: src })
  // ... rest of create flow
  return
}
```

### Jot agent workflow with validate

```bash
# Step 1: agent builds markdown blob in a variable ($md)
# Step 2: validate + inspect
validated=$(echo "$md" | /Users/subramk/.local/bin/cap validate --type Blip)
echo "$validated"   # agent reads this, confirms fields look right

# Step 3: create from validated output
objectId=$(echo "$validated" | /Users/subramk/.local/bin/cap create --type Blip --markdown - --quiet)
echo $objectId

# Step 4: link entities
/Users/subramk/.local/bin/cap link "$objectId" related "$relatedId"
```

### Test

- Pipe frontmatter with `ring: trial` → assert output contains `ring: Trial`
- Pipe frontmatter with unknown field → assert warning in stderr, exit 0
- Pipe frontmatter with `--type` that doesn't exist → exit 4

---

## Verification

After implementing, run these against your live space:

```bash
# 1. Field flag — create a test Blip
cap create --type Blip --title "CLI Test Blip" \
  --desc "Testing --field flag" \
  --field ring=Assess \
  --field quadrant=Tool
# → returns objectId; verify ring/quadrant are set in Capacities UI

# 2. Validate + normalize
echo "---\ntitle: Test\nring: trial\nquadrant: tools\n---" | cap validate --type Blip
# → ring: Trial, quadrant: Tool in output

# 3. Full pipe: validate → create
echo "---\ntitle: Validate Test Blip\ndescription: Full pipe test\nring: trial\nquadrant: tool\nlink: https://example.com\n---" \
  | cap validate --type Blip \
  | cap create --type Blip --markdown -
# → returns objectId; object appears in Capacities with correct fields

# 4. Daily note
cap daily-note "## Test\n\nHandoff doc verified."
# → appears in today's daily note in Capacities
```

---

## What happens after

Once both commands are working, report back and jot's MCP calls will be replaced
with `cap` Bash calls. The jot plugin changes are already designed and ready to implement.
