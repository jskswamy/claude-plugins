# Teaching Note Template

## Instructions for Agent

Generate a comprehensive teaching note that captures the user's learning journey and refined understanding using the Feynman Technique. This should be a standalone resource they can return to for review.

### Output Format

```markdown
# [Topic Title]

**Source:** [URL or "Concept"]
**Learned:** [YYYY-MM-DD]
**Based on:** [paper|video|article|concept]

*[One-sentence essence of the topic - the core insight in plain language]*

## 🎯 The Simple Explanation

[The final, refined explanation from the learning session. Write this as if explaining to a curious 12-year-old. 2-3 paragraphs, no jargon. Use the user's own words where possible, cleaned up for clarity. This is THEIR understanding, captured.]

## 💡 Key Insight

> **TL;DR:** [Single most important takeaway - one powerful sentence that captures the essence]

## 🏷️ Tags

`[tag1]` `[tag2]` `[tag3]` `[tag4]` `[tag5]`

## 🧩 Core Concepts

| Concept | Simple Definition |
|---------|-------------------|
| [Term 1] | [Plain-language definition a 12-year-old could understand] |
| [Term 2] | [Plain-language definition] |
| [Term 3] | [Plain-language definition] |
| [Term 4] | [Plain-language definition] |

## 🎭 Analogies That Stick

### Primary Analogy

> **[Topic] is like [analogy]** because [explanation of why this analogy works and what aspects it captures].

### Alternative Perspective

> You can also think of it as [alternative analogy] - [brief explanation of this different angle].

## ❌ Common Misconceptions

- **Misconception 1:** [What people often incorrectly think]
  - **Reality:** [What's actually true and why]

- **Misconception 2:** [Another common misunderstanding]
  - **Reality:** [The correct understanding]

## 🔧 Applied Understanding

### Scenario 1: [Descriptive Title]

[Description of the real-world scenario discussed]

**How it applies:** [How the concept works in this scenario]

### Scenario 2: [Descriptive Title]

[Description of the edge case or boundary scenario]

**Key insight:** [What this scenario reveals about the topic's limitations or nuances]

### When NOT to Use This

[Counter-examples or situations where this concept doesn't apply, if discussed]

## 📈 Learning Journey

**Started with:**
> [User's initial understanding/prior knowledge, quoted if memorable]

**Key gaps identified:**
- [Gap 1 that was addressed during learning]
- [Gap 2 that was addressed]
- [Gap 3 if applicable]

**Breakthrough moment:**
> [The "aha!" insight or key realization from the learning session - capture the moment of understanding]

## 🔗 Related Notes

[[related-note-1]]
[[related-note-2]]
[[related-note-3]]

## 📚 References

- [Source URL if applicable]
- [Additional resources mentioned during learning]
```

### Content Requirements

1. **Simple Explanation** (required)
   - Must be in plain language - no jargon
   - Written in first person from user's perspective
   - 2-3 paragraphs capturing their refined understanding
   - Use their actual words where they were clear

2. **Key Insight** (required)
   - Single sentence - the most important takeaway
   - Should be memorable and quotable
   - Captures the "so what?" of the topic

3. **Tags** (required)
   - 5 relevant tags
   - Lowercase, hyphenated (e.g., `event-sourcing`, `distributed-systems`)
   - Mix of specific and general for discoverability

4. **Core Concepts** (required)
   - 4-6 key terms that came up during learning
   - Definitions must be simple - no jargon in definitions
   - These are the building blocks of understanding

5. **Analogies** (required)
   - Include the user's analogy if they created a good one
   - Always provide an alternative perspective
   - Analogies should be vivid and relatable

6. **Misconceptions** (required)
   - 2-3 common misunderstandings
   - Based on gaps identified during the session
   - "Reality" section should be constructive, not dismissive

7. **Applied Understanding** (required)
   - 2+ real-world scenarios from the session
   - Show practical application, not just theory
   - Include any limitations or edge cases discussed

8. **Learning Journey** (required)
   - Capture where they started
   - List the specific gaps that were filled
   - The breakthrough moment is the heart of the note

9. **Related Notes** (optional but encouraged)
   - Link to existing notes in the workbench
   - Use [[wikilinks]] format for Obsidian compatibility
   - Max 5 related notes

### Writing Rules

- **First person perspective** - "I learned...", "I think of it as...", "My understanding is..."
- **Use emojis on headings** exactly as shown in template
- **Be concise** - quality over quantity, but ensure completeness
- **Make it scannable** - someone should be able to review quickly
- **Make it standalone** - a reader unfamiliar with the topic should understand
- **Capture the user's voice** - these are their notes, not a textbook

### File Naming

- **Filename**: `slugified-topic-name.md`
  - Lowercase
  - Hyphens for spaces
  - No special characters
  - No date prefix (unlike inbox items)
  - Examples: `event-sourcing.md`, `attention-mechanisms.md`, `cap-theorem.md`

- **Save to**: `${WORKBENCH_PATH}/notes/learned/`

### Output

- Output only the markdown content
- No preamble or explanation
- The note should be ready to save directly
