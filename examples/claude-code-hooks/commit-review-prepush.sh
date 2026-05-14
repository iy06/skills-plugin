#!/bin/sh
# PreToolUse hook: fires when Claude Code is about to run a Bash tool call.
# When the bash command contains "git push", spawn a fresh claude session that
# runs the /commit-review skill in range mode. If the review fails (non-zero
# exit), this script exits 2 so the host Claude Code session blocks the tool
# call and shows the reason on stderr.

set -eu

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

case "$cmd" in
  *"git push"*) ;;
  *) exit 0 ;;
esac

if ! command -v claude >/dev/null 2>&1; then
  echo "[commit-review-prepush] claude CLI not found; skipping review" 1>&2
  exit 0
fi

GIT_HOOK=pre-push claude --print "/commit-review range mode" \
  --allowedTools "Bash(git:*),Read,Glob,Grep" 1>&2 || exit 2
