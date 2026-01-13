# Sketch Note Plugin

Generate visual sketch notes in Excalidraw format from conversations, code architecture, or custom content.

## Features

- **Multiple content modes**: Capture conversation summaries, visualize code architecture, or sketch custom content
- **Excalidraw output**: Creates `.excalidraw` files that open directly in Excalidraw
- **Customizable styling**: Configure background, pen type, roughness, and visual effects
- **Persistent preferences**: Settings saved per-project for consistent output

## Installation

```bash
claude --plugin-dir ./plugins/sketch-note
```

## Usage

### Command

```bash
/sketch                           # Interactive mode selection
/sketch --mode conversation       # Sketch current conversation
/sketch --mode code               # Visualize code architecture
/sketch --mode custom             # Custom content input
/sketch --output my-diagram       # Specify output filename
```

### Agent

The sketch agent triggers proactively when you ask to:
- "visualize this architecture"
- "create a diagram of..."
- "sketch the flow"
- "draw how this works"

## Configuration

Settings are stored in `.claude/sketch-note.local.md`:

```yaml
---
background_color: white      # white, cream, light-gray, light-blue, light-yellow
roughness: hand-drawn        # hand-drawn, sketchy, clean
stroke_width: medium         # thin, medium, bold
background_pattern: none     # none, dots, grid, lines
visual_effects: []           # shadow, glow, cursive
resolution: standard         # standard, high, 4k
---
```

## Output

Sketch notes are saved to `sketches/` directory as `.excalidraw` files.

## Styles

| Roughness | Description |
|-----------|-------------|
| hand-drawn | High roughness, casual sketch look |
| sketchy | Medium roughness, balanced appearance |
| clean | Low roughness, professional diagrams |

| Stroke Width | Description |
|--------------|-------------|
| thin | 1px stroke, delicate lines |
| medium | 2px stroke, balanced visibility |
| bold | 4px stroke, emphasis and impact |

## Visual Effects

- **shadow**: Adds drop shadow to elements
- **glow**: Adds subtle glow effect
- **cursive**: Uses handwriting-style font for text
