extends RefCounted

const RUNTIME_FAMILIES: Array[String] = [
    "person", "promotion", "touring", "contract", "championship", "program",
    "media_deal", "agreement", "relationship", "command", "event"
]

static func is_content_id(value: String) -> bool:
    var parts: PackedStringArray = value.split(".")
    if parts.size() < 2:
        return false
    for part: String in parts:
        if part.is_empty():
            return false
        var first: String = part.substr(0, 1)
        if first < "a" or first > "z":
            return false
        for index: int in range(part.length()):
            var character: String = part.substr(index, 1)
            var valid_lower: bool = character >= "a" and character <= "z"
            var valid_digit: bool = character >= "0" and character <= "9"
            if not valid_lower and not valid_digit and character != "_":
                return false
    return true

static func is_runtime_id(value: String, expected_family: String = "") -> bool:
    var colon_index: int = value.find(":")
    if colon_index <= 0 or colon_index != value.rfind(":") or colon_index >= value.length() - 1:
        return false
    var family: String = value.substr(0, colon_index)
    if not family in RUNTIME_FAMILIES:
        return false
    if not expected_family.is_empty() and family != expected_family:
        return false
    var token: String = value.substr(colon_index + 1)
    for index: int in range(token.length()):
        var character: String = token.substr(index, 1)
        var valid_upper: bool = character >= "A" and character <= "Z"
        var valid_lower: bool = character >= "a" and character <= "z"
        var valid_digit: bool = character >= "0" and character <= "9"
        if not valid_upper and not valid_lower and not valid_digit and character != "_" and character != "-":
            return false
    return true

static func runtime_family(value: String) -> String:
    if not is_runtime_id(value):
        return ""
    return value.get_slice(":", 0)

static func sorted_keys(source: Dictionary) -> Array[String]:
    var output: Array[String] = []
    for key: Variant in source.keys():
        output.append(str(key))
    output.sort()
    return output
