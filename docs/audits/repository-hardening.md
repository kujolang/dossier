# Dossier repository hardening audit

## Repository and provenance

- Repository: `kujolang/dossier`, local directory `/Users/robertdevore/2026/Kujolang/kujo-repos/dossier`.
- Branch: `main`; initially clean.
- Starting SHA: `5c17bd7c77abee499fe9c67498bed6f2a1baf8fa`.
- Ending implementation SHA: `eea32708d6b018c05d030507cc5b6d02f23ff9cf`.
- This report/evidence is committed separately after the implementation. Resolve its publication SHA with `git log -1 --format=%H -- docs/audits/repository-hardening.md`; a commit cannot embed its own hash.
- Audit date: 2026-09-07 UTC. Host: Darwin x86_64; tested executable: sibling Kujo `target/release/kujo`, reporting 1.3.1.
- Purpose: offline evidence ledger for editors, reviewers, agents, and CI, covering claims, sources, captured support, classifications, consent, and rights assertions.
- Dependencies: one external Kujo executable, no manifest package dependencies, no database/model/provider/network service. Tests/release wrappers also use standard POSIX utilities and Bash. No dependencies added or removed.
- CI runtime: Kujo commit `5059695d14d6726bc17fef55e0b95511624967cf`, built from source. GitHub actions are SHA-pinned. This audit executed the local 1.3.1 runtime, not a fresh build of the CI pin; source inspection confirmed the atomic no-replace and encoding/schema primitives at the pin.

## Ground truth and coverage

Read every implementation module and test, entrypoint/launcher, package/version
configuration, JSON schemas, committed fixtures/example, all existing docs,
security policy, ignore rules, and CI/release scripts. Source consists of seven
small Kujo modules behind `dossier.kujo`. The CLI calls `parse_args`, `dispatch`,
domain validation, then flat-file storage. Optional hardening APIs are imported
by tests, not wired to new CLI verbs. No background worker, server, MCP schema,
model prompt, retry orchestrator, database migration, or hosted provider exists.

Reviewed storage initialization, immutable publication, record locks, history
rollback, reads and hashes, listing/filter/cursor behavior, export paths,
configuration and argument boundaries, all domain validators, signing and
streaming crypto delegation, freshness/citation/retention helpers, and error
translation. Read the Kujo implementations of `create_dir`, `write_file_atomic`,
`path_absolute`, string length, and streamed AEAD to verify dependencies instead
of guessing from names. Searches in sibling `kujo-agents`, `kujo-workflows`, and
`kujo-skills` found no direct `dossier history/verify/report` command or Dossier
module imports under the inspected patterns; this is not proof of no consumers.
No sibling repository source was modified.

Complexity review preserved the small module boundaries, generic profile hooks,
canonical serializer and exported helpers. No evidence justified removing the
legacy diff/profile hooks or changing their public surface. No broad formatting
rewrite, cache, index, dependency replacement, or synthetic micro-optimization
was introduced. No build/binary optimization is claimed for a Kujo-source tool.

## Baseline

`/usr/bin/time -p bash scripts/validate.sh` passed before any edits: 46 assertions,
32 distinct concurrent writes, entrypoint check, fixture/schema JSON parsing,
launcher smoke commands, repository policy checks, and `git diff --check`.
Elapsed time was 6.33 seconds; see [baseline receipt](evidence/baseline.txt).
There was no pre-existing failure in that gate. The old contention script only
counted filenames and used bare `wait`; it did not check each worker's status,
same-ID contention, or persisted history equivalence.

An immutable archive of the starting SHA in `/tmp/dossier-audit/baseline` was
used to run the new regressions against old code. It reproduced six failed
assertions (dry-run/invalid-write side effects, missing argument values, invalid
calendar dates) before the oversized integer caused runtime exit 4. Full
reproduction output is [preserved](evidence/regression-before.txt). Other
findings below are explicitly source-supported or validated with final tests.

## Findings

