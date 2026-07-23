---
name: capture
description: Capture anything — notes, ideas, tasks, URLs, meetings, books, or any Capacities type — using natural language. Delegates to jot's routing agent which detects the type and handles the rest.
argument-hint: "[type?] <content or URL>"
---

# Jot Capture

## MANDATORY — DO NOT SKIP

You MUST use the `Agent` tool immediately with `subagent_type: "jot:capture"`
and the user's raw arguments as the prompt. Do NOT:
- Fetch URLs yourself
- Ask clarifying questions before delegating
- Handle any part of the capture inline
- Use mcp__capacities__* tools directly

Delegate **everything** to the `jot:capture` agent. It runs the full workflow:
content extraction, entity linking, draft assembly, review gate, and save.
The agent stays alive for the entire capture — do not re-invoke it mid-flow.

Pass your input directly to the jot routing agent. The agent identifies what you're capturing, confirms the type, and handles everything from there.

## Examples

```
/jot:capture https://github.com/astral-sh/uv
/jot:capture spoke with Alice about the roadmap
/jot:capture book Atomic Habits by James Clear
/jot:capture idea What if we used event sourcing for the audit trail
/jot:capture meeting with the infra team about cost reduction
```

Any natural language works. You can also embed "jot" in a sentence:
- "had a jot meeting with Alice"
- "jot this as a technology evaluation"

## Routing

The routing agent (`agents/capture`) handles all input. If the type hasn't been configured before, it runs a quick one-time setup inline and then proceeds with the capture — no separate setup command needed.

## Configuration

Run `/jot:setup` once to choose your capture backend (workbench or Capacities).
