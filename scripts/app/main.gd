extends Control

@onready var status_label: Label = %StatusLabel
@onready var profile_1_button: Button = %Profile1Button
@onready var profile_2_button: Button = %Profile2Button
@onready var profile_3_button: Button = %Profile3Button
@onready var profile_detail_label: Label = %ProfileDetailLabel
@onready var launch_p1_button: Button = %LaunchP1Button
@onready var launch_p2_button: Button = %LaunchP2Button
@onready var delete_profile_button: Button = %DeleteProfileButton
@onready var delete_confirm_layer: Control = %DeleteConfirmLayer
@onready var delete_message: Label = %DeleteMessage
@onready var cancel_delete_button: Button = %CancelDeleteButton
@onready var confirm_delete_button: Button = %ConfirmDeleteButton

var _composition_root: AppCompositionRoot
var _composition_root_override: AppCompositionRoot
var _save_service_override: SaveService
var _active_save_service: SaveService
var _profile_roster: SaveProfileRoster
var _profile_snapshot: SaveProfileRosterSnapshot
var _selected_profile_id: StringName = &"profile-1"
var _pending_delete_profile_id: StringName = &""
var _profile_message: String = ""


func _ready() -> void:
	launch_p1_button.pressed.connect(_on_launch_p1_pressed)
	launch_p2_button.pressed.connect(_on_launch_p2_pressed)
	delete_profile_button.pressed.connect(
		request_delete_selected_profile
	)
	cancel_delete_button.pressed.connect(
		resolve_delete_confirmation.bind(false)
	)
	confirm_delete_button.pressed.connect(
		resolve_delete_confirmation.bind(true)
	)
	for index: int in SaveSnapshot.PROFILE_IDS.size():
		_profile_buttons()[index].pressed.connect(
			select_profile.bind(SaveSnapshot.PROFILE_IDS[index])
		)
	_composition_root = (
		_composition_root_override
		if _composition_root_override != null
		else AppCompositionRoot.new()
	)
	status_label.text = _composition_root.bootstrap()
	var p1_available := _composition_root.entry_status(
		AppCompositionRoot.ENTRY_P1_EXPERIENCE_PROBE,
	).is_available()
	var p2_available := _composition_root.entry_status(
		AppCompositionRoot.ENTRY_P2_H01,
	).is_available()
	launch_p1_button.disabled = not p1_available
	launch_p2_button.disabled = not p2_available
	if not p1_available and not p2_available:
		_disable_profile_screen("H01 入口不可用")
		var p1_status := _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P1_EXPERIENCE_PROBE,
		)
		var p2_status := _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P2_H01,
		)
		push_error(
			"[WuxiangRuzuo] bootstrap failed: P1: %s; H01: %s"
			% [p1_status.describe_issues(), p2_status.describe_issues()]
		)
		return
	if not p1_available:
		var p1_status := _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P1_EXPERIENCE_PROBE,
		)
		var p1_diagnostic := p1_status.describe_issues()
		status_label.text = "%s · P1 blocked · %s" % [
			status_label.text,
			p1_diagnostic,
		]
		push_warning(
			"[WuxiangRuzuo] P1 entry unavailable; H01 remains usable: %s"
			% p1_diagnostic
		)
	if not p2_available:
		_disable_profile_screen("H01 入口不可用；P1 仍可启动")
		var h01_status := _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P2_H01,
		)
		push_warning(
			"[WuxiangRuzuo] H01 entry unavailable; P1 remains usable: %s"
			% h01_status.describe_issues()
		)
	else:
		_initialize_profile_screen()
	print("[WuxiangRuzuo] main scene started: %s" % status_label.text)


func configure_composition_root_override(root_override: AppCompositionRoot) -> void:
	assert(
		not is_node_ready(),
		"Main composition root override must be configured before entering the tree",
	)
	assert(
		root_override != null,
		"Main composition root override requires an AppCompositionRoot",
	)
	_composition_root_override = root_override


func configure_save_service_override(service: SaveService) -> void:
	assert(
		not is_node_ready(),
		"Main save override must be configured before entering the tree",
	)
	assert(service != null, "Main save override requires a SaveService")
	_save_service_override = service


func profile_screen_state() -> ProfileScreenState:
	if _profile_snapshot == null:
		return null
	return ProfileScreenState.new(
		_profile_snapshot,
		_selected_profile_id,
		_pending_delete_profile_id,
		_profile_message,
	)


func select_profile(profile_id: StringName) -> bool:
	if (
		_profile_snapshot == null
		or not SaveSnapshot.PROFILE_IDS.has(profile_id)
		or not _pending_delete_profile_id.is_empty()
	):
		return false
	_selected_profile_id = profile_id
	_profile_message = _profile_snapshot.advisory
	_render_profile_screen()
	return true


