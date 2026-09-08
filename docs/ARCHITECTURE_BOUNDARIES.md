# Architecture Boundaries

The governing Technical Architecture defines inward dependencies:

```text
Presentation -> Application -> Simulation Domain
                         \-> Persistence / content-facing services as explicit boundaries
```

The domain is simulation truth. It must not require scene-tree presence, renderer state, screen size, audio, input devices, wall-clock calls, or direct global randomness.

## Repository layers

- `app/`: bootstrap, session lifecycle, command routing, UI-facing queries.
- `domain/`: pure simulation entities/systems/rules/invariants.
- `persistence/`: save/recovery/migration/codec infrastructure.
- `content/`: validated static definitions, campaigns, schemas, localization.
- `presentation/`: scenes, Controls, map/dashboard/panels, view-facing code.
- `assets/`: governed reproducible UI/portrait/audio/font assets and ledger.
- `tools/`: content/build/simulation tooling.
- `tests/`: stock-Godot unit, integration, golden, soak, and fixtures.

Phase A implements only the shell and enforcement scaffolding required to keep those boundaries real.


## Phase F-R ownership and creative seams

- `CampaignState.ownership_seat` is control authority, **not** a human entity. It may point at the controlled promotion but may not carry Person identity, portrait, body, age, biography, health, skills, traits, family or mortality state.
- `PromotionState.controlling_owner_person_id` remains valid in-world governance for NPC/historical people and is independent of the player seat.
- Player commands are scoped by the seat's promotion and cannot use a player `person_id`; AI/automation/system issuers may identify simulated people where the domain action genuinely belongs to them.
- Reality remains CampaignState/domain truth. Perception remains knowledge/projection state. Presentation intent is explicit context and cannot be used as a hidden-truth channel.
- WrestlingLanguage context may enter the existing ShowPlan/BookingSystem/ShowResolver path; future microbooking must use that same path rather than create a second resolution authority.
- Relationship/identity/Chronicle seams support future lineage without replacing Person IDs. `presentation/map/` remains a non-authoritative client for the future map-first home surface.

## F→G adversarial enforcement clarifications

- A validated command does not gain authority merely because its payload references a valid entity. Player/AI/automation issuers are promotion-scoped; resource-targeted handlers must verify that the target resource belongs to the issuer promotion. System authority is separate and explicit.
- Player-visible commands may choose among governed economic opportunities but may not author arbitrary authoritative economic terms. `command.sign_media_deal` is system-authority only until a real offer/proposal seam owns the terms.
- Staff appointments that consume Person skill require live employment/availability. Contract expiry/release must reconcile stale appointments and assignments rather than leave free capability in world state.
- Adversarial tests are clients of the same knowledge/query and command/month-pipeline boundaries as gameplay. Direct authoritative mutation is diagnostic/fault-injection evidence only and cannot establish a legal-player exploit.


## Phase G presentation boundary

The playable map is a client of the application layer, not a second simulation authority. The permitted Phase G dependency shape is:

`domain/Chronicle authoritative state -> application query/projection -> presentation`

`presentation intent -> CampaignSession -> CommandEnvelope -> CommandRouter/MonthPipeline -> authoritative state -> fresh query/projection -> presentation`

Rules enforced by the static gate:

- scripts under `presentation/` do not import `domain/`, `persistence/`, or `app/commands/`;
- presentation scripts do not reference `CommandRouter`, `CommandEnvelope`, `CampaignState`, raw `influence_by_promotion`, `true_value`, or player-person identity fields;
- `OwnerPresentationQuery` retains `KnowledgeQueryService`, `ChronicleQueryService` and Ownership Seat seams and cannot use debug truth;
- `CampaignSession` remains the application write boundary and routes commands/month advancement through existing canonical services;
- the default root contains the map-first `StrategicHome`;
- map interaction retains tap/drag/zoom support and required information is not hover-only.

Presentation may own ephemeral concerns such as selected market, active surface, map pan/zoom and layout mode. Those values have no simulation meaning and are discarded/rebuilt without changing CampaignState.
