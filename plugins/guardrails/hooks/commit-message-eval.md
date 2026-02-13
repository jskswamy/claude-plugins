# Commit Message Context Leak Detection

You are about to execute a `git commit` command. Before allowing it, you MUST evaluate the commit message for leaked internal context.

## Quick Check

First, determine if this Bash command contains a `git commit` operation. If it does NOT contain `git commit`, **ALLOW this tool call immediately** - no further evaluation needed.

If it DOES contain `git commit`, extract the commit message and evaluate it below.

## Evaluation Criteria

Check the commit message for these violations:

### BLOCK if any of these are found:

1. **Task Tracker IDs**: `beads-*` prefixes or similar internal tracker IDs that aren't public issue references
2. **Workflow Phase Labels**: "Phase 1", "Phase 2", etc. used as structural labels (NOT technical terms like "two-phase commit")
3. **AI Attribution**: Any `Co-Authored-By:` line mentioning Claude, Anthropic, GPT, OpenAI, or any AI tool. Any `noreply@anthropic.com` or similar AI email addresses. Any AI model version references (e.g., "Claude Sonnet 4.5", "Claude Opus 4.6")
4. **Progress Tracking Artifacts**: Completion metrics used as workflow markers (e.g., "Total: 24 tests, 990 lines", "Coverage: >90%") rather than meaningful context

### ALLOW these (not violations):

- GitHub issue references (`#123`, `fixes #456`)
- Technical use of "phase" ("two-phase commit", "multi-phase migration")
- Meaningful metrics in context ("Improve test coverage from 60% to 90%")
- Standard Jira-style references when project uses Jira

## Decision

- If the commit message is **clean**: ALLOW the tool call. Respond with nothing or a brief approval.
- If violations are **found**: **BLOCK this tool call**. Explain what was found and provide a corrected version of the commit message. Instruct to re-run the commit with the cleaned message.
