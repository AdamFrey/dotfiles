#!/usr/bin/env bash
# Hook dispatcher: fans stdin to scripts in global.d/ and project hooks.d/
# for the current hook event, then merges their JSON outputs.
#
# Contract:
#   Pre:  stdin is JSON with hook_event_name field
#   Post: stdout is single JSON with merged additionalContext, or empty
#   Inv:  every matching script receives identical stdin
set -uo pipefail
shopt -s nullglob

INPUT=$(cat)
EVENT=$(jq -r '.hook_event_name // empty' <<< "$INPUT")
[ -z "$EVENT" ] && exit 0

GLOBAL_DIR="$HOME/.claude/hooks/global.d/$EVENT"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:+$CLAUDE_PROJECT_DIR/.claude/hooks.d/$EVENT}"

scripts=()
if [ -d "$GLOBAL_DIR" ]; then
  for f in "$GLOBAL_DIR"/*.sh; do
    [ -x "$f" ] && scripts+=("$f")
  done
fi
if [ -n "${PROJECT_DIR:-}" ] && [ -d "$PROJECT_DIR" ]; then
  for f in "$PROJECT_DIR"/*.sh; do
    [ -x "$f" ] && scripts+=("$f")
  done
fi

[ ${#scripts[@]} -eq 0 ] && exit 0

exit_code=0
contexts=()

for script in "${scripts[@]}"; do
  out=$(printf '%s' "$INPUT" | "$script") || {
    code=$?
    [ "$exit_code" -eq 0 ] && exit_code=$code
    continue
  }
  [ -z "$out" ] && continue
  ctx=$(jq -r '.hookSpecificOutput.additionalContext // empty' <<< "$out") || continue
  [ -n "$ctx" ] && contexts+=("$ctx")
done

if [ ${#contexts[@]} -gt 0 ]; then
  merged=""
  for ctx in "${contexts[@]}"; do
    [ -n "$merged" ] && merged+=$'\n'
    merged+="$ctx"
  done
  jq -n --arg ctx "$merged" --arg event "$EVENT" '{
    hookSpecificOutput: {
      hookEventName: $event,
      additionalContext: $ctx
    }
  }'
fi

exit "$exit_code"
