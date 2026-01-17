---
name: teach
description: Teach it back to deepen your understanding - requires you to have already engaged with the content (Feynman Technique)
argument-hint: "[type] <url|topic> [--depth shallow|standard|deep]"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - WebFetch
  - AskUserQuestion
---

# Teach Command

Teach back content you've already studied to deepen your understanding using the Richard Feynman Iterative Learning Framework. This command guides you through explaining concepts simply, identifying gaps, and iterating to mastery.

## Important: Prerequisites

**This command requires you to have already engaged with the content.**

The Feynman Technique works by having YOU explain concepts to reveal gaps in your understanding. This only works if you've spent time with the material first. There are no shortcuts to learning.

If you haven't read the paper, watched the video, or studied the concept yet, do that first. This command will ask to confirm your prior engagement before starting.

## The Feynman Framework

1. **Prerequisite Check** - Confirm you've engaged with the content
2. **Topic Assessment** - Identify subject and current understanding level
3. **Simplified Explanation** - You explain as if to a 12-year-old
4. **Gap Identification** - Highlight areas lacking depth/clarity
5. **Guided Questioning** - Questions to push re-explanation
6. **Iterative Refinement** - 2-3 cycles making simpler and clearer
7. **Application Testing** - Apply to new scenarios
8. **Teaching Note Creation** - Concise summary with memorable analogies

## Configuration

Read user settings from `.claude/jot.local.md` if it exists:

```yaml
---
workbench_path: ~/workbench
---
```

**Default**: If no config exists, use `~/workbench` as the workbench path.

## Content Types

### Supported Sources
- `paper` → Research papers (PDF URLs from arxiv, etc.)
- `video` → YouTube videos (requires yt-dlp)
- `article` → Web articles and documentation
- `concept` → Plain text concept/topic (no URL needed)

### Auto-Detection from URL
- `arxiv.org`, `*.pdf` → paper
- `youtube.com`, `youtu.be` → video
- Other URLs → article
- No URL → concept

## Depth Levels

| Depth | Iterations | Description |
|-------|------------|-------------|
| shallow | 1 | Quick check, single explanation cycle |
| standard | 2 | Two refinement cycles (default) |
| deep | 3 | Full deep-dive with extensive questioning |

## Workflow

### Step 1: Parse Arguments

Parse the command arguments to determine:
1. **Type**: First argument (paper, video, article, concept) or auto-detect
2. **URL/Topic**: The source URL or concept name
3. **Flags**: `--depth shallow|standard|deep` (default: standard)

**Examples:**
- `/teach concept Event Sourcing` → type=concept, topic="Event Sourcing"
- `/teach https://arxiv.org/pdf/2512.24601` → type=paper (auto-detected)
- `/teach video https://youtube.com/watch?v=abc --depth deep` → type=video, depth=deep

### Step 2: Read Configuration

```bash
# Expand ~ to home directory
WORKBENCH_PATH=$(eval echo "~/workbench")
```

Check if `.claude/jot.local.md` exists and read `workbench_path` from YAML frontmatter.

### Step 3: Ensure Directory Structure

Create the target directory if it doesn't exist:

```bash
mkdir -p "${WORKBENCH_PATH}/notes/learned"
```

### Step 4: Check for Existing Teaching Note

Before proceeding, check if a teaching note already exists:

```bash
ls "${WORKBENCH_PATH}/notes/learned/slugified-topic.md" 2>/dev/null
```

If found:
1. Read the existing note
2. Ask user: "Update existing teaching note" or "Create new" or "View existing"
3. If update: Proceed to enhance workflow
4. If create new: Continue to Step 5

### Step 5: Delegate to Content Extractor (URL-based only)

For URL-based content (paper, video, article), delegate to the `content-extractor` agent:

**Provide to agent:**
- Content type (paper, video, article)
- URL
- Workbench path

**Agent returns:**
- Extracted content (text, structure)
- Title
- Author (if available)
- Key sections

### Step 6: Delegate to Learning Tutor

Delegate to the `learning-tutor` agent for the interactive Feynman learning loop.

**Provide to agent:**
- Content type
- Extracted content (from Step 5) or topic name (for concepts)
- Source URL (if applicable)
- Depth level
- Workbench path
- Template path: `${CLAUDE_PLUGIN_ROOT}/templates/teach/teaching-note.md`

**Agent handles:**
- Prerequisite confirmation (Phase 0)
- All 7 phases of the Feynman Framework
- Interactive questioning with user
- Teaching note generation
- Related notes linking
- Saving to `notes/learned/`

### Step 7: Report Success

After the learning-tutor agent completes, report:
"Teaching note saved to [path]"
"Linked to [N] related notes" (if applicable)

## Examples

### Teach Back of a Research Paper
```
/teach paper https://arxiv.org/pdf/2512.24601
```
→ Confirms you've read it, runs Feynman loop
→ Saves to `~/workbench/notes/learned/attention-mechanisms.md`

### Teach Back of a YouTube Video
```
/teach video https://youtube.com/watch?v=abc123
```
→ Confirms you've watched it, extracts transcript for reference
→ Saves to `~/workbench/notes/learned/video-topic.md`

### Teach Back of an Article
```
/teach article https://martinfowler.com/articles/microservices.html
```
→ Confirms you've read it, runs Feynman loop
→ Saves to `~/workbench/notes/learned/microservices.md`

### Teach Back of a Concept
```
/teach concept Event Sourcing
```
→ Confirms you've studied it, runs full Feynman loop
→ Saves to `~/workbench/notes/learned/event-sourcing.md`

### Auto-Detect Type from URL
```
/teach https://arxiv.org/abs/2103.12345
```
→ Auto-detects as paper, confirms engagement, runs Feynman loop

### Control Depth
```
/teach concept CQRS --depth deep
```
→ Runs 3 refinement iterations for comprehensive solidification

## Tips

- **You must engage with the content first** - there are no shortcuts
- Start with `--depth standard` (default) for most topics
- Use `--depth shallow` for quick verification of understanding
- Use `--depth deep` for complex topics you want to master
- The more honestly you engage with the questions, the better
- Teaching notes integrate with your jot captures via [[wikilinks]]
- Your teaching notes are written in first person - they're YOUR understanding
