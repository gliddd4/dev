Commands:

VIEW - Show file with line numbers (shows next step suggestions):
d view <file>
d view <file> 50 75     # Lines 50-75 only

FIND - Search project for text pattern:
d find '<pattern>'

RENAME - Replace ALL occurrences of text (ONLY for simple renames):
d rename <file> '<old>' '<new>'
⚠️ WARNING: Replaces EVERY occurrence in entire file!
⚠️ For code changes, use REPLACE instead!

REPLACE - Replace specific line ranges (PREFERRED for ALL code changes):
d replace <file> <start> <end> '<new_content>'
✓ Runs automatic dupecheck after applying
✓ Shows diff preview before applying
✓ Checks for duplicate functions

UNDO - Restore file from backup:
d undo <file>

DUPECHECK - Check for duplicate functions/imports:
d dupecheck [file]
(Also runs automatically after REPLACE)

DIFF - Show all pending changes across ALL files:
d diff
What it does:
- Finds all .bak files in project
- Shows numbered list of modified files
- Displays diff for each file (old → new)
- Helps you review all changes before finalizing

ARCHIVE - Finalize changes and archive backups:
d archive
What it does:
- Creates .bak_archive/ directory
- Moves all .bak files to archive with timestamp
- Preserves history (doesn't delete!)
- Finalizes all changes

What REPLACE does (step-by-step):
1. YOU MUST use VIEW first to see line numbers
2. Shows diff preview BEFORE applying
3. Checks for duplicate functions (warns if found)
4. Checks syntax (Python/Swift/Shell/JSON)
5. If syntax valid:
   - Creates .bak with PREVIOUS version
   - Applies change to file
   - Runs automatic DUPECHECK (silent unless issues)
6. If syntax invalid:
   - Shows error message
   - File NOT modified

What RENAME does:
- Replaces ALL occurrences of exact text match
- Shows big warning that it affects entire file
- Best ONLY for simple variable/function name renames
- Checks syntax after replacement
- If pattern not found: file NOT changed
- If syntax invalid: file NOT changed
- If valid: creates .bak and applies change

What DUPECHECK does:
- Scans for duplicate function definitions (def/func)
- Scans for duplicate imports
- Reports line numbers where duplicates appear
- Runs automatically after every REPLACE command

Rules:
✓ ALWAYS use VIEW before REPLACE to see line numbers
✓ Use REPLACE for code changes (NOT rename)
✓ Use RENAME only for simple text renames
✓ If syntax check fails, file is NOT modified
✓ If pattern not found (rename), file is NOT modified
✓ Every successful edit creates/updates .bak
✓ .bak always contains the PREVIOUS version
✓ DUPECHECK runs automatically after REPLACE
✓ DIFF shows ALL pending changes before you finalize
✓ ARCHIVE finalizes (archives, not deletes) all backups

Workflow:
1. VIEW <file> to see content with line numbers
   - Tool suggests next steps automatically
2. Decide what to change (note line numbers)
3. Use REPLACE <file> <start> <end> '<new_content>' for code
   - Tool shows diff preview
   - Tool checks syntax
   - Tool runs dupecheck automatically
   OR use RENAME <file> '<old>' '<new>' ONLY for simple renames
4. DIFF to see all pending changes across all files
5. ARCHIVE to finalize and archive backups
   OR UNDO <file> to revert specific file

Example session:
$ d view script.py
     1  def old_function():
     2      print("hello")
     3      return 42

$ d replace script.py 1 3 'def new_function():
    print("hello world")
    return 100'

Output shows:
-def old_function():
-    print("hello")
-    return 42
+def new_function():
+    print("hello world")
+    return 100

script.py updated (lines 1-3 replaced, .bak in same dir)

$ d diff
Files with .bak:

[1] Changes in: script.py
-def old_function():
+def new_function():

$ d archive
Archived 1 .bak'(s) to /Users/jb/dev/.bak_archive
