# Security Review: kujolang/dossier

## Scope

Full repository source review, baseline main 1d8ccee740820e25332ae8f25e422ca522a3ac0b plus current hardening; no host scan registered. Snapshot identifies source at security completion, not the later ending repository snapshot.

- Scan mode: repository
- Target kind: git_worktree
- Target ID: kujolang-dossier
- Revision: 1d8ccee740820e25332ae8f25e422ca522a3ac0b
- Snapshot digest: codex-security-snapshot/v1:sha256:1ce61a232bbd9efe151e1aac438369b975f69b82b02d0ac8660eb3cd7ff390cc
- Inventory strategy: repository
- Included paths: .
- Excluded paths: none
- Runtime or test status: Daybreak Blue; capability preflight ready with 3 worker slots (fewer-than-suggested warning); no dynamic exploit execution by architecture reviewer.
- Scan context: Production-grade repository hardening preserving compatibility and offline core; no sibling writes. SECURITY.md operator-local trust policy applies. Artifact timestamps cover final contract preparation; source review preceded preparation.

Limitations and exclusions:
- No claim of external/runtime-wide audit or remote deployment coverage.
- Source-at-security-completion snapshot uses plugin directory_content_digest, excluding generated docs/audits/evidence/2026-09-22 to avoid self-reference; security scope remains repository-wide.
- Token usage for prompt-only scan is unavailable.

### Scan Summary

| Field | Value |
| --- | --- |
| Scan outcome | completed |
| Reportable findings | 0 |
| Severity mix | none |
| Confidence mix | none |
| Coverage | complete |
| Validation mode | Source-backed prompt-only standard scan; independent baseline and architecture review plus parent review. |

Canonical artifacts: `scan-manifest.json`, `findings.json`, and `coverage.json`. This report is a deterministic projection of those files.

## Threat Model

Dossier 0.2.0 is an offline, operator-run Kujo evidence ledger for editors, agents and CI. The launcher selects KUJO_BIN or kujo on PATH and invokes dossier.kujo (bin/dossier:3-4; dossier.kujo:1-2). CLI parsing produces versioned JSON envelopes (src/core.kujo:225-240). Mutations validate JSON, actor labels and optional artifact metadata before writing immutable records and creation events (src/core.kujo:71-93; src/storage.kujo:72-102). Reads provide bounded pages, integrity validation and explicit exports. Optional library helpers supply signatures, encryption, citations, freshness and retention receipts independently of CLI dispatch (src/hardening.kujo:11-81; src/core.kujo:1-5; README.md:18-21).

### Assets

- Ledger confidentiality/integrity: state precedence is nonempty CLI --state, JSON config state, then caller-working-directory-relative .dossier (src/core.kujo:43-47,149-156; src/profile.kujo:8). Metadata is STATE/metadata.json; records are STATE/records/\<id\>.json; per-record locks are STATE/locks/\<id\>.lock (src/storage.kujo:35-43,62-66).
- Current events use STATE/history/\<first32 SHA256(timestamp + newline + id)\>.json and raw record-byte SHA256; original 0.1.0 records without contract_version use first24 SHA256(timestamp + id) filenames and canonical-JSON checksums (src/storage.kujo:91-95,117-132).
- Evidence provenance includes actor, timestamp, payload and optional artifact path/hash/size. Actor and reviewed_by are recorded assertions rather than authenticated identities or privileges (src/core.kujo:76-88; src/domain.kujo:43-54; src/profile.kujo:18).
- Explicit --output receives a versioned JSON envelope capped at 8 MiB; --force permits replacing an otherwise safe destination. Without --output, results go to stdout (src/core.kujo:124-146,235-237).
- Optional library secrets are explicit in-memory HMAC key arguments (at least 16 bytes) and AES key arguments (32 bytes); baseline configuration stores no keys (src/hardening.kujo:16-24,57-58; docs/contracts.md:5).

### Trust Boundaries

