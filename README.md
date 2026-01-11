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

## Roadmap

### Dev Workflows
- Git commit helpers and conventional commit enforcement
- Code review automation
- Test generation and coverage analysis

### Code Generation
- Project scaffolding and boilerplate generators
- Component templates for common frameworks

### Productivity
- Documentation generators
- Note-taking and knowledge management
- Task and todo management

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on creating and submitting plugins.

## License

MIT
