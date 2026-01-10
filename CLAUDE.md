# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a Claude Code plugin marketplace. Plugins are stored in `plugins/` and registered in `.claude-plugin/marketplace.json`.

```
.claude-plugin/marketplace.json  # Marketplace registry
plugins/<plugin-name>/           # Individual plugins
```

## Creating a New Plugin

1. Install the official plugin-dev tool:
   ```
   /plugin install github:anthropics/claude-code/plugins/plugin-dev
   ```

2. Create the plugin:
   ```
   /plugin-dev:create-plugin
   ```

3. Move the plugin to `plugins/` directory

4. Register it in `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "plugin-name",
     "description": "What this plugin does",
     "version": "1.0.0",
     "author": { "name": "Author Name" },
     "source": "./plugins/plugin-name",
     "category": "utilities",
     "tags": ["tag1", "tag2"]
   }
   ```

## Testing Plugins Locally

```bash
claude --plugin-dir ./plugins/<plugin-name>
```

## Plugin Structure

Each plugin in `plugins/` should have:
```
plugin-name/
├── .claude-plugin/
│   └── plugin.json      # Plugin metadata (name, version, description)
├── commands/            # Slash commands (*.md files)
├── agents/              # Specialized agents (*.md files)
├── skills/              # Auto-invoked capabilities (*.md files)
├── hooks/               # Event handlers (*.md files)
└── README.md            # Plugin documentation
```
