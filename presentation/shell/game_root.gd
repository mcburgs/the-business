extends Node

const DiagnosticLog = preload("res://app/bootstrap/diagnostic_log.gd")
const BootProbe = preload("res://app/bootstrap/boot_probe.gd")

var _diagnostics: Variant

func _ready() -> void:
    _diagnostics = DiagnosticLog.new()
    var probe: Variant = BootProbe.new()
    _diagnostics.info(
        "bootstrap",
        "APP_SHELL_READY",
        "Application shell initialized.",
        probe.collect()
    )
