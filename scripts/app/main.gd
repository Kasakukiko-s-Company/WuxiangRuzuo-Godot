extends Control

@onready var status_label: Label = %StatusLabel

var _composition_root: AppCompositionRoot


func _ready() -> void:
	_composition_root = AppCompositionRoot.new()
	status_label.text = _composition_root.bootstrap()
	print("[WuxiangRuzuo] G1 main scene started: %s" % status_label.text)
