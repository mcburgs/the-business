extends RefCounted

const ChronicleDelta = preload("res://domain/chronicle/chronicle_delta.gd")

func get_projection(store: RefCounted, target_date: String) -> Dictionary:
    var checkpoint: Dictionary = {}
    for candidate: Dictionary in store.get("checkpoints"):
        if str(candidate.get("date", "")) <= target_date:
            checkpoint = candidate
        else:
            break
    if checkpoint.is_empty():
        return _failure("CHR003", "checkpoints", {"reason": "no_checkpoint_at_or_before_target", "target_date": target_date})
    var projection: Dictionary = (checkpoint.get("projection", {}) as Dictionary).duplicate(true)
    var checkpoint_date: String = str(checkpoint.get("date"))
    for delta: Dictionary in store.get("deltas"):
        var delta_date: String = str(delta.get("date", ""))
        if delta_date <= checkpoint_date: continue
        if delta_date > target_date: break
        var applied: Dictionary = ChronicleDelta.apply(projection, delta)
        if not bool(applied["passed"]): return applied
        projection = applied["projection"]
    if str(projection.get("date", "")) != target_date:
        return _failure("CHR003", "projection.date", {"reason": "target_not_reconstructed", "target_date": target_date, "actual": projection.get("date")})
    return {"passed": true, "projection": projection.duplicate(true), "errors": []}

func _failure(code: String, path: String, details: Dictionary) -> Dictionary:
    return {"passed": false, "projection": {}, "errors": [{"code": code, "path": path, "localization_key": "validation." + code.to_lower(), "details": details.duplicate(true)}]}
