#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  printf 'Usage: %s COMMAND [ARGUMENTS...]\n' "$0" >&2
  exit 2
fi

for attempt in 1 2 3; do
  if "$@"; then
    exit 0
  else
    status=$?
  fi
  if [ "$attempt" -lt 3 ]; then
    printf 'Attempt %s/3 failed (exit %s); retrying in %s seconds\n' \
      "$attempt" "$status" "$((attempt * 5))" >&2
    sleep "$((attempt * 5))"
  fi
done

exit "$status"
