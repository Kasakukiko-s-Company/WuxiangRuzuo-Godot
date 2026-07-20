extends Control

@onready var status_label: Label = %StatusLabel

var _composition_root: AppCompositionRoot


func _ready() -> void:
	_composition_root = AppCompositionRoot.new()
	status_label.text = _composition_root.bootstrap()
	if not _composition_root.is_ready():
		push_error("[WuxiangRuzuo] G2 bootstrap failed: %s" % _composition_root.bootstrap_issues)
		return
	print("[WuxiangRuzuo] G2 main scene started: %s" % status_label.text)
