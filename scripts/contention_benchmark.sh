#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"; STATE="$(mktemp -d)/state"
trap 'find "${STATE%/state}" -depth -delete' EXIT
for i in $(seq 1 32); do input="${STATE%/state}/input-$i.json"; printf '{"schema_version":"1.0.0","claim_text":"claim %s","claim_kind":"fact"}\n' "$i" > "$input"; KUJO_BIN="$KUJO_RUNTIME" "$ROOT/bin/dossier" claim add --state "$STATE" --input "$input" --actor benchmark --timestamp "2026-08-14T00:00:00Z" --id "claim-benchmark-$i" --json >/dev/null & done
wait; count="$(find "$STATE/records" -type f -name 'claim-benchmark-*.json' | wc -l | tr -d ' ')"; test "$count" = 32; printf 'Dossier contention benchmark passed: workers=32 records=%s\n' "$count"
