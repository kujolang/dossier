# Dossier remaining-item completion — 2026-09-22

## Scope and provenance

The follow-up request was “do the remaining items.” The actionable findings
were R06 (native crypto publication), D12 (directory-name memory), and D13
(additive event history) in the preceding audits. Necessary Kujo runtime changes
were included; unrelated sibling repositories were not modified.

- Dossier start: `96ad6d57a08852d84ace6b108d7ee31c4854ac58`, main, clean.
- Dossier implementation: `04cba8d35da4846ac05cd44dd52e623c3eb87fae`.
- Kujo start: `7f4a288587710003c60869c016c8f4d97ca3b8af`, main, clean.
- Kujo implementation: `5b057c62ec276c7761a5ae0534e30d86dc5e30bb`, pushed.
- Kujo final inventory/ignore publication: `cf785c0a7953717af16b657cda05b85d628144c5`, pushed; runtime source is unchanged from the pin.
- Report/evidence publication is a subsequent documentation commit, obtainable
  with `git log -1 --format=%H -- docs/audits/remaining-items-2026-09-22.md`.

Historical reports and their immutable before receipts remain available;
this document records their resolution rather than rewriting past observations.

## Implementation and compatibility

| Item | Change | Evidence |
| --- | --- | --- |
| R06 | Native encrypt/decrypt publication uses `hard_link` to claim the destination exclusively, then removes the private temporary name | Rust barrier publication test; both encrypt and decrypt contention tests; Dossier wrapper contention gate |
| D12 | New capability-gated `list_dir_page(path, after, limit, suffix)` retains a bounded max-heap and returns sorted names | Rust full-directory/pagination test; VM/interpreter and denied-capability contracts; memory workload |
| D13 | Add `history events`; retain `history` as the existing record view | Kujo CLI, schema, legacy, corruption, filter, byte/candidate-limit and symlink tests |
| F04 | Use the same filename ordering for record selection and continuation | Starting revision loses one of three prefix-related IDs; new regression returns all three |

### Exclusive native crypto publication

Both native streaming functions retain framed authenticated encryption,
authenticated termination, bounded chunk buffers, mode-0600 Unix temporary
files, and existing hashes/format. Publication is now atomic no-replace, even
if another writer creates the output after the initial existence check. Existing
files, directories and dangling symlinks cannot be replaced.

After successful publication a cleanup failure must not be reported as though
the output was never committed. Additive receipt fields `published` and
`temporary_removed` make the outcome explicit; `temporary_path` is included only
if cleanup failed. The operation requires hard-link support, already needed by
Dossier's existing no-replace record writes. It does not promise directory-sync
power-loss durability or protection from a hostile operator swapping ancestors.

Native tests include an eight-thread barrier at the exact publication boundary,
existing-entry preservation, four-way encryption and decryption races,
winning-content verification, absence of leftover temporaries, mode checks,
round-trip and tamper rejection. Dossier's new gate independently runs two
processes for each operation and checks receipts against persisted bytes. It
fails on older runtimes even if scheduling happens to avoid the old race.

### Bounded directory pages

The runtime retains at most `limit + 1` matching names (Dossier requests 1,000),
plus the current iterator entry. It scans every directory entry and keeps the
smallest names greater than an exclusive filename cursor, then sorts only the
retained page. This replaces Dossier's materialized `sort(list_dir(...))`.

Public runtime output contains `entries`, `next_after`, `truncated`,
`examined_entries` and `buffered_entries`. Limit is an integer in 1..10000;
read capability is required in both runtimes. I/O and non-UTF-8 names fail
explicitly instead of silently disappearing. Names are not followed as paths
by the primitive. Dossier still checks record/event file types and symlinks.

This bounds filename memory, not total directory traversal time. Each page is
O(N log K), uses O(K) retained names, and has no snapshot across calls. No cache,
index, invalidation scheme or crash-recovery sidecar is introduced. New files
sorting before an existing cursor require a fresh scan. Invalid record/event
filenames can still require operator repair before using their cursor.

Existing record cursor strings remain IDs. Internally their `.json` suffix is
restored for comparison with the same complete filenames used by enumeration.
Previously `claim-prefix-child.json` sorted before `claim-prefix.json`, but the
ID comparison then excluded `claim-prefix` after the first page. The immutable
starting-revision probe in `evidence/remaining/prefix-before.txt` records three
created IDs and only two returned. This is a correctness fix, not a reordered
API or removal of supported records.

### Event history

`history events --json [--id RECORD_ID] [--limit N] [--after EVENT_ID]` returns
an event page. Entries contain the filename-derived `event_id` and original
`event` object. The schema is `schemas/history-events.schema.json`. Both current
32-character event IDs and original 0.1.0 24-character IDs are supported.

Pages process at most 1,000 event files and 4 MiB; each event is at most 64 KiB.
Malformed entries produce bounded warnings. Filtering and corruption consume
the processing budget, and empty filtered pages retain usable continuation.
Byte-budget boundaries stop before consuming the next entry. Events are ordered
by filename, not chronology. The view checks event fields and filename identity,
but deliberately retains valid orphan events for operator recovery. Use
`verify --id` for record/event checksum integrity.

