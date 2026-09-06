extends RefCounted

func parse_dependency(spec: String) -> Dictionary:
    for operator: String in [">=", "<=", "==", ">", "<", "="]:
        var position: int = spec.find(operator)
        if position > 0:
            return {
                "pack_id": spec.substr(0, position),
                "operator": operator,
                "version": spec.substr(position + operator.length()),
            }
    return {}

func satisfies(actual_version: String, operator: String, required_version: String) -> bool:
    var comparison: int = compare(actual_version, required_version)
    match operator:
        ">=": return comparison >= 0
        "<=": return comparison <= 0
        ">": return comparison > 0
        "<": return comparison < 0
        "=", "==": return comparison == 0
        _: return false

func compare(left: String, right: String) -> int:
    var left_parts: Array[int] = _core_parts(left)
    var right_parts: Array[int] = _core_parts(right)
    for index: int in range(3):
        if left_parts[index] < right_parts[index]:
            return -1
        if left_parts[index] > right_parts[index]:
            return 1
    return 0

func _core_parts(version: String) -> Array[int]:
    var core: String = version.split("-", false, 1)[0].split("+", false, 1)[0]
    var pieces: PackedStringArray = core.split(".", false)
    var result: Array[int] = [0, 0, 0]
    for index: int in range(min(3, pieces.size())):
        result[index] = int(pieces[index])
    return result
