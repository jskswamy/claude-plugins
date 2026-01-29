# Claude Plugins Marketplace

A curated collection of Claude Code plugins focused on developer workflows, code generation, and productivity.

## About

This is a personal collection of useful Claude Code plugins that I've built to enhance my daily development workflow. All plugins are open to anyone who finds them helpful.

## Philosophy

- **Practical focus**: Plugins solve real, everyday problems in development workflows
- **Simplicity first**: Each plugin does one thing well without unnecessary complexity
- **Quality over quantity**: A small number of polished, reliable plugins is better than many half-baked ones

## Quick Start

### Prerequisites

- [Claude Code](https://claude.ai/code) installed on your machine

### Installation

1. Add this marketplace to Claude Code:

   ```
   /plugin marketplace add jskswamy/claude-plugins
   ```

2. Browse available plugins:

   ```
   /plugin search @claude-plugins
   ```

3. Install any plugin:

   ```
   /plugin install <plugin-name>@claude-plugins
   ```

4. Use the plugin via its commands or skills (see individual plugin documentation)

## Available Plugins

<!-- PLUGINS:START -->


### devenv

Initialize and manage Nix flake development environments with auto-detection and security tooling

**Features:**
- Auto-detection: Automatically detects your project's tech stack and suggests appropriate packages
- Native Nix pre-commit: Uses [git-hooks.nix](https://github.com/cachix/git-hooks.nix) for pure Nix pre-commit integration
- Security tooling: Built-in support for gitleaks and SAST tools
- Nix best practices: Generated flakes follow Nix conventions and are automatically linted/formatted
- No system dependencies: All tools run via Nix, ensuring reproducibility

**Install:**
```
/plugin install devenv@claude-plugins
```

**Usage:**
```
/devenv
```

[View documentation](./plugins/devenv/README.md)


### git-commit

Generate intelligent git commit messages with classic or conventional commit style support, strict atomic commit validation, and session context awareness

**Features:**
- Auto-Activation: Triggers automatically when you ask to commit (no need to type `/commit`)
- Two Commit Styles: Classic commits (default) and conventional commits
- Strict Atomic Commit Validation: Warns when staged changes aren't atomic
- Split Commits Helper: Guides you through staging changes separately
- Pair Programming Support: Save and reuse co-author information

**Install:**
```
/plugin install git-commit@claude-plugins
```

**Usage:**
```
/commit                    # Generate commit with default style (classic)
```

[View documentation](./plugins/git-commit/README.md)


### jot

Quick, low-friction capture of notes, tasks, ideas, session summaries, tech radar blips, and Feynman-style teaching notes with Obsidian-style auto-linking

**Features:**
- Quick captures: Task, note, idea, session, blip - minimal friction
- Full captures: Article, video, blip (GitHub/tools), person, book, organisation, trove, research - URL-based extraction
- Feynman teaching: Interactive `/teach` command for deepening understanding of papers, videos, articles, and concepts you've already studied
- Teaching notes: Capture your learning journey with analogies, misconceptions, and applied scenarios
- Session summaries: Capture Claude Code session outcomes with guided questions

**Install:**
```
/plugin install jot@claude-plugins
```

**Usage:**
```
/capture task Buy groceries
/capture note Meeting notes about project X
/capture idea What if we tried approach Y
/capture blip Docker --ring adopt --quadrant platforms
```

[View documentation](./plugins/jot/README.md)


### sketch-note

Generate visual sketch notes in Excalidraw format from conversations, code architecture, or custom content

**Features:**
- Multiple content modes: Capture conversation summaries, visualize code architecture, or sketch custom content
- Excalidraw output: Creates `.excalidraw` files that open directly in Excalidraw
- PNG export: Interactive workflow detects available tools and guides you through export options
- Customizable styling: Configure background, pen type, roughness, and visual effects
- Persistent preferences: Settings saved per-project for consistent output

**Install:**
```
/plugin install sketch-note@claude-plugins
```

**Usage:**
```
/sketch                           # Interactive mode selection
/sketch --mode conversation       # Sketch current conversation
/sketch --mode code               # Visualize code architecture
/sketch --mode custom             # Custom content input
/sketch --output my-diagram       # Specify output filename
/sketch --format png              # PNG via Excalidraw conversion
```

[View documentation](./plugins/sketch-note/README.md)


### task-decomposer

Transform complex tasks into structured beads issues with proper dependencies, capture ideas without breaking flow, and create rich commit messages

**Features:**
- Task Understanding
- Task Decomposition
- Idea Parking
- Parked Idea Review
- Task Commit

**Install:**
```
/plugin install task-decomposer@claude-plugins
```

**Usage:**
```
User: Help me understand what adding caching to our API would involve

Claude: [Enters discovery phase]
- Asks: What's driving the need - performance, load, cost?
- Probes scope: Which endpoints? What data types?
- Explores constraints: Freshness requirements? Tech preferences?
```

[View documentation](./plugins/task-decomposer/README.md)


### typst-notes

Generate beautiful PDF/HTML shareable notes using Typst with 7 professional templates, infographics, and modern typography

**Features:**
- Typst
- Pdf
- Html
- Notes
- Templates

**Install:**
```
/plugin install typst-notes@claude-plugins
```

**Usage:**
```
/publish [--template exec|cheat|sketch|meeting|study|tech|portfolio]
         [--theme light|dark|minimal|vibrant]
         [--format pdf|html|both]
         [--output <name>]
         [--source conversation|jot:<path>|file:<path>]
         [content description...]
```

[View documentation](./plugins/typst-notes/README.md)
<!-- PLUGINS:END -->

## Roadmap

### Dev Workflows
- Code review automation
- Test generation and coverage analysis

### Code Generation
- Project scaffolding and boilerplate generators
- Component templates for common frameworks

### Productivity
- Documentation generators
- Task and todo management

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on creating and submitting plugins.

## License

MIT
