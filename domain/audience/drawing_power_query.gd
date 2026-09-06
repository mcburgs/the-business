extends RefCounted

# The governing design requires drawing power to be derived, while deliberately
# leaving its numerical formula open. This query therefore exposes the stable
# input boundary without inventing weights or persisting a duplicate score.
static func collect_inputs(person: RefCounted, promotion: RefCounted, market_id: String) -> Dictionary:
    var audience_by_market: Dictionary = person.get("audience_by_market") as Dictionary
    var local_state: Dictionary = {}
    if audience_by_market.has(market_id) and audience_by_market[market_id] is Dictionary:
        local_state = (audience_by_market[market_id] as Dictionary).duplicate(true)
    return {
        "market_id": market_id,
        "local_audience_state": local_state,
        "promotion_prestige": promotion.get("prestige"),
        "promotion_momentum": promotion.get("momentum"),
        "person_skills": (person.get("skills") as Dictionary).duplicate(true),
        "person_traits": (person.get("traits") as Dictionary).duplicate(true),
        "current_hot_state": person.get("current_hot_state"),
    }

static func evaluate_with_ruleset(person: RefCounted, promotion: RefCounted, market_id: String, evaluator: Callable) -> Variant:
    if not evaluator.is_valid():
        return null
    return evaluator.call(collect_inputs(person, promotion, market_id))
