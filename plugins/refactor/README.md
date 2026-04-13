# Refactor Plugin

Semantic refactoring opportunity detection for Claude Code. After each task completes (or on demand), scans committed code against the codebase-memory index to find cross-package duplication, code smells, and design pattern opportunities. Creates actionable beads issues with TDD-first refactoring plans.

## Prerequisites

- **codebase-memory-mcp** — Semantic code index. Must be installed and configured.
- **codebase plugin** — Index management. The refactor plugin calls `/codebase:index` to ensure the index is fresh.
- **beads plugin** — Issue tracker. The validator creates beads issues for confirmed opportunities.
- **task-executor plugin** (optional) — Enables automatic post-task scanning.

## Usage

### Manual Scan

```
/refactor:scan                   # scan changes since upstream
/refactor:scan --base abc1234    # scan changes since specific SHA
```

### Automatic (with task-executor)

When installed alongside `task-executor`, the plugin automatically scans after each task closes. Suppress with `--no-refactor` on the execute command.

## What It Detects

### Structural Duplication (Fowler Catalog)
- Replace Inline Code with Function Call
- Extract Function + Move Function
- Parameterize Function
- Combine Functions into Class/Group
- Pull Up Method
- Introduce Parameter Object
- Replace Conditional with Polymorphism

### Code Smells (Fowler/Beck)
- Duplicate Code, Feature Envy, Data Clumps
- Parallel Inheritance Hierarchies, Shotgun Surgery
- Divergent Change, Message Chains, Inappropriate Intimacy

### Design Pattern Opportunities (GoF)
- Strategy, Template Method, Factory Method
- Decorator, Facade, Observer, Command

### Principle Violations
- DRY (logic, knowledge, structural duplication)
- SOLID (SRP, OCP, ISP, DIP)
- Law of Demeter

### Language Idioms (Go, Python, TypeScript)
- Go: raw strings for typed values, error chain loss, unmanaged goroutines
- Python: manual resource management, mutable defaults, missing type annotations
- TypeScript: `any` type, manual null guards, `.then()` chains

## How It Works

1. **Scanner agent** queries `codebase-memory-mcp` for semantic similarity + analyzes the diff for structural patterns. Provides breadth — covers the entire codebase cheaply via the index.

2. **Validator agent** reads actual source files for confirmed candidates. Provides depth — checks test coverage, deduplicates against existing issues, creates beads issues with TDD-first plans.

## Output

```
Refactoring scan complete.

Issues created:
  beads-xxx  P2  Extract writeJSON to internal/framework
  beads-yyy  P3  Parameterize FaultParam as generic FaultParam[T]

Dismissed (false positives): 1
Deferred (trivial): 0
```

Each created issue includes:
- TDD-first refactoring steps in the design field
- Pattern classification in notes
- Test coverage status
- Priority based on scope (P2 for cross-layer, P3 for same-layer, P4 for minor)