| ID | Priority | Area | Finding | Evidence | Action | Status |
| --- | --- | --- | --- | --- | --- | --- |
| D01 | P0 | Integrity/concurrency | Recursive directory creation is not an exclusive lock; record/event writes explicitly allowed overwrite. | Storage `acquire_lock` and runtime `create_dir_all`; no-replace runtime implementation checked at CI pin. | Atomic no-replace file locks and immutable publication; inspect every worker and its event hash. | Fixed |
| D02 | P0 | Integrity/export | `export --force` could replace records or metadata. | Old export only checked symlinks/existence; regression explicitly attempts four managed destinations. | Resolve aliases and reject metadata/records/history/locks destinations, preserving safe external replacement. | Fixed |
| D03 | P1 | Integrity/validation | Verification never compared stored bytes with creation history. | Old `validate_record` checked shape/artifact only; final tests mutate valid payload and remove event. | Check event checksum, identity, actor, time, schema and kind; reuse checksums from the bounded scan. | Fixed |
| D04 | P1 | Resource/output | Filtering and corruption could scan an entire directory and accumulate unbounded warnings; up to 1000 MiB of record contents could be retained. | Old loop bounded matching records only; 2000-corrupt-file benchmark. | 1000-candidate and 4 MiB page budget, additive continuation cursor, byte-budget pagination tests. | Fixed for record processing; filename enumeration remains D12 |
| D05 | P1 | Failure contracts | Whole-state checks could return success on truncated state. | Old `valid`/`healthy` ignored `truncated`; boundary regressions. | Fail incomplete checks with `validation_incomplete`; document per-ID verification. | Fixed |
| D06 | P1 | Side effects | Dry runs and invalid creates initialized state; dry-run export/init wrote files. | Starting-code regression and final no-write assertions. | Validate before initialization; return dry-run receipts before publication. | Fixed |
| D07 | P1 | Input/error | Very large decimal options escaped as runtime errors; impossible dates passed regex validation; version alias dropped flags. | Baseline regression; actual subprocess exit and JSON assertions. | Bounded numeric accumulation, Gregorian date validation, missing-value diagnostics, version flag parsing, native-error envelope. | Fixed |
| D08 | P1 | Byte contracts | `len(string)` counts characters, allowing byte-budget violations and incorrect export receipts. | Kujo `str_len` uses Unicode character count; 530000 two-byte characters exceeded record byte budget. | Exact UTF-8 sizes for record/field/export/citation/key checks, multibyte regressions. | Fixed |
| D09 | P2 | Schema/domain | Config types were unchecked, schema rejected supported legacy records, references/duplicate conflict sources were inconsistent. | Published config schema vs loader; old record schema fixed version to 0.2.0. | Typed config, supported version enum and required contract field, safe references and unique source IDs. | Fixed |
| D10 | P2 | Portability/verification | Launcher embedded a developer path; validation did not propagate its resolved runtime into contention; tests left state behind. | Launcher/scripts/test inspection. | PATH fallback, explicit runtime propagation, test-owned cleanup, assertion of fixture setup, 96-assertion gate and real contention receipts. | Fixed |
| D11 | P2 | Documentation | Broad streaming/encryption/freshness claims obscured library-only and synthetic behavior. | `core.dispatch` and `src/hardening.kujo`; benchmark just counts generated entries. | Clarify module APIs, materialized arrays, HMAC/shared-key semantics, and CLI validation behavior. | Fixed |
| D12 | P2 | Scale | `sort(list_dir(...))` still materializes every directory name before bounded processing. | Source-supported; no paged directory API found in inspected Kujo inventory. | Document limit; review a stable bounded enumeration primitive or compatible index before claiming constant-memory large-ledger queries. | Open |
| D13 | Needs more evidence | API | `history` remains a record-list view rather than an event view. | [Probe](evidence/history-probe.txt) shows record keys despite a separate creation event. | Document actual behavior; design an additive event-view contract after consumer review. | Open; no breaking replacement |

## Changes implemented

### Immutable persistence and verification — D01–D03

Root causes were check-then-create locking, overwrite-enabled publication, and
verification that ignored the separate audit record. Storage now creates an
exclusive lock file using the runtime's atomic no-replace path. Metadata race
losers revalidate the winning metadata. Record and event publication never
replace existing destinations. Managed directories are checked again before a
write. Export destination comparison uses resolved paths before allowing force.
Validation hashes the exact loaded bytes and compares the creation event; the
whole-state validator reuses scan checksums rather than rereading each record.

