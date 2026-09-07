extends RefCounted

const DomainIds = preload("res://domain/core/domain_ids.gd")
const DrawingPowerQuery = preload("res://domain/audience/drawing_power_query.gd")
const PhaseEMath = preload("res://domain/core/phase_e_math.gd")
const ShowPlan = preload("res://domain/booking/show_plan.gd")

func generate(state: RefCounted, schedules: Array[Dictionary], tuning: Dictionary) -> Dictionary:
    var plans: Array = []
    var people: Dictionary = state.get("people")
    var promotions: Dictionary = state.get("promotions")
    var programs: Dictionary = state.get("programs")
    var championships: Dictionary = state.get("championships")
    var world_state: Dictionary = state.get("world_state")
    var bookers: Dictionary = world_state.get("booker_by_promotion", {})
    var approved: Dictionary = world_state.get("approved_major_outcomes", {})
    for schedule: Dictionary in schedules:
        var promotion_id: String = str(schedule.get("promotion_id"))
        var company_id: String = str(schedule.get("touring_company_id"))
        var market_id: String = str(schedule.get("market_id"))
        if not promotions.has(promotion_id):
            continue
        var promotion: RefCounted = promotions[promotion_id]
        var company: RefCounted = (state.get("touring_companies") as Dictionary)[company_id]
        var available: Array = schedule.get("available_person_ids", [])
        if available.is_empty():
            continue
        var directives: Array = company.get("directives")
        var featured_program_id: Variant = _directive_reference(directives, "program_emphasis", "program_id")
        if featured_program_id == null:
            featured_program_id = _best_active_program(programs, promotion_id, available)
        var program_strength: float = 0.0
        if featured_program_id != null and programs.has(str(featured_program_id)):
            var program: RefCounted = programs[str(featured_program_id)]
            program_strength = PhaseEMath.clamp01((float(program.get("heat")) + (float(program.get("momentum")) + 1.0) * 0.5) * 0.5)
        var featured_championship_id: Variant = _directive_reference(directives, "title_priority", "championship_id")
        if featured_championship_id == null:
            featured_championship_id = _first_carried_championship(company, championships)
        var preferred_person_id: Variant = _directive_reference(directives, "push", "person_id")
        var featured_person_id: String = _choose_featured_person(available, preferred_person_id, people, promotion, market_id, tuning, program_strength)
        var booking_skill: float = _booker_skill(bookers.get(promotion_id), people)
        var road_agent_skill: float = _road_agent_skill(available, people)
        var protect_bonus: float = 0.0
        if _directive_reference(directives, "protect", "person_id") != null:
            protect_bonus = float(tuning.get("protect_coherence_bonus", 0.04))
        var coherence: float = PhaseEMath.clamp01(
            float(tuning.get("booking_base_coherence", 0.45))
            + booking_skill * float(tuning.get("booker_coherence_weight", 0.25))
            + road_agent_skill * float(tuning.get("road_agent_coherence_weight", 0.15))
            + program_strength * float(tuning.get("program_coherence_weight", 0.12))
            + protect_bonus
            - float(schedule.get("travel_pressure", 0.0)) * float(tuning.get("fatigue_booking_penalty", 0.12))
        )
        var booking_quality: float = PhaseEMath.clamp01((coherence + booking_skill + road_agent_skill) / 3.0)
        var plan: RefCounted = ShowPlan.new()
        plan.set("show_id", "show:" + company_id.get_slice(":", 1) + ":" + str(state.get("turn_number")).pad_zeros(6))
        plan.set("promotion_id", promotion_id)
        plan.set("touring_company_id", company_id)
        plan.set("market_id", market_id)
        plan.set("participant_person_ids", available.duplicate())
        plan.set("featured_person_id", featured_person_id)
        plan.set("featured_program_id", featured_program_id)
        plan.set("featured_championship_id", featured_championship_id)
        if approved.has(promotion_id) and approved[promotion_id] is Dictionary:
            plan.set("approved_major_outcome", (approved[promotion_id] as Dictionary).duplicate(true))
        plan.set("booking_quality", booking_quality)
        plan.set("coherence", coherence)
        plan.set("travel_pressure", float(schedule.get("travel_pressure", 0.0)))
        plan.set("market_context", {
            "wrestling_interest": float(((state.get("markets") as Dictionary)[market_id] as RefCounted).get("wrestling_interest")),
            "program_strength": program_strength,
        })
        plan.set("causal_factors", [
            {"source": "booker_skill", "value": booking_skill},
            {"source": "road_agent_skill", "value": road_agent_skill},
            {"source": "program_strength", "value": program_strength},
            {"source": "travel_pressure", "value": schedule.get("travel_pressure", 0.0)},
            {"source": "featured_person", "person_id": featured_person_id},
        ])
        plans.append(plan)
    return {"passed": true, "errors": [], "plans": plans}

