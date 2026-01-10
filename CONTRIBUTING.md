# Contributing

## Creating a Plugin

1. Install the official plugin-dev tool:
   ```
   /plugin install github:anthropics/claude-code/plugins/plugin-dev
   ```

2. Run the plugin creation wizard:
   ```
   /plugin-dev:create-plugin
   ```

3. Move your plugin to `plugins/<plugin-name>/`

4. Test locally:
   ```bash
   claude --plugin-dir ./plugins/<plugin-name>
   ```

## Submitting a Plugin

1. Fork this repository
2. Create your plugin in `plugins/`
3. Add your plugin entry to `.claude-plugin/marketplace.json`
4. Update README.md to list your plugin
5. Submit a pull request

## Plugin Entry Format

Add to the `plugins` array in `.claude-plugin/marketplace.json`:

```json
{
  "name": "your-plugin",
  "description": "Brief description of what it does",
  "version": "1.0.0",
  "author": { "name": "Your Name" },
  "source": "./plugins/your-plugin",
  "category": "utilities",
  "tags": ["relevant", "tags"]
}
```

## Requirements

- Plugin must have a valid `.claude-plugin/plugin.json`
- Plugin must include a README.md with usage instructions
- Plugin must be tested locally before submission
