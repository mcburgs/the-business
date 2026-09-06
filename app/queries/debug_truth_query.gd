extends RefCounted

# Deliberately separate from normal presentation query paths.
func person_truth(state: RefCounted, person_id: String) -> Dictionary:
    var people: Dictionary = state.get("people")
    if not people.has(person_id):
        return {}
    var person: RefCounted = people[person_id]
    return (person.call("to_dict") as Dictionary).duplicate(true)

func promotion_truth(state: RefCounted, promotion_id: String) -> Dictionary:
    var promotions: Dictionary = state.get("promotions")
    if not promotions.has(promotion_id):
        return {}
    var promotion: RefCounted = promotions[promotion_id]
    return (promotion.call("to_dict") as Dictionary).duplicate(true)