func activate_selected_profile() -> bool:
	var screen := profile_screen_state()
	if screen == null or not screen.can_launch():
		if screen != null and screen.selected_profile() != null:
			_profile_message = screen.selected_profile().message
			_render_profile_screen()
		return false
	var launch := _composition_root.create_h01_launch(
		_selected_profile_id,
		_active_save_service,
	)
	if not launch.is_ready():
		_profile_message = "档位启动失败：%s" % launch.message
		status_label.text = "H01 档位不可用（原文件未被覆盖）"
		push_error(
			"[WuxiangRuzuo] P2 scene transition blocked: %s"
			% launch.message
		)
		_refresh_profile_screen(false, _profile_message)
		return false
	var recent_result := _profile_roster.record_recent(
		_selected_profile_id
	)
	if not recent_result.is_applied():
		push_warning(
			"[WuxiangRuzuo] H01 launched but recent-profile metadata failed: %s"
			% recent_result.message
		)
	_replace_current_scene(launch.pilot)
	return true


func request_delete_selected_profile() -> bool:
	var screen := profile_screen_state()
	if (
		screen == null
		or not screen.can_delete()
		or screen.is_delete_confirmation_open()
	):
		return false
	_pending_delete_profile_id = _selected_profile_id
	var summary := screen.selected_profile()
	delete_message.text = (
		"确认删除档位 %d（%s）？\n"
		+ "当前、受保护恢复点和隔离证据都会删除，无法撤销。"
	) % [
		_profile_number(_pending_delete_profile_id),
		_summary_status_text(summary),
	]
	_render_profile_screen()
	delete_confirm_layer.visible = true
	cancel_delete_button.grab_focus()
	return true


func resolve_delete_confirmation(
	confirm: bool,
) -> SaveProfileMutationResult:
	if _pending_delete_profile_id.is_empty():
		return SaveProfileMutationResult.rejected(
			"no profile deletion is awaiting confirmation"
		)
	var profile_id := _pending_delete_profile_id
	_pending_delete_profile_id = &""
	delete_confirm_layer.visible = false
	if not confirm:
		_profile_message = "已取消删除档位 %d" % _profile_number(profile_id)
		_render_profile_screen()
		_focus_selected_profile()
		return SaveProfileMutationResult.rejected("profile deletion cancelled")
	var result := _profile_roster.delete_profile(profile_id)
	var message := (
		"档位 %d 已删除" % _profile_number(profile_id)
		if result.is_applied()
		else "档位删除未完整完成：%s" % result.message
	)
	_refresh_profile_screen(result.is_applied(), message)
	_focus_selected_profile()
	return result


func _on_launch_p1_pressed() -> void:
	if (
		_composition_root == null
		or not _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P1_EXPERIENCE_PROBE,
		).is_available()
	):
		push_error("[WuxiangRuzuo] P1 scene transition blocked: entry is unavailable")
		return
	var result := get_tree().change_scene_to_file(
		AppCompositionRoot.P1_PROTOTYPE_SCENE
	)
	if result != OK:
		push_error(
			"[WuxiangRuzuo] P1 scene transition failed: %s"
			% error_string(result)
		)


func _on_launch_p2_pressed() -> void:
	if (
		_composition_root == null
		or not _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P2_H01,
		).is_available()
	):
		push_error("[WuxiangRuzuo] P2 scene transition blocked: bootstrap is not ready")
		return
	activate_selected_profile()


func _initialize_profile_screen() -> void:
	_active_save_service = (
		_save_service_override
		if _save_service_override != null
		else _composition_root.create_save_service()
	)
	if _active_save_service == null:
		_disable_profile_screen("开发存档目录必须位于 D 盘")
		push_warning("[WuxiangRuzuo] profile screen has no D-drive SaveService")
		return
	_profile_roster = _composition_root.create_profile_roster(
		_active_save_service
	)
	if _profile_roster == null:
		_disable_profile_screen("档位目录无法装配")
		return
	_refresh_profile_screen(true)


func _refresh_profile_screen(
	reset_selection: bool,
	message: String = "",
) -> void:
	_profile_snapshot = _profile_roster.refresh()
	if (
		reset_selection
		or _profile_snapshot.profile(_selected_profile_id) == null
	):
		_selected_profile_id = _profile_snapshot.default_profile_id()
	_profile_message = (
		message
		if not message.is_empty()
		else _profile_snapshot.advisory
	)
	_render_profile_screen()


