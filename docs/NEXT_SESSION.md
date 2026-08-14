# Dossier next-session worklist

- [x] Add signed evidence packets and detached checksum manifests.
- [x] Add configurable freshness policies by source and claim class.
- [x] Add bounded citation-format adapters with offline conformance fixtures.
- [x] Add encrypted-at-rest optional storage without making keys a baseline requirement.
- [x] Add large-corpus streaming packet benchmarks and multi-process contention tests.
- [x] Add privacy-retention policies with explicit redaction receipts.

Completed 2026-08-14. `src/hardening.kujo` implements the bounded contracts; validation covers a 10,000-claim stream, 32 concurrent writers, optional AES-256-GCM packet encryption, detached signatures, freshness, citations, and redaction receipts.
