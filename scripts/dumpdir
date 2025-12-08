#!/usr/bin/env bash
# dumpdir <dir> [maxdepth] [exclusion...]
# Exclusions are relative to <dir>

set -eu

DIR=${1:-}
[ -z "$DIR" ] && { echo "Usage: $0 <dir> [maxdepth] [exclusion...]"; exit 1; }
shift

DEPTH=
if [[ $# -gt 0 && $1 =~ ^[0-9]+$ ]]; then
  DEPTH=$1
  shift
fi

# defaults to merge with user exclusions
DEFAULTS=(node_modules __pycache__ .git .venv .cache .tox build dist .pytest_cache .idea .vscode)
escape() { printf '%s' "$1" | sed 's/[][\\.^$*+?|(){}]/\\&/g'; }

EX_PAT=
for d in "${DEFAULTS[@]}"; do
  EX_PAT=${EX_PAT:+$EX_PAT|}$(escape "$d")
done
if [ $# -gt 0 ]; then
  for e; do
    e=${e%/}
    EX_PAT=${EX_PAT:+$EX_PAT|}$(escape "$e")
  done
fi

# decide find base args
FARGS=(-print)
if [ -n "$DEPTH" ]; then
  FIND_BASE=(find "$DIR" -mindepth 0 -maxdepth "$DEPTH")
else
  FIND_BASE=(find "$DIR")
fi

# filter function: read full paths from find, compute path relative to DIR, skip if matches EX_PAT
_filtered() {
  "${FIND_BASE[@]}" "${FARGS[@]}" | while IFS= read -r p; do
    # normalize DIR with no trailing slash for prefix removal
    pd="${DIR%/}"
    rel="${p#"$pd"/}"
    # special-case when p equals DIR itself
    if [ "$p" = "$pd" ]; then
      rel="."
    fi
    if [ -n "$EX_PAT" ] && [[ $rel =~ ^($EX_PAT)(/|$) ]]; then
      continue
    fi
    printf '%s\n' "$p"
  done
}

tmp=$(mktemp)

{
  echo "### Directory: $DIR (depth: ${DEPTH:-∞}) ###"
  _filtered

  echo
  echo "### Text Files ###"
  # list files (filtered), then check mime and print contents
  "${FIND_BASE[@]}" -type f -print | while IFS= read -r f; do
    pd="${DIR%/}"
    rel="${f#"$pd"/}"
    [ "$f" = "$pd" ] && rel="."
    if [ -n "$EX_PAT" ] && [[ $rel =~ ^($EX_PAT)(/|$) ]]; then
      continue
    fi
    t=$(file --mime-type -b "$f" 2>/dev/null || echo "")
    if [[ $t == text/* ]]; then
      echo "---- $f ----"
      cat "$f"
      echo
    fi
  done
} > "$tmp"

if command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard < "$tmp"
  echo "Copied to clipboard (xclip)."
elif command -v wl-copy >/dev/null 2>&1; then
  wl-copy < "$tmp"
  echo "Copied to clipboard (wl-copy)."
else
  echo "No clipboard tool found. Output follows:"
  cat "$tmp"
fi

rm -f "$tmp"
