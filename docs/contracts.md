# Contracts

Contract 1.0.0. Dossier owns: Claim Record; Source Record; Evidence Record; Conflict Record; Quotation Record; Consent Record; Rights Record; Freshness Review; Evidence Packet. Records carry schema/tool versions, stable IDs, actor, timestamp, provenance, command, and payload. Consumers accept compatible 1.x, preserve safe unknown payload metadata, and reject incompatible majors. JSON uses `ok/data/error/tool_version/contract_version`. Offline upstream fixtures identify repository, tag, schema, and checksum.

Hardening contracts add detached SHA-256/HMAC-SHA256 packet manifests, source-and-claim freshness ceilings, bounded offline APA/MLA/Chicago citations, explicit-key AES-256-GCM packet encryption, 10,000-claim batched reports, concurrent-writer evidence, and policy-versioned retention/redaction receipts. Keys are passed explicitly and are never stored in baseline configuration.
