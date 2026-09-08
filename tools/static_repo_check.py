#!/usr/bin/env python3
"""Phase G repository/content/architecture checks that do not require Godot."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_DIRS = [
    "app/bootstrap", "app/content", "app/session", "app/commands", "app/queries",
    "domain/core", "domain/people", "domain/promotions", "domain/world",
    "domain/touring", "domain/booking", "domain/audience", "domain/economy",
    "domain/media", "domain/diplomacy", "domain/knowledge", "domain/events",
    "domain/chronicle", "domain/ai", "persistence/migrations", "persistence/codecs",
    "content/base", "content/campaigns/great_lakes_1975", "content/schemas",
    "content/localization", "presentation/shell", "presentation/map",
    "presentation/dashboard", "presentation/people", "presentation/touring",
    "presentation/markets", "presentation/finance", "presentation/inbox",
    "presentation/chronicle", "presentation/common", "assets/ui", "assets/portraits",
    "assets/audio", "assets/fonts", "tools/content_validator", "tools/campaign_builder",
    "tools/simulation_cli", "tools/adversarial_runner", "tests/unit", "tests/integration", "tests/golden",
    "tests/soak", "tests/adversarial", "tests/adversarial/evidence", "tests/adversarial/repro", "tests/fixtures/phase_b/valid/mini_campaign",
    "tests/fixtures/phase_b/invalid", "tests/helpers",
]

REQUIRED_FILES = [
    "project.godot", "README.md", "BUILD.md", "ENGINE_VERSION", "CHANGELOG.md",
    ".gitignore", ".gitattributes", ".editorconfig", "tests/runner.gd",
    "presentation/shell/game_root.tscn", "presentation/shell/game_root.gd",
    "app/bootstrap/project_version.gd", "app/bootstrap/diagnostic_log.gd",
    "app/content/content_loader.gd", "app/content/content_registry.gd",
    "app/content/content_validator.gd", "app/content/json_schema_validator.gd",
    "app/content/content_fingerprint.gd", "app/content/content_safety.gd",
    "app/content/version_constraint.gd", "content/schemas/we.phase0.schema.json",
    "content/schemas/DERIVATION.md", "content/base/manifest.json",
    "content/campaigns/great_lakes_1975/manifest.json", "docs/PHASE_B_ACCEPTANCE.md",
    "app/commands/command_envelope.gd", "app/commands/command_result.gd",
    "app/commands/command_router.gd", "app/session/random_service.gd",
    "app/queries/knowledge_query_service.gd", "app/queries/debug_truth_query.gd",
    "domain/core/campaign_state.gd", "domain/core/campaign_state_validator.gd",
    "domain/core/domain_ids.gd", "domain/core/entity_store.gd",
    "domain/core/ownership_seat_state.gd", "domain/core/random_state.gd",
    "domain/core/victory_state.gd", "domain/people/person_state.gd",
    "domain/people/contract_state.gd", "domain/people/relationship_state.gd",
    "domain/promotions/promotion_state.gd", "domain/world/market_state.gd",
    "domain/world/region_state.gd", "domain/world/venue_state.gd",
    "domain/touring/touring_company_state.gd", "domain/booking/championship_state.gd",
    "domain/booking/program_state.gd", "domain/media/media_deal_state.gd",
    "domain/diplomacy/agreement_state.gd", "domain/knowledge/knowledge_base.gd",
    "domain/knowledge/knowledge_projection.gd", "domain/events/event_state.gd",
    "domain/audience/drawing_power_query.gd",
    "persistence/codecs/campaign_state_codec.gd", "persistence/migrations/state_migrator.gd",
    "tests/helpers/phase_c_fixture.gd", "docs/PHASE_C_ACCEPTANCE.md",
    "tests/unit/test_phase_c_state_invariants.gd", "tests/unit/test_phase_c_commands.gd",
    "tests/unit/test_phase_c_random_service.gd", "tests/unit/test_phase_c_knowledge_projection.gd",
    "tests/unit/test_phase_c_entity_store.gd",
    "tests/integration/test_phase_c_state_roundtrip.gd",
    "app/session/turn_context.gd", "app/session/turn_result.gd", "app/session/month_pipeline.gd",
    "domain/events/domain_event.gd", "domain/economy/ledger_service.gd",
    "domain/chronicle/chronicle_store.gd", "domain/chronicle/chronicle_delta.gd",
    "domain/chronicle/historical_projection.gd", "domain/chronicle/chronicle_committer.gd",
    "domain/chronicle/chronicle_query_service.gd", "domain/chronicle/chronicle_validator.gd",
    "domain/chronicle/identity_catalog_service.gd", "persistence/codecs/chronicle_codec.gd",
    "persistence/services/save_service.gd", "tools/simulation_cli/run.gd",
    "tests/helpers/phase_d_fixture.gd", "tests/unit/test_phase_d_pipeline.gd",
    "tests/unit/test_phase_d_ledger.gd", "tests/integration/test_phase_d_chronicle_reconstruction.gd",
    "tests/integration/test_phase_d_save_service.gd",
    "docs/PHASE_D_ACCEPTANCE.md", "docs/PHASE_D_RUNTIME_RESULT.md",
    "domain/core/phase_e_math.gd", "domain/touring/logistics_system.gd",
    "domain/booking/show_plan.gd", "domain/booking/booking_system.gd",
    "domain/booking/show_result.gd", "domain/booking/show_resolver.gd",
    "domain/audience/audience_creative_system.gd", "domain/audience/hot_state_system.gd",
    "domain/world/influence_query.gd", "domain/media/media_market_system.gd",
    "domain/economy/economy_system.gd", "tests/helpers/phase_e_fixture.gd",
    "tests/integration/test_phase_e_strategic_loop.gd", "tests/integration/test_phase_e_chronicle_save.gd",
    "tests/unit/test_phase_e_commands_logistics.gd", "tests/unit/test_phase_e_booking_audience.gd",
    "tests/unit/test_phase_e_economy_media_hot.gd", "docs/PHASE_E_ACCEPTANCE.md",
    "docs/PHASE_E_RUNTIME_RESULT.md",
    "domain/ai/ai_planning_view.gd", "domain/ai/ai_planning_service.gd",
    "domain/ai/owner_strategy.gd", "domain/ai/talent_manager.gd",
    "domain/ai/touring_planner.gd", "domain/ai/booker_ai.gd",
    "domain/ai/recovery_ai.gd", "domain/ai/diplomacy_ai.gd",
    "domain/people/contract_system.gd", "domain/knowledge/scouting_system.gd",
    "domain/diplomacy/diplomacy_system.gd", "tests/helpers/phase_f_fixture.gd",
    "tests/unit/test_phase_f_ai_boundary.gd", "tests/unit/test_phase_f_contracts.gd",
    "tests/unit/test_phase_f_knowledge_ai.gd", "tests/unit/test_phase_f_recovery_diplomacy.gd",
    "tests/integration/test_phase_f_competition.gd", "tests/integration/test_phase_f_chronicle_save.gd",
    "tools/simulation_cli/phase_f_soak.gd", "docs/PHASE_F_ACCEPTANCE.md",
    "docs/PHASE_F_RUNTIME_RESULT.md", "tests/soak/PHASE_F_SOAK_REPORT.md",
    "tests/soak/phase_f_5_year_soak.json",
    "docs/PHASE_F_R_ACCEPTANCE.md", "docs/PHASE_F_R_RUNTIME_RESULT.md",
    "docs/PHASE_F_R_OWNERSHIP_AUDIT.md", "docs/PHASE_F_R_ARCHITECTURE_SEAM_AUDIT.md",
    "tests/integration/test_phase_f_r_reconciliation.gd",
    "tests/soak/PHASE_F_R_SOAK_REPORT.md", "tests/soak/phase_f_r_5_year_soak.json",
    "docs/governing/The_Business_Creative_Direction_and_Experience_Bible_v0_1.docx",
    "docs/governing/The_Business_Creative_to_Systems_Impact_Matrix_v0_1.docx",
    "tools/adversarial_runner/run.gd", "tests/integration/test_f2g_adversarial_regressions.gd",
    "docs/F2G_ACCEPTANCE.md", "docs/F2G_RUNTIME_RESULT.md", "docs/F2G_FINDINGS.md",
    "tests/adversarial/evidence/F2G-STRAT-001/PACKAGE_MANIFEST.json",
    "tests/adversarial/evidence/F2G-STRAT-001/aggregate_summary.json",
    "tests/adversarial/evidence/F2G-STRAT-001/SUMMARY.md",
    "tests/adversarial/evidence/F2G-STRAT-001/RUN_COMMANDS.md",
    "tests/adversarial/repro/F2G-001/manifest.json", "tests/adversarial/repro/F2G-001/reproduce_pre_fix.gd",
    "tests/adversarial/repro/F2G-002/manifest.json", "tests/adversarial/repro/F2G-002/reproduce_pre_fix.gd",
    "tests/adversarial/repro/F2G-003/manifest.json", "tests/adversarial/repro/F2G-003/reproduce_pre_fix.gd",
    "app/session/slice_tuning.gd", "app/session/campaign_runtime_factory.gd",
    "app/session/campaign_session.gd", "app/queries/owner_presentation_query.gd",
    "presentation/common/ui_theme_factory.gd", "presentation/map/strategic_map_view.gd",
    "presentation/shell/strategic_home.gd", "presentation/shell/strategic_home.tscn",
    "tests/unit/test_phase_g_owner_projection.gd",
    "tests/integration/test_phase_g_runtime_bootstrap.gd",
    "tests/integration/test_phase_g_command_and_month_flow.gd",
    "tests/integration/test_phase_g_presentation_scene_and_history.gd",
    "docs/PHASE_G_ACCEPTANCE.md", "docs/PHASE_G_RUNTIME_RESULT.md",
]

FORBIDDEN_DOMAIN_TOKENS = [
    "extends Node", "extends Control", "get_tree(", "SceneTree", "RenderingServer",
    "DisplayServer", "AudioServer", "Input.", "randf(", "randi(", "Time.", "OS.",
]

FORBIDDEN_SCENARIO_TOKENS = [
    "great_lakes", "great lakes", "1975", "promotion alpha", "promotion beta", "promotion gamma",
]

GENERATED_ROOT_NAMES = {".godot", ".import", "build", "builds", "dist", ".gradle"}
CONTENT_ID = re.compile(r"^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+$")
EXECUTABLE_EXTENSIONS = {
    ".gd", ".gdc", ".cs", ".csx", ".js", ".mjs", ".py", ".pyc", ".exe",
    ".dll", ".so", ".dylib", ".sh", ".bat", ".cmd", ".ps1", ".tscn", ".scn",
    ".tres", ".res",
}
INVALID_CASES = {
    "duplicate_ids": "ID002",
    "missing_reference": "REF001",
    "illegal_range": "STATE001",
    "dependency_failure": "REF001",
    "path_traversal": "MOD001",
    "remote_reference": "MOD001",
    "executable_reference": "MOD002",
    "invalid_narrative_context": "NAR001",
    "unknown_field": "STATE001",
}


def load_json(path: Path, failures: list[str]) -> object | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        failures.append(f"invalid/unreadable JSON: {path.relative_to(ROOT)}: {exc}")
        return None


def safe_pack_path(value: str) -> tuple[bool, str]:
    lower = value.lower()
    if not value or value.startswith(("/", "\\")) or re.match(r"^[A-Za-z]:", value):
        return False, "MOD001"
    if "://" in lower or lower.startswith(("data:", "file:", "res:", "user:")):
        return False, "MOD001"
    if "\\" in value:
        return False, "MOD001"
    parts = PurePosixPath(value).parts
    if any(part in {".", ".."} for part in parts):
        return False, "MOD001"
    if Path(lower).suffix in EXECUTABLE_EXTENSIONS:
        return False, "MOD002"
    if not lower.endswith(".json"):
        return False, "MOD001"
    return True, ""


def collect_valid_pack(pack_dir: Path, failures: list[str]) -> tuple[dict, dict[str, list[dict]]]:
    manifest_obj = load_json(pack_dir / "manifest.json", failures)
    if not isinstance(manifest_obj, dict):
        return {}, {}
    files = manifest_obj.get("files")
    if not isinstance(files, dict):
        failures.append(f"manifest files field must be an object: {(pack_dir/'manifest.json').relative_to(ROOT)}")
        return manifest_obj, {}
    records: dict[str, list[dict]] = {}
    for family, rel in sorted(files.items()):
        if not isinstance(rel, str):
            failures.append(f"manifest file reference must be string: {pack_dir.relative_to(ROOT)} files.{family}")
            continue
        safe, code = safe_pack_path(rel)
        if not safe:
            failures.append(f"valid pack contains unsafe path ({code}): {pack_dir.relative_to(ROOT)} files.{family}={rel!r}")
            continue
        obj = load_json(pack_dir / rel, failures)
        if family == "map":
            if isinstance(obj, dict):
                records[family] = [obj]
            else:
                failures.append(f"map family must be a JSON object: {(pack_dir/rel).relative_to(ROOT)}")
        elif isinstance(obj, list) and all(isinstance(item, dict) for item in obj):
            records[family] = obj
        else:
            failures.append(f"content family must be an array of objects: {(pack_dir/rel).relative_to(ROOT)}")
    return manifest_obj, records


def validate_valid_content(failures: list[str]) -> None:
    base_manifest, base = collect_valid_pack(ROOT / "content/base", failures)
    campaign_manifest, campaign = collect_valid_pack(ROOT / "content/campaigns/great_lakes_1975", failures)
    mini_manifest, mini = collect_valid_pack(ROOT / "tests/fixtures/phase_b/valid/mini_campaign", failures)
    if not base_manifest or not campaign_manifest or not mini_manifest:
        return

    all_records: dict[str, list[dict]] = {}
    for source in (base, campaign):
        for family, records in source.items():
            all_records.setdefault(family, []).extend(records)

    id_family: dict[str, str] = {}
    for family, records in sorted(all_records.items()):
        for index, record in enumerate(records):
            cid = record.get("id")
            if not isinstance(cid, str) or not CONTENT_ID.fullmatch(cid):
                failures.append(f"malformed content ID in {family}[{index}]: {cid!r}")
                continue
            if cid in id_family:
                failures.append(f"duplicate content ID {cid!r}: {id_family[cid]} and {family}")
            else:
                id_family[cid] = family

    def require_ref(target: object, family: str, where: str) -> None:
        if not isinstance(target, str) or target not in id_family:
            failures.append(f"missing required reference at {where}: {target!r}")
        elif id_family[target] != family:
            failures.append(f"wrong reference family at {where}: {target!r} is {id_family[target]}, expected {family}")

    require_ref(campaign_manifest.get("map_id"), "map", "campaign manifest.map_id")
    require_ref(campaign_manifest.get("ruleset_id"), "rulesets", "campaign manifest.ruleset_id")
    for r in all_records.get("media_tech", []):
        require_ref(r.get("medium_id"), "media_mediums", f"{r.get('id')}.medium_id")
    for r in all_records.get("map", []):
        for x in r.get("region_ids", []): require_ref(x, "regions", f"{r.get('id')}.region_ids")
        for x in r.get("market_ids", []): require_ref(x, "markets", f"{r.get('id')}.market_ids")
        for edge in r.get("connections", []):
            if isinstance(edge, dict):
                require_ref(edge.get("from_market_id"), "markets", f"{r.get('id')}.connections.from_market_id")
                require_ref(edge.get("to_market_id"), "markets", f"{r.get('id')}.connections.to_market_id")
                for field in ("base_distance_km", "base_time_minutes", "base_cost_index"):
                    value = edge.get(field)
                    if not isinstance(value, (int, float)) or isinstance(value, bool) or value < 0:
                        failures.append(f"illegal travel range at {r.get('id')}.{field}: {value!r}")
    for r in all_records.get("regions", []):
        for x in r.get("market_ids", []): require_ref(x, "markets", f"{r.get('id')}.market_ids")
    for r in all_records.get("markets", []):
        require_ref(r.get("region_id"), "regions", f"{r.get('id')}.region_id")
        for x in r.get("venue_ids", []): require_ref(x, "venues", f"{r.get('id')}.venue_ids")
    for r in all_records.get("venues", []): require_ref(r.get("market_id"), "markets", f"{r.get('id')}.market_id")
    for r in all_records.get("people", []):
        for x in r.get("role_ids", []): require_ref(x, "roles", f"{r.get('id')}.role_ids")
        require_ref(r.get("home_market_id"), "markets", f"{r.get('id')}.home_market_id")
    for r in all_records.get("promotions", []):
        require_ref(r.get("owner_person_seed_id"), "people", f"{r.get('id')}.owner")
        require_ref(r.get("booker_person_seed_id"), "people", f"{r.get('id')}.booker")
        for x in r.get("home_market_ids", []): require_ref(x, "markets", f"{r.get('id')}.home_market_ids")
        if r.get("strategy_profile_id") is not None:
            require_ref(r.get("strategy_profile_id"), "promotion_strategies", f"{r.get('id')}.strategy_profile_id")
    for r in all_records.get("media_outlets", []):
        require_ref(r.get("medium_id"), "media_mediums", f"{r.get('id')}.medium_id")
        require_ref(r.get("tech_id"), "media_tech", f"{r.get('id')}.tech_id")
        for x in r.get("market_ids", []): require_ref(x, "markets", f"{r.get('id')}.market_ids")
    for r in all_records.get("championships", []):
        require_ref(r.get("promotion_seed_id"), "promotions", f"{r.get('id')}.promotion_seed_id")
        for x in r.get("holder_person_seed_ids", []): require_ref(x, "people", f"{r.get('id')}.holder_person_seed_ids")
        for x in r.get("recognition_market_ids", []): require_ref(x, "markets", f"{r.get('id')}.recognition_market_ids")
    for r in all_records.get("contracts", []):
        require_ref(r.get("person_seed_id"), "people", f"{r.get('id')}.person_seed_id")
        require_ref(r.get("promotion_seed_id"), "promotions", f"{r.get('id')}.promotion_seed_id")
    for r in all_records.get("history_hooks", []):
        if r.get("narrative_context") not in {"public_kayfabe", "backstage_business", "system_neutral"}:
            failures.append(f"invalid NarrativeContext: {r.get('id')}: {r.get('narrative_context')!r}")
        for x in r.get("subject_ids", []):
            if x not in id_family: failures.append(f"missing history subject reference: {r.get('id')}: {x!r}")
        if r.get("market_id") is not None: require_ref(r.get("market_id"), "markets", f"{r.get('id')}.market_id")

    counts = {family: len(records) for family, records in campaign.items()}
    if not 12 <= counts.get("markets", 0) <= 15:
        failures.append(f"Great Lakes Phase B skeleton must contain 12-15 markets, found {counts.get('markets', 0)}")
    if counts.get("promotions", 0) != 3:
        failures.append(f"Great Lakes Phase B skeleton must author three promotions, found {counts.get('promotions', 0)}")
    for family in ("people", "media_outlets", "championships", "contracts", "history_hooks"):
        if counts.get(family, 0) < 1:
            failures.append(f"Great Lakes Phase B skeleton missing required family content: {family}")

    mini_counts = {family: len(records) for family, records in mini.items()}
    if (mini_counts.get("markets"), mini_counts.get("promotions"), mini_counts.get("people")) != (2, 1, 3):
        failures.append(f"variable-count fixture changed unexpectedly: {mini_counts}")


def check() -> dict:
    failures: list[str] = []
    warnings: list[str] = []

    for rel in REQUIRED_DIRS:
        if not (ROOT / rel).is_dir():
            failures.append(f"missing directory: {rel}")
    for rel in REQUIRED_FILES:
        if not (ROOT / rel).is_file():
            failures.append(f"missing file: {rel}")

    try:
        engine_pin = (ROOT / "ENGINE_VERSION").read_text(encoding="utf-8").strip()
        if engine_pin != "4.7.2-stable":
            failures.append(f"ENGINE_VERSION is {engine_pin!r}, expected '4.7.2-stable'")
    except OSError as exc:
        failures.append(f"unable to read ENGINE_VERSION: {exc}")

    try:
        project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
        if 'run/main_scene="res://presentation/shell/game_root.tscn"' not in project_text:
            failures.append("project.godot does not point to the retained launch shell")
    except OSError as exc:
        failures.append(f"unable to read project.godot: {exc}")

    try:
        ignore_text = (ROOT / ".gitignore").read_text(encoding="utf-8")
        for required in (".godot/", "builds/", "export_credentials.cfg"):
            if required not in ignore_text:
                failures.append(f".gitignore missing required pattern: {required}")
    except OSError as exc:
        failures.append(f"unable to read .gitignore: {exc}")

    for script in sorted((ROOT / "domain").rglob("*.gd")):
        text = script.read_text(encoding="utf-8")
        for token in FORBIDDEN_DOMAIN_TOKENS:
            if token in text:
                failures.append(f"domain boundary violation token {token!r}: {script.relative_to(ROOT)}")

    for code_root in (ROOT / "app", ROOT / "domain", ROOT / "persistence"):
        for script in sorted(code_root.rglob("*.gd")):
            lowered = script.read_text(encoding="utf-8").lower()
            for token in FORBIDDEN_SCENARIO_TOKENS:
                if token in lowered:
                    failures.append(f"Phase B scenario special-case token {token!r}: {script.relative_to(ROOT)}")

    for json_path in sorted((ROOT / "content").rglob("*.json")):
        load_json(json_path, failures)
    for json_path in sorted((ROOT / "tests/fixtures/phase_b").rglob("*.json")):
        load_json(json_path, failures)

    schema_obj = load_json(ROOT / "content/schemas/we.phase0.schema.json", failures)
    if isinstance(schema_obj, dict):
        if schema_obj.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
            failures.append("we.phase0.schema.json must declare JSON Schema Draft 2020-12")
        if schema_obj.get("x-we-derivation-status") != "controlled_reconstruction":
            failures.append("reconstructed Phase B schema must disclose controlled_reconstruction status")
        if schema_obj.get("x-we-original-artifact-status") != "not_supplied":
            failures.append("reconstructed Phase B schema must disclose that the original artifact was not supplied")
        if "maxItems" in json.dumps(schema_obj):
            failures.append("reconstructed static-content schema must not encode slice entity-count ceilings via maxItems")

    validate_valid_content(failures)

    # Phase G current metadata plus retained Phase F/F-R/F->G static gates.
    try:
        version_text = (ROOT / "app/bootstrap/project_version.gd").read_text(encoding="utf-8")
        if 'const BUILD_PHASE: String = "G"' not in version_text:
            failures.append("Phase G metadata must report build phase G")
        if 'const GAME_VERSION: String = "0.0.0-phase-g"' not in version_text:
            failures.append("Phase G game version must be 0.0.0-phase-g")
        if 'const ARCHITECTURE_VERSION: String = "0.3.0"' not in version_text:
            failures.append("Phase G architecture version must remain 0.3.0")
        if 'const CONTRACT_VERSION: String = "0.2.0"' not in version_text:
            failures.append("Phase G contract version must remain 0.2.0")
        project_text = (ROOT / "project.godot").read_text(encoding="utf-8")
        if 'config/version="0.0.0-phase-g"' not in project_text:
            failures.append("project.godot must report Phase G game version")
    except OSError as exc:
        failures.append(f"unable to inspect Phase G version metadata: {exc}")

    expected_commands = {
        "command.hire_staff", "command.assign_role", "command.fire_person", "command.set_booker", "command.adjust_budget",
        "command.create_touring_company", "command.assign_person", "command.set_route", "command.set_directive", "command.split_company", "command.merge_company",
        "command.start_program", "command.end_program", "command.set_champion", "command.approve_major_outcome", "command.push_person", "command.protect_person",
        "command.offer_contract", "command.counter_offer", "command.renew_contract", "command.release_person",
        "command.book_market_focus", "command.set_local_media_spend", "command.sign_media_deal",
        "command.propose_agreement", "command.violate_territory", "command.accept_talent_share",
        "command.advance_month", "command.save_campaign",
    }
    try:
        router_text = (ROOT / "app/commands/command_router.gd").read_text(encoding="utf-8")
        observed_commands = set(re.findall(r'"(command\.[a-z_]+)"', router_text))
        missing = sorted(expected_commands - observed_commands)
        unexpected = sorted(observed_commands - expected_commands)
        if missing:
            failures.append(f"Phase C command catalog missing canonical commands: {missing}")
        if unexpected:
            failures.append(f"Phase C command catalog contains unexpected commands: {unexpected}")
    except OSError as exc:
        failures.append(f"unable to inspect Phase C command catalog: {exc}")

    random_service_path = ROOT / "app/session/random_service.gd"
    for code_root in (ROOT / "app", ROOT / "domain", ROOT / "persistence"):
        for script in sorted(code_root.rglob("*.gd")):
            if script == random_service_path:
                continue
            text = script.read_text(encoding="utf-8")
            for token in ("RandomNumberGenerator", "randf(", "randi(", "randi_range(", "randf_range("):
                if token in text:
                    failures.append(f"randomness boundary violation token {token!r}: {script.relative_to(ROOT)}")

    try:
        projection_text = (ROOT / "domain/knowledge/knowledge_projection.gd").read_text(encoding="utf-8")
        if "true_value" in projection_text:
            failures.append("KnowledgeProjection must not expose a true_value escape hatch")
    except OSError as exc:
        failures.append(f"unable to inspect knowledge projection: {exc}")

    try:
        for rel in ("domain/core/campaign_state.gd", "persistence/codecs/campaign_state_codec.gd"):
            state_text = (ROOT / rel).read_text(encoding="utf-8").lower()
            if "drawing_power" in state_text:
                failures.append(f"derived drawing power must not be persisted in authoritative state: {rel}")
    except OSError as exc:
        failures.append(f"unable to inspect derived-state boundary: {exc}")

    try:
        derivation_text = (ROOT / "content/schemas/DERIVATION.md").read_text(encoding="utf-8").lower()
        if "phase c runtime-contract reconstruction addendum" not in derivation_text or "controlled reconstruction" not in derivation_text:
            failures.append("Phase C controlled runtime-schema reconstruction must remain explicitly documented")
    except OSError as exc:
        failures.append(f"unable to inspect Phase C derivation record: {exc}")

    try:
        pipeline_text = (ROOT / "app/session/month_pipeline.gd").read_text(encoding="utf-8")
        phase_names_match = re.search(r"const PHASE_NAMES: Array\[String\] = \[(.*?)\]", pipeline_text, re.S)
        if not phase_names_match or len(re.findall(r'"[a-z_]+"', phase_names_match.group(1))) != 15:
            failures.append("Phase D month pipeline must expose exactly 15 named phase boundaries")
        if "ChronicleCommitter" not in pipeline_text or "_chronicle_commit" not in pipeline_text or "_postflight" not in pipeline_text:
            failures.append("Phase D pipeline must retain explicit Chronicle commit and postflight boundaries")
    except OSError as exc:
        failures.append(f"unable to inspect Phase D month pipeline: {exc}")

    try:
        query_text = (ROOT / "domain/chronicle/chronicle_query_service.gd").read_text(encoding="utf-8")
        for forbidden in ("month_pipeline", "RandomService", "random_service.gd", "CommandRouter"):
            if forbidden in query_text:
                failures.append(f"historical reconstruction must not depend on simulation/RNG mutation boundary: {forbidden}")
    except OSError as exc:
        failures.append(f"unable to inspect Chronicle query boundary: {exc}")

    try:
        derivation_text = (ROOT / "content/schemas/DERIVATION.md").read_text(encoding="utf-8").lower()
        if "phase d chronicle/save/ledger reconstruction addendum" not in derivation_text or "controlled reconstruction" not in derivation_text:
            failures.append("Phase D controlled Chronicle/save/ledger reconstruction must remain explicitly documented")
    except OSError as exc:
        failures.append(f"unable to inspect Phase D derivation record: {exc}")

    # Phase E architecture-sensitive static gates.
    try:
        pipeline_text = (ROOT / "app/session/month_pipeline.gd").read_text(encoding="utf-8")
        for seam in ("LogisticsSystem", "BookingSystem", "ShowResolver", "AudienceCreativeSystem", "MediaMarketSystem", "EconomySystem"):
            if seam not in pipeline_text:
                failures.append(f"Phase E pipeline is missing strategic-loop seam: {seam}")
    except OSError as exc:
        failures.append(f"unable to inspect Phase E pipeline integration: {exc}")

    try:
        resolver_text = (ROOT / "domain/booking/show_resolver.gd").read_text(encoding="utf-8")
        for forbidden in ("AudienceCreativeSystem", "MediaMarketSystem", "EconomySystem", "ChronicleCommitter", "LedgerService"):
            if forbidden in resolver_text:
                failures.append(f"ShowResolver must return effects rather than mutate downstream systems directly: {forbidden}")
    except OSError as exc:
        failures.append(f"unable to inspect Phase E ShowResolver boundary: {exc}")

    try:
        market_text = (ROOT / "domain/world/market_state.gd").read_text(encoding="utf-8").lower()
        for forbidden in ("owner_promotion_id", "owning_promotion_id", "market_owner"):
            if forbidden in market_text:
                failures.append(f"market influence must not become ownership state: {forbidden}")
    except OSError as exc:
        failures.append(f"unable to inspect Phase E market ownership boundary: {exc}")

    try:
        cli_text = (ROOT / "tools/simulation_cli/run.gd").read_text(encoding="utf-8")
        for fixture in ("phase_e_good", "phase_e_bad"):
            if fixture not in cli_text:
                failures.append(f"Phase E CLI must expose acceptance fixture: {fixture}")
        if "WE_SIM_SUMMARY" not in cli_text or "we.simulation_summary.v1" not in cli_text:
            failures.append("Phase E CLI must expose generic structured simulation diagnostics")
    except OSError as exc:
        failures.append(f"unable to inspect Phase E CLI: {exc}")

    try:
        derivation_text = (ROOT / "content/schemas/DERIVATION.md").read_text(encoding="utf-8").lower()
        if "phase e strategic-loop reconstruction addendum" not in derivation_text or "controlled reconstruction" not in derivation_text:
            failures.append("Phase E controlled strategic-loop schema reconstruction must be explicitly documented")
    except OSError as exc:
        failures.append(f"unable to inspect Phase E derivation record: {exc}")

    # Phase F architecture-sensitive static gates.
    try:
        pipeline_text = (ROOT / "app/session/month_pipeline.gd").read_text(encoding="utf-8")
        for seam in ("AIPlanningService", "ContractSystem", "DiplomacySystem", "ScoutingSystem"):
            if seam not in pipeline_text:
                failures.append(f"Phase F pipeline is missing competitive-world seam: {seam}")
        if "ai_planner_mutated_frozen_snapshot" not in pipeline_text:
            failures.append("Phase F pipeline must enforce frozen planning-snapshot immutability")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F pipeline integration: {exc}")

    try:
        service_text = (ROOT / "domain/ai/ai_planning_service.gd").read_text(encoding="utf-8")
        for module in ("OwnerStrategy", "TalentManager", "TouringPlanner", "BookerAI", "RecoveryAI", "DiplomacyAI"):
            if module not in service_text:
                failures.append(f"Phase F AI service is missing separated module: {module}")
        if "CommandEnvelope" not in service_text:
            failures.append("Phase F AI decisions must enter the canonical CommandEnvelope path")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F AI separation: {exc}")

    try:
        planner_view = (ROOT / "domain/ai/ai_planning_view.gd").read_text(encoding="utf-8")
        if "KnowledgeQueryService" not in planner_view or '"external_talent"' not in planner_view:
            failures.append("Phase F external-talent planning must use knowledge projections")
        for rel in ("owner_strategy.gd", "talent_manager.gd", "touring_planner.gd", "booker_ai.gd", "recovery_ai.gd", "diplomacy_ai.gd"):
            planner = (ROOT / "domain/ai" / rel).read_text(encoding="utf-8")
            if 'state.get("people")' in planner or 'state.get("contracts")' in planner or "ShowPlan" in planner or "ShowResult" in planner:
                failures.append(f"Phase F planner bypasses knowledge/card boundary: domain/ai/{rel}")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F knowledge/card boundary: {exc}")

    try:
        soak_text = (ROOT / "tools/simulation_cli/phase_f_soak.gd").read_text(encoding="utf-8")
        if "WE_PHASE_F_SOAK_SUMMARY" not in soak_text or "we.phase_f.soak.v1" not in soak_text:
            failures.append("Phase F soak CLI must expose machine-readable diagnostics")
        soak_data = load_json(ROOT / "tests/soak/phase_f_5_year_soak.json", failures)
        if not isinstance(soak_data, dict) or not soak_data.get("passed") or soak_data.get("phase") != "F" or soak_data.get("game_version") != "0.0.0-phase-f" or soak_data.get("years_per_run", 0) < 5:
            failures.append("Phase F must retain a passing multi-year soak artifact")
        elif (
            not soak_data.get("repeated_seed_deterministic")
            or soak_data.get("distinct_world_fingerprints") != soak_data.get("unique_seed_count")
            or soak_data.get("active_promotion_endings") != soak_data.get("run_count", 0) * 3
            or soak_data.get("maximum_market_concentration", 1.0) >= 0.95
            or len(soak_data.get("policy_wins", {})) < 2
        ):
            failures.append("Phase F soak artifact does not prove replay, divergence, survival, bounded concentration and policy variance")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F soak evidence: {exc}")

    try:
        derivation_text = (ROOT / "content/schemas/DERIVATION.md").read_text(encoding="utf-8").lower()
        if "phase f competitive-world reconstruction addendum" not in derivation_text or "controlled reconstruction" not in derivation_text:
            failures.append("Phase F controlled competitive-world reconstruction must be explicitly documented")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F derivation record: {exc}")


    # Phase F-R reconciliation-sensitive static gates.
    try:
        seat_text = (ROOT / "domain/core/ownership_seat_state.gd").read_text(encoding="utf-8").lower()
        for forbidden in ("owner_person_id", "person_id", "portrait", "biograph", "health", "skill", "trait", "mortality"):
            if forbidden in seat_text:
                failures.append(f"Phase F-R OwnershipSeatState must remain non-person; forbidden token: {forbidden}")
        if 'var promotion_id: string' not in seat_text:
            failures.append("Phase F-R OwnershipSeatState must retain promotion control identity")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F-R OwnershipSeatState: {exc}")

    try:
        codec_text = (ROOT / "persistence/codecs/campaign_state_codec.gd").read_text(encoding="utf-8")
        migrator_text = (ROOT / "persistence/migrations/state_migrator.gd").read_text(encoding="utf-8")
        state_text = (ROOT / "domain/core/campaign_state.gd").read_text(encoding="utf-8")
        if 'const STATE_SCHEMA_VERSION: int = 2' not in state_text or 'const CURRENT_STATE_SCHEMA_VERSION: int = 2' not in migrator_text:
            failures.append("Phase F-R current CampaignState/migration schema must be v2")
        ownership_match = re.search(r'const OWNERSHIP_FIELDS: Array\[String\] = \[(.*?)\]', codec_text, re.S)
        if not ownership_match or "owner_person_id" in ownership_match.group(1) or '"promotion_id"' not in ownership_match.group(1):
            failures.append("Phase F-R current ownership codec must contain promotion_id and no owner_person_id")
        if "_migrate_v1_to_v2" not in migrator_text or 'seat.erase("owner_person_id")' not in migrator_text or "promotion_owner_semantics" not in migrator_text:
            failures.append("Phase F-R must retain explicit v1 -> v2 player-seat migration provenance")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F-R state migration: {exc}")

    try:
        router_text = (ROOT / "app/commands/command_router.gd").read_text(encoding="utf-8")
        for token in ("player_is_non_person_ownership_seat", "player_ownership_seat_scope_mismatch", "player_ownership_seat_requires_promotion_scope"):
            if token not in router_text:
                failures.append(f"Phase F-R player command boundary missing guard: {token}")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F-R player issuer boundary: {exc}")

    try:
        projection_text = (ROOT / "domain/chronicle/historical_projection.gd").read_text(encoding="utf-8")
        if '"ownership_seat"' not in projection_text or "controlling_owner_person_id" not in projection_text:
            failures.append("Phase F-R HistoricalProjection must separate non-person seat from legitimate promotion owner Persons")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F-R Chronicle ownership projection: {exc}")

    try:
        plan_text = (ROOT / "domain/booking/show_plan.gd").read_text(encoding="utf-8")
        booking_text = (ROOT / "domain/booking/booking_system.gd").read_text(encoding="utf-8")
        resolver_text = (ROOT / "domain/booking/show_resolver.gd").read_text(encoding="utf-8")
        for seam in ("presentation_context", "wrestling_language_context"):
            if seam not in plan_text or seam not in booking_text or seam not in resolver_text:
                failures.append(f"Phase F-R ShowPlan context seam missing from booking/resolution path: {seam}")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F-R booking context seams: {exc}")

    try:
        derivation_text = (ROOT / "content/schemas/DERIVATION.md").read_text(encoding="utf-8").lower()
        if "phase f-r ownership-seat reconciliation addendum" not in derivation_text or "controlled reconciliation" not in derivation_text:
            failures.append("Phase F-R ownership/schema reconciliation provenance must be explicitly documented")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F-R derivation record: {exc}")

    try:
        fr_soak = load_json(ROOT / "tests/soak/phase_f_r_5_year_soak.json", failures)
        if not isinstance(fr_soak, dict) or not fr_soak.get("passed") or fr_soak.get("phase") != "F-R" or fr_soak.get("game_version") != "0.0.0-phase-f-r" or fr_soak.get("years_per_run", 0) < 5:
            failures.append("Phase F-R must retain a passing five-year soak artifact")
        elif (
            not fr_soak.get("repeated_seed_deterministic")
            or fr_soak.get("distinct_world_fingerprints") != fr_soak.get("unique_seed_count")
            or fr_soak.get("active_promotion_endings") != fr_soak.get("run_count", 0) * 3
            or fr_soak.get("maximum_market_concentration", 1.0) >= 0.95
            or len(fr_soak.get("policy_wins", {})) < 2
        ):
            failures.append("Phase F-R soak artifact does not prove replay, divergence, survival, bounded concentration and policy variance")
    except OSError as exc:
        failures.append(f"unable to inspect Phase F-R soak evidence: {exc}")

    # F->G adversarial strategic gate retention and scar-tissue checks.
    try:
        runner_text = (ROOT / "tools/adversarial_runner/run.gd").read_text(encoding="utf-8")
        for token in ("AIPlanningView", "MonthPipeline", "CommandEnvelope", "F2G-STRAT-001", "rational_optimizer", "turn_boundary_attacker", "_save_roundtrip", "historical_reconstruction"):
            if token not in runner_text:
                failures.append(f"F->G adversarial runner missing required boundary/evidence token: {token}")
        if "DebugTruthQuery" in runner_text or "debug_truth_query" in runner_text.lower():
            failures.append("F->G legal-gameplay adversarial runner must not use debug truth as policy input")
    except OSError as exc:
        failures.append(f"unable to inspect F->G adversarial runner: {exc}")

    try:
        router_text = (ROOT / "app/commands/command_router.gd").read_text(encoding="utf-8")
        contract_text = (ROOT / "domain/people/contract_system.gd").read_text(encoding="utf-8")
        for token in ("promotion_scope_mismatch", "media_deal_terms_require_authoritative_offer", "booker_requires_active_contract", "person_not_available_to_promotion"):
            if token not in router_text:
                failures.append(f"F->G corrected command boundary missing guard: {token}")
        if 'bookers.erase(promotion_id)' not in contract_text:
            failures.append("F2G-003 regression: contract deactivation must clear a matching booker appointment")
    except OSError as exc:
        failures.append(f"unable to inspect F->G corrected command/contract boundaries: {exc}")

    try:
        evidence = load_json(ROOT / "tests/adversarial/evidence/F2G-STRAT-001/aggregate_summary.json", failures)
        if not isinstance(evidence, dict) or evidence.get("gate_result") != "PASS" or evidence.get("baseline_commit") != "20ddeaa45bfdbfce98be066cdc13d656d5d6363a":
            failures.append("F->G accepted evidence must retain PASS against the frozen Phase F-R baseline")
        else:
            directed = evidence.get("directed", {})
            totals = evidence.get("totals", {})
            findings = evidence.get("findings", [])
            if directed.get("run_count") != 30 or directed.get("months_completed") != 720 or len(directed.get("profiles", [])) != 10:
                failures.append("F->G directed evidence must retain 10 profiles / 30 runs / 720 months")
            if not directed.get("all_runs_passed") or not directed.get("same_seed_deterministic") or not directed.get("varied_seed_divergence"):
                failures.append("F->G directed evidence must retain pass, same-seed replay and varied-seed divergence")
            if totals.get("runs", 0) < 32 or totals.get("months_completed", 0) < 845:
                failures.append("F->G evidence must retain the accepted long-horizon supplement")
            fixed_ids = {str(f.get("id")) for f in findings if isinstance(f, dict) and f.get("status") == "fixed"}
            if not {"F2G-001", "F2G-002", "F2G-003"}.issubset(fixed_ids):
                failures.append("F->G evidence must retain fixed material finding records F2G-001..003")
    except OSError as exc:
        failures.append(f"unable to inspect F->G accepted evidence: {exc}")

    for finding_id in ("F2G-001", "F2G-002", "F2G-003"):
        repro = ROOT / "tests/adversarial/repro" / finding_id
        for name in ("manifest.json", "reproduce_pre_fix.gd", "pre_fix_output.log", "post_fix_output.log", "expected_vs_observed.md", "command.txt"):
            if not (repro / name).is_file():
                failures.append(f"F->G repro bundle incomplete: {finding_id}/{name}")

    # Phase G presentation/client-boundary gates.
    try:
        presentation_scripts = sorted((ROOT / "presentation").rglob("*.gd"))
        forbidden_presentation_tokens = (
            "res://domain/", "res://persistence/", "res://app/commands/",
            "CommandRouter", "CommandEnvelope", "CampaignState", "owner_person_id",
            "player_person", "true_value", "influence_by_promotion", "state.get(",
        )
        for script in presentation_scripts:
            source = script.read_text(encoding="utf-8")
            lowered = source.lower()
            for token in forbidden_presentation_tokens:
                if token.lower() in lowered:
                    failures.append(f"Phase G presentation must remain a client of application/query state; forbidden token {token!r}: {script.relative_to(ROOT)}")

        session_text = (ROOT / "app/session/campaign_session.gd").read_text(encoding="utf-8")
        for token in ("OwnerPresentationQuery", "CommandEnvelope", "CommandRouter", "MonthPipeline", "queue_player_command", "advance_month"):
            if token not in session_text:
                failures.append(f"Phase G CampaignSession missing authoritative application seam: {token}")

        owner_query_text = (ROOT / "app/queries/owner_presentation_query.gd").read_text(encoding="utf-8")
        for token in ("KnowledgeQueryService", "ChronicleQueryService", "ownership_seat"):
            if token not in owner_query_text:
                failures.append(f"Phase G OwnerPresentationQuery missing governed query seam: {token}")
        if "DebugTruthQuery" in owner_query_text or "debug_truth_query" in owner_query_text.lower() or "true_value" in owner_query_text:
            failures.append("Phase G OwnerPresentationQuery must not use a debug/true-value escape hatch")

        home_text = (ROOT / "presentation/shell/strategic_home.gd").read_text(encoding="utf-8")
        for token in ("queue_player_command", "advance_month", "roster", "touring", "programs", "recent_history"):
            if token not in home_text:
                failures.append(f"Phase G strategic home missing required map-loop presentation seam: {token}")

        map_text = (ROOT / "presentation/map/strategic_map_view.gd").read_text(encoding="utf-8")
        for token in ("market_selected", "InputEventScreenDrag", "zoom"):
            if token not in map_text:
                failures.append(f"Phase G map must retain touch-capable selection/navigation seam: {token}")

        root_scene_text = (ROOT / "presentation/shell/game_root.tscn").read_text(encoding="utf-8")
        if "StrategicHome" not in root_scene_text:
            failures.append("Phase G map-first StrategicHome must be present in the default game root scene")
    except OSError as exc:
        failures.append(f"unable to inspect Phase G presentation architecture: {exc}")

    # G->H adversarial interaction gate scar-tissue checks.
    try:
        session_text = (ROOT / "app/session/campaign_session.gd").read_text(encoding="utf-8")
        for token in ("_player_intent_key", "duplicate_suppressed", "superseded", "preview_state", "_advance_in_progress"):
            if token not in session_text:
                failures.append(f"G->H interaction boundary missing command/month protection token: {token}")
        home_text = (ROOT / "presentation/shell/strategic_home.gd").read_text(encoding="utf-8")
        for token in ("_advance_locked_until_idle", "_repair_selected_market", "_historical_card", "child.free()"):
            if token not in home_text:
                failures.append(f"G->H presentation interaction protection missing token: {token}")
        regression_text = (ROOT / "tests/integration/test_g2h_interaction_regressions.gd").read_text(encoding="utf-8")
        for token in ("duplicate_suppressed", "CMD002", "STALEG2H", "touring churn", "HistoricalProjectionCard"):
            if token not in regression_text:
                failures.append(f"G->H retained interaction regression missing attack token: {token}")
        harness_text = (ROOT / "tools/adversarial_runner/g2h_interaction_run.gd").read_text(encoding="utf-8")
        for token in ("InputEventScreenTouch", "InputEventScreenDrag", "pending_after_48_repeated_callbacks", "historical_reselections", "we.g2h.interaction.v1"):
            if token not in harness_text:
                failures.append(f"G->H rendered interaction harness missing required token: {token}")
        for required_doc in ("docs/G2H_ACCEPTANCE.md", "docs/G2H_FINDINGS.md", "docs/G2H_RUNTIME_RESULT.md"):
            if not (ROOT / required_doc).is_file():
                failures.append(f"G->H acceptance evidence missing: {required_doc}")
    except OSError as exc:
        failures.append(f"unable to inspect G->H interaction scar tissue: {exc}")

    for case_name, code in INVALID_CASES.items():
        case_dir = ROOT / "tests/fixtures/phase_b/invalid" / case_name
        expected = load_json(case_dir / "expected.json", failures)
        if not isinstance(expected, dict) or expected.get("code") != code:
            failures.append(f"invalid fixture {case_name} must declare expected code {code}")

    tracked_generated = subprocess.run(
        ["git", "-C", str(ROOT), "ls-files", "--", *sorted(GENERATED_ROOT_NAMES)],
        capture_output=True, text=True, check=False,
    )
    if tracked_generated.returncode != 0:
        warnings.append("Unable to verify whether generated/cache roots are tracked by Git.")
    else:
        for path in tracked_generated.stdout.splitlines():
            failures.append(f"generated/cache path is tracked by Git: {path}")

    return {
        "schema": "we.g2h.static_check.v1",
        "passed": not failures,
        "failures": failures,
        "warnings": warnings,
    }


def main() -> int:
    result = check()
    print(json.dumps(result, indent=2))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
