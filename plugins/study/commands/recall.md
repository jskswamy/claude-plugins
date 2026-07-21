---
name: recall
description: Run a Feynman recall session on a previously coached topic
argument-hint: "<topic|url> [--depth shallow|standard|deep]"
---

# Recall Command

Run a Feynman-style recall session on a topic you've previously coached or studied independently. Reads the existing coaching note to target known gaps, then appends a row to the Recall Log.

## Arguments

- `<topic|url>` - Topic name or original URL used during coaching (required)
- `--depth shallow|standard|deep` - How many Feynman iterations to run (default: standard)

## Workflow

### Step 1: Parse Arguments

Extract topic/url and depth (default: standard).

### Step 2: Read Config

```bash
cat "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/study.md" 2>/dev/null
```

Extract `notes_path`. Expand `~`:
```bash
NOTES_PATH=$(eval echo "<notes_path>")
```

### Step 3: Find Coaching Note

Generate slug from input (lowercase, hyphens, strip special chars).

```bash
ls "${NOTES_PATH}/<slug>.md" 2>/dev/null
```

If not found, try fuzzy match:
```bash
ls "${NOTES_PATH}/" | grep -i "<keywords_from_topic>"
```

If still not found:
- Inform user no coaching note exists for this topic
- Ask: start a coaching session first with `/study:coach <topic>`, or run recall without prior note?
- If they choose to proceed without note: run recall as cold recall (no gap targeting)

### Step 4: Delegate to Recall Agent

Spawn the `recall-agent` ONCE with:
- Topic name
- Coaching note path (or null if not found)
- Notes path
- Depth level
- `from_coach: false`

Store the returned agentId as `RECALL_AGENT_ID`.

For every subsequent user response during the session, use:
```
SendMessage(to: RECALL_AGENT_ID, content: <user response>)
```

Do NOT spawn a new agent for follow-up turns. The same agent tracks all
explanation attempts, gap assessments, and probe answers in one context.

The session ends when the agent updates the coaching note and wraps up.

### Step 5: Done

Report: "Recall log updated in `<note_path>`"
