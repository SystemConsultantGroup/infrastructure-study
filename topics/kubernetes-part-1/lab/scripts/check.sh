#!/usr/bin/env bash
set -euo pipefail
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
python3 "$script_dir/check.py" "$@" &
child=$!
on_signal() {
  trap '' INT TERM
  kill -TERM "$child" 2>/dev/null || true
  wait "$child" || true
  exit 130
}
trap on_signal INT TERM
trap 'kill -TERM "$child" 2>/dev/null || true' EXIT
status=0
wait "$child" || status=$?
trap - EXIT INT TERM
exit "$status"
