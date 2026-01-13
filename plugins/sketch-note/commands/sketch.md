---
name: sketch
description: Generate visual sketch notes in Excalidraw format from conversations, code architecture, or custom content
argument-hint: "[--mode conversation|code|custom] [--output <name>] [description...]"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Sketch Command

Generate visual sketch notes as Excalidraw files with customizable styling.

## Argument Parsing

Parse the command arguments to extract:

| Argument | Short | Type | Default | Description |
|----------|-------|------|---------|-------------|
| `--mode` | `-m` | string | (prompt) | Content mode: `conversation`, `code`, or `custom` |
| `--output` | `-o` | string | auto | Output filename (without extension) |
| `[description...]` | | string | | Free-form description for custom mode |

**Examples:**
```
/sketch                              # Interactive mode selection
/sketch --mode conversation          # Sketch current conversation
/sketch -m code                      # Visualize code architecture
/sketch --mode custom API flow       # Custom sketch with description
/sketch -o my-diagram -m code        # Named output file
```

---

## Execution Flow

### Step 1: Load User Preferences

Read `.claude/sketch-note.local.md` if it exists:

```yaml
---
background_color: white
roughness: hand-drawn
stroke_width: medium
background_pattern: none
visual_effects: []
resolution: standard
---
```

**If settings file doesn't exist (first-time setup):**

Use AskUserQuestion to gather preferences:

1. **Background color:**
   ```
   Choose a background color for your sketch notes:
   ○ White (Recommended) - Clean, classic look
   ○ Cream - Warm, paper-like feel
   ○ Light Gray - Subtle, modern appearance
   ○ Light Blue - Calm, focused feel
   ○ Light Yellow - Sunny, creative vibe
   ```

2. **Roughness (pen style):**
   ```
   How should your sketches look?
   ○ Hand-drawn (Recommended) - Casual, authentic sketch feel
   ○ Sketchy - Balanced between rough and clean
   ○ Clean - Professional, precise diagrams
   ```

3. **Stroke width:**
   ```
   Choose line thickness:
   ○ Thin - Delicate, detailed lines
   ○ Medium (Recommended) - Balanced visibility
   ○ Bold - Strong emphasis, high impact
   ```

4. **Background pattern:**
   ```
   Add a background pattern?
   ○ None (Recommended) - Clean background
   ○ Dots - Subtle dot grid
   ○ Grid - Square grid lines
   ○ Lines - Horizontal ruled lines
   ```

5. **Visual effects (multi-select):**
   ```
   Select visual effects to apply:
   ☐ Shadow - Add drop shadows to elements
   ☐ Glow - Subtle glow effect around elements
   ☐ Cursive - Use handwriting-style font for text
   ```

6. **Resolution:**
   ```
   Output resolution:
   ○ Standard (Recommended) - Good for most uses
   ○ High - 2x resolution for presentations
   ○ 4K - Maximum quality for large displays
   ```

After gathering all preferences:
- Create `.claude/sketch-note.local.md` with selections
- Show confirmation: "Preferences saved! You can change these anytime by editing `.claude/sketch-note.local.md`"

### Step 2: Determine Content Mode

**If `--mode` argument provided:** Use specified mode

**If no mode specified:** Use AskUserQuestion:
```
What would you like to sketch?
○ Conversation - Summarize our current conversation as visual notes
○ Code Architecture - Visualize code structure from this project
○ Custom - Create a sketch from your own description
```

### Step 3: Gather Content Based on Mode

#### Mode: Conversation

1. **Analyze the conversation history** to extract:
   - Main topics discussed
   - Key decisions made
   - Important concepts explained
   - Action items or next steps
   - Relationships between ideas

2. **Create a visual hierarchy:**
   - Central theme/topic
   - Major branches for subtopics
   - Connections between related concepts
   - Callouts for important points

3. **Structure for Excalidraw:**
   - Title box at top
   - Main concept boxes arranged spatially
   - Arrows showing relationships
   - Text annotations for context

#### Mode: Code Architecture

1. **Discover project structure:**
   - Use Glob to find source files: `**/*.{ts,tsx,js,jsx,py,go,rs,java}`
   - Read key files to understand architecture
   - Identify main modules/packages

2. **Extract architecture elements:**
   - Entry points (main files, index files)
   - Core modules and their responsibilities
   - Dependencies between modules
   - External integrations (APIs, databases)

