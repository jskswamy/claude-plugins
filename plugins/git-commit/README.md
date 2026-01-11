# Git Commit Plugin

Generate intelligent git commit messages with classic or conventional commit style support and strict atomic commit validation.

## Features

- **Two Commit Styles:** Classic commits (default) and conventional commits
- **Strict Atomic Commit Validation:** Warns when staged changes aren't atomic
- **Split Commits Helper:** Guides you through staging changes separately
- **Pair Programming Support:** Save and reuse co-author information
- **Smart Message Generation:** Analyzes your diff to generate meaningful messages

## Installation

```bash
claude /plugin install github:jskswamy/claude-plugins/plugins/git-commit
```

Or for local development:

```bash
claude --plugin-dir ./plugins/git-commit
```

## Usage

### Basic Usage

```bash
/commit                    # Generate commit with default style (classic)
```

### With Context

```bash
/commit fix the login redirect issue    # Provide context for message generation
/commit refactoring auth for testability
```

### Style Options

```bash
/commit --style classic       # Classic commits (default)
/commit --style conventional  # Conventional commits (feat:, fix:, etc.)
/commit -s conventional       # Short form
```

### Amending Commits

```bash
/commit --amend              # Amend previous commit
/commit -a                   # Short form
```

### Pair Programming

```bash
/commit --pair               # Add co-author to commit
/commit -p                   # Short form
```

First time: Enter co-author name and email, optionally save for future use.
Subsequent: Pick from saved pairs or add new.

### Skip Atomicity Check

```bash
/commit --no-atomic-check    # Skip atomic commit validation
```

### Combined Options

```bash
/commit -p -s conventional fix auth bug
/commit --pair --amend update the error message
```

## Commit Styles

### Classic Commits (Default)

Follows the "7 Rules of Great Git Commit Messages":

1. Separate subject from body with a blank line
2. Limit subject to 50 characters
3. Capitalize the subject line
4. Do not end subject with a period
5. Use imperative mood ("Add feature" not "Added feature")
6. Wrap body at 72 characters
7. Explain what and why, not how

**Example:**
```
Add user authentication with OAuth2 support

Implement OAuth2 authentication flow for the login system. This adds
support for Google and GitHub as identity providers.

The migration to OAuth2 provides:
- Single sign-on capability
- Reduced password management burden
- Industry-standard security practices
```

### Conventional Commits

Structured format for automation (changelogs, semantic versioning):

**Format:** `<type>[scope]: <description>`

**Types:** feat, fix, docs, style, refactor, perf, test, build, ci, chore

**Example:**
```
feat(auth): add OAuth2 login support

Implement OAuth2 authentication flow for the login system.
Adds support for Google and GitHub as identity providers.

BREAKING CHANGE: removes legacy session-based authentication
```

## Atomic Commit Validation

The plugin enforces atomic commits by default. An atomic commit:

- Does ONE thing and one thing only
- Can be reverted without side effects
- Can be described in ONE sentence (no "and also")

### What Gets Flagged

- Multiple unrelated modules changed together
- Mix of bug fix + new feature
- Multiple distinct purposes in one commit

### When Flagged

You'll see options to:
- **Split commits** - Stage changes separately (recommended)
- **Proceed anyway** - Commit all together
- **Review changes** - See the diff again
- **Cancel** - Exit without committing

### Related Changes Detection

The plugin also checks for unstaged changes that might belong with your staged changes:

| Pattern | Example |
|---------|---------|
| Test files | Staged `foo.ts` with unstaged `foo.test.ts` |
| Same directory | Other modified files in the same module |
| Manifest files | `package.json`, `tsconfig.json` changes |
| Config companions | `feature.ts` with `feature.config.ts` |

When related unstaged files are detected, you can:
- **Stage related files** - Include them in this commit (recommended)
- **Review changes** - See the unstaged diff first
- **Proceed without** - Commit only the originally staged files

## Configuration

Settings are stored in `.claude/git-commit.local.md`:

```yaml
---
commit_style: classic
pairs:
  - name: "John Doe"
    email: "john@example.com"
---
```

### Settings

| Setting | Values | Description |
|---------|--------|-------------|
| `commit_style` | `classic`, `conventional` | Default commit style |
| `pairs` | list | Saved co-authors for pair programming |

## Adding Custom Commit Styles

Commit styles are defined in the `styles/` directory. Each style is a self-contained markdown file with YAML frontmatter.

**Structure:**
```
plugins/git-commit/
└── styles/
    ├── classic.md       # Traditional git commit style
    ├── conventional.md  # Conventional Commits spec
    └── your-style.md    # Add your own!
```

**Style file format:**
```yaml
---
name: your-style
description: Brief description of the style
default: false
---

# Style Name

Rules and examples in markdown format...
```

To add a new style:
1. Create a new `.md` file in `styles/`
2. Add YAML frontmatter with name and description
3. Document the rules, examples, and anti-patterns
4. Use with `/commit --style your-style`

## Sources

- [How to Write a Git Commit Message](https://cbea.ms/git-commit/) - The 7 rules
- [Conventional Commits](https://www.conventionalcommits.org/) - Specification
- [Atomic Git Commits](https://www.aleksandrhovhannisyan.com/blog/atomic-git-commits/) - Best practices

## License

MIT