- Caller CLI/config/payload -\> parsing/domain validation -\> operator-authorized filesystem. Config is a regular non-symlink file capped at 64 KiB with only state/actor/limit keys; payload is a regular non-symlink JSON object capped at 1 MiB with compatible major schema. Sensitive-shaped keys are recursively rejected (src/core.kujo:26-60; src/common.kujo:54-75). This is input robustness, not tenant authorization.
- Caller state path -\> immutable persistence. Safe IDs, state/managed-directory checks, exclusive per-ID lock files and native atomic no-replace publication protect normal operation. Record/event writes are separate with attempted rollback on event failure; OS ownership and ancestor integrity remain operator obligations (src/common.kujo:32-34; src/storage.kujo:27-32,40-57,64-102; docs/security.md:10-16).
- Caller or stored artifact path -\> filesystem read/hash. Creation stores the supplied path without copying the file into managed state. Validation reopens that path and compares size/hash; relative paths remain relative to the invoking process. Regular non-symlink checks and 64-MiB caps apply (src/core.kujo:63-68,80-88,113-117).
- Stored record/event -\> validation result. Full validation checks domain/artifact integrity and exact event fields/checksum with explicit legacy handling; truncated whole-state checks fail. Show/report/export retrieve records without those full integrity checks (src/core.kujo:168-178,188-210; src/storage.kujo:105-132).
- Record retrieval -\> explicit export destination. Resolved parent and state comparisons protect metadata and records/history/locks; existing leaf symlinks fail, replacement needs --force, output is bounded, dry-run returns digest without writing (src/core.kujo:124-146). No network publication/approval consumer is present in dispatcher.
- Optional library caller -\> crypto builtins. Canonical JSON and explicit shared keys provide HMAC manifests. Packet encryption/decryption take independent input/output paths and a key, check string path types, regular input and initially absent output, then delegate native file crypto. These APIs do not inherit CLI managed-state destination exclusions (src/hardening.kujo:11-24,57-58).
- CI repository inputs -\> trusted build runner. Pinned action/runtime commits build .runtime/kujo and pass ${github.workspace}/.runtime/kujo/target/release/kujo as KUJO_BIN; token permissions are contents:read (.github/workflows/validate.yml:5-27). Developer validation selects KUJO_BIN, then ROOT/../kujo/target/release/kujo with PATH fallback and changes to repository root (scripts/validate.sh:3-9). Core ledger operation does not require that network build path.

### Attacker Capabilities

- A lower-trust producer may supply malformed evidence JSON, locator text or artifacts that an operator chooses to ingest. The producer does not inherently control the CLI account, configuration, state ancestors or runtime executable. Boundary failures would need to add meaningful availability, integrity or confidentiality impact.
- Library callers supply packet objects, policies, manifests and paths; robustness matters without assuming a remote-service deployment. Filesystem access and key custody are inherited from the caller.
- Supplied policy: local state is operator-controlled rather than a multi-tenant boundary (SECURITY.md:3). Rewriting both records/events under the operator account does not gain an authenticated identity; checksums detect drift rather than such an attacker (docs/security.md:10-16).
- Locators are recorded data, not fetched URLs in inspected core. No HTTP server, browser session, tenant store, credential issuance or autonomous publication boundary was identified.

### Security Objectives

- Preserve CLI behavior, record IDs/canonical hashes, legacy compatibility and contract 1.0.0 while failing closed on invalid input (src/core.kujo:96-120; src/storage.kujo:122-131; docs/contracts.md:55-67).
- Prevent unintended overwrite of immutable records/events and managed state; detect audit mismatch without claiming crash-atomic two-file commits (src/storage.kujo:84-102,117-132; src/core.kujo:127-145).
- Keep core offline and distinguish stored claims from consent, rights or publication authority (src/profile.kujo:18; README.md:18-21,37-38).
- Bound accepted bytes, record size, artifact size, page candidates and record-byte budgets; report incomplete whole-state checks (src/core.kujo:29,53,67,143,188-203; src/storage.kujo:89,111,128,145-158).
- Keep evidence private through operator permissions; sensitive-key filtering is not arbitrary credential detection, and optional packet encryption is not automatic ledger encryption (docs/security.md:7-22).

### Assumptions

- Authoritative SECURITY.md:3 policy excludes multi-tenant authorization. Operator controls configuration, runtime executable and state ancestors. Hostile same-account ancestor replacement is outside the promised sandbox (docs/security.md:10-16).
- CLI packet is an immutable payload of safe claim_ids, whereas library packet_manifest expects a separate claims-array object; it does not resolve/sign CLI claim records automatically (src/domain.kujo:67-69; src/core.kujo:212; src/hardening.kujo:11-24).
- freshness check maps to integrity validation, not policy freshness, and history remains a record-list view rather than raw events; contracts explicitly explain both (src/profile.kujo:13-15; docs/contracts.md:23-33).
- No repository chmod/ACL enforcement establishes private state; permissions and backups are operator duties. Two-file crash recovery and stale locks remain manual (docs/security.md:10-16; docs/contracts.md:39-47).
- POSIX shell/slash-path startup is established; Windows-native guarantees are not established (bin/dossier:1-4; src/storage.kujo:12-30). No remote deployment or hostile shared-service exposure is assumed.
- Independent baseline audit covered all seven src modules, entrypoint, launcher, CI, validation script and tests; parent reviewed remaining tests/scripts/docs/schemas. Architecture review was offline/read-only. Parent supplied completed baseline outcome findings=\[\] and reviewed current hardening. Parent dynamic crypto-race verification is recorded separately; no hostile-service security exploit is claimed.
- README.md:79-80 now correctly distinguishes bounded record inputs/page processing from proportional directory enumeration. src/storage.kujo:141-149 and docs/contracts.md:15-17 retain this documented limit; the earlier README overstatement was resolved during hardening.
- Parent inspected native Kujo crypto.rs fs::rename publication and reproduced concurrent encryptions to one initially absent destination: both encryptions returned ok with different plaintext hashes, while final decryption matched one result (docs/audits/evidence/2026-09-22/crypto-one.txt:1; docs/audits/evidence/2026-09-22/crypto-two.txt:1; docs/audits/evidence/2026-09-22/crypto-read.txt:1). Dossier checks string path types and initial absence at src/hardening.kujo:57-58. This verified no-clobber reliability limit is not a demonstrated security boundary violation in operator-controlled storage; sibling runtime was not edited.

