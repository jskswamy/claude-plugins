# Article Capture Template

## Instructions for Agent

Extract content from web articles and documentation into a comprehensive, structured summary. **Target 60-100+ lines of rich content.**

### Output Format

```markdown
# [Title]

**Source:** [URL]
**Captured:** [Date]
**Author:** [Author if available]

*[DISCOVERY CONTEXT FROM USER - Must ask before saving]*

## 📝 Summary

[2-3 sentences capturing the essence of the article - what it's about, why it matters, and the main approach or methodology.]

## 💎 Key Insight

> **TL;DR:** [The single most important takeaway - one sentence that captures the core message]

## 🏷️ Tags

`[tag1]` `[tag2]` `[tag3]` `[tag4]` `[tag5]` `[tag6]` `[tag7]`

## 🔑 Key Points

- [Main takeaway 1 - concise but complete]
- [Main takeaway 2]
- [Main takeaway 3]
- [Main takeaway 4]
- [Main takeaway 5]

## 📚 Details

### [Section 1: Core Concept or Framework]

[Detailed explanation with structure. Use numbered lists for processes/phases:]

1. **[Phase/Step 1]**: [Description]
2. **[Phase/Step 2]**: [Description]
3. **[Phase/Step 3]**: [Description]

### [Section 2: Key Components/Criteria]

[Break down important concepts:]

- [Component 1 with explanation]
- [Component 2 with explanation]
- [Component 3 with explanation]

### [Section 3: Applications/Use Cases]

- **[Category 1]**: [Examples]
- **[Category 2]**: [Examples]
- **[Category 3]**: [Examples]

## 💡 Key Arguments

[The main thesis or arguments made by the author. What are they trying to convince you of? Explain the logical flow:]

1. [First argument or premise]
2. [Supporting point]
3. [Conclusion or call to action]

## 🔗 Related Notes

[[related-note-1]]
[[related-note-2]]

## 📎 References

- [Original Article](url)
- [Related Resource 1](url)
- [Related Resource 2](url)
```

### Content Requirements

**IMPORTANT: Generate rich, detailed content. Target 60-100+ lines.**

1. **Summary**: 2-3 complete sentences, not just the headline
2. **Key Insight**: One powerful TL;DR sentence
3. **Key Points**: 4-5 distinct takeaways, each a complete thought
4. **Details**:
   - Break into 2-3 subsections with headers
   - Use numbered lists for processes/frameworks
   - Use bullet points for criteria/components
   - Include specific examples or use cases
5. **Key Arguments**: Explain the author's reasoning, not just conclusions
6. **Tags**: 5-7 relevant tags

### What to Extract

- Main thesis and arguments
- Frameworks, processes, or methodologies mentioned
- Specific examples and case studies
- Statistics and data points
- Actionable recommendations
- Related resources mentioned

### Rules

- **REQUIRED: Ask for discovery context** - "How did you discover this article? What caught your attention?"
- **Write in first person** - these are personal notes (use "I think", "I found")
- **Use emojis on headings** exactly as shown
- **Generate 5-7 relevant tags** - lowercase, hyphenated (e.g., `software-engineering`, `career`, `architecture`)
- **Be concise but capture essential information** - don't pad, but don't skip important details
- **Extract actionable insights** - what can be applied?
- **Note statistics and data points** - specific numbers are valuable
- **Filename**: `YYYY-MM-DD-slugified-title.md`
- **Save to**: `notes/articles/`
- Output only markdown, no preamble
