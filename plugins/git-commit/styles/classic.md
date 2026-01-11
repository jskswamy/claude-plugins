---
name: classic
description: Traditional git commit style following the "7 Rules of Great Git Commit Messages"
default: true
source: https://cbea.ms/git-commit/
---

# Classic Commit Style

The classic commit style follows the time-tested conventions established by the Git community and popularized by Chris Beams' "How to Write a Git Commit Message."

## Reference

**Source:** https://cbea.ms/git-commit/

For complex commits or edge cases not covered here, read the full article. It provides excellent context on why each rule matters and how to apply them in practice.

## The 7 Rules

1. **Separate subject from body with a blank line**
2. **Limit subject to 50 characters**
3. **Capitalize the subject line**
4. **Do not end subject with a period**
5. **Use imperative mood in the subject line**
6. **Wrap body at 72 characters**
7. **Use the body to explain what and why, not how**

## Subject Line Rules

### Capitalization
The first letter of the subject MUST be uppercase.
- Good: `Add user authentication`
- Bad: `add user authentication`

### No Type Prefixes
Do NOT use type prefixes like `feat:`, `fix:`, etc. This is what distinguishes classic from conventional commits.
- Good: `Add user authentication`
- Bad: `feat: add user authentication`

### Character Limit
Keep the subject line to 50 characters or fewer. This ensures readability in git log, GitHub, and other tools.

### No Trailing Period
The subject line is a title, not a sentence.
- Good: `Fix null pointer in session handler`
- Bad: `Fix null pointer in session handler.`

### Imperative Mood
Write the subject as if giving a command. The subject should complete the sentence: "If applied, this commit will ___"
- Good: `Add validation for email addresses`
- Bad: `Added validation for email addresses`
- Bad: `Adds validation for email addresses`
- Bad: `Adding validation for email addresses`

**Imperative verb examples:** Add, Fix, Update, Remove, Refactor, Rename, Move, Extract, Implement, Introduce, Merge, Release, Revert

## Body Rules

### When to Include a Body
Include a body when:
- The change requires explanation beyond the subject
- There's important context or reasoning to document
- The change has non-obvious implications
- You're reverting a previous change

Skip the body when:
- The subject fully explains the change
- The change is trivial (typo fix, formatting)

### Line Wrapping
Wrap all body lines at 72 characters. This ensures proper display in terminals and git tools.

### Content Guidelines
Explain:
- **WHAT** changed (if not obvious from the subject)
- **WHY** the change was made (motivation, context)
- **Implications** or side effects

Do NOT explain HOW - the code shows that.

### Formatting
- Use blank lines to separate paragraphs
- Use bullet points for lists (prefix with `-`)
- Reference issues/tickets when relevant

## Examples

### Minimal (Subject Only)
```
Fix typo in README
```

### With Body
```
Add rate limiting to authentication endpoint

Implement a sliding window rate limiter that allows 5 login attempts
per minute per IP address. After exceeding the limit, clients receive
a 429 response with a Retry-After header.

This prevents brute force attacks while allowing legitimate users
to recover from typos quickly.
```

### Explaining a Revert
```
Revert "Add caching to user lookup"

This reverts commit abc1234.

The caching implementation caused stale data issues when users
updated their profiles. Reverting until we implement proper cache
invalidation.
```

### With Issue Reference
```
Fix race condition in connection pool

Multiple threads could acquire the same connection when the pool
was nearly exhausted, leading to corrupted state.

The fix adds a mutex around the acquisition logic. Performance
impact is negligible since contention is rare.

Fixes #1234
```

## Anti-Patterns to Avoid

### Vague Subjects
- Bad: `Fix bug`
- Bad: `Update code`
- Bad: `Changes`
- Good: `Fix null pointer when user has no profile`

### Implementation Details in Subject
- Bad: `Add null check on line 45 of UserService.java`
- Good: `Handle missing user profile gracefully`

### Multiple Concerns
- Bad: `Fix login bug and add logout button`
- Good: Two separate commits

### Past Tense
- Bad: `Fixed the authentication issue`
- Good: `Fix authentication issue`

### Ending with Period
- Bad: `Add new feature.`
- Good: `Add new feature`

## Further Reading

For complex commits, edge cases, or deeper understanding of the rationale behind these rules, consult the original source:

**https://cbea.ms/git-commit/**

The article explains the history and reasoning behind each rule, helping you make better judgment calls in ambiguous situations.
