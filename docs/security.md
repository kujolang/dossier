# Security and authority

Dossier is local-first. State paths are explicit, record IDs reject traversal,
record and managed-directory symlinks are refused, inputs are limited to 1 MiB,
and artifacts to 64 MiB. Immutable files use atomic no-replace publication;
`--force` cannot replace managed state. Validation checks the stored record
against its creation event. Secret-shaped payload fields are rejected on both
creation and validation; this is not detection of credentials embedded in prose.

The state directory and its ancestors must be controlled by the operator.
Path checks followed by reads/writes are not a sandbox against a hostile local
process swapping ancestors. Checksums detect drift, not an attacker rewriting
both record and event. Keep state private using OS permissions and backups.
Two-file commits and stale locks need operator recovery after a crash; consult
[contracts](contracts.md). No new multi-tenant or crash-durability guarantee is
claimed.

Packet crypto, freshness, citation, and retention helpers in
`src/hardening.kujo` are optional library APIs. They do not grant consent,
rights, publication approval, or network access. HMAC signatures require a
shared secret and are not public-key signatures. AES packet encryption is not
automatic encryption of the evidence ledger.
