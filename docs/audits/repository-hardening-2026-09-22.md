Remaining-item resolution: [2026-09-22 completion](remaining-items-2026-09-22.md).

# Dossier hardening re-audit — 2026-09-22

## Repository and scope

- Repository: `kujolang/dossier`, branch `main`.
- Starting SHA: `1d8ccee740820e25332ae8f25e422ca522a3ac0b`, initially clean.
- Ending implementation SHA: `656f34abdc2eb5cc7a552e8010e8b78f5bf322d6`.
  A subsequent documentation commit publishes this report and its evidence;
  retrieve that publication SHA with `git log -1 --format=%H -- docs/audits/repository-hardening-2026-09-22.md`.
- Purpose: offline immutable claims/evidence ledger, with separate optional
  packet signing, encryption, freshness, citation and retention library APIs.
- Dependencies: zero manifest packages; external Kujo runtime and POSIX launcher.
  Local runtime identifies as 1.4.0. Inspected sibling runtime source is
  `7f4a288587710003c60869c016c8f4d97ca3b8af`; this is source provenance, not a
  claim that the installed executable was built from that exact SHA.
- CI pins Kujo `5059695d14d6726bc17fef55e0b95511624967cf` and action commits;
  workflow token is read-only. Compiler toolchain is `stable`, so the entire
  build environment is not fully reproducible. No dependency versions changed.

This is a new pass over an already hardened repository. The
[previous audit](repository-hardening.md) remains historical evidence; its
before/after figures are not attributed to this session.

## Ground truth and coverage

Read all seven source modules, entrypoint, launcher, tests, scripts, fixtures,
schemas, CI, package metadata and operational docs. Traced CLI/config precedence,
JSON envelopes/exit codes, deterministic IDs, supported legacy records, input
and artifact limits, raw-byte and legacy canonical checksums, paginated
reports/exports, per-ID locks and two-file record/event publication. Inspected
optional APIs rather than assuming they are exposed as CLI features. Sibling
publishing-tool references were inspected read-only; no sibling was modified.

Complexity review found concentrated missing validation in optional helpers,
and repeated packet serialization on a real signing path. Existing profile
indirection, empty diff-command support and compatibility hooks were preserved:
there is no evidence their removal improves behavior or downstream safety.
There are no model calls, prompts, MCP schemas, replay transcripts, network
clients or resident caches/queues to optimize. AGENTS.md is already small;
no token-saving claim is made. Diagnostics stay concise with detailed evidence
in files. Page warnings, records and bytes retain their existing budgets.

Independent security and architecture reviews supplemented parent source and
runtime review. [Canonical security report](evidence/2026-09-22/security/report.md)
records reviewed boundaries and remaining assumptions; no attacker vulnerability
was validated under the operator-controlled storage model. A concurrency bug in
the external crypto runtime is recorded separately as reliability/data integrity.

## Baseline

`/usr/bin/time -p bash scripts/validate.sh` passed before edits: 106 assertions,
eight suites, both contention cases, static entrypoint check, JSON documents,
launcher smoke and repository policy checks; elapsed 24.11s. No pre-existing
failure in that gate. Receipt: [baseline.txt](evidence/2026-09-22/baseline.txt).
New regressions run before their fixes demonstrated gaps the old gate missed:

- [helper-before.txt](evidence/2026-09-22/helper-before.txt): fractional batch/count
  assertions failed, then null batch arithmetic escaped with runtime exit 4.
- [storage-before.txt](evidence/2026-09-22/storage-before.txt): invalid direct
  storage metadata was not rejected without persistence; non-object input
  escaped with runtime exit 4. This does not imply CLI actor validation failed.

## Findings

