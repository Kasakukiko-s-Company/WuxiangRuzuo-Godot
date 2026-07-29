class_name P2PersistenceBinding
extends Node

var _module: GameSaveModule
var _pilot: P2EstatePilot
var _profile_id: StringName
var _saving_enabled: bool = true
var _prepared_exit: P2SessionExitPreparation


func configure(
	module: GameSaveModule,
	pilot: P2EstatePilot,
	profile_id: StringName,
	saving_allowed: bool = true,
) -> void:
	assert(not is_node_ready(), "persistence binding must be configured before ready")
	assert(module != null, "persistence binding requires a GameSaveModule")
	assert(pilot != null, "persistence binding requires a P2EstatePilot")
	assert(
		not pilot.durable_state_committed.is_connected(
			_on_durable_state_committed
		),
		"persistence binding must only be configured once",
	)
	_module = module
	_pilot = pilot
	_profile_id = profile_id
	_saving_enabled = saving_allowed
	pilot.durable_state_committed.connect(_on_durable_state_committed)


func prepare_session_exit() -> P2SessionExitPreparation:
	if _prepared_exit != null:
		return _prepared_exit
	if not _saving_enabled:
		_prepared_exit = P2SessionExitPreparation.ready_read_only()
		return _prepared_exit
	var result := _commit_state(&"session.returning", false)
	if result.is_saved():
		_prepared_exit = P2SessionExitPreparation.ready_saved()
		return _prepared_exit
	return P2SessionExitPreparation.blocked(result.message)


func invalidate_prepared_session_exit() -> void:
	_prepared_exit = null


func _on_durable_state_committed(
	reason: StringName,
	protect_recovery: bool,
) -> void:
	if reason == &"session.exiting" and _prepared_exit != null:
		return
	if not _saving_enabled:
		return
	_commit_state(reason, protect_recovery)


func _commit_state(
	reason: StringName,
	protect_recovery: bool,
) -> GameSaveCommitResult:
	var state := _pilot.capture_persistent_state()
	var result := _module.save(state, protect_recovery)
	if result.status == GameSaveCommitResult.Status.SAVED:
		_pilot.present_persistence_status(
			"%s · 本地自动保存" % _profile_id,
			"已自动保存：%s" % reason,
		)
		return result
	if result.status == GameSaveCommitResult.Status.SAVED_RECOVERY_DEGRADED:
		_pilot.present_persistence_status(
			"%s · 当前档已保存；恢复点待修复" % _profile_id,
			"当前档已保存，但受保护恢复点更新失败：%s" % result.message,
		)
		return result
	if result.status == GameSaveCommitResult.Status.REJECTED:
		_saving_enabled = false
	_pilot.present_persistence_failure(
		result.message,
		_saving_enabled,
	)
	return result