Affected: `src/storage.kujo`, `src/core.kujo`, contention runner and receipt,
storage/security/contract tests. Existing immutable record and event formats,
canonical IDs and versions are unchanged. Legacy 0.1.0 compatibility is tested
by publishing a complete legacy record/event pair, not rewriting an existing
record while retaining its old checksum. Lock representation changes are
internal; old lock directories still block writers. Mixed-version concurrent
writers are unsupported and explicitly documented.

### Bounded reads and honest completeness — D04–D05

The old limit counted only selected records. It did not bound skipped records,
corruption diagnostics, or cumulative record bytes. The shared scan now limits
candidate processing and bytes, supplies `next_after`, and preserves deterministic
lexical order. A page cut off before a record does not advance beyond that record.
Tests cover empty filtered continuation, corrupt pages, incomplete validation,
and a six-record corpus crossing the byte budget without losing records.

Affected: storage/core, `tests/audit_test.kujo`, query benchmark. Existing result
fields remain; scan/export cursors are additive. Consumers must continue pages
until `truncated` is false. Validation of an incomplete scan now correctly fails.
Directory enumeration remains an explicitly separate limit (D12).

### Input, byte, CLI and schema contracts — D06–D09

Initialization occurred before payload validation, alias parsing discarded all
trailing flags, and numeric/date checks relied on unsafe conversion or shape
alone. Byte contracts incorrectly used a character count. Fixed each boundary
without changing valid record IDs or hashes. The UTF-8 size helper derives byte
length from Base64 because the CI runtime predates native `byte_length`; it has
a temporary encoding cost, not a speed claim. No runtime-minimum bump is hidden.

Affected: args/common/domain/core/hardening, published record schema,
`tests/audit_contract_test.kujo`, audit/domain/hardening tests. Tests cover actual
CLI JSON and exit codes, calendar centuries, long digits, config shapes,
protected outputs, Unicode, domain-valid record tampering, missing history,
secret fields in stored payloads, wrong signing keys and failed AEAD publication.

### Verification, output and developer experience — D10–D11

The launcher now honors `KUJO_BIN` or PATH. The selected runtime is propagated
through subprocess tests. The contention runner tests 32 distinct IDs and 32
identical IDs, waits for each exit, requires the right winner count, verifies
successful writer content, audit hashes and absence of leftover locks, and
emits one concise receipt. Full evidence remains in fixtures and committed
receipts. Existing tests clean their own UUID paths without following symlinks;
symlink cleanup uses POSIX `unlink` because the pinned runtime's delete helper
rejects directory symlinks. The application has no new subprocess dependency.

Documentation now distinguishes actual CLI behavior from module helpers. The
432-byte `AGENTS.md` was already concise and remains unchanged; profile metadata
is 1259 bytes. There are no model prompts, tool schemas, context replay, or
agent-model calls to optimize. No token estimate or provider-token saving is
claimed. All diagnostic reduction measurements below use exact ASCII bytes.

## Performance and efficiency

A dedicated corruption fixture created by `scripts/query_benchmark.kujo` contains
2000 one-byte malformed JSON files with safe IDs. Both revisions read the same
fixture with a 100-record limit. Timing includes process startup. One sample was
collected per revision; the host was busy and subsequently experienced transient
process exhaustion, so timings are observations, not a stable speed guarantee.
The query is intentionally a corruption/failure-path workload, not general CRUD
throughput. Preserved [before](evidence/query-before.txt) and [after](evidence/query-after.txt).

