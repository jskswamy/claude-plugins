---
name: coach
description: Start a coaching session on any topic, URL, or local file
argument-hint: "<topic|url|path> [--depth shallow|standard|deep] [--no-recall]"
---

# Coach Command

Start an adaptive coaching session on any topic, URL, or local file. After the session, automatically flows into a recall phase to test understanding - unless `--no-recall` is passed.

## Arguments

- `<topic|url|path>` - What to study (required)
  - Plain text → concept coaching, also searches content vaults
  - URL → fetches and coaches on the content
  - Local path → reads and coaches on the file
- `--depth shallow|standard|deep` - Recall depth after coaching (default: standard)
- `--no-recall` - End after coaching without entering recall phase

## Workflow

### Step 1: Parse Arguments

Extract:
- Input (everything before flags)
- `--depth` value (default: standard)
- `--no-recall` flag presence

### Step 2: Read Config

```bash
cat ~/.claude/study.md 2>/dev/null
```

Extract `notes_path` and `content_vaults`. If config missing, prompt user to run `/study:setup` first.

Expand `~` in paths:
```bash
NOTES_PATH=$(eval echo "<notes_path>")
```

### Step 3: Detect Input Type

Determine what the user passed:

- Starts with `http://` or `https://` → **URL**
- Starts with `/`, `~/`, `./` or matches an existing file path → **local file**
- Otherwise → **topic** (search vaults, then treat as concept)

### Step 4: Extract Content (URL or File Only)

For URL or local file, delegate to the `content-extractor` agent:

**Provide:**
- Input type (url or file)
- The URL or resolved file path
- Notes path (for temp storage if needed)

**Agent returns:** extracted title, summary, full content.

### Step 5: Search Vaults (Topic Only)

For plain topic input, search configured content vaults:

```bash
grep -ril "<topic>" <vault_1> <vault_2> 2>/dev/null | head -10
```

If matches found, list them and ask the user to pick one or proceed with concept-only coaching.

### Step 6: Delegate to Coach Agent

Delegate to the `coach-agent` with:
- Topic name or title
- Extracted content (if any)
- Source (URL, file path, or "concept")
- Notes path
- Template path: `${CLAUDE_PLUGIN_ROOT}/templates/study-note.md`

The coach-agent runs the full coaching session and saves the coaching note.

### Step 7: Flow into Recall (Unless --no-recall)

After the coach-agent completes, unless `--no-recall` was passed:

Delegate to the `recall-agent` with:
- Topic slug (from coaching note filename)
- Notes path
- Depth level
- `from_coach: true` (skip prerequisite check - user just coached)

### Step 8: Done

Report the path to the saved coaching note.
