extends RefCounted

const ContentLoader = preload("res://app/content/content_loader.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var loader: Variant = ContentLoader.new()
    var project_search_roots: Array[String] = [
        "res://content/base",
        "res://content/campaigns",
    ]
    var great_lakes: Dictionary = loader.load_campaign(
        "res://content/campaigns/great_lakes_1975",
        project_search_roots
    )
    _expect(bool(great_lakes.get("passed", false)), "Great Lakes skeleton campaign failed to load: %s" % JSON.stringify(great_lakes.get("errors", [])), failures)

    if bool(great_lakes.get("passed", false)):
        var registry: Variant = great_lakes.get("registry")
        _expect(registry.count("markets") == 15, "Great Lakes Phase B skeleton must contain 15 authored markets.", failures)
        _expect(registry.count("promotions") == 3, "Great Lakes Phase B skeleton must contain exactly its authored three promotions.", failures)
        _expect(registry.count("people") == 15, "Great Lakes Phase B skeleton should contain its authored people/staff shells.", failures)
        _expect(registry.count("media_outlets") >= 1, "Great Lakes Phase B skeleton must exercise local-TV content.", failures)
        _expect(str(great_lakes.get("fingerprint", "")).length() == 64, "Loaded content must emit a SHA-256 fingerprint.", failures)
        var map_record: Dictionary = registry.get_record("map", "map.great_lakes")
        _expect(not map_record.is_empty(), "Campaign map must resolve through the generic registry.", failures)
        _expect((map_record.get("connections", []) as Array).size() > 0, "Generic map must load travel connections from data.", failures)

        var repeated: Dictionary = loader.load_campaign(
            "res://content/campaigns/great_lakes_1975",
            project_search_roots
        )
        _expect(bool(repeated.get("passed", false)), "Repeated deterministic load failed.", failures)
        _expect(str(repeated.get("fingerprint", "")) == str(great_lakes.get("fingerprint", "")), "Same resolved content must produce the same fingerprint.", failures)

    var fixture_search_roots: Array[String] = [
        "res://content/base",
        "res://tests/fixtures/phase_b/valid",
    ]
    var miniature: Dictionary = loader.load_campaign(
        "res://tests/fixtures/phase_b/valid/mini_campaign",
        fixture_search_roots
    )
    _expect(bool(miniature.get("passed", false)), "Generic miniature campaign failed to load: %s" % JSON.stringify(miniature.get("errors", [])), failures)
    if bool(miniature.get("passed", false)):
        var mini_registry: Variant = miniature.get("registry")
        _expect(mini_registry.count("markets") == 2, "Fixture market count must come from data, not engine assumptions.", failures)
        _expect(mini_registry.count("promotions") == 1, "Fixture promotion count must come from data, not engine assumptions.", failures)
        _expect(mini_registry.count("people") == 3, "Fixture people count must come from data, not engine assumptions.", failures)

    return {"name": "phase_b_campaign_loading", "passed": failures.is_empty(), "failures": failures,
        "great_lakes_fingerprint": str(great_lakes.get("fingerprint", "")),
        "great_lakes_market_count": 15 if bool(great_lakes.get("passed", false)) else 0,
        "mini_market_count": 2 if bool(miniature.get("passed", false)) else 0}

func _expect(condition: bool, failure_message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure_message)