| Dimension | Starting revision | Hardened implementation | Interpretation |
| --- | ---: | ---: | --- |
| Warning entries in one response | 2000 | 1000 | Bounded processing; remaining evidence is paginated, not discarded |
| Compact result bytes | 184045 | 92071 | Exact fixture result size, including the new cursor |
| Query elapsed seconds | 23.36 | 13.52 | Single noisy sample |
| Query CPU user/system seconds | 10.74 / 2.13 | 5.10 / 0.86 | Same caveat |
| Accepted-size record bytes processed per page | No aggregate bound | 4194304 | Code-enforced budget, not measured RSS |
| Regression assertions | 46 | 96 | Includes 20 query/byte-boundary and 25 contract checks |
| Contention cases | 32 distinct writes | 32 distinct plus 32 same-ID writes | Exactly 32 and 1 winners, respectively |
| Full gate seconds | 6.33 | 32.62 | Expanded verification workload; not an application regression comparison |
| Manifest package dependencies | 0 | 0 | Unchanged; Kujo remains external |

No allocation/RSS, binary size, build-time, provider-token, or network-performance
improvement is claimed. Optional 100000-entry synthetic counting remains a
functional smoke check, not evidence for persisted streaming performance.

## Security, state and failure boundaries

Reviewed CLI/config/payload types, traversal, final/managed-directory symlinks,
export aliases, record and history integrity, secret-shaped fields, atomic
publication, crash rollback, stale locks, cryptographic delegation, resource
budgets and diagnostic failure paths. No production secrets or network calls
were used. Shell strings are not assembled from record content; concurrent
launches use quoted arguments and test subprocesses use argv arrays.

State is operator-controlled, not a hostile multi-tenant boundary. Ancestor
symlink swaps and file-size/read races are not eliminated by preflight path
checks. An actor able to rewrite both record and history can rewrite checksums.
Record/event publication remains two independent file operations: a crash can
leave a record without an event or a stale lock. Verification now detects the
missing event; recovery is manual, never a silent retry that overwrites records.
This audit does not claim power-loss durability or an automatic recovery journal.
Retain private OS permissions and backups as documented in `docs/security.md`.

## Compatibility

- Public APIs: existing signatures/record formats remain; internal scan support and UTF-8 helper are additive exports. `history` retains its existing view.
- CLI: valid commands remain. Missing values now return 2; version JSON works; dry runs avoid writes; unsafe forced exports and incomplete checks fail. Unexpected native failures retain their diagnostic inside exit-1 envelopes.
- File formats: record/event/metadata formats unchanged; per-record locks change from directories to exclusive files. Stop old writers before upgrading a shared state.
- JSON schemas: record schema accepts both supported tool versions and requires the already-present `contract_version`; query/export `next_after` is additive.
- Config/environment: config file shape and `KUJO_BIN` are unchanged; schema-invalid config types now fail. The default executable is PATH `kujo` rather than a developer-specific absolute path.
- Unicode: documented byte limits now mean bytes. Previously accepted over-budget Unicode content/keys may fail; export byte receipts are corrected.
- External consumers: pagination and fail-closed validation require callers to handle `truncated` and nonzero exits. No consumer source was changed or assumed private. Existing incomplete/corrupt states are reported rather than migrated silently.

## Cross-repository follow-ups

D12 affects the Kujo filesystem contract: Dossier cannot bound memory for all
filenames while using `list_dir` followed by sorting. Review a paginated,
deterministically ordered and capability-aware directory reader, or a Dossier
index with explicit crash-recovery/invalidation semantics. Such an API would be
additive and optional; the current fixes do not require another repository to
change. Evidence is the storage scan plus inspected runtime inventory. No
constant-memory claim should be made until measured with a representative large
ledger. A future minimum-runtime review could also replace the compatibility
UTF-8 helper with existing modern `byte_length`; no runtime change is required.

## Remaining work

- P0/P1: no unresolved finding established within the documented operator-controlled trust boundary; no known introduced regression remains.
- P2: D12 directory-name enumeration. An index/new runtime primitive needs measurement and recovery design, not a speculative cache.
- Needs more evidence: D13 additive audit-event view and downstream contract review. Current `history` semantics are preserved and documented.
- Needs more evidence: crash-recovery automation, hostile-local-filesystem isolation, generic malformed-type coverage for all optional policy helpers, and multi-sample/RSS performance characterization. These were reviewed but are not claimed solved.
- P3 / not worth changing: profile indirection, unused-looking compatibility hooks, formatting of compact helper modules, tiny duplicate packet canonicalization absent a measured hot workload, and dependency replacement.
- Verification boundary: local gate passed on Kujo 1.3.1; remote pinned-runtime CI is a separate result, not implied by the local receipt.

