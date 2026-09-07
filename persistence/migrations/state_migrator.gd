extends RefCounted

const CURRENT_STATE_SCHEMA_VERSION: int = 2

func migrate_to_current(input: Dictionary) -> Dictionary:
    if not input.has("state_schema_version"):
        return _failure("STATE001", "state_schema_version", {"reason": "required_field_missing"})
    var source_version: int = int(input["state_schema_version"])
    if source_version == CURRENT_STATE_SCHEMA_VERSION:
        return {"passed": true, "data": input.duplicate(true), "errors": [], "migrations_applied": []}
    if source_version > CURRENT_STATE_SCHEMA_VERSION:
        return _failure("STATE001", "state_schema_version", {"reason": "future_schema_not_supported", "actual": source_version, "supported": CURRENT_STATE_SCHEMA_VERSION})
    if source_version == 1:
        return _migrate_v1_to_v2(input)
    return _failure("STATE001", "state_schema_version", {"reason": "migration_not_available", "actual": source_version, "target": CURRENT_STATE_SCHEMA_VERSION})

func _migrate_v1_to_v2(input: Dictionary) -> Dictionary:
    var output: Dictionary = input.duplicate(true)
    var seat_value: Variant = output.get("ownership_seat", {})
    if not seat_value is Dictionary:
        return _failure("STATE001", "ownership_seat", {"reason": "expected_dictionary_for_v1_migration"})
    var seat: Dictionary = seat_value
    var legacy_owner_person_id: Variant = seat.get("owner_person_id", null)
    seat.erase("owner_person_id")
    output["ownership_seat"] = seat
    output["state_schema_version"] = 2

    # v1 used the same person reference both as player-seat identity and, normally, as
    # in-world promotion governance. v2 retires only the player-seat meaning. Existing
    # PromotionState.controlling_owner_person_id remains untouched and authoritative for NPC/world ownership.
    var details: Dictionary = {
        "from": 1,
        "to": 2,
        "change": "retire_player_owner_person_from_ownership_seat",
        "legacy_owner_person_id": legacy_owner_person_id,
        "promotion_owner_semantics": "preserved_unchanged",
    }
    return {"passed": true, "data": output, "errors": [], "migrations_applied": [details]}

func _failure(code: String, path: String, details: Dictionary) -> Dictionary:
    return {
        "passed": false,
        "data": {},
        "migrations_applied": [],
        "errors": [{"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)}],
    }
