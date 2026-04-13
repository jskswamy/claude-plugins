---
description: |
  Explore codebase using indexed knowledge from codebase-memory-mcp. Use when:
  exploring project context during brainstorming or planning,
  user asks about codebase architecture or structure,
  user asks how something works or where something happens,
  user asks what would be affected by a change,
  user wants to understand code before modifying it
---

# Codebase Explore Skill

Enrich codebase exploration with indexed knowledge from `codebase-memory-mcp`. This skill provides grounded, accurate codebase context by querying a semantic and structural graph rather than doing expensive grep/glob/read exploration.

## When This Skill Activates

- During brainstorming "Explore project context" step
- During planning codebase analysis step
- When the user asks about codebase architecture, structure, or how things work
- When the user asks "where does X happen?" or "how does Y work?"
- When the user wants to understand the impact of a change

## Activation Flow

### Step 1: Check codebase-memory-mcp Availability

Attempt to call the `codebase-memory-mcp` `list_projects` tool.

**If the MCP server is NOT available:**
Fall back to standard grep/glob/read exploration silently. Do NOT print an error — this skill should not block any workflow. Proceed with normal file exploration tools.

**If the MCP server IS available:** Continue to Step 2.

### Step 2: Check Index Freshness

Read `.claude/codebase.local.md` if it exists. Check the `last_indexed` timestamp.

- If `last_indexed` is more than 24 hours old or missing, print:
  ```
  ⚠ Codebase index may be stale (last indexed: [time ago]). Results may be incomplete.
  ```
- Continue regardless — stale results are better than no results.

### Step 3: Determine Project Name

Call `list_projects` and match against the current repo (from `git rev-parse --show-toplevel` basename).

If no match, suggest indexing:
```
Codebase is not yet indexed. Run /codebase:index to build the index.
```
Then fall back to grep/glob/read exploration.

### Step 4: Context-Dependent Exploration

**If activated during brainstorming or planning (exploring project context):**

1. Call `get_architecture` with `project` set to the matched project name. Request all aspects: `["languages", "packages", "services", "dependencies", "entry_points", "hotspots", "clusters"]`.

2. Summarize the architecture overview as grounded context:
   - Primary languages and their distribution
   - Key packages and their responsibilities
   - Service boundaries and entry points
   - Dependency patterns and hotspots

3. If the brainstorming/planning topic is known, run targeted queries:
   - Call `search_graph` with `semantic_query` matching the topic to find relevant existing code
   - For the top 3-5 results, note the file:line references and what each does

4. Present the results as context for the brainstorming/planning session. Frame it as "here's what exists that's relevant to what we're discussing."

**If activated on a direct user question:**

Route the question through the same logic as `/codebase:ask`:

1. Classify intent (Location, Understanding, Impact, Similarity, Onboarding)
2. Call the appropriate `codebase-memory-mcp` tools
3. Present the answer with file:line references and contextual explanation

See the `/codebase:ask` command (in `${CLAUDE_PLUGIN_ROOT}/commands/ask.md`) for the full intent classification and tool sequence for each intent type.

### Step 5: Fallback

If any `codebase-memory-mcp` tool call fails during exploration:
- Do NOT fail the overall workflow
- Fall back to `Grep`, `Glob`, and `Read` for the specific information needed
- Continue with whatever results are available
