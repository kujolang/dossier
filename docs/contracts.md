# Contracts

Contract 1.0.0. Dossier owns: Claim Record; Source Record; Evidence Record; Conflict Record; Quotation Record; Consent Record; Rights Record; Freshness Review; Evidence Packet. Records carry schema/tool versions, stable IDs, actor, timestamp, provenance, command, and payload. Consumers accept compatible 1.x, preserve safe unknown payload metadata, and reject incompatible majors. JSON uses `ok/data/error/tool_version/contract_version`. Offline upstream fixtures identify repository, tag, schema, and checksum.

Hardening contracts add detached SHA-256/HMAC-SHA256 packet manifests, source-and-claim freshness ceilings, bounded offline APA/MLA/Chicago citations, explicit-key AES-256-GCM packet encryption, 10,000-claim batched reports, concurrent-writer evidence, and policy-versioned retention/redaction receipts. Keys are passed explicitly and are never stored in baseline configuration.

## Bounded reads and integrity

Report/export pages retain `records`, `warnings`, and `truncated`, and add
`next_after` after a scan. Pass that cursor as `--after`, even for an empty
filtered page. A page examines at most 1,000 JSON record candidates and 4 MiB
of accepted-size record files, and retains at most the requested 1..1000
records. Corruption warnings count toward the scan budget. A record is still
limited to 1 MiB; exports written to a file remain limited to 8 MiB.
Directory enumeration uses `list_dir_page` and retains at most 1,001 filenames
per call. Every page still scans all directory entries (O(N) time); there is no
cross-call snapshot or cache. UTF-8/entry errors fail explicitly rather than
silently skipping names. Files are ordered by their complete `.json` filenames;
record cursors remain suffix-free IDs and are translated consistently, including
prefix-related IDs. Invalid filenames may require operator repair before a cursor
can be used; cursors retain the safe-record-ID contract.

Byte limits and export `bytes` receipts count UTF-8 bytes, including non-ASCII
text. The pinned runtime predates `byte_length`; a local Base64-size helper
preserves that runtime compatibility at the cost of a temporary encoding.

`validate`, `verify`, and `freshness check` perform record/domain/artifact and
audit-event integrity checks. The event must match the exact stored bytes,
record ID, actor, timestamp, event type, and schema. Missing history and drift
are failures, including for supported 0.1.0 records. These commands do not
authenticate external evidence or apply the optional freshness-policy helper.
A truncated whole-state check returns `ok: false`, `validation_incomplete`,
and exit 1. `doctor` checks bounded readability, not full domain integrity, and
also refuses to certify a truncated scan.

`history` retains its record-list view. The additive `history events` command
reads `STATE/history/` and returns `events`, `warnings`, `truncated`, `next_after`.
Each entry contains `event_id` (the filename stem) and `event` (the original
creation-event object). `--id` filters by record ID, `--limit` is 1..1000, and
`--after` accepts an exclusive 24- or 32-character hex event ID. Events are
ordered by filename, not chronology. Original 0.1.0 events remain readable.
Pages process at most 1,000 files and 4 MiB; each event is at most 64 KiB.
Warnings and filtered-out events count toward the scan budget. Continue empty
filtered pages using `next_after` while `truncated` is true. Invalid filenames
may require operator repair, as with record cursors. The published page schema
is `schemas/history-events.schema.json`.

Event views validate fields and filename identity, but do not assert that the
referenced record exists or authenticate its checksum: orphan events remain
inspectable for recovery. Use `verify --id` for record/event integrity. Neither
view repairs, rewrites or removes history. Existing CLI output remains unchanged.

## Writes and failure semantics

Dry runs of record creation, init, and file export do not write state or output.
Payload and actor validation precede state creation. No-overwrite atomic writes
publish records, history, and metadata. Locks are now exclusively created files;
legacy lock directories still block writes. Do not mix old and new writers on
the same state concurrently. Stop writers and inspect incomplete operations
before removing a stale lock; no automatic stale-lock removal is performed.

`--force` authorizes replacement of a safe named export only. Resolved output
paths cannot replace metadata or files beneath records/history/locks. The
record and its event are two writes, not one crash-atomic transaction; a crash
between them is detectable by validation and requires operator recovery.

Missing CLI flag values return exit 2. `--version --json` honors JSON output and
validates trailing flags. Config values must match their published types;
calendar dates must exist and conflict source IDs must be distinct. Native
operation errors are returned with `operation_failed` and their diagnostic in
the ordinary JSON envelope, exit 1, instead of escaping as runtime exit 4.

The record schema accepts tool versions 0.1.0 and 0.2.0. Original tagged 0.1.0
records/metadata may omit `contract_version`; that specific legacy format
implies contract 1.0.0 and uses its original record-type labels and 24-character
event filenames with canonical-JSON `checksum`. Later records require the
explicit contract field and use the 32-character filename/raw-byte checksum.
Readers select the documented format, never silently fall back to accepting
missing history. Legacy files are not rewritten; new records can coexist with
them. Historical payloads lacking current required domain fields still fail
validation and need review before a new record is created.

Record IDs, canonical hashes, input shapes,
and environment variables are unchanged. The launcher uses `KUJO_BIN` when
provided and otherwise finds `kujo` on PATH.

## Optional helper input boundaries

Freshness and retention day values accept non-negative finite integers or
fractions; strings and booleans are not numeric policies. Batch sizes and
synthetic claim counts must be integers within their existing limits.
Citation author/title/year/locator values must be non-empty strings, with the
existing 4 KiB rendered limit. Retention `redact_fields` must be an array of
strings. Invalid helper arguments return `ok: false`, rather than relying on
native coercions or arithmetic errors. Packet manifests and HMAC bytes remain
unchanged; signing reuses a single canonical representation.

The pinned runtime publishes native AES file outputs with atomic no-replace
semantics. Competing calls to one destination have exactly one successful
publisher; the loser returns a structured error and does not overwrite it.
Existing crypto receipt fields remain; `published` and `temporary_removed` are
additive. If temporary cleanup fails after successful publication, the receipt
includes `temporary_path` for operator cleanup instead of falsely reporting that
the committed output failed. This is exclusive publication, not a power-loss
or hostile-ancestor sandbox guarantee. Older runtimes retain the race described
in the historical audit; upgrade to the exact runtime revision pinned in CI.


## Runtime build contract

`version` and `doctor` report both `minimum_kujo` and
`minimum_kujo_revision`. CI pins the source revision and Rust 1.96.0, uses the
committed Cargo lock with `--locked`, and builds `--no-default-features`:
Dossier does not require Kujo's optional database, image, PDF, archive or JIT
APIs. The full default-feature runtime is also supported. Runner system packages
are not bit-for-bit pinned; this is a bounded build-input improvement, not a
claim of reproducible binaries. Atomic no-replace publication requires a
filesystem supporting hard links (as existing Dossier record writes already do).
