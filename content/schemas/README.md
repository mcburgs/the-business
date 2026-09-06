# Canonical schema integration point

The governing Phase 0 contract identifies `schemas/we.phase0.schema.json` as the canonical JSON Schema Draft 2020-12 definition set, with wrapper schemas and semantic validation.

The original standalone machine-readable schema package was **not supplied** with the governing attachments and was **not present on remote `main` when Phase B began**. Phase B requires machine-readable campaign/map/content validation, so this directory now contains a **controlled reconstruction** of the minimum Phase B static-content subset derived from the governing prose contracts.

This reconstruction is not represented as the missing original artifact. See `DERIVATION.md` and the `x-we-derivation-status` metadata inside `we.phase0.schema.json`.

The reconstruction deliberately does not invent Phase C runtime CampaignState, command/result, RNG, save/migration, knowledge, or Chronicle schemas. If the original Phase 0 machine package is later recovered, compare it explicitly and treat any divergence as controlled architecture/migration work.
