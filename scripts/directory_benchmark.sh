#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
WORK="$(mktemp -d)"
trap 'find "$WORK" -depth -delete' EXIT
"$KUJO_RUNTIME" run "$ROOT/scripts/directory_benchmark.kujo" -- prepare "$WORK/names"
if [[ "$(uname -s)" == Darwin ]]; then time_flag=-l; else time_flag=-v; fi
for iteration in 1 2 3; do
  for mode in full page; do
    printf 'iteration=%s mode=%s\n' "$iteration" "$mode"
    /usr/bin/time "$time_flag" "$KUJO_RUNTIME" run "$ROOT/scripts/directory_benchmark.kujo" -- "$mode" "$WORK/names"
  done
done
