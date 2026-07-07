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

## Step 3: If capacities chosen — Confirm Type Mapping

Present the following default jot-to-Capacities mapping to the user:

| jot type     | Default Capacities type       |
|--------------|-------------------------------|
| task         | Task                          |
| note         | Page                          |
| idea         | Page                          |
| session      | daily_note *(special)*        |
| blip         | Page                          |
| article      | Page                          |
| video        | Page                          |
| person       | Person                        |
| book         | Book                          |
| organisation | Page                          |
| trove        | Page                          |
| research     | Page                          |

`daily_note` is a special value — session captures use `saveToDailyNote` instead of `createObjectViaMD`. Skip validation for this type.

Tell the user: "Here are the proposed jot → Capacities type mappings. Say 'yes' to accept all, or provide overrides as space- or comma-separated key=value pairs (e.g. `note=Article, blip=Blip`). Extract all key=value tokens from the user's response, ignoring surrounding prose."

Wait for their response. Apply any overrides to the mapping before proceeding.

## Step 4: Validate Capacities Types via getObjectTypeShape

For each mapping where the Capacities type is NOT `daily_note`:

1. Call `getObjectTypeShape(objectType: "<mapped type>")` via the Capacities MCP. If the Capacities MCP tool is unavailable, stop and tell the user: 'Capacities MCP is not connected. Connect it and re-run `/jot:setup`.'
2. **If the call fails or returns no writable properties:**
   - Warn: "Type '[name]' was not found in your Capacities space."
   - Ask the user: "What Capacities type should jot use for '[jot type]' captures?"
   - Re-validate the new name (repeat this step for that type only).
   - After 3 failed attempts for any one type, ask the user: 'Skip this jot type for now, or abort setup entirely?' and honour their choice.
3. **If valid:** extract the list of writable fields from the response — each item has a `frontmatterKey` (string) and an indication of whether it is required.

## Step 5: Write Config to ~/.claude/jot.md

Construct the YAML and write it to `~/.claude/jot.md` (expand `~` to home directory; create if absent, overwrite if present). Preserve any existing fields not managed by this step (such as `workbench_path`) by reading the current file first and merging — only `capture_backend` and `capacities_mapping` are replaced.
For each type, fill `type` with the confirmed Capacities type name and `fields` with the actual writable fields from Step 4 (empty array `[]` for `daily_note`).

Example structure (actual values come from Step 4 results):

```yaml
---
capture_backend: capacities
capacities_mapping:
  task:
    type: "Task"
    fields:
      - { key: "title", required: true }
      - { key: "dueDate", required: false }
  note:
    type: "Page"
    fields:
      - { key: "title", required: true }
      - { key: "tags", required: false }
  idea:
    type: "Page"
    fields:
      - { key: "title", required: true }
      - { key: "tags", required: false }
  session:
    type: "daily_note"
    fields: []
  blip:
    type: "Page"
    fields:
      - { key: "title", required: true }
      - { key: "tags", required: false }
  article:
    type: "Page"
    fields:
      - { key: "title", required: true }
  video:
    type: "Page"
    fields:
      - { key: "title", required: true }
  person:
    type: "Person"
    fields:
      - { key: "title", required: true }
      - { key: "email", required: false }
  book:
    type: "Book"
    fields:
      - { key: "title", required: true }
      - { key: "author", required: false }
  organisation:
    type: "Page"
    fields:
      - { key: "title", required: true }
  trove:
    type: "Page"
    fields:
      - { key: "title", required: true }
  research:
    type: "Page"
    fields:
      - { key: "title", required: true }
---
```

## Step 6: Report Success

"Capacities integration configured. Run `/jot:setup` any time to reconfigure."
