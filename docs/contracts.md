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
Directory name enumeration and sorting still use memory proportional to the
directory size. Invalid filenames may require operator repair before a cursor
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

`history` currently retains its existing record-list view. Raw creation events
are in `STATE/history/`; a dedicated event-view contract remains open.

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
