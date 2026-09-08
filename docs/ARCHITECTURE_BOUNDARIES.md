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

## G→H interaction-boundary hardening

The G→H gate adds no new authority layer. It hardens the existing Phase G boundary against hostile input timing and stale presentation state:

- repeated setter-style UI intents are normalized inside `CampaignSession` before month resolution; exact duplicates are suppressed and same-target replacements supersede the prior pending intent;
- every new/replacement intent is still validated through `CommandRouter` on a clone of current authoritative state with other pending canonical commands preview-applied;
- presentation cannot use coalescing to bypass cross-promotion, stale-turn/date, availability or payload validation;
- `StrategicHome` owns only a deferred-frame advance lock, current surface/selection and transient historical-card lifecycle;
- `CampaignSession` owns only an in-progress re-entry guard around the existing `MonthPipeline`; it does not create a second turn resolver;
- invalid/stale market selection is rejected against the current Owner projection;
- Chronicle/history churn remains read-only and knowledge-scoped.

These protections are retained by `tests/integration/test_g2h_interaction_regressions.gd`, `tools/adversarial_runner/g2h_interaction_run.gd`, and the static repository gate.

## Phase H Android / lifecycle boundary

Android changes the host lifecycle and input surface, not the authority graph.

`Android/desktop host notification -> GameRoot -> CampaignSession checkpoint/resume seam -> SaveService / Chronicle`

`touch intent -> StrategicHome / StrategicMapView -> CampaignSession -> canonical CommandEnvelope / CommandRouter / MonthPipeline`

Phase H rules:

- `domain/` remains platform-agnostic: no Android package IDs, OS branches, display APIs, lifecycle callbacks or mobile-specific simulation state;
- `CampaignSession` remains platform-neutral and owns only application orchestration, pending canonical commands and checkpoint requests;
- `SaveService` remains the single save/recovery authority for desktop and Android; no mobile save schema or alternate Chronicle exists;
- lifecycle notifications may request/flush a checkpoint only after an authoritative state exists and may not run month simulation inside the callback;
- successful month resolution publishes state/Chronicle before checkpointing, so no half-resolved save can be created;
- exact int64/binary64 tagging exists only in physical JSON I/O and does not change logical CampaignState/Chronicle contracts;
- `backups/last_good` is a complete validated save snapshot, loaded through the same codecs as primary state;
- orientation, viewport layout, touch contacts, pan/zoom and system Back are presentation/host concerns with no domain meaning;
- the 720x720 design base is a presentation scaling choice for dual-orientation evidence, not a simulation constraint;
- the Android export preset is build configuration only and may not leak package/ABI/signing assumptions into domain/persistence identity.

The permanent G→H protections remain in force under touch input: setter coalescing, duplicate-month suppression, stale selection rejection, Chronicle transient-card ownership, cross-promotion authority rejection and knowledge-limited presentation.
