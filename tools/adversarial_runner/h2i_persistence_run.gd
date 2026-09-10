extends SceneTree

const CampaignSession = preload("res://app/session/campaign_session.gd")

const CAMPAIGN := "res://content/campaigns/great_lakes_1975"
const SEED := 424242
const ROOT := "user://h2i_persistence_harness"
const SAVE_ID := "h2i_hostile"

var failures: Array[String] = []
var metrics: Dictionary = {}

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    _reset_root()
    var session: RefCounted = CampaignSession.new()
    var started: Dictionary = session.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, "H2I hostile")
    _expect(bool(started.get("passed", false)), "initial_start")
    if not bool(started.get("passed", false)):
        _finish(); return

    var interruptions: int = 0
    var recovered_interruptions: int = 0
    var historical_reads: int = 0
    var last_good_checks: int = 0
    var stages: Array[String] = ["after_manifest_write", "after_preserve_previous", "after_publish", "backup_copy_failure"]

    for month_index: int in range(12):
        if month_index % 4 == 1:
            var view: Dictionary = session.call("current_projection")
            var controlled: Dictionary = {}
            for item: Dictionary in view.get("touring", []):
                if str(item.get("ownership", "")) == "controlled": controlled = item; break
            var markets: Array = view.get("markets", [])
            if not controlled.is_empty() and not markets.is_empty():
                session.call("queue_player_command", "command.set_route", {"touring_company_id": str(controlled.get("company_id", "")), "route": [{"market_id": str((markets[month_index % markets.size()] as Dictionary).get("market_id", ""))}]})

        var service: RefCounted = session.get("_save_service")
        if month_index > 0 and month_index % 4 != 0:
            service.set("failure_injection_stage", stages[(month_index - 1) % stages.size()])
            interruptions += 1
        var advanced: Dictionary = session.call("advance_month")
        service.set("failure_injection_stage", "")
        _expect(bool(advanced.get("passed", false)), "month_" + str(month_index) + "_resolved")
        var expected_state: Dictionary = session.call("state_snapshot")
        var expected_chronicle: Dictionary = session.call("chronicle_snapshot")

        var relaunched: RefCounted = CampaignSession.new()
        var reload: Dictionary = relaunched.call("start_or_resume", CAMPAIGN, SAVE_ID, SEED, ROOT, "H2I hostile")
        _expect(bool(reload.get("passed", false)), "month_" + str(month_index) + "_relaunch")
        if not bool(reload.get("passed", false)): break
        if bool(reload.get("recovered", false)): recovered_interruptions += 1
        _expect(relaunched.call("state_snapshot") == expected_state, "month_" + str(month_index) + "_state_exact")
        _expect(relaunched.call("chronicle_snapshot") == expected_chronicle, "month_" + str(month_index) + "_chronicle_exact")
        _expect(int(relaunched.call("pending_count")) == 0, "month_" + str(month_index) + "_no_pending_after_relaunch")
        session = relaunched

        var dates: Array = (session.call("current_projection") as Dictionary).get("history_dates", [])
        var state_guard: Dictionary = session.call("state_snapshot")
        var chronicle_guard: Dictionary = session.call("chronicle_snapshot")
        for date_value: Variant in dates:
            session.call("historical_projection", str(date_value))
            historical_reads += 1
        _expect(session.call("state_snapshot") == state_guard and session.call("chronicle_snapshot") == chronicle_guard, "month_" + str(month_index) + "_history_read_only")

        var current_service: RefCounted = session.get("_save_service")
        if bool(current_service.call("has_last_good", SAVE_ID)):
            var last_good: Dictionary = current_service.call("load_last_good", SAVE_ID, str(session.get("_state").get("content_fingerprint")))
            _expect(bool(last_good.get("passed", false)), "month_" + str(month_index) + "_last_good_loadable")
            last_good_checks += 1

    metrics = {
        "months": int((session.call("current_projection") as Dictionary).get("turn_number", -1)),
        "relaunches": 12,
        "injected_interruptions": interruptions,
        "recovered_interruptions": recovered_interruptions,
        "historical_projections_checked": historical_reads,
        "last_good_validations": last_good_checks,
    }
    _reset_root()
    _finish()

func _expect(condition: bool, code: String) -> void:
    if not condition: failures.append(code)

func _finish() -> void:
    var result: Dictionary = {
        "schema": "we.h2i.persistence.v1",
        "passed": failures.is_empty(),
        "failures": failures,
        "metrics": metrics,
        "engine": str(Engine.get_version_info().get("string", "unknown")),
    }
    print("WE_H2I_PERSISTENCE " + JSON.stringify(result))
    quit(0 if failures.is_empty() else 1)

func _reset_root() -> void:
    var base: String = ProjectSettings.globalize_path(ROOT)
    for artifact: String in [SAVE_ID, "." + SAVE_ID + ".tmp", "." + SAVE_ID + ".previous", "." + SAVE_ID + ".recovery_old"]:
        _remove_tree(base.path_join(artifact))
    if DirAccess.dir_exists_absolute(base): DirAccess.remove_absolute(base)

func _remove_tree(path: String) -> void:
    if not DirAccess.dir_exists_absolute(path): return
    var directory: DirAccess = DirAccess.open(path)
    if directory == null: return
    directory.list_dir_begin()
    var name: String = directory.get_next()
    while name != "":
        if name != "." and name != "..":
            var child: String = path.path_join(name)
            if directory.current_is_dir(): _remove_tree(child)
            else: DirAccess.remove_absolute(child)
        name = directory.get_next()
    directory.list_dir_end()
    DirAccess.remove_absolute(path)