func _choose_featured_person(available: Array, preferred: Variant, people: Dictionary, promotion: RefCounted, market_id: String, tuning: Dictionary, program_strength: float) -> String:
    if preferred != null and str(preferred) in available:
        return str(preferred)
    var best_id: String = str(available[0])
    var best_score: float = -1.0
    for value: Variant in available:
        var person_id: String = str(value)
        if not people.has(person_id):
            continue
        var score: float = DrawingPowerQuery.evaluate(people[person_id], promotion, market_id, tuning, {"program_strength": program_strength})
        if score > best_score or (score == best_score and person_id < best_id):
            best_id = person_id
            best_score = score
    return best_id

func _booker_skill(booker_value: Variant, people: Dictionary) -> float:
    if booker_value != null and people.has(str(booker_value)):
        var skills: Dictionary = (people[str(booker_value)] as RefCounted).get("skills")
        return float(skills.get("skill.booking", skills.get("skill.performance", 0.5)))
    return 0.5

func _road_agent_skill(available: Array, people: Dictionary) -> float:
    var total: float = 0.0
    var count: int = 0
    for value: Variant in available:
        var person_id: String = str(value)
        if people.has(person_id):
            var skills: Dictionary = (people[person_id] as RefCounted).get("skills")
            if skills.has("skill.road_agenting"):
                total += float(skills["skill.road_agenting"])
                count += 1
    return total / float(count) if count > 0 else 0.5

func _best_active_program(programs: Dictionary, promotion_id: String, available: Array) -> Variant:
    var best_id: Variant = null
    var best_score: float = -2.0
    for program_id: String in DomainIds.sorted_keys(programs):
        var program: RefCounted = programs[program_id]
        if str(program.get("promotion_id")) != promotion_id or str(program.get("status")) != "active":
            continue
        var participants: Array = []
        for side_name: String in ["side_a", "side_b"]:
            var side: Dictionary = program.get(side_name)
            for person_value: Variant in side.get("person_ids", []):
                participants.append(str(person_value))
        var available_overlap: int = 0
        for person_id: Variant in participants:
            if str(person_id) in available:
                available_overlap += 1
        if available_overlap == 0:
            continue
        var score: float = float(program.get("heat")) + float(program.get("momentum")) * 0.5 + float(available_overlap) * 0.05
        if score > best_score:
            best_score = score
            best_id = program_id
    return best_id

func _first_carried_championship(company: RefCounted, championships: Dictionary) -> Variant:
    var ids: Array = company.get("carried_championship_ids")
    var sorted_ids: Array[String] = []
    for value: Variant in ids:
        if championships.has(str(value)):
            sorted_ids.append(str(value))
    sorted_ids.sort()
    return sorted_ids[0] if not sorted_ids.is_empty() else null

func _directive_reference(directives: Array, kind: String, field: String) -> Variant:
    for value: Variant in directives:
        if value is Dictionary and str((value as Dictionary).get("kind", "")) == kind and (value as Dictionary).has(field):
            return (value as Dictionary)[field]
    return null
