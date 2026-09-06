extends RefCounted

const PhaseCFixture = preload("res://tests/helpers/phase_c_fixture.gd")
const ChronicleStore = preload("res://domain/chronicle/chronicle_store.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")

static func make_state() -> RefCounted:
    return PhaseCFixture.make_state()

static func content_index() -> Dictionary:
    return PhaseCFixture.content_index()

static func make_chronicle(checkpoint_cadence_months: int = 12) -> RefCounted:
    var store: RefCounted = ChronicleStore.new()
    store.set("checkpoint_cadence_months", checkpoint_cadence_months)
    var definitions: Array[Dictionary] = [{
        "metric_id": "promotion.prestige",
        "subject_scope": "promotion",
        "field": "prestige",
        "cadence": "monthly",
        "aggregation": "point",
        "precision": "float",
        "retention": "campaign",
    }]
    store.set("metric_definitions", definitions)
    return store

static func championship_command(state: RefCounted, month_index: int, holder_person_id: String = "") -> RefCounted:
    var holder: String = holder_person_id
    if holder.is_empty(): holder = "person:PER00001" if month_index % 2 == 0 else "person:PER00002"
    var command: RefCounted = CommandEnvelope.new()
    command.set("command_id", "command:D" + str(int(state.get("turn_number"))).pad_zeros(8) + str(month_index % 10))
    command.set("command_type", "command.set_champion")
    command.set("issued_for_turn", int(state.get("turn_number")))
    command.set("issued_on", str(state.get("current_date")))
    command.set("issuer", {"kind": "system"})
    command.set("turn_phase_ordinal", 3)
    command.set("priority", 0)
    command.set("issuer_key", "system.fixture")
    command.set("payload", {"championship_id": "championship:CHA00001", "holder_person_ids": [holder]})
    return command
