# dev

A CLI safe code editor for AI agents. Includes syntax checking, backup management, and a curses-based help menu.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/gliddd4/dev/main/install.sh | sh
```

Run the menu:

```bash
dev
```

## Commands

```bash
dev view <file>                          # View with line numbers
dev rename <file> '<old>' '<new>'        # Replace text (simple renames only)
dev replace <file> <start> <end> '<new>' # Replace lines (preferred)
dev find '<pattern>'                     # Search project
dev dupecheck [file]                     # Check for duplicate functions/imports
dev diff                                 # Show all changes
dev undo <file>                          # Restore backup
dev archive                              # Archive backups
```

## Features

- Syntax checking (Python, Swift, Shell, JSON)
- Auto .bak files
- Diff preview
- Duplicate function detection
- Won't apply if syntax broken

## AI workflow

1. `dev view file.py` - See line numbers
2. `dev replace file.py 10 20 'new code'` - Edit lines
3. `dev diff` - Check changes
4. `dev archive` - Keep changes OR `dev undo file.py` - Revert

## Why .bak not git?

- Works instantly anywhere (no git init)
- Won't mess with your git history
- AI agents can verify backups exist
- Simple undo for fast code editing
- Use git for real commits, .bak for AI

## Requirements

- Python 3 (for syntax checking)
- Bash (built-in on macOS/Linux)
