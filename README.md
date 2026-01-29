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

### devenv

Initialize and manage Nix flake development environments with auto-detection and security tooling.

**Features:**
- Auto-detects project stack (Node.js, Python, Go, Rust, etc.)
- Generates `flake.nix` with best practices
- Offers pre-commit hooks with SAST tools
- Includes gitleaks for secret detection
- Automatic linting with nixfmt, statix, deadnix

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

Generate intelligent git commit messages with classic or conventional commit style support, strict atomic commit validation, and session context awareness.

**Features:**
- Two commit styles: Classic (default) and Conventional Commits
- Strict atomic commit validation with split commit helper
- Pair programming support with co-author attribution
- Session context awareness for meaningful messages
- 72-character wrapping for message bodies

**Install:**
```
/plugin install git-commit@claude-plugins
```

**Usage:**
```
/commit                           # Generate with default style
/commit --style conventional      # Use conventional commits
/commit --pair                    # Add co-author
/commit fix the login issue       # Provide context
```

[View documentation](./plugins/git-commit/README.md)

### jot

Quick, low-friction capture of notes, tasks, ideas, session summaries, and tech radar blips with Obsidian-style auto-linking.

**Features:**
- Quick captures: tasks, notes, ideas, session summaries
- URL-based captures: articles, videos, books, people, repositories
- Tech radar blips with rings (Adopt, Trial, Assess, Hold) and quadrants
- Obsidian-style wikilinks for auto-linking related notes
- Session context awareness (git repo, branch, directory)

**Install:**
```
/plugin install jot@claude-plugins
```

**Usage:**
```
/capture task Review the PR
/capture note Meeting notes about X
/capture idea Try approach Y
/capture session                  # Guided session summary
/capture blip Docker --ring adopt --quadrant platforms
/capture https://github.com/repo  # URL-based capture
```

[View documentation](./plugins/jot/README.md)

### sketch-note

Generate visual sketch notes in Excalidraw format from conversations, code architecture, or custom content.

**Features:**
- Multiple content modes: conversation summaries, code architecture, custom content
- Creates `.excalidraw` files that open directly in Excalidraw
- PNG export with interactive tool detection workflow
- Customizable styling: background, pen type, roughness, visual effects
- Persistent per-project preferences

**Install:**
```
/plugin install sketch-note@claude-plugins
```

**Usage:**
```
/sketch                           # Interactive mode selection
/sketch --mode conversation       # Sketch current conversation
/sketch --mode code               # Visualize code architecture
/sketch --format png              # Export as PNG
/sketch --format both             # Both Excalidraw and PNG
```

[View documentation](./plugins/sketch-note/README.md)

### task-decomposer

Transform complex tasks into well-structured beads issues through a thoughtful workflow, capture side ideas without breaking flow, and create rich commit messages with full context.

**Features:**
- Deep task understanding with 7 questioning dimensions
- Break down work into structured beads issues with dependencies
- Park side ideas quickly without losing focus
- Review parked ideas and promote to real issues
- Rich commit messages combining beads context with code changes

**Install:**
```
/plugin install task-decomposer@claude-plugins
```

**Usage:**
```
/understand                       # Explore a task deeply
/decompose                        # Break work into beads issues
/park-idea rate limiting          # Capture side thought quickly
/review-parked                    # Review parked ideas
/task-commit                      # Commit with beads context
```

[View documentation](./plugins/task-decomposer/README.md)

### typst-notes

Generate beautiful PDF/HTML shareable notes using Typst with 7 professional templates, infographics support, and modern typography.

**Features:**
- 7 templates: executive summary, cheat sheet, sketch, meeting minutes, study guide, technical brief, portfolio
- 4 themes: light, dark, minimal, vibrant
- Auto-generated infographics via CeTZ, Fletcher, Pintorita
- Jot integration for publishing captures directly
- Bundled OFL-licensed fonts (Inter, Source Serif 4, JetBrains Mono)

**Install:**
```
/plugin install typst-notes@claude-plugins
```

**Usage:**
```
/publish                          # Interactive template selection
/publish --template exec          # Executive summary
/publish --template cheat --theme dark    # Dark cheat sheet
/publish --source jot:notes/meeting.md    # Publish a jot note
/publish --format both --output api-design # PDF and HTML
```

[View documentation](./plugins/typst-notes/README.md)

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
