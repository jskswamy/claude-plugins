# Task Capture Template

## Instructions for Agent

Quickly capture a task. Minimal structure for fast capture - to be processed later in GTD inbox review.

### Output Format

```markdown
# [Task Title]

**Status:** To Process
**Saved:** [Date]

*[DISCOVERY CONTEXT FROM USER - Must ask before saving]*

## 📋 Task
[Task description - what needs to be done]

## 📝 Notes
[Any additional context or details]

## 🔗 Related Notes
[[related-note-1]]
[[related-note-2]]

---
_Quick captured - process in GTD inbox review_
```

### Rules

- **REQUIRED: Ask for context** - "What were you working on when this came up?"
- **Keep it brief** - minimize friction
- **Use emojis on headings** exactly as shown
- **Filename**: `YYYY-MM-DD-slugified-title.md`
- **Save to**: `notes/inbox/`
- Output only markdown, no preamble
- Task will be processed later during GTD inbox review