## Findings

### No findings

No reportable findings survived the canonical discovery, validation, and reportability gates.

## Reviewed Surfaces

| Surface | Risk Area | Outcome | Notes |
| --- | --- | --- | --- |
| CLI, configuration and JSON inputs | not recorded | No issue found | Regular-file/symlink/size checks, actor constraints, safe IDs and secret-shaped-key rejection traced at src/core.kujo:26-93 and src/common.kujo:25-89; args handling at src/args.kujo:19-74. No validated boundary failure. |
| Immutable storage and events | not recorded | No issue found | Atomic no-replace writes, per-ID exclusive locks, history checksum and legacy formats traced at src/storage.kujo:40-132. Same-authority state rewriting and hostile ancestor races are outside SECURITY.md:3 policy; crash atomicity and stale locks are documented limits, not hidden guarantees. |
| Bounded record retrieval and integrity validation | not recorded | No issue found | src/storage.kujo:135-168 bounds candidates and accepted bytes; src/core.kujo:188-203 rejects incomplete checks. Directory enumeration remains proportional to names, explicitly documented at docs/contracts.md:15-17. Show/report/export are retrieval, not full validation. |
| Output destinations and force semantics | not recorded | No issue found | src/core.kujo:124-146 protects managed state, rejects leaf symlinks and requires force for replacement. Dry-run does not write; native path-race protection is limited to operator-controlled directories. |
| Artifact reads and drift | not recorded | No issue found | src/core.kujo:63-68,113-117 bounds and hashes regular non-symlink artifacts; paths are stored verbatim and reopened. No network fetch of locators. |
| Evidence and authority assertions | not recorded | No issue found | src/domain.kujo:33-69 validates fields/taxonomies/references; src/profile.kujo:18 preserves consent/rights non-authority. Actor/reviewer assertions are not authentication; no missing tenant-auth finding under supplied policy. |
| Optional library crypto, policies and receipts | not recorded | No issue found | Current src/hardening.kujo:11-81 is independent of CLI. Explicit-key HMAC/AES, string path guards and finite policy-type checks preserve caller boundaries. Parent native fs::rename inspection and crypto-one.txt/crypto-two.txt/crypto-read.txt receipts establish a concurrent-output no-clobber reliability limitation, not a security finding. Helper boundary tests passed 90 checks (docs/audits/evidence/2026-09-22/final-gate.txt:7). Retention emits a receipt; it does not delete data. |
| Launcher, CI and developer validation | not recorded | No issue found | bin/dossier:3-4 selects trusted runtime; .github/workflows/validate.yml:5-27 pins actions/runtime source and uses read-only contents permission; scripts/validate.sh:3-9 has explicit executable selection. CI network/build authority is separate from offline core. |
| Tests, schemas, fixtures, docs and scripts | not recorded | No issue found | Parent completed remaining repository coverage. Fixtures/tests are developer inputs and schemas/docs describe contracts. README.md:79-80 now correctly qualifies directory enumeration; docs/contracts.md:23-33 explains history/freshness behavior. No validated security finding from support surfaces. |

## Open Questions And Follow Up

- Would a future workload require bounded directory enumeration rather than only bounded record-page processing? Current list_dir/sort is proportional to directory entries (src/storage.kujo:141; docs/contracts.md:15-17); no hostile shared-service deployment is assumed.
- Would future deployment require sandbox-grade ancestor-race resistance, authenticated state or crash-atomic record/event transactions? Those guarantees are explicitly absent under operator-local storage (SECURITY.md:3; docs/security.md:10-16; docs/contracts.md:39-47).
- Can a future Kujo runtime provide no-replace crypto output publication? Parent source inspection identified fs::rename, and concurrent encryptions both returned success while final output retained only one payload (docs/audits/evidence/2026-09-22/crypto-one.txt:1; docs/audits/evidence/2026-09-22/crypto-two.txt:1; docs/audits/evidence/2026-09-22/crypto-read.txt:1). Dossier type-checks paths and initially checks absence (src/hardening.kujo:57-58). This is verified reliability debt; native runtime changes are outside this repository task.
