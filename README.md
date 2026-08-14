# Dossier

Evidence, claims, sources, consent, freshness, conflicts, and rights records for defensible editorial work.

Dossier 0.1.0 is an independently installable, local-first Kujo tool. It requires no hosted service, Chain of Command, WebOps, or sibling Publishing House tool. The canonical entrypoint is `dossier.kujo`; `bin/dossier` contains no product logic.

## CLI

Commands: claim add; claim show; source add; evidence attach; evidence classify; conflict add; quote add; consent record; rights record; freshness check; verify; packet; report; export; doctor; version; init; show; validate. Run `./bin/dossier help` for flags. Mutations require `--actor`; JSON input uses `--input`. Common flags include `--json`, `--dry-run`, `--state`, `--output`, `--config`, and `--force`. Exit codes: 0 success, 1 validation/operation failure, 2 usage error.

State defaults to `.dossier/`. Immutable JSON records and append-only history use atomic writes. IDs reject traversal; symlinks and oversized inputs are rejected. See [contracts](docs/contracts.md), [security](docs/security.md), and [quickstart](examples/quickstart.md).

Test with `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/test.kujo`, then run `./bin/dossier doctor --json`.

0.1.0 covers the documented local records, fixtures, validation, checksums, deterministic fixed-time IDs, and structured export. It does not manufacture human judgment, consent, rights, approval, or causation. Dossier records evidence and rights assertions but never grants consent or rights and never treats a URL as verification.
