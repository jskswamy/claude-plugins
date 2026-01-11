---
name: conventional
description: Conventional Commits specification for automated changelog generation and semantic versioning
default: false
source: https://www.conventionalcommits.org/en/v1.0.0/
---

# Conventional Commits Style

The Conventional Commits specification provides a structured format designed for automation, including automatic changelog generation, semantic version bumping, and structured commit history.

## Reference

**Source:** https://www.conventionalcommits.org/en/v1.0.0/

For complex commits or edge cases not covered here, read the full specification. It provides the complete rules and explains the relationship with Semantic Versioning.

## Format

```
<type>[optional scope][!]: <description>

[optional body]

[optional footer(s)]
```

## Types

| Type | Description | SemVer Impact |
|------|-------------|---------------|
| `feat` | A new feature | MINOR |
| `fix` | A bug fix | PATCH |
| `docs` | Documentation only changes | - |
| `style` | Formatting, white-space, etc. (no code change) | - |
| `refactor` | Code change that neither fixes a bug nor adds a feature | - |
| `perf` | A code change that improves performance | PATCH |
| `test` | Adding missing tests or correcting existing tests | - |
| `build` | Changes to build system or external dependencies | - |
| `ci` | Changes to CI configuration files and scripts | - |
| `chore` | Other changes that don't modify src or test files | - |
| `revert` | Reverts a previous commit | - |

## Subject Line Rules

### Case
Use **lowercase** for type, scope, and description.
- Good: `feat(auth): add oauth2 login support`
- Bad: `Feat(Auth): Add OAuth2 login support`

### Character Limit
Keep the entire subject line (including type and scope) to 50 characters or fewer when possible, with a hard limit of 72 characters.

### No Trailing Period
- Good: `fix: resolve null pointer exception`
- Bad: `fix: resolve null pointer exception.`

### Imperative Mood
Use imperative mood in the description.
- Good: `feat: add user authentication`
- Bad: `feat: added user authentication`

## Scope

The scope provides additional context about what part of the codebase is affected.

### Format
Scope is enclosed in parentheses after the type: `type(scope): description`

### Guidelines
- Use lowercase
- Keep it short (one word when possible)
- Use consistent scopes across the project
- Common scopes: `api`, `ui`, `auth`, `db`, `config`, `deps`

### Examples
```
feat(auth): add password reset flow
fix(api): handle timeout errors gracefully
docs(readme): update installation instructions
refactor(ui): extract button component
```

## Breaking Changes

Breaking changes MUST be indicated in one of two ways:

### Option 1: Exclamation Mark
Append `!` after the type/scope:
```
feat(api)!: change authentication endpoint response format
```

### Option 2: Footer
Include `BREAKING CHANGE:` in the footer:
```
feat(api): change authentication endpoint response format

BREAKING CHANGE: The /auth/login endpoint now returns a JSON object
instead of a plain token string. Clients must update their parsing logic.
```

### Both Together (Recommended for Visibility)
```
feat(api)!: change authentication endpoint response format

BREAKING CHANGE: The /auth/login endpoint now returns a JSON object
instead of a plain token string.
```

## Body Rules

### Line Wrapping
Wrap all body lines at 72 characters.

### Content
Same as classic commits:
- Explain WHAT and WHY, not HOW
- Provide context for the change
- Reference related issues or discussions

## Footer Rules

### Format
Footers follow the format: `token: value` or `token #value`

### Common Footers
- `BREAKING CHANGE: <description>` - Indicates a breaking API change
- `Fixes #123` - Closes an issue
- `Refs #456` - References an issue without closing
- `Reviewed-by: Name <email>` - Code review attribution
- `Co-authored-by: Name <email>` - Pair programming attribution

## Examples

### Simple Feature
```
feat: add user profile page
```

### Feature with Scope
```
feat(ui): add dark mode toggle to settings
```

### Bug Fix with Body
```
fix(auth): resolve session timeout not refreshing

The session refresh logic was checking the wrong timestamp field,
causing sessions to expire even when the user was active.

Fixes #892
```

### Breaking Change
```
feat(api)!: require authentication for all endpoints

All API endpoints now require a valid JWT token in the Authorization
header. Previously, read-only endpoints were public.

BREAKING CHANGE: Unauthenticated requests to any endpoint will now
receive a 401 response. Clients must implement authentication before
upgrading.

Migration guide: https://docs.example.com/auth-migration
```

### Revert
```
revert: feat(ui): add experimental dashboard widget

This reverts commit abc1234def5678.

The widget caused performance issues on mobile devices. Reverting
while we investigate optimization options.
```

### Multiple Footers
```
fix(db): prevent connection pool exhaustion under load

Implement connection timeout and add health check pings to detect
and remove stale connections from the pool.

Fixes #1234
Refs #1100
Co-authored-by: Jane Doe <jane@example.com>
```

## Type Selection Guide

### When to Use `feat`
- Adding new functionality visible to users
- New API endpoints
- New UI components or pages

### When to Use `fix`
- Correcting incorrect behavior
- Fixing crashes or errors
- Resolving security vulnerabilities

### When to Use `refactor`
- Restructuring code without changing behavior
- Renaming variables/functions for clarity
- Extracting reusable components

### When to Use `chore`
- Updating `.gitignore`
- Modifying editor configs
- Maintenance tasks that don't affect src/test

### When to Use `build`
- Updating dependencies in package.json/Cargo.toml/etc.
- Modifying webpack/rollup/build configurations
- Docker/container changes

## Anti-Patterns to Avoid

### Wrong Type
- Bad: `feat: fix login bug` (should be `fix`)
- Bad: `fix: add new button` (should be `feat`)

### Uppercase
- Bad: `Feat: Add feature`
- Bad: `FIX: Resolve bug`

### Missing Type
- Bad: `add user authentication`
- Good: `feat: add user authentication`

### Vague Description
- Bad: `fix: fix bug`
- Good: `fix(auth): handle expired tokens gracefully`

### Period at End
- Bad: `feat: add new feature.`
- Good: `feat: add new feature`

## Further Reading

For complex commits, edge cases, or deeper understanding of the specification, consult the official source:

**https://www.conventionalcommits.org/en/v1.0.0/**

The specification covers:
- Full grammar and parsing rules
- Integration with Semantic Versioning (SemVer)
- FAQ for common questions
- Links to tooling and ecosystem