func _render_profile_screen() -> void:
	if _profile_snapshot == null:
		return
	var screen := profile_screen_state()
	var modal_open := (
		screen != null
		and screen.is_delete_confirmation_open()
	)
	var buttons := _profile_buttons()
	for index: int in SaveSnapshot.PROFILE_IDS.size():
		var profile_id: StringName = SaveSnapshot.PROFILE_IDS[index]
		var summary := _profile_snapshot.profile(profile_id)
		var is_recent := profile_id == _profile_snapshot.recent_profile_id
		buttons[index].disabled = modal_open
		buttons[index].button_pressed = profile_id == _selected_profile_id
		buttons[index].text = "档位 %d%s · %s" % [
			index + 1,
			" · 最近游玩" if is_recent else "",
			_summary_status_text(summary),
		]
	launch_p2_button.disabled = screen == null or not screen.can_launch()
	delete_profile_button.disabled = screen == null or not screen.can_delete()
	launch_p1_button.disabled = (
		modal_open
		or not _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P1_EXPERIENCE_PROBE,
		).is_available()
	)
	if screen != null:
		launch_p2_button.text = _launch_button_text(screen.selected_profile())
		profile_detail_label.text = _profile_detail_text(
			screen.selected_profile()
		)


func _disable_profile_screen(message: String) -> void:
	_profile_snapshot = null
	for index: int in _profile_buttons().size():
		var button := _profile_buttons()[index]
		button.disabled = true
		button.text = "档位 %d · 当前不可用" % (index + 1)
	launch_p2_button.disabled = true
	delete_profile_button.disabled = true
	profile_detail_label.text = message


func _summary_status_text(summary: SaveProfileSummary) -> String:
	if summary == null:
		return "无法读取"
	if summary.status == SaveProfileSummary.Status.EMPTY:
		return "空档 · 可开始新游戏"
	if summary.status == SaveProfileSummary.Status.READY:
		return "第 %d 天 · H01 玩家地产" % summary.world_day
	if summary.status == SaveProfileSummary.Status.RECOVERY_AVAILABLE:
		return "第 %d 天 · 可从恢复点继续" % summary.world_day
	if summary.status == SaveProfileSummary.Status.UNSUPPORTED_SCHEMA:
		return "版本不支持 · 原文件未覆盖"
	if summary.status == SaveProfileSummary.Status.INCOMPATIBLE:
		return "内容不兼容 · 原文件未覆盖"
	if summary.status == SaveProfileSummary.Status.READ_FAILED:
		return "存储读取失败 · 原文件未覆盖"
	return "存档损坏 · 原文件未覆盖"


func _launch_button_text(summary: SaveProfileSummary) -> String:
	if summary == null:
		return "所选档位不可用"
	if summary.status == SaveProfileSummary.Status.EMPTY:
		return "用档位 %d开始新游戏" % _profile_number(summary.profile_id)
	if summary.status == SaveProfileSummary.Status.RECOVERY_AVAILABLE:
		return "用档位 %d恢复并继续" % _profile_number(summary.profile_id)
	if summary.is_launchable():
		return "继续档位 %d" % _profile_number(summary.profile_id)
	return "所选档位不可用"


func _profile_detail_text(summary: SaveProfileSummary) -> String:
	if summary == null:
		return "档位状态不可用"
	var details := "档位 %d · %s" % [
		_profile_number(summary.profile_id),
		_summary_status_text(summary),
	]
	if not summary.saved_at.is_empty():
		details += " · %s" % summary.saved_at.replace("T", " ")
	if not _profile_message.is_empty():
		details += "\n%s" % _profile_message
	elif not summary.is_launchable():
		details += "\n%s" % _unavailable_profile_guidance(summary)
	return details


func _unavailable_profile_guidance(summary: SaveProfileSummary) -> String:
	if summary.status == SaveProfileSummary.Status.UNSUPPORTED_SCHEMA:
		return "当前版本无法读取；请保留档位等待兼容工具。原文件不会被覆盖。"
	if summary.status == SaveProfileSummary.Status.INCOMPATIBLE:
		return "该档位不属于当前内容版本；请保留档位等待迁移。原文件不会被覆盖。"
	if summary.status == SaveProfileSummary.Status.READ_FAILED:
		return "读取存储失败；请检查存储目录后重试。原文件不会被覆盖。"
	return "存档校验失败；可删除后重新开始，或保留等待恢复。原文件不会被覆盖。"


func _profile_number(profile_id: StringName) -> int:
	return SaveSnapshot.PROFILE_IDS.find(profile_id) + 1


func _profile_buttons() -> Array[Button]:
	return [profile_1_button, profile_2_button, profile_3_button]


func _focus_selected_profile() -> void:
	var index := SaveSnapshot.PROFILE_IDS.find(_selected_profile_id)
	if index >= 0:
		_profile_buttons()[index].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if (
		not _pending_delete_profile_id.is_empty()
		and event.is_action_pressed("ui_cancel")
	):
		resolve_delete_confirmation(false)
		get_viewport().set_input_as_handled()


func _replace_current_scene(next_scene: Node) -> void:
	var tree := get_tree()
	var previous_scene := tree.current_scene
	tree.root.add_child(next_scene)
	tree.current_scene = next_scene
	if previous_scene != null:
		previous_scene.queue_free()