No existing `history` consumer is switched to this view. Read-only searches in
Kujo skills, agents, workflows and public docs found no direct history invocation
requiring migration; absence of search results is not proof there are no external
consumers. Preserving the old command avoids depending on such proof.

## Runtime and build compatibility

The runtime update is explicit: Dossier now requires Kujo 1.4.0 with the exact
revision pinned in CI. Earlier binaries reporting 1.4.0 can lack these primitives;
`version` and `doctor` therefore add `minimum_kujo_revision`. Upgrade the runtime
before adopting this source revision. There is no fallback to unbounded scans
or unsafe crypto publication. Record formats, IDs, hashes, existing CLI commands,
exit codes, config and environment variables remain compatible. New event pages
and runtime receipt fields are additive.

CI pins Rust 1.96.0 and Ubuntu 24.04, builds the pinned runtime with `--locked`,
and omits optional runtime database/image/PDF/archive/JIT features that Dossier
does not use. The local full-feature runtime remains supported and is independently
tested. This reduces unnecessary CI build inputs without replacing dependencies
or weakening Dossier's gate. It is not a bit-for-bit reproducible-binary claim:
runner images and system packages can still change.

## Verification

Baseline: the existing Dossier gate ran before modifications; receipt is
`evidence/remaining/baseline.txt`. New helpers and integration tests were executed
as code changed. The first Rust test-edit attempts exposed missing imports and
an extra inserted call argument; both were corrected before passing checks.
Those were implementation mistakes, not baseline failures.

Runtime commands from the Kujo checkout:

```sh
cargo test --lib stream_
cargo test --lib directory_pages
cargo test --test directory_page_contract --test stdlib_reference_contract --test stdlib_reference_policy_contract
cargo test --lib
cargo test --test native_api_security_boundaries --test docs_examples --test readme_contracts --test cli_contracts --test cli_json_contracts --test diagnostics_golden
cargo fmt --check
cargo build --release --locked
```

The full library run passed **901 tests**, with **7 existing ignored tests**.
No test was disabled or assertion weakened. The directory/runtime documentation
contracts passed 8 tests. The selected integration suites passed 145 tests,
including 87 native security-boundary tests. Complete receipts are in
`evidence/remaining/kujo-library.txt`, `kujo-contracts.txt`, and
`kujo-integration.txt`. Existing vendored tiny_http compiler warnings remain.

Application commands from Dossier:

```sh
../kujo/target/debug/kujo run tests/history_events_test.kujo -- ../kujo/target/debug/kujo
KUJO_BIN="$PWD/../kujo/target/debug/kujo" bash scripts/crypto_contention.sh
KUJO_BIN="$PWD/../kujo/target/debug/kujo" /usr/bin/time -p bash scripts/validate.sh
bash -n scripts/validate.sh scripts/crypto_contention.sh scripts/directory_benchmark.sh
sh -n bin/dossier
git diff --check
```

The event suite has 32 assertions, including actual CLI/error exits, schema
validation, legacy events, prefix-related record IDs, empty filtered pages,
corruption, 4-MiB boundaries, direct API types and directory symlinks. The crypto
contention gate checks both directions against the persisted winning payload.
No arbitrary sleeps or timeout increases were used. Local timings during
concurrent unrelated builds must not be interpreted as a performance regression.

## Measurement method

`scripts/directory_benchmark.sh` creates 20,000 fixed filenames once, then runs
three alternating full-materialization and bounded-page processes. Both select
the first 1,000 names and print their digest. The shell records peak RSS and
CPU/wall time with platform time tools; raw units differ on macOS and Linux.
The fixture exposes directory-memory cost without inventing a CRUD throughput
claim. CI runs the same workload on Linux. No elapsed/RSS threshold is imposed;
the stable memory ratchet is the tested retained-name bound, while digests prove
selection equivalence. Detailed completed-run receipts follow below.

## Remaining architectural assumptions

R06/D12/D13 are concrete implementation findings; the prior reports also list
possible future product guarantees under “needs more evidence.” They are not
silently promised by these changes:

- Hostile-local-filesystem isolation would change the operator-controlled trust
  model in SECURITY.md. Rooted read/write primitives now exist in Kujo, but a
  full sandbox cannot be claimed merely by replacing selected calls. That is a
  separate deployment requirement, not an outstanding vulnerability in this model.
- Automatic crash journaling would change the existing two-file record/event
  protocol and needs explicit recovery/authenticity semantics. The new event view
  improves inspectability; it never blesses an edited record by inventing history.
  Manual recovery and detectable incomplete writes remain the documented contract.
- Directory enumeration remains linear in directory size, and paging is not a
  transactional snapshot. The resolved issue is unbounded retained names.
- Locked sources/compiler and multi-platform measurement improve evidence;
  they do not claim bit-identical artifacts or universal performance results.

