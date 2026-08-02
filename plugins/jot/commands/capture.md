---
name: capture
description: Capture anything — from your current conversation or by starting a guided session. The agent classifies, extracts, helps you understand, drafts, reviews, and saves.
argument-hint: "[type?] <content, URL, or leave empty to capture from conversation>"
---

# Jot Capture

## MANDATORY — DO NOT SKIP

You MUST use the `Agent` tool immediately with `subagent_type: "jot:capture"`
and the user's raw arguments as the prompt. Do NOT:
- Classify or detect the type yourself
- Fetch URLs yourself
- Ask clarifying questions before delegating
- Handle any part of the capture inline
- Use mcp__capacities__* tools directly

Delegate **everything** to the `jot:capture` agent. It runs the full
6-phase workflow: classify → extract → study → draft → review → save.
The agent stays alive for the entire capture — do not re-invoke it mid-flow.

## Examples

```
/jot:capture                              # captures from current conversation
/jot:capture https://github.com/astral-sh/uv
/jot:capture meeting with Alice about roadmap
/jot:capture book Atomic Habits by James Clear
/jot:capture idea what if we used event sourcing
```
