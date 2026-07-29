class_name P2PauseMenu
extends Control

signal resume_requested
signal return_to_title_requested

enum Mode {
	CLOSED,
	OPEN,
	RETURN_CONFIRMATION,
}

@onready var _session_status: Label = %PauseSessionStatus
@onready var _return_message: Label = %ReturnConfirmationMessage
@onready var _normal_actions: VBoxContainer = %PauseNormalActions
@onready var _return_confirmation: VBoxContainer = %ReturnConfirmation
@onready var _resume_button: Button = %ResumeButton
@onready var _return_button: Button = %ReturnToTitleButton
@onready var _cancel_return_button: Button = %CancelReturnButton
@onready var _confirm_return_button: Button = %ConfirmReturnButton

var _mode: Mode = Mode.CLOSED
var _return_pending: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_on_resume_pressed)
	_return_button.pressed.connect(request_return_confirmation)
	_cancel_return_button.pressed.connect(cancel_return_confirmation)
	_confirm_return_button.pressed.connect(confirm_return_to_title)
	close()


func open(
	session_status: String,
	saving_allowed: bool = true,
) -> void:
	assert(
		not session_status.strip_edges().is_empty(),
		"pause menu requires a visible session status",
	)
	_mode = Mode.OPEN
	_return_pending = false
	_cancel_return_button.disabled = false
	_confirm_return_button.disabled = false
	_apply_session_copy(session_status, saving_allowed)
	_normal_actions.visible = true
	_return_confirmation.visible = false
	visible = true
	_resume_button.grab_focus()


func present_return_failure(
	message: String,
	session_status: String,
	saving_allowed: bool,
) -> bool:
	if _mode != Mode.RETURN_CONFIRMATION:
		return false
	_return_pending = false
	_cancel_return_button.disabled = false
	_confirm_return_button.disabled = false
	_apply_session_copy(session_status, saving_allowed)
	_return_message.text = (
		(
			"返回标题前保存失败：%s\n"
			+ "仍停留在当前会话；请选择取消或再次确认重试。"
		)
		if saving_allowed
		else (
			"当前状态无法写入：%s\n"
			+ "会话已切换为只读；再次确认将不保存并返回。"
		)
	) % _visible_failure_message(message)
	_cancel_return_button.grab_focus()
	return true


func close() -> void:
	_mode = Mode.CLOSED
	_return_pending = false
	visible = false
	if is_node_ready():
		_normal_actions.visible = true
		_return_confirmation.visible = false
		_cancel_return_button.disabled = false
		_confirm_return_button.disabled = false


func request_return_confirmation() -> bool:
	if _mode != Mode.OPEN or _return_pending:
		return false
	_mode = Mode.RETURN_CONFIRMATION
	_normal_actions.visible = false
	_return_confirmation.visible = true
	_cancel_return_button.grab_focus()
	return true


func cancel_return_confirmation() -> bool:
	if _mode != Mode.RETURN_CONFIRMATION or _return_pending:
		return false
	_mode = Mode.OPEN
	_return_confirmation.visible = false
	_normal_actions.visible = true
	_return_button.grab_focus()
	return true


func confirm_return_to_title() -> bool:
	if _mode != Mode.RETURN_CONFIRMATION or _return_pending:
		return false
	_return_pending = true
	_cancel_return_button.disabled = true
	_confirm_return_button.disabled = true
	return_to_title_requested.emit()
	return true


func is_open() -> bool:
	return _mode != Mode.CLOSED


func is_return_confirmation_open() -> bool:
	return _mode == Mode.RETURN_CONFIRMATION


func _on_resume_pressed() -> void:
	if _mode != Mode.OPEN:
		return
	resume_requested.emit()


func _apply_session_copy(
	session_status: String,
	saving_allowed: bool,
) -> void:
	var visible_status := session_status.strip_edges()
	assert(
		not visible_status.is_empty(),
		"pause menu requires a visible session status",
	)
	_session_status.text = (
		(
			"%s\n返回标题时会先保存当前日期、位置和生活状态。"
			if saving_allowed
			else "%s\n当前恢复会话只读；返回不会覆盖原档。"
		) % visible_status
	)
	_return_button.text = (
		"保存并返回标题"
		if saving_allowed
		else "返回标题（当前会话只读）"
	)
	_return_message.text = (
		(
			"保存当前状态并返回标题页？\n"
			+ "受保护恢复点仍保留最近一次成功休息。"
		)
		if saving_allowed
		else (
			"当前恢复会话只读，返回不会写入。\n"
			+ "损坏证据和受保护恢复点都会原样保留。"
		)
	)


func _visible_failure_message(message: String) -> String:
	var visible_message := message.strip_edges()
	if visible_message.is_empty():
		return "存储服务未提供详细原因"
	return visible_message


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_action_pressed(&"pause"):
		return
	if _return_pending:
		get_viewport().set_input_as_handled()
		return
	if is_return_confirmation_open():
		cancel_return_confirmation()
	else:
		resume_requested.emit()
	get_viewport().set_input_as_handled()