These limits remain explicit rather than being hidden behind a passing test.
No unrelated API redesign, destructive migration, or sibling rewrite was made.

## Memory and follow-ups

Previous R06, D12 and D13 SignalBox items remain historical evidence; no new
Capture is warranted for completed fixes. Their resolution and exact commits
belong in Strata's new handoff/current-state milestone, linked to the prior
`aa5bade5-526e-4292-8be0-001c5077be00` note. No SignalBox dispositions or external
messages are created by this engineering follow-up.

## Completed validation and measurements

The final macOS full-feature debug gate passed **234 assertions**, both 32-writer
record/event contention workloads, and both two-process crypto contention cases.
The baseline release gate passed 202 assertions in 31.68 seconds. The final debug
gate took 704.46 seconds on the overloaded development host; different build
profiles and concurrent workloads make those elapsed values unsuitable for
before/after performance comparison.

[Linux CI run 35761696168](https://github.com/kujolang/dossier/actions/runs/35761696168)
passed on implementation commit `04cba8d35da4846ac05cd44dd52e623c3eb87fae`.
It independently built the pinned Kujo runtime in release mode without optional
features, ran the full Dossier gate, and collected the directory measurements.
The full log is `evidence/remaining/ci-success.txt`.

The following are medians of three alternating processes per implementation.
RSS includes the entire Kujo process. macOS reports bytes; GNU time reports KiB.
Compare columns within each row only: compiler profiles, platforms and host load
differ. Timings are observations, not a stable latency promise or CI threshold.

| Workload / platform | Full names | Bounded page | Evidence |
| --- | ---: | ---: | --- |
| Retained filename count, both platforms | 20,000 | 1,001 | Structured benchmark receipts |
| Peak RSS, macOS full-feature debug, bytes | 44,642,304 | 19,107,840 | `evidence/remaining/directory-macos.txt` |
| Wall time, macOS debug, seconds | 1.33 | 0.43 | Same receipt; shared-host load |
| Peak RSS, Linux minimal release, KiB | 37,736 | 16,508 | `evidence/remaining/ci-success.txt` |
| Wall time, Linux release, seconds | 0.03 | 0.01 | Same receipt; coarse timer precision |

All twelve processes selected the same first 1,000 filenames, digest
`c2371701518f62ae1bf9b6c0d977ce4f99baac41dfedfba621cfa462d151bf53`.
The bounded implementation still examined all 20,000 directory entries; this
is a retained-memory improvement, not elimination of directory scans.
Commands were `KUJO_BIN="$PWD/../kujo/target/debug/kujo" bash scripts/directory_benchmark.sh`
on macOS and `bash scripts/directory_benchmark.sh` with CI's pinned release
`KUJO_BIN` on Linux. No token, binary-size or overall build-speed claim is made.

No P0/P1/P2 implementation finding remains from R06/D12/D13. The compatibility
requirements and architectural limits above remain applicable. The cross-repo
Kujo dependency is implemented, tested, pushed and pinned rather than left as
an unresolved follow-up.

### Broader runtime CI follow-through

Kujo CI detected line-reference drift in generated unsafe/TODO inventories after
the native edits. The authoritative generators refreshed both Markdown and CSV
outputs; no classifications or safety checks changed. The artifact guard also
found seven missing ignore rules already absent at starting SHA `7f4a288`; those
rules now match the existing shared artifact policy. Commands:

```sh
bash scripts/generate_unsafe_inventory.sh --strict
bash scripts/generate_v1_code_todo_triage.sh --strict
BASE_SHA=7f4a288587710003c60869c016c8f4d97ca3b8af HEAD_SHA=HEAD bash .github/scripts/check-kujo-tool-artifacts.sh
cargo test --test generated_artifact_freshness_contract
```

A local release smoke was inadvertently attempted while the optimized binary
was still building; it used the old runtime and failed at the new directory
contract. The raw receipt is `old-runtime-smoke.txt`. This is consistent with
the documented minimum-runtime upgrade, and is not counted as final validation.

The shared artifact guard passed, and all three generated-artifact freshness
contracts passed (123.33 seconds locally). Receipts: `kujo-freshness.txt`
and `kujo-artifact-guard.txt`.
The final runtime documentation-only commit `cf785c0` leaves the tested/pinned
runtime implementation unchanged. The prior runtime CI failures are retained
as diagnostic provenance; they are not presented as successful runs.

The full-feature macOS optimized build completed successfully with
`cargo build --release --locked` (57m36s under shared-host contention). The
subsequent `../kujo/target/release/kujo run tests/test.kujo` passed all 13 smoke
assertions. Receipts: `kujo-build.txt` and `release-smoke.txt`. This duration is
recorded as build evidence, not a representative build-performance measurement.

Final scope checks: shell syntax and `git diff --check` passed. No introduced
regression remains in the executed suites. Dossier Linux CI is successful; the
separate broad Kujo workflows for the documentation/ignore-only correction were
still queued at the last observation. Their affected checks passed locally.
