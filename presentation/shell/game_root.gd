extends Node

const DiagnosticLog = preload("res://app/bootstrap/diagnostic_log.gd")
const BootProbe = preload("res://app/bootstrap/boot_probe.gd")
const CampaignSession = preload("res://app/session/campaign_session.gd")

const DEFAULT_CAMPAIGN_DIRECTORY := "res://content/campaigns/great_lakes_1975"
const DEFAULT_SAVE_ID := "campaign.primary"
const DEFAULT_SEED := 424242

var _diagnostics: Variant
var _session: RefCounted
var _startup_result: Dictionary = {}
@onready var _home: Control = $PresentationRoot/StrategicHome

func _ready() -> void:
    _diagnostics = DiagnosticLog.new()
    var probe: Variant = BootProbe.new()
    _diagnostics.info("bootstrap", "APP_SHELL_READY", "Application shell initialized.", probe.collect())
    _session = CampaignSession.new()
    var capture_mode: bool = not _capture_args().is_empty()
    if capture_mode:
        _startup_result = _session.call("start", DEFAULT_CAMPAIGN_DIRECTORY, DEFAULT_SEED)
    else:
        _startup_result = _session.call("start_or_resume", DEFAULT_CAMPAIGN_DIRECTORY, DEFAULT_SAVE_ID, DEFAULT_SEED, "user://saves", "The Business")
    if not bool(_startup_result.get("passed", false)):
        push_error("Phase H campaign session failed to initialize: " + str(_startup_result.get("errors", [])))
        _show_startup_failure(_startup_result.get("errors", []))
        return
    _home.call("bind_session", _session)
    if bool(_startup_result.get("recovered", false)):
        _home.set("status_message", "Recovered the last known-good campaign checkpoint.")
        _home.call("refresh")
    call_deferred("_handle_capture_request")

func _notification(what: int) -> void:
    if _session == null or not _session.call("is_started"):
        return
    match what:
        NOTIFICATION_APPLICATION_PAUSED:
            # Android may kill a process after this notification. Flush the already-resolved
            # authoritative checkpoint synchronously here; no simulation runs in this callback.
            _session.call("request_checkpoint", "application_paused")
            _flush_lifecycle_checkpoint()
        NOTIFICATION_APPLICATION_FOCUS_OUT:
            _session.call("request_checkpoint", "application_focus_out")
            call_deferred("_flush_lifecycle_checkpoint")
        NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
            call_deferred("_resume_from_lifecycle")
        NOTIFICATION_WM_GO_BACK_REQUEST:
            if _home != null and bool(_home.call("handle_system_back")):
                return
            _session.call("request_checkpoint", "android_back_exit")
            _session.call("flush_checkpoint")
            get_tree().quit()
        NOTIFICATION_WM_CLOSE_REQUEST:
            _session.call("request_checkpoint", "application_close")
            _session.call("flush_checkpoint")

func _flush_lifecycle_checkpoint() -> void:
    if _session == null or not _session.call("is_started"):
        return
    var result: Dictionary = _session.call("flush_checkpoint")
    if not bool(result.get("passed", false)):
        push_warning("Lifecycle checkpoint failed and remains pending: " + str(result.get("errors", [])))

func _resume_from_lifecycle() -> void:
    if _session == null or not _session.call("is_started"):
        return
    # A failed background save stays pending in CampaignSession. Resume retries it,
    # then refreshes the projection from the same authoritative current state.
    var status: Dictionary = _session.call("persistence_status")
    if bool(status.get("checkpoint_requested", false)):
        _flush_lifecycle_checkpoint()
    if _home != null:
        _home.call("refresh")

func startup_result() -> Dictionary:
    return _startup_result.duplicate(true)

func _handle_capture_request() -> void:
    var args := _capture_args(); if args.is_empty(): return
    var size_text := str(args.get("size", ""))
    if not size_text.is_empty() and "x" in size_text:
        var width := int(size_text.get_slice("x", 0)); var height := int(size_text.get_slice("x", 1))
        if width >= 480 and height >= 480:
            get_window().content_scale_size = Vector2i(width, height); get_window().size = Vector2i(width, height); await get_tree().process_frame; await get_tree().process_frame
    _home.call("prepare_capture", str(args.get("name", "initial")))
    for _frame: int in range(5): await get_tree().process_frame
    var image := get_viewport().get_texture().get_image(); var path := str(args.get("path", ""))
    if not path.is_empty():
        var error := image.save_png(path); if error != OK: push_error("Phase H screenshot capture failed: " + path)
    get_tree().quit()

func _capture_args() -> Dictionary:
    var result: Dictionary = {}
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with("--capture="): result["name"] = argument.trim_prefix("--capture=")
        elif argument.begins_with("--capture-path="): result["path"] = argument.trim_prefix("--capture-path=")
        elif argument.begins_with("--capture-size="): result["size"] = argument.trim_prefix("--capture-size=")
    if not result.has("name") and not result.has("path"): return {}
    if not result.has("name"): result["name"] = "initial"
    return result

func _show_startup_failure(errors: Variant) -> void:
    var label := Label.new(); label.text = "The Business could not open the campaign.\n" + str(errors); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.position = Vector2(40, 40); label.size = Vector2(800, 300); $PresentationRoot.add_child(label)
