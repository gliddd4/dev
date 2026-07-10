#!/usr/bin/env bash
# dev.sh - All-in-one development tool
# Usage: dev.sh <command> [args]

set -euo pipefail

cmd=${1:-help}
shift || true

# Show curses-based help menu
if [[ "$cmd" == "help" ]]; then
  python3 "$(dirname "$0")/dev_menu.py"
  exit 0
fi

# RENAME - Simple text replacement (for renaming only)
rename() {
  local file=$1
  local search=$2
  local replace=$3
  
  echo "Renaming: '$search' -> '$replace' in $file"
  echo "Replaces ALL occurrences! For code changes use REPLACE."
  
  [[ -f "$file" ]] || { echo "File not found: $file"; exit 1; }
  
  # Pick linter based on file extension
  case "${file##*.}" in
    py)    linter=(python3 -m py_compile) ;;
    swift) linter=(swift -frontend -parse) ;;
    json)  linter=(python3 -m json.tool) ;;
    sh)    linter=(bash -n) ;;
    *)     linter=() ;;
  esac
  
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  
  # Apply text replacement
  python3 - "$file" "$search" "$replace" > "$tmp" <<'PYEOF'
import sys
with open(sys.argv[1], "r") as f:
    content = f.read()
new_content = content.replace(sys.argv[2], sys.argv[3])
if content == new_content:
    print("Pattern not found in file", file=sys.stderr)
    sys.exit(2)
