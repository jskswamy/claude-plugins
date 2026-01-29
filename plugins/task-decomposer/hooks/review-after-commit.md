---
event: Stop
description: After task-related commits, prompt to review any parked ideas from that task
---

# Review After Commit Hook

This hook triggers after a commit that references a beads task, prompting the user to review any parked ideas that were captured while working on that task.

## Trigger Conditions

This hook activates when:
1. A git commit was just completed
2. The commit message contains a beads task reference (e.g., `#claude-plugins-xyz` or `Closes: claude-plugins-xyz`)

## Workflow

### 1. Extract Task ID from Recent Commit

```bash
# Get the most recent commit message
git log -1 --pretty=format:"%B"
```

Look for patterns:
- `#claude-plugins-xxx` or `#{prefix}-xxx`
- `Closes: claude-plugins-xxx` or `Closes: {prefix}-xxx`
- `Fixes: {id}`
- `Refs: {id}`

If no task reference found, skip this hook silently.

### 2. Find Parked Ideas Linked to That Task

```bash
# List all parked ideas
bd list --status=deferred --labels=parked-idea --json
```

Filter for ideas that:
- Have dependency on the committed task ID
- Were parked "while working on" that task (check description text)

If no parked ideas found for this task, skip silently.

### 3. Prompt for Review

```
---
Commit successful!

You have {N} parked idea(s) from task {task-id}:

1. **{title}** - "{first line of idea}"
2. **{title}** - "{first line of idea}"

These were thoughts you captured while working. What would you like to do?
- Review and decide on each
- Keep all parked for later
- Discard all
---
```

### 4. Handle User Choice

**Review each:**
For each parked idea, show:
```
**{title}** ({id})

{full idea text}

Context: Parked while working on {source task}

→ Promote to real issue
→ Keep parked
→ Discard
```

Then execute based on choice:
- Promote: `bd update {id} --status open` + remove parked-idea label + remove PARKED: prefix
- Keep: no action
- Discard: `bd delete {id}`

**Keep all:**
> Keeping all {N} ideas parked. Review anytime with "review parked ideas".

**Discard all:**
```bash
bd delete {id1} {id2} ...
```
> Discarded {N} parked ideas.

### 5. Summary

After processing:
```
Review complete:
- Promoted: {N} → now in `bd ready`
- Kept parked: {N}
- Discarded: {N}
```

---

## Implementation Notes

- This hook runs at conversation Stop, checking if recent activity included a task commit
- It's non-blocking - user can dismiss and review later
- Parked ideas are linked via:
  - Explicit dependency: `bd dep add {parked-id} {source-task-id}`
  - Text in description: "Parked while working on: {task-id}"
- The hook complements the on-demand `/review-parked` skill

---

## Skip Conditions

Don't trigger this hook if:
- No commit happened in recent conversation turns
- Commit doesn't reference a beads task
- No parked ideas exist for the referenced task
- User explicitly dismissed the review prompt previously in this session