| ID | Priority | Area | Finding / evidence | Action | Status |
| --- | --- | --- | --- | --- | --- |
| R01 | P1 | API failure semantics | Optional helper arithmetic/concatenation relied on runtime types; new baseline regression exits 4 | Validate types before arithmetic, iteration, string building or path I/O | Fixed |
| R02 | P1 | Storage | Direct `save_new` could admit null actor metadata and index non-objects | Validate storage object and event metadata before locks/writes | Fixed |
| R03 | P2 | Performance | `sign_packet` canonicalized the same packet twice; measured 1,031,902-byte fixture | Reuse one canonical string for SHA256 and HMAC | Fixed |
| R04 | P2 | Regression/contract | Missing malformed helper matrices and independent signing vector | Add 90 boundary assertions, 5 storage assertions, 1 signing vector to gate | Fixed |
| R05 | P2 | Documentation | Broad README bounded-query wording omitted filename enumeration cost | State page-bound versus total-directory distinction; document helper types | Fixed |
| R06 | P1 | Cross-repo concurrency | Two concurrent native AES encryptions report success at one output; final file contains one payload | Unique destination workaround; upstream atomic no-replace publication requested | Open in Kujo |
| D12 | P2 | Resource usage | `sort(list_dir(...))` retains all filenames before page limits | Preserve prior follow-up; needs index/recovery or runtime API design | Existing open item |
| D13 | Needs evidence | CLI contract | `history` is a record-list view, not event view | Preserve behavior until consumer review supports additive API | Existing open item |

## Changes and compatibility

R01 changes `src/hardening.kujo`: finite non-negative numeric day values remain
fraction-friendly; batches/counts require bounded integers. Citation fields
must be non-empty strings and are checked before constructing oversized output.
Retention validates its record type, clocks/duration and redaction field array.
Crypto wrappers reject non-string paths before native I/O. Invalid arguments
return `ok: false`; valid return objects and valid policy decisions are unchanged.
Fractional batch/count acceptance was a bug: these values describe discrete
items, and previously generated inconsistent batch counts or truncated ranges.
Existing integer limits are unchanged. Error text is more precise for invalid
inputs; no caller should depend on a runtime exception for malformed policies.

R02 changes `src/storage.kujo`: direct library storage calls validate the object,
actor/timestamp string types, and safe ID before lock acquisition or persistence.
This is a storage-shape check, not a duplicate domain validator; CLI validation
continues to enforce actor, timestamp and command semantics. Regression tests
verify malformed calls leave no locks or records and that valid subsequent
writes, history conflicts and retries still behave correctly.

R03 reuses canonical bytes through private helpers. No cache or invalidation
state is added; SHA256/HMAC algorithm and serialized input remain identical.
The existing helper suite now includes a fixed SHA256/HMAC vector independently
computed with Python's standard library during development. Python is not a
runtime, fixture, test or CI dependency. Large benchmark outputs are byte-for-byte
identical across all six measured runs.

R04 adds `tests/helper_boundary_test.kujo` to `scripts/validate.sh`, expands
storage and signing coverage, and includes a manual `scripts/packet_benchmark.kujo`.
CI runs deterministic behavior assertions; timing is deliberately not a flaky
wall-clock gate. Performance changes can be compared by rerunning the same
fixture, preserving its manifest as the equivalence check.

Public signatures, CLI success/usage/operational exits, record IDs and file
formats, schemas, configuration and environment variables are unchanged.
Original 0.1.0 compatibility tests pass. External library callers passing invalid
shape/type data now receive failures earlier; whitespace-only citations and
fractional counts are rejected. No external consumer migration is required for
valid inputs. Published manifests and encryption format have not changed.

## Performance and efficiency

Workload: five signings of 1,000 claims, 1,031,902 canonical bytes, fixed fixture
key, one final canonical-size measurement. Three separate process runs per
revision on the same local runtime; process startup and fixture creation are
included. Not a general CRUD, constant-memory, or hosted-service benchmark.

| Dimension | Before | After |
| --- | ---: | ---: |
| Elapsed seconds, three samples | 5.75 / 6.29 / 5.56 | 4.22 / 3.95 / 4.03 |
| Median elapsed seconds | 5.75 | 4.03 |
| Median user CPU seconds | 4.65 | 3.38 |
| Canonicalization calls per successful signing | 2 | 1 |
| Canonical bytes / output manifest | 1,031,902 / fixed | Identical |
| Full gate assertions | 106 | 202 |
| Full gate elapsed seconds (different coverage) | 24.11 | 25.27 |
| Manifest dependencies | 0 | 0 |

