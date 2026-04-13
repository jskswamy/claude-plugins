---
name: ask
description: Ask a natural language question about the codebase
argument-hint: "<question>"
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
  - AskUserQuestion
---

# /codebase:ask Command

Ask a natural language question about the codebase. This command classifies your intent and orchestrates the right `codebase-memory-mcp` queries to answer it.

## Argument Parsing

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `<question>` | string | yes | Natural language question about the codebase |

If no question is provided:
```
Usage: /codebase:ask <question>

Examples:
  /codebase:ask where does webhook validation happen?
  /codebase:ask how does the auth pipeline work end to end?
  /codebase:ask I want to add a new API endpoint — what should I know?
  /codebase:ask anything similar to the writeJSON helper?
```

## Execution Flow

### Step 0: Check codebase-memory-mcp Availability

Call `list_projects` to verify the MCP server is available. If not:
```
codebase-memory-mcp not found. Install and configure it before using /codebase commands.
```
Exit.

### Step 0b: Check Index Freshness

Read `.claude/codebase.local.md`. Check the `auto_index` setting:

- If the file is missing or `auto_index` is `ask`:
  Use AskUserQuestion to prompt:
  ```
  The codebase needs to be indexed before querying. Index now?

  ○ Yes, always (save this preference)
  ○ Yes, just this once
  ○ No, I'll run /codebase:index manually (save this preference)
  ```
  If a "save" option is selected, write the preference to `.claude/codebase.local.md`.
  If "Yes", call `index_repository` with the saved `index_mode` (default: `moderate`).

- If `auto_index` is `always`:
  Call `index_repository` with the saved `index_mode` before proceeding.

- If `auto_index` is `never`:
  Check `last_indexed`. If >24 hours ago or missing, print:
  ```
  ⚠ Index may be stale (last indexed: [time ago]). Run /codebase:index to refresh.
  ```
  Proceed with the query.

### Step 1: Determine the Project Name

Call `list_projects` to get the list of indexed projects. Match against the current repository name (from `git rev-parse --show-toplevel`, using the directory basename). If no match is found, suggest running `/codebase:index` first.

### Step 2: Classify Intent

Read the user's question and classify it into one of these intents. This is a judgment call — use the signals as guidance, not rigid rules:

| Intent | Signal words | Action |
|--------|-------------|--------|
| **Location** | "where does", "find", "which file", "locate" | Go to Step 3a |
| **Understanding** | "how does", "explain", "walk me through", "what does X do" | Go to Step 3b |
| **Impact** | "what's affected", "blast radius", "what breaks", "what depends on" | Print: "Routing to /codebase:impact — use that command directly for more options." Then follow the /codebase:impact flow. |
| **Similarity** | "anything similar to", "what else does", "duplicates of", "related to" | Go to Step 3c |
| **Onboarding** | "I want to add", "what should I know about", "getting started with", "new to" | Go to Step 3d |

If the intent is ambiguous, make your best judgment. Do not ask the user to clarify — pick the most likely intent and answer.

### Step 3a: Location Query

1. Call `search_graph` with `semantic_query` set to a rephrased version of the user's question (extract the core concept, e.g. "webhook validation" from "where does webhook validation happen?"). Set `limit` to 5.
2. For the top 1-3 results, call `get_code_snippet` with the `qualified_name` to read the actual source.
3. Synthesize the answer: state which file:line the code lives in, what the function does, who calls it (from `search_graph` connected nodes if available), and any relevant context about why it exists.

### Step 3b: Understanding Query

1. Call `get_architecture` with `project` set to the current project. Request aspects: `["packages", "services", "entry_points"]`.
2. Call `search_graph` with `semantic_query` to find the entry point or main function related to the user's question. Set `limit` to 5.
3. For the most relevant result, call `trace_call_path` with `direction: "outbound"`, `depth: 3` to trace the flow from that entry point.
4. For key nodes in the trace (up to 3), call `get_code_snippet` to read the source.
5. Synthesize a narrative explanation: start with the entry point, walk through the call chain, explain what each step does and why, and how data flows through the system. Reference file:line for each function mentioned.

### Step 3c: Similarity Query

1. Call `search_graph` with `semantic_query` describing the function or concept the user is asking about. Set `limit` to 10.
2. Filter results: skip results from the same file. Group by package.
3. For the top 3-5 matches, call `get_code_snippet` to read the actual source and confirm similarity.
4. Synthesize: describe each match, explain how it's similar and how it differs, and note which ones could potentially be unified.

### Step 3d: Onboarding Query

1. Call `get_architecture` with `project` set to the current project. Request aspects: `["packages", "services", "dependencies", "entry_points"]`.
2. Call `search_graph` with `semantic_query` to find existing implementations similar to what the user wants to add. Set `limit` to 5.
3. For the top 1-2 matches, call `trace_call_path` with `direction: "both"`, `depth: 2` to understand the interfaces and patterns.
4. Call `get_code_snippet` for key files the user will need to understand.
5. Synthesize: "To add [X], you'll want to look at how [similar thing] is implemented. Here's the pattern..." Include: files to model after, interfaces to implement, configuration to update, test patterns to follow.

### Step 4: Present Answer

Format the answer with:
- **File:line references** for every function or type mentioned
- **Contextual explanation** — what the code does, why it exists, how it fits in the system
- **Connections** — callers, consumers, related patterns, relevant tests

Do NOT dump raw MCP JSON. Synthesize the results into a clear narrative.

If `codebase-memory-mcp` returns no results or empty results for any query, fall back to `Grep` and `Glob` for that specific sub-query. Do not fail silently — try the fallback and include those results in the answer.
