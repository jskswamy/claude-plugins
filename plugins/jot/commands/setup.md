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
- **capacities** — Save captures to your Capacities knowledge space via the `cap` CLI

## Step 2: If workbench chosen

Read `~/.claude/jot.md` if it exists (to preserve any existing fields).
Set `capture_backend: workbench` and write back to `~/.claude/jot.md`.

Report: "Configured. Captures will save to your workbench folder."

## Step 3: If capacities chosen — Discover and Confirm Type Mapping

Use the CLI for all type discovery. Always use the full path:
```
CAP=/Users/subramk/.local/bin/cap
```

### Step 3a: Discover Available Types via CLI

For each non-`daily_note` type in the default mapping table, validate it exists by running a search and checking the exit code:
```bash
$CAP search "*" --type "<TypeName>" --json 2>&1
```
- Exit 0 → type exists in this space
- Exit 4 → type not found; mark as missing

Run all checks in parallel via multiple Bash calls. The structures list is cached 24h after the first call, so subsequent lookups are instant.

Default mapping to check:

| jot type | Default Capacities type |
|---|---|
| task | Task |
| note | Page |
| idea | Page |
| session | daily_note *(skip — uses `cap daily-note`)* |
| blip | Blip |
| article | Page |
| video | Weblink |
| person | Person |
| book | Book |
| organisation | Organization |
| trove | Trove |
| research | Research |
| weblink | Weblink |

### Step 3b: Present Summary to User

Show which types were found and which are missing:
```
✓ Blip, Task, Page, Weblink, Person, Book, Organization, Research
✗ Trove — not found in your space
```

For any missing type, ask: "What Capacities type should jot use for '[jot type]' captures? (Or type 'skip' to exclude this type.)"

Validate any user-provided alternative with `$CAP search "*" --type "<name>" --json`. After 3 failed attempts for one type, ask: "Skip this type or abort setup?"

### Step 3c: Confirm Mapping

Tell the user: "Here are the confirmed mappings. Say 'yes' to accept all, or provide overrides as `key=TypeName` pairs (e.g. `blip=TechBlip, note=Note`)."

Wait for their response. Apply any overrides. Validate each override with `$CAP search "*" --type "<name>" --json` before accepting.

## Step 4: Write Config to ~/.claude/jot.md

Construct the YAML and write it to `~/.claude/jot.md` (expand `~` to home directory; create if absent, overwrite if present). Preserve any existing fields not managed by this step (such as `workbench_path`) by reading the current file first and merging — only `capture_backend` and `capacities_mapping` are replaced.

Write only `type:` per mapping entry — no `fields` array. Field normalization happens at capture time via `cap validate`.

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

If `cap` is unavailable (command not found), stop and tell the user: "capacities-cli is not installed or not in PATH. Expected at `/Users/subramk/.local/bin/cap`. Run `npm run link-bin` in the capacities-cli repo and re-run `/jot:setup`."

## Step 5: Report Success

"Capacities integration configured with [N] type mappings. Run `/jot:setup` any time to reconfigure."
