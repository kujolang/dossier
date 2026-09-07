# Dossier next-session worklist

- [x] Add signed evidence packets and detached checksum manifests.
- [x] Add configurable freshness policies by source and claim class.
- [x] Add bounded citation-format adapters with offline conformance fixtures.
- [x] Add encrypted-at-rest optional storage without making keys a baseline requirement.
- [x] Add large-corpus streaming packet benchmarks and multi-process contention tests.
- [x] Add privacy-retention policies with explicit redaction receipts.

Completed 2026-08-14. `src/hardening.kujo` implements the bounded contracts; validation covers a 100,000-claim synthetic stream benchmark, 32 concurrent writers, optional AES-256-GCM packet encryption, detached signatures, freshness, citations, and redaction receipts.

Audit clarification: the synthetic benchmark counts generated classifications;
it does not exercise persisted evidence or measure streaming I/O/memory.
`streaming_packet_report` accepts an already materialized array. See the
[current audit](audits/repository-hardening.md) for remaining limits and real
query measurements. The contention gate now tests both distinct and identical
record IDs and compares persisted records with their audit checksums.