## Verification receipt and reproduction

Run from the Dossier root unless the command explicitly identifies the baseline
archive. `KUJO_BIN` defaults in the gate to the sibling release executable.

| Command | Result |
| --- | --- |
| `/usr/bin/time -p bash scripts/validate.sh` before editing | PASS, 46 assertions and original contention, 6.33s |
| `git archive 5c17bd7c77abee499fe9c67498bed6f2a1baf8fa \| tar -x -C /tmp/dossier-audit/baseline` | Immutable baseline source extracted |
| `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/audit_test.kujo` in baseline archive with new test copied in | Expected FAIL, six assertions then oversized-number runtime exit 4 |
| `../kujo/target/release/kujo run scripts/query_benchmark.kujo -- prepare /tmp/dossier-audit/query-state` | PASS, 2000-file dedicated fixture |
| `/usr/bin/time -p /Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run scripts/query_benchmark.kujo -- query /tmp/dossier-audit/query-state` in baseline archive | PASS, 184045 bytes, 2000 warnings, 23.36s |
| `/usr/bin/time -p ../kujo/target/release/kujo run scripts/query_benchmark.kujo -- query /tmp/dossier-audit/query-state` | PASS, 92071 bytes, 1000 warnings, 13.52s |
| `../kujo/target/release/kujo run tests/test.kujo` | PASS, including complete legacy record/event compatibility |
| `../kujo/target/release/kujo run tests/audit_contract_test.kujo -- ../kujo/target/release/kujo` | PASS, 25 assertions |
| `bash scripts/contention_benchmark.sh` | PASS, all 64 exits and persisted receipts checked |
| `bash -n scripts/validate.sh scripts/contention_benchmark.sh` and `sh -n bin/dossier` | PASS |
| `/usr/bin/time -p bash scripts/validate.sh` after implementation | PASS, 96 assertions, both contention cases, all JSON documents, CLI smoke and policy checks; 32.62s |
| `git diff --check` | PASS |

The full gate executes `kujo check dossier.kujo`; seven suites (`test`,
`security_test`, `storage_test`, `domain_test`, `hardening_test`, `audit_test`,
`audit_contract_test`); the contention receipt; `scripts/validate_json.kujo` for
every fixture/schema; launcher help/version/doctor; dependency-reference,
README-badge and ignore-policy checks. A Kujo compiler build, Rust formatting,
separate type checker, UI/E2E suite, or model eval is not provided by this repo.

An intermediate test run encountered host fork exhaustion (OS error 35), not a
repository assertion failure. Another exposed directory-symlink cleanup behavior
and was fixed with non-following unlink. During implementation, a string-split
numeric conversion and an incorrectly named encoding builtin were caught and
corrected; neither is treated as a baseline failure. All final suites passed
without increasing timeouts, adding sleeps, disabling assertions, or reducing
concurrency. Logs are receipts, not a claim of exhaustive vulnerability absence.

## Durable follow-up register

SignalBox was searched for Dossier, directory enumeration and history views
before writing. No duplicate of either Dossier-specific finding was found.

- D12 Capture: `cap_a358124b-cb89-4cf7-a5ac-ae4c665125f1`.
- D12 review Signal: `sig_806c90dc-02bb-4569-8014-d08e1b7d7525`.
- D13 Capture: `cap_e225bc5b-ed8f-4e10-aa9b-19aa57db6cd3`; no Signal, pending consumer evidence.
- Each item was retrieved by exact ID. Concept queries `directory name`,
  `Dossier directory`, and `Dossier history` retrieved the respective items.
- Duplicates skipped: 0. Completed D01–D11 fixes, routine verification, and
  transient host errors were rejected as Capture candidates. No tasks,
  dispositions, or external messages were created.

The completed-session handoff/current milestone belongs in Strata `Agent Notes`,
with this report and the final commit as provenance; it is separate from the
unresolved-finding register above.
