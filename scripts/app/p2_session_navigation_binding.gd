class_name P2SessionNavigationBinding
extends Node

var _pilot: P2EstatePilot
var _persistence_binding: P2PersistenceBinding
var _title_scene_path: String


func configure(
	pilot: P2EstatePilot,
	persistence_binding: P2PersistenceBinding,
	title_scene_path: String,
) -> void:
	assert(
		not is_node_ready(),
		"session navigation must be configured before entering the tree",
	)
	assert(pilot != null, "session navigation requires a P2 pilot")
	assert(
		persistence_binding != null,
		"session navigation requires a persistence binding",
	)
	assert(
		ResourceLoader.exists(title_scene_path, "PackedScene"),
		"session navigation requires an existing title scene",
	)
	assert(
		not pilot.return_to_title_requested.is_connected(
			_on_return_to_title_requested
		),
		"session navigation must only be configured once",
	)
	_pilot = pilot
	_persistence_binding = persistence_binding
	_title_scene_path = title_scene_path
	pilot.return_to_title_requested.connect(
		_on_return_to_title_requested
	)


func _on_return_to_title_requested() -> void:
	var tree := _pilot.get_tree()
	if tree == null or tree.current_scene != _pilot:
		_pilot.present_navigation_failure(
			"当前会话不是活动场景，无法返回标题"
		)
		return
	var preparation := _persistence_binding.prepare_session_exit()
	if not preparation.is_ready():
		_pilot.present_return_save_failure(preparation.message)
		return
	tree.paused = false
	var result := tree.change_scene_to_file(_title_scene_path)
	if result != OK:
		_persistence_binding.invalidate_prepared_session_exit()
		_pilot.present_navigation_failure(
			"标题场景加载失败：%s" % error_string(result)
		)
