#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
WORK="$(mktemp -d)"
trap 'find "$WORK" -depth -delete' EXIT
"$KUJO_RUNTIME" run "$ROOT/scripts/crypto_contention_probe.kujo" -- prepare "$WORK/state"
for mode in encrypt decrypt; do
  for name in one two; do
    action="$name"
    if [[ "$mode" == decrypt ]]; then action="decrypt-$name"; fi
    "$KUJO_RUNTIME" run "$ROOT/scripts/crypto_contention_probe.kujo" -- "$action" "$WORK/state" > "$WORK/$mode-$name.json" &
    if [[ "$name" == one ]]; then first_pid=$!; else second_pid=$!; fi
  done
  wait "$first_pid"
  wait "$second_pid"
done
"$KUJO_RUNTIME" run "$ROOT/scripts/crypto_contention_probe.kujo" -- read "$WORK/state" > "$WORK/read.json"
"$KUJO_RUNTIME" run "$ROOT/tests/crypto_contention_receipt.kujo" -- "$WORK"
printf 'Dossier crypto contention passed: encrypt=1/2 decrypt=1/2; persisted bytes match winners.\n'
