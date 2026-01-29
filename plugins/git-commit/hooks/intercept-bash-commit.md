# Bash Git Commit Interception

You are about to execute a Bash command. Check if it contains a `git commit` operation.

## Detection Logic

Examine the command for git commit patterns:
- `git commit`
- `git commit -m`
- `git commit -am`
- `git commit --amend`
- `git commit -a -m`
- Any variation with `git` followed by `commit`

**Exceptions - DO NOT intercept these:**
- Commands that only READ commit info: `git log`, `git show`, `git rev-parse`
- Commands checking commit status: `git status`
- Commands in subshells that don't actually commit: `$(git log ...)`
- The /commit command itself invoking git commit (check if already in commit workflow)

## If Command Contains Git Commit

**BLOCK this tool call** and redirect to the `/commit` plugin:

### Why Direct Git Commit Should Be Avoided

The git-commit plugin provides critical features that direct `git commit` bypasses:

1. **Atomic Commit Validation**
   - Detects when staged changes mix unrelated concerns
   - Helps split non-atomic changes into separate commits
   - Checks for related unstaged files that should be included

2. **Intelligent Message Generation**
   - Analyzes the diff to understand WHAT changed
   - Reviews conversation history to capture WHY
   - Generates properly formatted messages (72-char wrap, style rules)

3. **Style Enforcement**
   - Classic style: Clean subject lines following "7 rules of commit messages"
   - Conventional style: Structured format (feat:, fix:, etc.)

4. **Safety Features**
   - Amend safety checks (pushed commits, author verification)
   - Prevents accidental commits of mixed concerns

### Redirect Instructions

Instead of running the git commit command directly, invoke:

```
/commit
```

Available options:
- `/commit` - Default classic style with atomicity checks
- `/commit --style conventional` - Use conventional commit format
- `/commit --amend` - Safely amend the previous commit
- `/commit --pair` - Add co-author attribution
- `/commit --no-atomic-check` - Skip atomicity validation (use sparingly)
- `/commit <context>` - Provide context for better message generation

## If Command Does NOT Contain Git Commit

Allow the command to proceed normally. This hook only intercepts git commit operations.

---

**Decision Logic:**
- Contains `git commit` -> **BLOCK** and suggest `/commit`
- Does not contain `git commit` -> **ALLOW** to proceed
