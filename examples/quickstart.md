# Quickstart

`./bin/dossier init --state /tmp/dossier-demo --json`

`./bin/dossier claim add --state /tmp/dossier-demo --input fixtures/core.json --actor operator --timestamp 2026-08-14T00:00:00Z --json`

The fixed timestamp makes fixture IDs deterministic; repeating the command is rejected.
