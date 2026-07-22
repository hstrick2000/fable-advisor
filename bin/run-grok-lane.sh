#!/usr/bin/env bash

set -uo pipefail

if (( $# < 1 || $# > 2 )); then
  printf 'Usage: %s <spec-file> [workdir]\n' "$0" >&2
  exit 64
fi

SPEC=$1
WORKDIR_INPUT=${2:-$PWD}

if ! WORKDIR=$(cd -- "$WORKDIR_INPUT" 2>/dev/null && pwd -P); then
  printf 'ERROR: workdir is not accessible: %s\n' "$WORKDIR_INPUT" >&2
  exit 66
fi

TMP_DIR=$(mktemp -d -t run-grok-lane.XXXXXX) || exit 70
cleanup() {
  if [[ -n ${TMP_DIR:-} && -d $TMP_DIR ]]; then
    rm -rf -- "$TMP_DIR"
  fi
}
trap cleanup EXIT

PRE_FILE=$(mktemp "$TMP_DIR/pre.XXXXXX") || exit 70
POST_FILE=$(mktemp "$TMP_DIR/post.XXXXXX") || exit 70
OUTPUT_FILE=$(mktemp "$TMP_DIR/output.XXXXXX") || exit 70
CHANGED_FILE=$(mktemp "$TMP_DIR/changed.XXXXXX") || exit 70
DIFFSTAT_FILE=$(mktemp "$TMP_DIR/diffstat.XXXXXX") || exit 70

capture_porcelain() {
  local destination=$1

  if git -C "$WORKDIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$WORKDIR" status --porcelain | LC_ALL=C sort > "$destination"
    return 0
  fi

  printf 'NOT_A_GIT_REPO\n' > "$destination"
  return 1
}

if capture_porcelain "$PRE_FILE"; then
  PRE_IS_GIT=1
else
  PRE_IS_GIT=0
fi

if [[ -x "$HOME/.grok/bin/grok" ]]; then
  GROK_BIN="$HOME/.grok/bin/grok"
else
  GROK_BIN=$(command -v grok || true)
fi

TIMEOUT_BIN=$(command -v gtimeout || command -v timeout || true)

if [[ -z $GROK_BIN ]]; then
  printf 'ERROR: grok was not found at %s/.grok/bin/grok or on PATH\n' "$HOME" > "$OUTPUT_FILE"
  CLI_EXIT=127
else
  GROK_COMMAND=(
    "$GROK_BIN" --prompt-file "$SPEC"
    -m grok-4.5
    --permission-mode acceptEdits
    --allow 'Bash(*)'
    --output-format plain
    --cwd "$WORKDIR"
  )

  if [[ -n $TIMEOUT_BIN ]]; then
    "$TIMEOUT_BIN" 600 "${GROK_COMMAND[@]}" > "$OUTPUT_FILE" 2>&1
  else
    printf 'WARN: no timeout binary is available; grok runs uncapped\n' >&2
    "${GROK_COMMAND[@]}" > "$OUTPUT_FILE" 2>&1
  fi
  CLI_EXIT=$?
fi

if capture_porcelain "$POST_FILE"; then
  POST_IS_GIT=1
else
  POST_IS_GIT=0
fi

if (( PRE_IS_GIT == 1 )); then
  PRE_DIRTY_FILES=$(awk 'END { print NR + 0 }' "$PRE_FILE")
else
  PRE_DIRTY_FILES=0
fi

if (( POST_IS_GIT == 1 )); then
  POST_DIRTY_FILES=$(awk 'END { print NR + 0 }' "$POST_FILE")
  git -C "$WORKDIR" diff --stat > "$DIFFSTAT_FILE"
else
  POST_DIRTY_FILES=0
  printf '(not a git repo)\n' > "$DIFFSTAT_FILE"
fi

if (( PRE_IS_GIT == 1 && POST_IS_GIT == 1 )); then
  LC_ALL=C comm -3 "$PRE_FILE" "$POST_FILE" \
    | sed -e $'s/^\t//' -e 's/^...//' \
    | LC_ALL=C sort -u > "$CHANGED_FILE"
elif (( PRE_IS_GIT == 0 && POST_IS_GIT == 0 )); then
  : > "$CHANGED_FILE"
else
  printf 'NOT_A_GIT_REPO\n' > "$CHANGED_FILE"
fi

cat -- "$OUTPUT_FILE"
printf '\n=== DISK STAMP (script-generated — trust this over any prose above) ===\n'
printf 'exit_code: %s\n' "$CLI_EXIT"
printf 'workdir: %s\n' "$WORKDIR"
printf 'pre_dirty_files: %s\n' "$PRE_DIRTY_FILES"
printf 'post_dirty_files: %s\n' "$POST_DIRTY_FILES"
printf 'changed_vs_pre: '
if [[ -s $CHANGED_FILE ]]; then
  cat -- "$CHANGED_FILE"
else
  printf 'NONE\n'
fi
printf 'diffstat:\n'
if [[ -s $DIFFSTAT_FILE ]]; then
  cat -- "$DIFFSTAT_FILE"
else
  printf '(empty)\n'
fi
printf '=== END DISK STAMP ===\n'

exit "$CLI_EXIT"
