# Jot

Quick, low-friction capture of notes, tasks, ideas, and tech radar blips with Obsidian-style auto-linking.

## Why Jot?

Capture thoughts, tasks, and discoveries without switching context. Jot provides a single `/capture` command that handles everything from quick tasks to full article extraction, automatically linking new notes to related content in your knowledge base.

## Features

- **Quick captures**: Task, note, idea, session, blip - minimal friction
- **Full captures**: Article, video, blip (GitHub/tools), person, book, organisation, trove, research - URL-based extraction
- **Session summaries**: Capture Claude Code session outcomes with guided questions
- **URL references**: Quick captures can reference URLs without triggering full extraction
- **Type aliases**: `todo` for task, `thought` for note, `conversation` for session
- **Context capture**: Every capture asks for discovery context
- **Tech radar**: ThoughtWorks-style blips with quadrants (Tools, Techniques, Platforms, Languages & Frameworks) and rings (Adopt, Trial, Assess, Hold)
- **Rich content**: Blips include features, installation, usage examples, pros/cons, and alternatives
- **Auto-linking**: Obsidian-style wikilinks to related notes
- **Central storage**: All captures go to your configured workbench path

## Installation

```bash
claude --plugin-dir ./plugins/jot
```

Or add to your Claude Code plugins.

## Configuration

Create `.claude/jot.local.md` in your project or home directory:

```yaml
---
workbench_path: ~/workbench
---
```

**Settings:**
- `workbench_path`: Where to store captured notes (default: `~/workbench`)

## Usage

### Quick Captures (text-based)

```
/capture task Buy groceries
/capture note Meeting notes about project X
/capture idea What if we tried approach Y
/capture blip Docker --ring adopt --quadrant platforms
```

### Session Captures

```
/capture session                    # Guided questions about this Claude session
/capture conversation               # Alias for session
```

### Using Aliases

```
/capture todo Review Alice's PR     # Same as: /capture task
/capture thought API seems slow     # Same as: /capture note
```

### Quick Captures with URL References

```
/capture todo use https://git-cliff.org/ to generate changelog
```

This keeps it as a quick task (not full article extraction) with the URL as a reference.

### Full Captures (URL-based)

```
/capture https://github.com/some/repo          # Auto-detects as blip
/capture blip https://github.com/astral-sh/uv --ring trial --quadrant tools
/capture article https://blog.com/post
/capture video https://youtube.com/watch?v=xxx
/capture person https://wikipedia.org/wiki/Person
/capture book https://goodreads.com/book/show/123
```

### Blip Options

Blips are for tracking technologies on your personal tech radar. All tools, frameworks, libraries, and platforms are captured as blips.

- `--ring`: adopt, trial, assess, hold
- `--quadrant`: tools, techniques, platforms, languages

**Ring definitions:**
- **Adopt**: Actively using in production, recommend for new projects
- **Trial**: Testing in real scenarios, building experience
- **Assess**: Worth exploring, researching, learning about
- **Hold**: Not recommended, proceed with caution, or deprecating

**Quadrant definitions:**
- **Tools**: Development tools, utilities, applications (Docker, VS Code, Terraform)
- **Techniques**: Methodologies, practices, patterns (TDD, Event Sourcing, GitOps)
- **Platforms**: Infrastructure, runtime, hosting (Kubernetes, AWS, Vercel)
- **Languages & Frameworks**: Programming languages, libraries, SDKs (Rust, React, FastAPI)

## Storage Structure

```
[workbench_path]/
└── notes/
    ├── inbox/          # Quick captures (task, note, idea)
    ├── sessions/       # Claude Code session summaries
    ├── blips/          # Tech radar items (tools, technologies, frameworks)
    ├── articles/
    ├── videos/
    ├── people/
    ├── books/
    ├── organisations/
    ├── troves/
    └── research/
```

## Requirements

- **For video captures**: `yt-dlp` must be installed
  - macOS: `brew install yt-dlp`
  - pip: `pip install yt-dlp`

## License

MIT
