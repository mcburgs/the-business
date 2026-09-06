#!/usr/bin/env python3
"""Phase D repository/content/headless-core checks that do not require Godot."""
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
    "tools/simulation_cli", "tests/unit", "tests/integration", "tests/golden",
    "tests/soak", "tests/fixtures/phase_b/valid/mini_campaign",
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

    # Phase D static headless-core gates. These complement, not replace, the real Godot runtime tests.
    try:
        version_text = (ROOT / "app/bootstrap/project_version.gd").read_text(encoding="utf-8")
        if 'const BUILD_PHASE: String = "D"' not in version_text:
            failures.append("Phase D candidate/final metadata must report build phase D")
        if not any(token in version_text for token in (
            'const GAME_VERSION: String = "0.0.0-phase-d-candidate"',
            'const GAME_VERSION: String = "0.0.0-phase-d"',
        )):
            failures.append("Phase D game version must be candidate or verified Phase D")
    except OSError as exc:
        failures.append(f"unable to inspect Phase D version metadata: {exc}")

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
        "schema": "we.phase_d.static_check.v1",
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
