# Dossier

[![Version](https://img.shields.io/badge/version-0.2.0-black)](VERSION)
[![CI](https://github.com/kujolang/dossier/actions/workflows/validate.yml/badge.svg)](https://github.com/kujolang/dossier/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)

Dossier is a Kujo-native, local-first evidence ledger for claims, sources,
captured support, classifications, conflicts, quotations, consent, freshness,
and rights. It gives editors, agents, CI jobs, and review workflows a portable
record of what a material claim may honestly rely on.

## Readiness posture

Dossier is ready for serious standalone evidence operations with immutable
records, append-only audit events, atomic writes, bounded queries, strict claim
and evidence taxonomies, secret rejection, deterministic fixtures, and
fail-closed validation. It never turns a URL into verification, inference into
fact, or a recorded assertion into granted rights, consent, or approval.

See the [production review](docs/PRODUCTION_READINESS_REVIEW.md) and
[next-session worklist](docs/NEXT_SESSION.md).

## Quick install

```bash
git clone https://github.com/kujolang/dossier.git
cd dossier
export KUJO_BIN=/absolute/path/to/kujo
export PATH="$PWD/bin:$PATH"
dossier --version --json
dossier doctor --json
```

Dossier requires Kujo 1.0.1 or newer and has no required database, provider,
model, or network dependency.

## Quick start

```bash
dossier init --state .dossier --json
dossier claim add --input fixtures/core.json \
  --actor standards-editor --timestamp 2026-08-14T12:00:00Z --json
dossier report --limit 100 --json
dossier validate --json
```

## Commands

| Command group | Purpose |
| --- | --- |
| `claim add`, `claim show` | Create and inspect material claims. |
| `source add` | Record source identity, type, and retrieval time. |
| `evidence attach`, `evidence classify` | Bind exact captured support and an explicit evidence state. |
| `conflict add` | Preserve disagreement between multiple sources. |
| `quote add` | Record exact quotation text, speaker, source, and approval status. |
| `consent record`, `rights record` | Preserve scoped assertions without granting authority. |
| `freshness check`, `verify`, `validate` | Validate stored record and contract integrity. |
| `packet`, `report`, `export` | Create and emit bounded portable evidence collections. |
| `history`, `doctor`, `version` | Inspect operation, health, and compatibility. |

Common flags include `--state`, `--config`, `--input`, `--actor`, `--timestamp`,
`--id`, `--path`, `--type`, `--after`, `--limit`, `--output`, `--force`,
`--dry-run`, and `--json`. `--force` can replace only an explicitly named safe
export; it never bypasses evidence or authority checks. Exit codes are `0`
success, `1` operational/validation failure, and `2` usage error.

## Evidence model

Claims distinguish fact, observation, inference, opinion, and hypothesis.
Evidence distinguishes verified, observed, inferred, opinion, hypothesis,
planned, conflicted, expired, unavailable, and rejected states. A verified
evidence record requires exact source location, captured support, checksum,
retrieval time, and reviewer identity.

State defaults to `.dossier/`. JSON records are immutable, history is
append-only, exports are atomic, and all inputs and query sizes are bounded.
Traversal, symlinks, malformed JSON, incompatible schema majors, duplicate IDs,
secret-shaped fields, and unsafe overwrites fail closed. See
[contracts](docs/contracts.md) and [security](docs/security.md).

## Project structure and verification

The canonical entrypoint is `dossier.kujo`; all implementation modules live in
`src/`. Tests, fixtures, schemas, scripts, and documentation are separated by
purpose. Run the complete gate with:

```bash
bash scripts/validate.sh
```

CI builds the pinned Kujo runtime and runs the same gate. Hosted providers are
optional and are not required for core operation.
