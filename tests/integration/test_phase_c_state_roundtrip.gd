extends RefCounted

const Fixture = preload("res://tests/helpers/phase_c_fixture.gd")
const Codec = preload("res://persistence/codecs/campaign_state_codec.gd")
const Migrator = preload("res://persistence/migrations/state_migrator.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var codec: RefCounted = Codec.new()
    var original: RefCounted = Fixture.make_state()
    var encoded: Dictionary = codec.call("encode", original)

    _expect(not _contains_key_recursive(encoded, "drawing_power"), "Derived drawing power must not be persisted as authoritative state.", failures)
    _expect(not _contains_key_recursive(encoded, "owner_market_id"), "Markets must not acquire a literal owner field.", failures)

    var decoded: Dictionary = codec.call("decode", encoded, Fixture.content_index())
    _expect(bool(decoded.get("passed", false)), "State round-trip decode must pass: %s" % JSON.stringify(decoded.get("errors", [])), failures)
    if bool(decoded.get("passed", false)):
        var reencoded: Dictionary = codec.call("encode", decoded.get("state"))
        _expect(reencoded == encoded, "Serialize -> deserialize -> serialize must reproduce authoritative current state.", failures)

    var malformed: Dictionary = encoded.duplicate(true)
    malformed["mystery_future_field"] = 42
    var malformed_result: Dictionary = codec.call("decode", malformed, Fixture.content_index())
    _expect(not bool(malformed_result.get("passed", true)), "Unknown current-state schema fields must be rejected.", failures)
    _expect(_has_code(malformed_result, "STATE001"), "Unknown field rejection must be structured as STATE001.", failures)

    var malformed_type: Dictionary = encoded.duplicate(true)
    malformed_type["turn_number"] = "7"
    var malformed_type_result: Dictionary = codec.call("decode", malformed_type, Fixture.content_index())
    _expect(_has_code(malformed_type_result, "STATE001"), "Load must reject wrong primitive types rather than coercing malformed state.", failures)

    var snapshot: Dictionary = codec.call("encode", original)
    (snapshot["people"] as Dictionary)["person:PER00001"]["skills"]["skill.performance"] = 0.0
    var original_person: RefCounted = (original.get("people") as Dictionary)["person:PER00001"]
    _expect(float((original_person.get("skills") as Dictionary)["skill.performance"]) == 0.8, "Encoded current-state data must be detached from authoritative mutable storage.", failures)

    var broken_ref: Dictionary = encoded.duplicate(true)
    (broken_ref["contracts"] as Dictionary)["contract:CON00001"]["person_id"] = "person:MISSING"
    var broken_result: Dictionary = codec.call("decode", broken_ref, Fixture.content_index())
    _expect(_has_code(broken_result, "REF001"), "Broken required reference must fail load with REF001.", failures)

    var migrator: RefCounted = Migrator.new()
    var same_version: Dictionary = migrator.call("migrate_to_current", encoded)
    _expect(bool(same_version.get("passed", false)) and (same_version.get("migrations_applied", []) as Array).is_empty(), "Schema v2 migration entry point must accept v2 as a no-op.", failures)
    var legacy: Dictionary = encoded.duplicate(true)
    legacy["state_schema_version"] = 1
    (legacy["ownership_seat"] as Dictionary)["owner_person_id"] = "person:PER00001"
    var migrated: Dictionary = migrator.call("migrate_to_current", legacy)
    _expect(bool(migrated.get("passed", false)), "Schema v1 must deliberately migrate to v2.", failures)
    if bool(migrated.get("passed", false)):
        _expect(int((migrated.get("data", {}) as Dictionary).get("state_schema_version", -1)) == 2, "v1 migration must publish schema v2.", failures)
        _expect(not ((migrated.get("data", {}) as Dictionary).get("ownership_seat", {}) as Dictionary).has("owner_person_id"), "v1 migration must retire player owner_person_id from OwnershipSeatState.", failures)
        _expect(((migrated.get("data", {}) as Dictionary).get("promotions", {}) as Dictionary).get("promotion:PRO00001", {}).get("controlling_owner_person_id") == "person:PER00001", "v1 migration must preserve in-world NPC promotion ownership semantics.", failures)
    var codec_migrated: Dictionary = codec.call("decode", legacy, Fixture.content_index())
    _expect(bool(codec_migrated.get("passed", false)) and (codec_migrated.get("migrations_applied", []) as Array).size() == 1, "Codec load must execute and report the v1->v2 migration.", failures)
    var future: Dictionary = encoded.duplicate(true)
    future["state_schema_version"] = 3
    _expect(not bool((migrator.call("migrate_to_current", future) as Dictionary).get("passed", true)), "Future state schemas must fail cleanly.", failures)

    var manifest: Dictionary = codec.call("build_manifest_scaffold", original, "save:fixture", "Fixture", "0.0.0-phase-c", "0.2.0", "4.7.2-stable")
    _expect(str(manifest.get("resolved_content_fingerprint", "")) == str(original.get("content_fingerprint")), "Manifest scaffold must carry the resolved content fingerprint.", failures)
    _expect((manifest.get("rng_checkpoint", {}) as Dictionary).has("internal_state"), "Manifest scaffold must carry RNG checkpoint metadata.", failures)

    return {"name": "phase_c_state_roundtrip", "passed": failures.is_empty(), "failures": failures}

func _contains_key_recursive(value: Variant, target: String) -> bool:
    if value is Dictionary:
        for key: Variant in (value as Dictionary).keys():
            if str(key) == target or _contains_key_recursive((value as Dictionary)[key], target):
                return true
    elif value is Array:
        for child: Variant in value:
            if _contains_key_recursive(child, target):
                return true
    return false

func _has_code(result: Dictionary, code: String) -> bool:
    for error_value: Variant in result.get("errors", []):
        if error_value is Dictionary and str((error_value as Dictionary).get("code", "")) == code:
            return true
    return false

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
