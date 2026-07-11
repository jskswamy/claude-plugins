---
name: setup
description: Configure jot's capture backend (workbench or Capacities). Run once for first-time setup, re-run any time to reconfigure.
argument-hint: ""
---

# Jot Setup

Configure where jot saves your captures: to a local workbench folder or to your Capacities knowledge space.

## Config Location

Reads and writes `~/.claude/jot.md` (global config, not per-project).
Expand `~` to the home directory before reading or writing.

## Step 1: Ask Backend Preference

Use AskUserQuestion with two options:
- **workbench** — Save captures as markdown files in your local workbench folder (current default)
- **capacities** — Save captures to your Capacities knowledge space via MCP

## Step 2: If workbench chosen

Read `~/.claude/jot.md` if it exists (to preserve any existing fields).
Set `capture_backend: workbench` and write back to `~/.claude/jot.md`.

Report: "Configured. Captures will save to your workbench folder."

## Step 3: If capacities chosen — Discover and Confirm Type Mapping

### Step 3a: Discover Available Types via MCP

Call `getObjectTypeShape` for each non-`daily_note` type in the default mapping table — run all calls in parallel. The goal is not just validation but **understanding the relationship topology** of the user's Capacities space: what entity fields each type has, what other types those fields link to (`allowedStructureIds`), and how the types connect.

Default mapping to probe:

| jot type | Default Capacities type |
|---|---|
| task | Task |
| note | Page |
| idea | Page |
| session | daily_note *(skip — uses `saveToDailyNote`)* |
| blip | Blip |
| article | Page |
| video | Weblink |
| person | Person |
| book | Book |
| organisation | Organization |
| trove | Trove |
| research | Research |
| weblink | Weblink |

For each call:
- **Success** → extract the type's title, its entity fields (`type: entity`), and `allowedStructureIds` per field
- **Failure** → type not found in this space; mark as missing

### Step 3b: Present Relationship Summary to User

Show a summary of what was discovered. For each jot type, show: found/not-found, key entity fields, and what types those fields accept.

Example:
```
✓ Blip         — ring, quadrant, link, related (→ any), tags
✓ Research     — date, blips (→ Blip), organizations (→ Organization), tags
✓ Person       — worksFor (→ Organization), tags
✓ Personality  — organizations (→ Organization), books (→ Book), creator (→ Person), tags
✓ Weblink      — iframeUrl, category, topic, tags
✗ Trove        — not found in your space
```

For any missing type, ask: "What Capacities type should jot use for '[jot type]' captures? (Or type 'skip' to exclude this type.)"

Re-probe any user-provided alternative with `getObjectTypeShape`. After 3 failed attempts for one type, ask: "Skip this type or abort setup?"

### Step 3c: Confirm Mapping

Tell the user: "Here are the confirmed mappings. Say 'yes' to accept all, or provide overrides as `key=TypeName` pairs (e.g. `blip=TechBlip, note=Note`)."

Wait for their response. Apply any overrides to the mapping. For any override, validate with `getObjectTypeShape` before accepting.

## Step 4: Write Config to ~/.claude/jot.md

Construct the YAML and write it to `~/.claude/jot.md` (expand `~` to home directory; create if absent, overwrite if present). Preserve any existing fields not managed by this step (such as `workbench_path`) by reading the current file first and merging — only `capture_backend` and `capacities_mapping` are replaced.

Write only `type:` per mapping entry — no `fields` array. Field discovery happens at capture time via `getObjectTypeShape`.

```yaml
---
capture_backend: capacities
capacities_mapping:
  task:
    type: "Task"
  note:
    type: "Page"
  idea:
    type: "Page"
  session:
    type: "daily_note"
  blip:
    type: "Blip"
  article:
    type: "Page"
  video:
    type: "Weblink"
  person:
    type: "Person"
  book:
    type: "Book"
  organisation:
    type: "Organization"
  trove:
    type: "Trove"
  research:
    type: "Research"
  weblink:
    type: "Weblink"
---
```

Omit any jot type the user chose to skip.

If the Capacities MCP is unavailable at any point during Step 3a, stop and tell the user: "Capacities MCP is not connected. Connect it and re-run `/jot:setup`."

## Step 5: Report Success

"Capacities integration configured with [N] type mappings. Run `/jot:setup` any time to reconfigure."
