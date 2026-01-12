---
name: capture
description: Capture notes, tasks, ideas, blips, and URL content. Supports quick text captures and full URL-based extraction with auto-linking to related notes.
argument-hint: "[type] <content|url> [--ring adopt|trial|assess|hold] [--quadrant tools|techniques|platforms|languages]"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - WebFetch
  - AskUserQuestion
---

# Capture Command

Capture notes, tasks, ideas, and tech radar blips with minimal friction. Supports quick text captures and full URL-based extraction with auto-linking to related notes.

## Configuration

Read user settings from `.claude/jot.local.md` if it exists:

```yaml
---
workbench_path: ~/workbench
---
```

**Default**: If no config exists, use `~/workbench` as the workbench path.

## Capture Types

### Quick Captures (text-based, no URL)
- `task` → Save to `notes/inbox/` with task template
- `note` → Save to `notes/inbox/` with note template
- `idea` → Save to `notes/inbox/` with idea template
- `blip` → Save to `notes/blips/` with blip template (tech radar style)

### Full Captures (URL-based)
- `article` → Save to `notes/articles/`
- `video` → Save to `notes/videos/` (requires yt-dlp)
- `blip` → Save to `notes/blips/` (for GitHub repos, tools, technologies)
- `person` → Save to `notes/people/`
- `book` → Save to `notes/books/`
- `organisation` → Save to `notes/organisations/`
- `trove` → Save to `notes/troves/`
- `research` → Save to `notes/research/`

**NOTE**: The `tool` type is deprecated. Use `blip` for all tools, technologies, libraries, and frameworks. GitHub URLs auto-detect as blips.

## Workflow

### Step 1: Parse Arguments

Parse the command arguments to determine:
1. **Type**: First argument (task, note, idea, blip, article, video, person, book, organisation, trove, research)
2. **Content/URL**: Remaining text or URL
3. **Flags** (for blips): `--ring` and `--quadrant`

**Type aliases**: If user specifies `tool`, treat as `blip`.

If no type specified and content is a URL, auto-detect type:
- `youtube.com`, `youtu.be` → video
- `github.com` → blip (NOT tool - tools are captured as blips)
- `wikipedia.org/wiki/[Person]` → person
- Default → article

### Step 2: Read Configuration

```bash
# Expand ~ to home directory
WORKBENCH_PATH=$(eval echo "~/workbench")
```

Check if `.claude/jot.local.md` exists and read `workbench_path` from YAML frontmatter.

### Step 3: Ensure Directory Structure

Create the target directory if it doesn't exist:

```bash
mkdir -p "${WORKBENCH_PATH}/notes/[type]"
```

For quick captures (task, note, idea), use `notes/inbox/`.
For blips (including tools/technologies), use `notes/blips/`.

### Step 4: Check Dependencies (Video Only)

For video captures, check if `yt-dlp` is installed:

```bash
which yt-dlp || command -v yt-dlp
```

If not found, inform the user:
"YouTube capture requires yt-dlp. Install with: `brew install yt-dlp` (macOS) or `pip install yt-dlp`"

### Step 5: Ask for Context (ALL Captures)

**IMPORTANT**: Before processing any capture, ask the user:

"How did you discover this? What's the context?"

Use their response verbatim in italics at the top of the note.

### Step 6: Additional Questions (Blips Only)

For blip captures, also ask:
1. "What is this and why is it on your radar?" → Summary
2. "Why are you placing it at this ring level?" → Ring Rationale

### Step 7: Fetch Content (URL Captures)

For URL-based captures:
- Use WebFetch to retrieve page content
- For videos: Use yt-dlp to get transcript
- For GitHub (blips): Fetch README, installation, usage examples

### Step 8: Read Template

Read the appropriate template from the plugin's templates directory:
`${CLAUDE_PLUGIN_ROOT}/templates/capture/[type].md`

**Note**: For blips, always use the `blip.md` template which includes rich technical documentation.

### Step 9: Generate Note Content

Follow the template structure to generate the note content:
- Fill in metadata (date, source, etc.)
- Add user's discovery context in italics
- For blips: Include user's Summary and Ring Rationale
- For blips with URLs: Include 6+ features, installation commands, usage examples, pros/cons, alternatives
- Generate tags based on content

### Step 10: Find Related Notes (Auto-Linking)

Scan existing notes in the workbench for related content:

1. Extract tags and key terms from the new note
2. Search existing notes:
   ```bash
   # Find notes with matching tags
   grep -r "tag1\|tag2\|tag3" "${WORKBENCH_PATH}/notes/" --include="*.md"
   ```
3. Find notes with similar titles/topics
4. Add [[wikilinks]] to top 3-5 most relevant notes in "Related Notes" section

**Matching heuristics:**
- Same tags → Strong match
- Same quadrant (for blips) → Medium match
- Mentioned person/tool → Medium match
- Similar topic keywords → Weak match

### Step 11: Save the Note

Generate filename:
- Quick captures: `YYYY-MM-DD-slugified-title.md`
- Blips: `slugified-name.md` (no date prefix)
- Research: `slugified-topic.md` (no date prefix)

Save to the appropriate directory:
```
${WORKBENCH_PATH}/notes/[type]/[filename]
```

### Step 12: Report Success

Tell the user:
"Captured [type] to [full path]"

If related notes were found, also mention:
"Linked to [N] related notes"

## Examples

### Quick Task Capture
```
/capture task Review pull request from Alice
```
→ Asks for context
→ Saves to `~/workbench/notes/inbox/2026-01-12-review-pull-request-from-alice.md`

### Quick Note Capture
```
/capture note The API rate limit is 1000 requests per minute
```
→ Asks for context
→ Saves to `~/workbench/notes/inbox/2026-01-12-the-api-rate-limit.md`

### Idea Capture
```
/capture idea What if we used event sourcing for the audit log
```
→ Asks for context
→ Saves to `~/workbench/notes/inbox/2026-01-12-what-if-we-used-event-sourcing.md`

### Blip Capture (Quick)
```
/capture blip Kubernetes --ring adopt --quadrant platforms
```
→ Asks for context, summary, and ring rationale
→ Saves to `~/workbench/notes/blips/kubernetes.md`

### Blip Capture from URL (GitHub)
```
/capture blip https://github.com/astral-sh/uv --ring trial --quadrant tools
```
→ Asks for context, summary, and ring rationale
→ Fetches README, extracts features, installation, usage
→ Saves to `~/workbench/notes/blips/uv.md`

### Article Capture
```
/capture article https://martinfowler.com/articles/microservices.html
```
→ Asks for context
→ Fetches and extracts article content
→ Saves to `~/workbench/notes/articles/2026-01-12-microservices.md`

### Auto-Detect URL (GitHub → Blip)
```
/capture https://github.com/astral-sh/uv
```
→ Auto-detects as `blip` (GitHub URLs are captured as blips)
→ Asks for context, summary, and ring rationale
→ Saves to `~/workbench/notes/blips/uv.md`

## Tips

- For minimal friction, keep context answers brief
- Blips are for tracking technologies (tools, frameworks, libraries, platforms) on your personal radar
- Use task/note/idea for quick captures that go to inbox for later GTD processing
- Related notes are auto-linked using [[wikilinks]] - works great with Obsidian
- GitHub repos are always captured as blips, not articles
