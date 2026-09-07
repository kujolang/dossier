#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
WORK="$(mktemp -d)"
trap 'find "$WORK" -depth -delete' EXIT
for mode in distinct same; do
  state="$WORK/$mode"
  KUJO_BIN="$KUJO_RUNTIME" "$ROOT/bin/dossier" init --state "$state" --json > "$WORK/init-$mode.json"
  pids=()
  for i in $(seq 1 32); do
    input="$WORK/input-$i.json"
    printf '{"schema_version":"1.0.0","claim_text":"claim %s","claim_kind":"fact"}\n' "$i" > "$input"
    id="claim-benchmark-$i"
    if [[ "$mode" == same ]]; then id="claim-contended"; fi
    KUJO_BIN="$KUJO_RUNTIME" "$ROOT/bin/dossier" claim add --state "$state" --input "$input" --actor benchmark --timestamp "2026-08-14T00:00:00Z" --id "$id" --json > "$WORK/$mode-$i.json" 2> "$WORK/$mode-$i.err" &
    pids+=("$!")
  done
  succeeded=0
  for pid in "${pids[@]}"; do
    if wait "$pid"; then succeeded=$((succeeded + 1)); elif [[ "$mode" == distinct ]]; then exit 1; fi
  done
  expected=32
  if [[ "$mode" == same ]]; then expected=1; fi
  test "$succeeded" = "$expected"
  "$KUJO_RUNTIME" run "$ROOT/tests/contention_receipt.kujo" -- "$WORK" "$mode" "$expected"
done
printf 'Dossier contention checks passed: distinct=32/32 same-id=1/32; record/history checksums agree.\n'
