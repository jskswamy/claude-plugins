# Note Capture Template

## Instructions for Agent

Quickly capture a thought, observation, or piece of information. Minimal structure for fast capture.

### Output Format

```markdown
# [Note Title]

**Saved:** [Date]

*[DISCOVERY CONTEXT FROM USER - Must ask before saving]*

## 📝 Note
[The thought, observation, or information]

## 🔗 Related Notes
[[related-note-1]]
[[related-note-2]]

---
_Quick captured_
```

### Rules

- **REQUIRED: Ask for context** - "What prompted this thought?"
- **Keep it brief** - minimize friction
- **Use emojis on headings** exactly as shown
- **Filename**: `YYYY-MM-DD-slugified-title.md`
- **Save to**: `notes/inbox/`
- Output only markdown, no preamble
