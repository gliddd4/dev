#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.expanduser("~/.tui"))

import tui

ui = tui.TUIHelper("dev", "v1.0.0", "blue", "gliddd4")

def show_help_menu():
    ui.show_menu(
        information=[
            "Commands:",
            "view <file>                    - View with line numbers",
            "rename <file> '<old>' '<new>'  - Replace text (simple renames)",
            "replace <file> <start> <end> '<new>' - Replace lines (preferred)",
            "find '<pattern>'               - Search project",
            "dupecheck [file]              - Check for duplicates",
            "diff                          - Show all changes",
            "undo <file>                   - Restore from backup",
            "archive                       - Archive backups",
        ],
        prompt="❯  Press q to exit",
        menu_items=[],
        quit_presses=1,
    )

if __name__ == "__main__":
    show_help_menu()
