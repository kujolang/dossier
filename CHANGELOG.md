# Changelog

## Unreleased

- Publish immutable records, audit events, metadata, and record locks without replacement; verify record bytes against creation events and protect managed state from forced exports.
- Bound query scans to 1,000 JSON candidates and 4 MiB, add `next_after` to scanned report/export pages, and fail whole-state checks with `validation_incomplete` when truncated.
- Make record/init/export dry runs write-free; enforce missing CLI values, JSON version flags, configuration types, real calendar dates, distinct conflict sources, and safe references.
- Enforce UTF-8 byte limits for records, required text, exports, citations, and explicit crypto keys; export byte receipts now count bytes rather than characters.
- Return unexpected native-operation diagnostics in the CLI error envelope; align the record schema with supported 0.1.0/0.2.0 records and required contract version.
- Resolve the default runtime from PATH, propagate the selected runtime through validation, verify same-ID contention and audit checksums, and clean test-owned temporary state.
- Add regression and corruption-query fixtures and clarify library-only functionality and remaining storage limits in the hardening audit.
- Standardized README badge ordering and repository-local artifact ignores.
- Kept Loop Engineering evidence available locally while removing it from published source.

## 0.2.0 - 2026-08-14

- Preserved validation compatibility with immutable 0.1.0 records while emitting 0.2.0 records.
- Prevented audit-history conflicts from leaving partial records and added clean-retry regression coverage.
- Enforced bounded record references, SHA-256 evidence checksums, retrieval timestamps, state compatibility, managed-directory safety, and stricter immutable-record validation.
- Modularized the Kujo runtime and added strict claim, source, evidence, conflict, quotation, consent, rights, and packet contracts.
- Added atomic storage/export, per-record locks, bounded pagination, JSON configuration, structured errors, secret rejection, and corrupt-record diagnostics.
- Added production CI, domain/security suites, improved documentation, and an explicit future-work list.

## 0.1.0 - 2026-08-14

- Initial Kujo-native release with working local records, validation, contracts, fixtures, and safety boundaries.
