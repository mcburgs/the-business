extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const CommandEnvelope = preload("res://app/commands/command_envelope.gd")
const AIPlanningView = preload("res://domain/ai/ai_planning_view.gd")
const OwnerStrategy = preload("res://domain/ai/owner_strategy.gd")
const TalentManager = preload("res://domain/ai/talent_manager.gd")
const TouringPlanner = preload("res://domain/ai/touring_planner.gd")
const BookerAI = preload("res://domain/ai/booker_ai.gd")
const RecoveryAI = preload("res://domain/ai/recovery_ai.gd")
const DiplomacyAI = preload("res://domain/ai/diplomacy_ai.gd")

func plan(planning_state: RefCounted, content_index: Dictionary, random_service: RefCounted) -> Dictionary:
    var tuning: Dictionary = content_index.get("phase_f_tuning", {})
    var control: Dictionary = content_index.get("phase_f_ai_controlled_promotions", {})
    var promotion_ids: Array[String] = []
    if control.is_empty():
        var player_promotion_id: String = str((planning_state.get("ownership_seat") as RefCounted).get("promotion_id"))
        for promotion_id: String in DomainIds.sorted_keys(planning_state.get("promotions")):
            if promotion_id != player_promotion_id: promotion_ids.append(promotion_id)
    else:
        promotion_ids = DomainIds.sorted_keys(control)
    var commands: Array = []
    var decisions: Array[Dictionary] = []
    var explanations: Dictionary = {}
    var scouting_intents: Array[Dictionary] = []
    for promotion_id: String in promotion_ids:
        var sequence: int = 0
        var promotion: Variant = (planning_state.get("promotions") as Dictionary).get(promotion_id, null)
        if not promotion is RefCounted or str((promotion as RefCounted).get("lifecycle")) != "active": continue
        var view: Dictionary = AIPlanningView.new().build(planning_state, promotion_id)
        var profile: Dictionary = _profile(view, tuning)
        var action_groups: Array = []
        var recovery: Dictionary = RecoveryAI.new().plan(view, profile, tuning)
        action_groups.append(recovery.get("actions", []))
        var owner: Dictionary = OwnerStrategy.new().plan(view, profile, random_service, tuning)
        action_groups.append(owner.get("actions", []))
        var talent: Dictionary = TalentManager.new().plan(view, profile, tuning)
        action_groups.append(talent.get("actions", [])); scouting_intents.append_array(talent.get("scouting_intents", []))
        action_groups.append_array([
            TouringPlanner.new().plan(view, str(owner.get("target_market_id", "")), profile, tuning).get("actions", []),
            BookerAI.new().plan(view, profile).get("actions", []),
            DiplomacyAI.new().plan(view, profile, tuning).get("actions", []),
        ])
        for group_value: Variant in action_groups:
            if not group_value is Array: continue
            for action_value: Variant in group_value:
                if not action_value is Dictionary: continue
                sequence += 1
                var action: Dictionary = action_value
                var command: RefCounted = _command(planning_state, promotion_id, str(control.get(promotion_id, "ai")), sequence, action)
                commands.append(command)
                var explanation: Dictionary = (action.get("explanation", {}) as Dictionary).duplicate(true)
                explanations[str(command.get("command_id"))] = explanation
                decisions.append({"command_id": command.get("command_id"), "promotion_id": promotion_id, "command_type": command.get("command_type"), "historical": bool(action.get("historical", false)), "explanation": explanation})
    return {"passed": true, "errors": [], "commands": commands, "decisions": decisions, "explanations": explanations, "scouting_intents": scouting_intents}

func _profile(view: Dictionary, tuning: Dictionary) -> Dictionary:
    var profiles: Dictionary = tuning.get("strategy_profiles", {})
    var profile_id: String = str(view.get("strategy_profile_id", "strategy.balanced"))
    var profile: Dictionary = (profiles.get(profile_id, profiles.get("strategy.balanced", {})) as Dictionary).duplicate(true) if profiles.get(profile_id, profiles.get("strategy.balanced", {})) is Dictionary else {}
    return profile

func _command(state: RefCounted, promotion_id: String, issuer_kind: String, sequence: int, action: Dictionary) -> RefCounted:
    var command: RefCounted = CommandEnvelope.new()
    var token: String = promotion_id.get_slice(":", 1).replace("-", "").replace("_", "")
    command.set("command_id", "command:F" + str(int(state.get("turn_number"))).pad_zeros(6) + token.substr(0, 8) + str(sequence).pad_zeros(3))
    command.set("command_type", str(action.get("command_type")))
    command.set("issued_for_turn", int(state.get("turn_number")))
    command.set("issued_on", str(state.get("current_date")))
    command.set("issuer", {"kind": issuer_kind if issuer_kind in ["ai", "automation"] else "ai", "promotion_id": promotion_id})
    command.set("turn_phase_ordinal", 3)
    command.set("priority", 100 + sequence)
    command.set("issuer_key", str(command.get("issuer").get("kind")) + "." + promotion_id)
    command.set("payload", (action.get("payload", {}) as Dictionary).duplicate(true))
    return command
