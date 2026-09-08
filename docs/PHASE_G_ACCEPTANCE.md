# Phase G Strategic Map / Playable Presentation Acceptance

Phase: **G — Strategic Map / Playable Presentation**
Required starting commit: `2e18d88164b46c7bd5d217a2d8fa4818af0c3f6e`
Required starting tree: `1102cc79c3c630361081b52c40ee9fa9333e648b`
Pinned runtime: `4.7.2.stable.official.ed1daf0bf`
Status: **VERIFIED**

## Scope

Phase G turns the accepted Phase F-R/F→G simulation into the first coherent playable presentation vertical slice. It does not add Android packaging, a second simulation engine, a player-owner Person/avatar, a manual microbooking engine, or Phase I balance/polish depth.

The strategic map is the default gameplay surface. Markets remain audience/business environments with people, promotions, routes, media and history rather than owned territory tiles.

## Presentation architecture

Authoritative flow:

`CampaignState / Chronicle -> OwnerPresentationQuery -> KnowledgeQueryService / ChronicleQueryService -> StrategicHome / StrategicMapView`

Player intent flow:

`StrategicHome -> CampaignSession.queue_player_command -> CommandEnvelope -> CommandRouter -> pending canonical commands -> MonthPipeline -> authoritative post-turn state -> fresh OwnerPresentationQuery`

Presentation scripts do not import domain state, persistence codecs, CommandRouter or CommandEnvelope and do not mutate CampaignState. The `CampaignSession` application seam owns authoritative runtime references and is the only presentation-facing write boundary.

## Runtime bootstrap / derivation

The existing governed content pack contains campaign identities, geography, market coordinates, connections, people, promotions and starting records but not a fully serialized opening `CampaignState`. `CampaignRuntimeFactory` therefore materializes the Phase G vertical-slice opening state deterministically from those content records plus the retained generic Phase E/F slice tuning. The derivation is application/session code, contains no Great Lakes/1975 engine branch, and produces authoritative state before presentation reads it.

No new map-coordinate metadata was authored for Phase G. The map consumes the existing normalized `markets.json` coordinates and `map.json` connections. A deterministic presentation-only layout fallback remains available for content without coordinates; it does not alter simulation meaning.

## Implemented playable surfaces

- strategic map home with content-driven markets and connections;
- controlled-promotion identity/date/cash/prestige/momentum HUD;
- market drill-down with local interest, controlled influence, known/estimated rival activity, touring/media context and recent history;
- people/roster surface retaining stable Person identity;
- touring surface with routes, assignments, budget/fatigue/cohesion and knowledge-limited rival context;
- wrestling/program surface exposing booker, programs and championships without creating a second booking model;
- Chronicle/recent-history surface plus historical reconstruction;
- complete strategic month advance and post-turn refresh.

## Canonical UI actions

Phase G exposes a deliberately small set of already-supported commands:

- `command.book_market_focus`
- `command.set_route`
- `command.push_person`
- `command.adjust_budget`

Commands are validated through `CommandRouter`; invalid cross-promotion actions remain rejected. Month resolution uses the existing `MonthPipeline`.

## Knowledge and Ownership Seat boundaries

The controlled promotion is obtained from `OwnershipSeatState.promotion_id`. No player Person, portrait, biography, age, skill, trait, health, family or mortality state exists in the Phase G presentation.

Controlled facts may be shown exactly where the Owner is entitled to know them. Rival influence and comparable outside information are supplied through `KnowledgeQueryService` and remain estimated/uncertain where the knowledge projection is uncertain. The presentation adapter exposes no raw `influence_by_promotion` dictionary and no `true_value` escape hatch.

Historical inspection uses `ChronicleQueryService` reconstruction, then scopes the result back through the Owner presentation boundary. It does not run `MonthPipeline`, RNG or commands and does not mutate current state or Chronicle storage.

## Responsive / Phase H compatibility

The Phase G shell uses scalable containers, large primary interaction targets, tap selection, drag/pan and zoom abstractions. Required information is not hover-only. The reference desktop layout and a substantially narrower 720×900 layout are part of visual QA. Android export/package work is explicitly deferred to Phase H.

## Automated acceptance obligations

Final acceptance requires all of the following to pass. All items below are verified in `docs/PHASE_G_RUNTIME_RESULT.md`:

1. pinned engine version;
2. Phase G static architecture/content gate;
3. complete retained + Phase G automated suite;
4. explicit F2G-001/002/003 regression;
5. accepted Phase F 24-month competition regression;
6. accepted eight-run five-year soak with deterministic fingerprints unchanged except metadata;
7. save/load and Chronicle reconstruction regressions;
8. fresh editor/import;
9. Phase G presentation runtime;
10. visual QA at reference and narrow layouts;
11. `git diff --check` and staged `git diff --cached --check`;
12. exact staged tree and reproducible staged archive.

Final measured results are recorded in `docs/PHASE_G_RUNTIME_RESULT.md`.