[Before](evidence/2026-09-22/packet-before.txt) and
[after](evidence/2026-09-22/packet-after.txt) retain times, digests and signatures.
No RSS/allocation, binary/build size, token or network savings were measured.
A single canonical buffer is reused, but peak-memory improvement is not claimed.
Expanded gate timing is not an application performance comparison.

## Security and state boundaries

Reviewed untrusted JSON, safe IDs and paths, file limits, symlinks, force exports,
secret-shaped fields, integrity events, native crypto authentication, concurrent
writers, lock cleanup, rollback and crash behavior. No live credentials or network
calls were used in application tests. Signed packets are shared-secret assertions,
not public-key identity. Policy receipts never delete records or grant authority.

Existing limitations remain: operator-owned ancestors, check/use races, manual
stale-lock/crash recovery, two separate record/event writes, checksum rewriting
by an operator who controls both files, and directory enumeration memory. Do not
advertise multi-tenant isolation, constant-memory queries or power-loss atomicity.

## Cross-repository follow-up R06

Affected repository: **Kujo**. Native `encrypt_file_stream` and
`decrypt_file_stream` in `src/interpreter/native_functions/crypto.rs` check output
absence then publish with `fs::rename`. The Dossier wrapper cannot make that
native publication exclusive against other runtime callers. A Dossier-only
advisory lock would not fix the native contract, and buffering an entire encrypted
file into `write_file_atomic` would regress streaming/resource behavior.

A manual two-process probe encrypted separate 8 MiB `a`/`b` files to one output.
Both receipts report success with distinct plaintext hashes; subsequent decryption
matches only the first file. Receipts: [one](evidence/2026-09-22/crypto-one.txt),
[two](evidence/2026-09-22/crypto-two.txt), [read](evidence/2026-09-22/crypto-read.txt).
Encryption was reproduced; decryption has the same source-supported publication
mechanism but was not independently raced. This is local concurrent data loss,
not a fabricated remote vulnerability.

Recommended fix: native atomic no-replace publication for both operations,
preserving 0600 temporary files, chunking, authentication and cleanup; add runtime
contention tests. Correctness requires one winner and a structured loser, not
silent overwrite. Current Dossier works with unique destinations; same-output
concurrency requires that upstream fix. No sibling modification or runtime bump
was made. `docs/contracts.md` documents the workaround.

The manual probe is outside CI because race scheduling is nondeterministic.
The first preparation attempt exceeded Kujo's generated-string limit at 16 MiB;
the final 8 MiB probe respects that limit. It did not justify raising a limit.

## Remaining work

- P0: none established in this pass.
- P1: R06 upstream streaming crypto no-replace publication; use unique paths.
- P2: existing D12 directory enumeration, already registered for review.
- Needs more evidence: D13 event-view consumers, sandbox-grade filesystem isolation,
  crash journaling, multi-host performance/RSS and complete build reproducibility.
- Not worth changing: compatibility hooks, profile layout, CLI output style,
  dependency replacement and cosmetic rewrites without behavioral evidence.
- No known regression introduced by this pass remains.

## Verification receipt

Commands run from Dossier unless noted; `../kujo/target/release/kujo` is the
absolute runtime required by AGENTS.md resolved relative to this checkout.