print(new_content, end='')
PYEOF
  
  if [[ $? -eq 2 ]]; then
    echo "File NOT modified (pattern not found)"
    exit 2
  fi
  
  # Check syntax
  if ((${#linter[@]})); then
    error_output=$("${linter[@]}" "$tmp" 2>&1) || {
      echo "Syntax check failed"
      echo "$error_output"
      echo "File NOT modified"
      exit 1
    }
  fi

  # Backup and apply
  cp "$file" "$file.bak"
  cat "$tmp" > "$file"
  
  echo "Renamed in $file (backup: $file.bak)"
}
# REPLACE - Replace specific line ranges
replace() {
  local file=$1
  local start=$2
  local end=$3
  local new_content=$4
  
  [[ -f "$file" ]] || { echo "$file not found"; exit 1; }
  
  # Pick linter based on file extension
  case "${file##*.}" in
    py)    linter=(python3 -m py_compile) ;;
    swift) linter=(swift -frontend -parse) ;;
    json)  linter=(python3 -m json.tool) ;;
    sh)    linter=(bash -n) ;;
    *)     linter=() ;;
  esac
  
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  
  # Build new file content
  {
    sed -n "1,$((start-1))p" "$file"
    echo "$new_content"
    sed -n "$((end+1)),\$p" "$file"
  } > "$tmp"
  
  # CHECK FOR DUPLICATES - Prevent accidental code duplication
  local dup_check=$(grep -E "^(def|func|class) " "$tmp" 2>/dev/null | cut -d" " -f2 | cut -d"(" -f1 | sort | uniq -d)
  if [[ -n "$dup_check" ]]; then
    echo "Duplicate function/class definitions:"
    echo "$dup_check" | while read -r dup; do
      echo "  - $dup"
    done
    echo "Review diff before applying:"
    echo "-"
    diff -u "$file" "$tmp" | tail -n +3 || true
    echo "-"
    echo ""
  fi
  
  # Show diff preview (concise)
  diff -u "$file" "$tmp" | tail -n +3 | head -20 || true
  
  # Check syntax
  if ((${#linter[@]})); then
    error_output=$("${linter[@]}" "$tmp" 2>&1) || {
      echo "Syntax error:"
      echo "$error_output"
      exit 1
    }
  fi

  # Backup and apply
  cp "$file" "$file.bak"
  mv "$tmp" "$file"
  
  echo "$file updated (lines $start-$end replaced, .bak in same dir)"
  
  # Run automatic dupecheck (silent unless issues found)
  local dupecheck_output=$(dupecheck "$file" 2>&1 | grep -v "^===\|^$" || true)
  if echo "$dupecheck_output" | grep -q "WARNING:\|Duplicate"; then
    echo "$dupecheck_output"
  fi
}
# UNDO - Restore from backup
undo() {
  local file=$1
  
  [[ -f "$file.bak" ]] || { echo "$file.bak not found"; exit 1; }
  
  mv "$file.bak" "$file"
  echo "$file restored from .bak"
}

# VIEW - Display file with line numbers
view() {
  local file=$1
  local start=${2:-}
  local end=${3:-}
  
  [[ -f "$file" ]] || { echo "$file not found"; exit 1; }
  
  if [[ -n "$start" && -n "$end" ]]; then
    sed -n "${start},${end}p" "$file" | awk -v s=$start '{printf "%6d\t%s\n", s+NR-1, $0}'
  elif [[ -n "$start" ]]; then
    sed -n "${start},\$p" "$file" | awk -v s=$start '{printf "%6d\t%s\n", s+NR-1, $0}'
  else
    awk '{printf "%6d\t%s\n", NR, $0}' "$file"
  fi
}

# FIND - Search for text in project
find_text() {
  local pattern=$1
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  
  local found=0
  
  # Search through project files
  find "$script_dir" -type f \
    \( -name "*.py" -o -name "*.swift" -o -name "*.sh" -o -name "*.md" \) \
    ! -name "*.bak" 2>/dev/null | while IFS= read -r file; do
      if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "$file:"
        grep --color=auto -n "$pattern" "$file" | head -5
        echo ""
        found=$((found + 1))
      fi
    done
  
  if [[ $found -eq 0 ]]; then
    echo "'$pattern' not found"
  fi
}
# DUPECHECK - Check for duplicate definitions
dupecheck() {
  local file=${1:-.}
  
  # Collect files to check
  if [[ -f "$file" ]]; then
    files=("$file")
  else
    files=($(find "$file" -type f \( -name "*.py" -o -name "*.swift" -o -name "*.sh" \) 2>/dev/null))
  fi
  
  local issues=0
  
  for f in "${files[@]}"; do
    # Check for duplicate function/def definitions
    local defs=$(grep -n "^def \|^func " "$f" 2>/dev/null || true)
    if [[ -n "$defs" ]]; then
      local func_names=$(echo "$defs" | sed 's/.*\(def\|func\) //' | cut -d"(" -f1 | sort)
      local duplicates=$(echo "$func_names" | uniq -d)
      
      if [[ -n "$duplicates" ]]; then
        echo "Duplicate functions in $f:"
        echo "$duplicates" | while read -r dup; do
          echo "  - $dup (lines: $(grep -n "^\(def\|func\) $dup" "$f" | cut -d: -f1 | tr '\n' ' ' | sed 's/ $//'))"
        done
        ((issues++))
      fi
    fi
    
    # Check for duplicate imports
    local imports=$(grep -n "^import \|^from .* import" "$f" 2>/dev/null | cut -d: -f2- | sort || true)
    if [[ -n "$imports" ]]; then
      local dup_imports=$(echo "$imports" | uniq -d)
      
      if [[ -n "$dup_imports" ]]; then
        echo "Duplicate imports in $f:"
        echo "$dup_imports" | while read -r dup; do
          echo "  - $dup"
        done
        ((issues++))
      fi
    fi
  done
  
  # Only output if issues found (silent otherwise)
  if [[ $issues -gt 0 ]]; then
    echo "-"
    echo "Found $issues issue(s)"
  fi
}

# DIFF - Show all pending changes
diff_changes() {
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  local backups=$(find "$script_dir" -name "*.bak" -type f 2>/dev/null || true)
  
  if [[ -z "$backups" ]]; then
    echo "All clear"
    exit 0
  fi
  
  echo "Files with .bak:"
  echo ""
  
  local count=0
  while IFS= read -r bakfile; do
    [[ -z "$bakfile" ]] && continue
    original="${bakfile%.bak}"
    count=$((count + 1))
    
    echo "[$count] Changes in: $original"
    diff -u "$bakfile" "$original" | tail -n +3 | head -30 || true
    echo ""
  done <<< "$backups"
}

# ARCHIVE - Archive backups (finalize changes)
archive() {
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  local backup_dir="$script_dir/.bak_archive"
  local timestamp=$(date +%Y%m%d_%H%M%S)
  
  # Create archive directory if it doesn't exist
  mkdir -p "$backup_dir"
  
  local backups=$(find "$script_dir" -maxdepth 5 -name "*.bak" -type f 2>/dev/null || true)
  
  if [[ -z "$backups" ]]; then
    echo "No .bak's to archive"
    exit 0
  fi
  
  local count=0
  while IFS= read -r bakfile; do
    [[ -z "$bakfile" ]] && continue
    local basename=$(basename "$bakfile")
    local archived_name="${basename%.bak}_${timestamp}.bak"
    mv "$bakfile" "$backup_dir/$archived_name"
    count=$((count + 1))
  done <<< "$backups"
  
  echo "Archived $count .bak'(s) to $backup_dir"
}

# HELP
help() {
  cat <<'HELP'
dev.sh - Development tool with syntax checking

COMMANDS:

  view <file> [start] [end]
    Display file with line numbers
    Example: dev.sh view script.py
    Example: dev.sh view script.py 10 20

  find '<pattern>'
    Search for text across project files
    Example: dev.sh find 'function_name'

  edit <file> '<old>' '<new>'
    Replace all occurrences of text (for renames)
    - Checks syntax before applying
    - Creates backup with previous version
    Example: dev.sh edit script.py 'old_func' 'new_func'

  replace <file> <start> <end> '<new>'
    Replace specific line range (preferred for code)
    - Shows diff preview before applying
    - Checks syntax before applying
    - Creates backup with previous version
    Example: dev.sh replace script.py 10 15 'new code here'

  undo <file>
    Restore file from most recent backup
    - Shows what changes will be reverted
    Example: dev.sh undo script.py

  dupecheck [file]
    Check for duplicate function definitions and imports
    - Scans Python, Swift, and Shell files
    Example: dev.sh dupecheck script.py
    Example: dev.sh dupecheck .

  verify
    Show all pending changes (diffs) across files
    - Displays what changed in each file
    Example: dev.sh verify

  clean
    Archive all backups and finalize changes
    - Moves .bak files to .bak_archive/ with timestamp
    - Keeps last backup in archive (not deleted)
    Example: dev.sh clean

WORKFLOW:

  1. VIEW: dev.sh view file.py
  2. EDIT or REPLACE: dev.sh replace file.py 10 15 'new code'
  3. VERIFY: dev.sh verify
  4. KEEP: dev.sh clean
  OR UNDO: dev.sh undo file.py

HELP
}

# MAIN
case "$cmd" in
  rename)    rename "$@" ;;
  replace)   replace "$@" ;;
  undo)      undo "$@" ;;
  find)      find_text "$@" ;;
  view)      view "$@" ;;
  dupecheck) dupecheck "$@" ;;
  diff)      diff_changes ;;
  archive)   archive ;;
  help)      help ;;
  *)         echo "Unknown cmd: $cmd"; help; exit 1 ;;
esac
