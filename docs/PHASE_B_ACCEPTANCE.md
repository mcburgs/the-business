# Phase B Acceptance Record

Date: 2026-09-06

## Governing objective

Phase B proves that campaigns, maps, and definitions are data loaded through generic registries and validators rather than engine special cases.

This record is subordinate to the Game Design Document v0.2, Technical Architecture and Vertical Slice Specification v0.2, Development and Build Plan v0.1, and Canonical Data Schemas and Domain Contracts v0.1.

## Phase B implementation boundary

Implemented in Phase B:

- generic content-pack discovery and deterministic dependency ordering;
- semantic-version dependency checks;
- JSON/schema-backed structural validation;
- stable authored content-ID checks and duplicate detection;
- graph/reference validation with canonical error codes;
- safe relative JSON-only pack file policy;
- immutable-by-copy ContentRegistry service;
- deterministic SHA-256 resolved-content fingerprint;
- generic map/region/market/connection loading;
- skeletal Great Lakes 1975 campaign data;
- valid variable-count and deliberately invalid campaign fixtures.

Explicitly not implemented here:

- mutable CampaignState or runtime entity stores;
- command/result mutation surface;
- RandomService or simulation formulas;
- save codecs/migrations beyond the content fingerprint output;
- knowledge projection implementation;
- Chronicle runtime stores/reconstruction;
- production historical names, full roster population, final portraits/assets, or deep historical accuracy.

Those belong to Phase C or later under the governing Build Plan.

## Missing machine-schema artifact decision

The original `we.phase0.schema.json` package referenced by Canonical Data Schemas and Domain Contracts v0.1 was not supplied and was not present in the repository. Phase B therefore introduces a controlled reconstruction limited to the static-content surface Phase B must execute. It is labeled as a reconstruction in machine metadata and documented in `content/schemas/DERIVATION.md`; it is not presented as the missing original artifact.

## Required gate

- [x] A valid campaign loads entirely from authored campaign/dependency data through the generic loader.
- [x] Deliberately invalid campaigns fail with specific actionable validation errors.
- [x] A fixture with different market/promotion/person counts loads through the same code without engine edits.
- [x] Path traversal, remote URI, executable/engine-resource references, and non-JSON pack inputs are rejected.
- [x] No Great Lakes/1975/promotion-name conditional exists in application or domain code.
- [x] Great Lakes skeleton content contains 12-15 markets, three promotions, people/staff shells, local-TV definitions, title/contract placeholders, and seeded-history hooks.
- [x] Content fingerprinting is deterministic for identical resolved content.
- [x] Existing Phase A architecture and repository gates remain green.
- [x] The canonical stock-Godot headless command passes under Godot 4.7.2-stable with no parser/harness failures.
- [x] Fresh editor import under the pinned engine completes with no parser/import errors attributable to retained source/content.

## Verified status

**PASS**

Runtime/editor verification was performed on 2026-09-06 using Godot `4.7.2.stable.official.ed1daf0bf`. The static repository/content gate passed with zero failures and zero warnings. The canonical headless runner discovered 10 tests; all 10 passed with zero failures and zero harness failures. The Great Lakes campaign loaded with 15 markets, the generic miniature fixture loaded with 2 markets, and the malformed-content fixture suite produced the expected diagnostic codes. A fresh editor import completed with no parser/import errors.

See `docs/PHASE_B_RUNTIME_RESULT.md` for the recorded runtime evidence and retained verification fixes.