| Command | Result |
| --- | --- |
| `/usr/bin/time -p bash scripts/validate.sh` before edits | PASS, 106 assertions, 24.11s |
| `../kujo/target/release/kujo run tests/helper_boundary_test.kujo` before fix | Expected FAIL, fractional cases and native exit 4; preserved |
| `../kujo/target/release/kujo run tests/storage_test.kujo` before fix | Expected FAIL, malformed cases and native exit 4; preserved |
| `../kujo/target/release/kujo run tests/helper_boundary_test.kujo` after fix | PASS, 90 assertions |
| `../kujo/target/release/kujo run tests/storage_test.kujo` after fix | PASS, 9 assertions |
| `../kujo/target/release/kujo run tests/hardening_test.kujo` after helper fix | PASS; golden vector subsequently verified in full gate |
| `for run in 1 2 3; do /usr/bin/time -p ../kujo/target/release/kujo run scripts/packet_benchmark.kujo; done` before/after | PASS, same output, six timing samples |
| `/usr/bin/time -p bash scripts/validate.sh` after edits | PASS, 202 assertions, nine suites, both contention cases, 25.27s |
| `bash -n scripts/validate.sh scripts/contention_benchmark.sh` | PASS |
| `sh -n bin/dossier` | PASS |
| `git diff --check` | PASS |

[Final gate](evidence/2026-09-22/final-gate.txt) includes static entrypoint check,
all nine suites, 64 writer exits with persisted content/history verification,
all fixture/schema JSON checks, help/version/doctor, dependency-reference checks,
badge ordering and ignore policy. No separate formatter, package build, UI E2E
or model eval is supplied by Dossier. Application tests remain Kujo-native.

Crypto reproduction sequence (use a new disposable `probe_root` each time):

```sh
probe_root="$(mktemp -d)/crypto"
../kujo/target/release/kujo run scripts/crypto_contention_probe.kujo -- prepare "$probe_root"
../kujo/target/release/kujo run scripts/crypto_contention_probe.kujo -- one "$probe_root" > one.json &
first_pid=$!
../kujo/target/release/kujo run scripts/crypto_contention_probe.kujo -- two "$probe_root" > two.json &
second_pid=$!
wait "$first_pid"
wait "$second_pid"
../kujo/target/release/kujo run scripts/crypto_contention_probe.kujo -- read "$probe_root"
find "$(dirname "$probe_root")" -depth -delete
```

## Durable follow-up register

SignalBox deduplication searched `aes_encrypt_file_stream`, `crypto output`, and
`Dossier`. Existing D12 and D13 were skipped as duplicates (2); completed fixes,
normal tests and timing results were rejected as Capture candidates.

- R06 Capture: `cap_6d249381-f239-4326-86b4-2fa0a11847d7`, project `kujo`.
- R06 human-review Signal: `sig_21ebb8b7-a9eb-4bf8-97d1-dd0d927b8ad3`.
- Both exact ID retrievals and concept search `streaming AES` passed.
- No downstream tasks, dispositions or external messages were created.

The Strata Agent Notes handoff records this new milestone with report/commit
provenance, linking the previous 2026-09-07 milestone rather than duplicating it.

Security artifact verification used the plugin's
`finalize_scan_contract.py --scan-dir docs/audits/evidence/2026-09-22/security --source-root "$PWD"`;
it passed and generated the report from canonical JSON. A development-only
Python standard-library comparison also verified that all six parsed benchmark
receipts are identical. Agent instruction/profile sizes remain 432/1,259 bytes;
these are exact bytes, not model token counts.


## Pinned-runtime verification

[GitHub CI run 35758015330](https://github.com/kujolang/dossier/actions/runs/35758015330)
passed on implementation `656f34abdc2eb5cc7a552e8010e8b78f5bf322d6` after building
the pinned runtime. `gh run watch 35758015330 --exit-status` and
`gh run view 35758015330 --log` completed successfully;
[CI evidence](evidence/2026-09-22/ci-success.txt) preserves the full gate result.
Subsequent publication changes only docs, receipts and the manual dependency
probe; production source and the gate are unchanged.

A final compatibility probe ran the starting hardening module in a temporary
Kujo file with an integer citation year. It failed with `string + int`, confirming
that rejection replaces an existing runtime error rather than a supported
numeric-year conversion. [Receipt](evidence/2026-09-22/citation-before.txt).
The temporary probe file was removed.
