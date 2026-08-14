# Changelog

## 0.2.0 - 2026-08-14

- Preserved validation compatibility with immutable 0.1.0 records while emitting 0.2.0 records.
- Prevented audit-history conflicts from leaving partial records and added clean-retry regression coverage.
- Enforced bounded record references, SHA-256 evidence checksums, retrieval timestamps, state compatibility, managed-directory safety, and stricter immutable-record validation.
- Modularized the Kujo runtime and added strict claim, source, evidence, conflict, quotation, consent, rights, and packet contracts.
- Added atomic storage/export, per-record locks, bounded pagination, JSON configuration, structured errors, secret rejection, and corrupt-record diagnostics.
- Added production CI, domain/security suites, improved documentation, and an explicit future-work list.

## 0.1.0 - 2026-08-14

- Initial Kujo-native release with working local records, validation, contracts, fixtures, and safety boundaries.