3. **Create architecture diagram:**
   - Boxes for modules/services
   - Arrows for dependencies/data flow
   - Groups for related components
   - Labels for key interfaces

4. **Ask for scope if large codebase:**
   ```
   This is a large codebase. Which area should I focus on?
   ○ Full overview - High-level architecture only
   ○ Specific directory - Choose a directory to visualize
   ○ Entry point flow - Trace from main entry point
   ```

#### Mode: Custom

1. **Use the description from arguments** or prompt:
   ```
   Describe what you'd like to sketch:
   > [user input]
   ```

2. **Parse the description** to identify:
   - Main entities/concepts
   - Relationships between them
   - Flow direction (if applicable)
   - Groupings or categories

3. **Generate appropriate diagram type:**
   - Flowchart for processes
   - Mind map for concepts
   - Architecture diagram for systems
   - Sequence for interactions

### Step 4: Load Style Configuration

Read style definitions from `${CLAUDE_PLUGIN_ROOT}/styles/` based on preferences:

**Map preferences to Excalidraw properties:**

| Preference | Excalidraw Property |
|------------|---------------------|
| `background_color: white` | `appState.viewBackgroundColor: "#ffffff"` |
| `background_color: cream` | `appState.viewBackgroundColor: "#faf8f5"` |
| `background_color: light-gray` | `appState.viewBackgroundColor: "#f5f5f5"` |
| `background_color: light-blue` | `appState.viewBackgroundColor: "#f0f8ff"` |
| `background_color: light-yellow` | `appState.viewBackgroundColor: "#fffef0"` |
| `roughness: hand-drawn` | `roughness: 2` |
| `roughness: sketchy` | `roughness: 1` |
| `roughness: clean` | `roughness: 0` |
| `stroke_width: thin` | `strokeWidth: 1` |
| `stroke_width: medium` | `strokeWidth: 2` |
| `stroke_width: bold` | `strokeWidth: 4` |

**Visual effects mapping:**
- `shadow`: Add `shadow` element property
- `glow`: Lighter stroke color with blur effect simulation
- `cursive`: Use `fontFamily: 3` (Virgil handwriting font)

**Resolution mapping:**
- `standard`: Default canvas size
- `high`: 2x element scaling
- `4k`: 4x element scaling

### Step 5: Generate Excalidraw JSON

Create valid Excalidraw JSON structure:

```json
{
  "type": "excalidraw",
  "version": 2,
  "source": "sketch-note-plugin",
  "elements": [
    // Generated elements based on content
  ],
  "appState": {
    "viewBackgroundColor": "#ffffff",
    "gridSize": null
  },
  "files": {}
}
```

**Element generation rules:**

1. **Text elements:**
   ```json
   {
     "type": "text",
     "id": "unique-id",
     "x": 100,
     "y": 100,
     "width": 200,
     "height": 30,
     "text": "Label text",
     "fontSize": 20,
     "fontFamily": 1,
     "roughness": 2,
     "strokeColor": "#1e1e1e",
     "backgroundColor": "transparent"
   }
   ```

2. **Rectangle elements (boxes):**
   ```json
   {
     "type": "rectangle",
     "id": "unique-id",
     "x": 50,
     "y": 50,
     "width": 200,
     "height": 100,
     "strokeColor": "#1e1e1e",
     "backgroundColor": "#a5d8ff",
     "fillStyle": "hachure",
     "roughness": 2,
     "strokeWidth": 2
   }
   ```

3. **Arrow elements (connections):**
   ```json
   {
     "type": "arrow",
     "id": "unique-id",
     "x": 250,
     "y": 100,
     "width": 100,
     "height": 0,
     "points": [[0, 0], [100, 0]],
     "strokeColor": "#1e1e1e",
     "roughness": 2,
     "strokeWidth": 2,
     "startBinding": { "elementId": "box-1", "focus": 0, "gap": 5 },
     "endBinding": { "elementId": "box-2", "focus": 0, "gap": 5 }
   }
   ```

**Layout algorithm:**

1. **Calculate positions** to avoid overlaps
2. **Group related elements** spatially
3. **Use consistent spacing** (40px between elements)
4. **Center the diagram** in canvas
5. **Flow direction:** Top-to-bottom for hierarchies, left-to-right for flows

