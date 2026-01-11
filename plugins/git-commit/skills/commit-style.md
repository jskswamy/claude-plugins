---
name: commit-style
description: Provides guidance on writing good git commit messages, including classic commits, conventional commits, and atomic commit principles
---

# Git Commit Message Guidelines

This skill provides context about writing effective git commit messages.

## When to Activate

Activate this skill when the user asks about:
- How to write commit messages
- Commit message formats or styles
- Conventional commits vs classic commits
- What makes a good commit message
- Atomic commits
- Git best practices for commits

## Available Commit Styles

This plugin supports multiple commit styles. For detailed rules, examples, and anti-patterns, read the style files in the `styles/` directory:

- **Classic** (`styles/classic.md`) - Traditional git commit style following the "7 Rules"
- **Conventional** (`styles/conventional.md`) - Structured format for automation

## Quick Reference

| Aspect | Classic | Conventional |
|--------|---------|--------------|
| Subject case | Capitalized | lowercase |
| Type prefix | No | Yes (feat:, fix:, etc.) |
| Max subject | 50 chars | 50 chars (including type) |
| Body wrap | 72 chars | 72 chars |
| Mood | Imperative | Imperative |
| Automation | Manual | Changelog/semver friendly |

## Atomic Commits

An atomic commit represents a **single, complete, coherent unit of work**.

### Principles

1. **Single Responsibility:** One commit = one logical change
2. **Reversibility:** Can be reverted without side effects
3. **Completeness:** Leaves codebase in working state
4. **Describable:** Can be explained in one sentence without "and also"

### Red Flags (Non-Atomic)

- Multiple unrelated concerns in one commit
- Using "and" to connect separate ideas in message
- Mix of bug fix + new feature
- Changes across unrelated modules
- Difficult to revert cleanly

### Benefits

- **Easier code review:** Reviewers understand each change
- **Clean git history:** Meaningful, navigable history
- **Safe git bisect:** Find bugs efficiently
- **Simple reverts:** Undo specific changes without collateral damage

## Recommendations

- **Default to classic commits** for most projects
- **Use conventional commits** when you need:
  - Automated changelog generation
  - Semantic version bumping
  - Structured commit history for tooling
- **Always write atomic commits** regardless of style
- **Use `/commit`** to generate properly formatted messages

## Detailed Style Guides

For comprehensive rules, examples, and anti-patterns for each style, read the corresponding file in the `styles/` directory. The style files are the authoritative source for formatting rules.