**Color palette for elements:**
- Primary boxes: `#a5d8ff` (light blue)
- Secondary boxes: `#b2f2bb` (light green)
- Accent boxes: `#ffec99` (light yellow)
- Warning boxes: `#ffc9c9` (light red)
- Neutral boxes: `#e9ecef` (light gray)

### Step 6: Determine Output Path

**If `--output` provided:** Use specified name
**Otherwise:** Generate name based on mode and timestamp

```
sketches/{mode}-{timestamp}.excalidraw
```

Examples:
- `sketches/conversation-20240115-143022.excalidraw`
- `sketches/code-architecture-20240115-143022.excalidraw`
- `sketches/my-api-flow.excalidraw` (if --output my-api-flow)

**Create sketches directory if needed:**
```bash
mkdir -p sketches
```

### Step 7: Write Output File

1. **Write the Excalidraw JSON file:**
   ```
   Write to: sketches/{filename}.excalidraw
   ```

2. **Show success message:**
   ```
   ✓ Sketch created: sketches/conversation-20240115-143022.excalidraw

   Elements: 12 boxes, 8 arrows, 15 text labels
   Style: hand-drawn, medium stroke, white background

   Open in Excalidraw:
   - Visit excalidraw.com and drag the file to open
   - Or use VS Code with Excalidraw extension
   ```

3. **Offer follow-up options:**
   ```
   What would you like to do next?
   ○ Open location - Show the file in finder/explorer
   ○ Create another - Make another sketch
   ○ Done - Finish
   ```

---

## Background Pattern Implementation

Since Excalidraw doesn't have native background patterns, implement them as subtle elements:

**Dots pattern:**
- Create small ellipse elements in a grid pattern
- Color: Very light gray (#e0e0e0)
- Size: 2px diameter
- Spacing: 20px grid

**Grid pattern:**
- Create line elements forming a grid
- Color: Very light gray (#e8e8e8)
- Stroke width: 0.5px
- Spacing: 20px

**Lines pattern:**
- Create horizontal line elements
- Color: Very light gray (#e8e8e8)
- Stroke width: 0.5px
- Spacing: 30px

**Note:** Pattern elements should be at the back (lowest z-index) and non-interactive.

---

## Settings File Template

When creating `.claude/sketch-note.local.md`:

```markdown
---
background_color: white
roughness: hand-drawn
stroke_width: medium
background_pattern: none
visual_effects: []
resolution: standard
---

# Sketch Note Plugin Settings

Your preferences for generating sketch notes.

## Available Options

| Setting | Options | Description |
|---------|---------|-------------|
| background_color | white, cream, light-gray, light-blue, light-yellow | Canvas background |
| roughness | hand-drawn, sketchy, clean | Line roughness style |
| stroke_width | thin, medium, bold | Line thickness |
| background_pattern | none, dots, grid, lines | Background pattern |
| visual_effects | shadow, glow, cursive | Effects (array, multi-select) |
| resolution | standard, high, 4k | Output resolution |

## Examples

Change to clean professional style:
```yaml
roughness: clean
stroke_width: thin
background_color: white
```

Warm creative style:
```yaml
roughness: hand-drawn
background_color: cream
visual_effects: [cursive, shadow]
```
```

---

## Error Handling

### No Content to Sketch

**Conversation mode with no conversation:**
```
No conversation history to sketch.
Try using:
- /sketch --mode custom "your description"
- /sketch --mode code
```

### Code Mode in Empty Directory

```
No source files found in this directory.
Make sure you're in a project directory with source code.
```

### Invalid Mode

```
Invalid mode: "{mode}"
Available modes: conversation, code, custom
```

### Write Permission Error

```
Cannot create sketches directory.
Please check write permissions or specify a different location with --output.
```

---

## Important Notes

- **Excalidraw compatibility:** Generated files work with excalidraw.com and VS Code extension
- **Unique IDs:** Generate unique IDs for each element using timestamp + random suffix
- **Bindings:** Arrow bindings require valid element IDs for connected boxes
- **Z-index:** Background patterns first, then boxes, then arrows, then text on top
- **Font family:** Use 1 (normal), 2 (code), or 3 (handwriting/Virgil)
- **File extension:** Always use `.excalidraw` extension
