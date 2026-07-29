class_name AtomicFileSaveAdapter
extends SaveService

var _base_directory: String
var _slot_id_pattern := RegEx.new()


func _init(base_directory: String) -> void:
	_base_directory = base_directory.trim_suffix("/").trim_suffix("\\")
	_slot_id_pattern.compile("^[a-z0-9]+(?:[._-][a-z0-9]+)*$")


func read(slot_id: StringName) -> SaveReadResult:
	if not _is_valid_slot_id(slot_id):
		return SaveReadResult.failed("invalid save slot ID")
	if not _has_valid_base_directory():
		return SaveReadResult.failed("save base directory must be absolute")
	var target_path := _target_path(slot_id)
	if FileAccess.file_exists(target_path):
		return _read_path(target_path)
	var rollback_path := _rollback_path(slot_id)
	if FileAccess.file_exists(rollback_path):
		return _read_path(rollback_path)
	return SaveReadResult.missing()


func read_previous(slot_id: StringName) -> SaveReadResult:
	if not _is_valid_slot_id(slot_id):
		return SaveReadResult.failed("invalid save slot ID")
	if not _has_valid_base_directory():
		return SaveReadResult.failed("save base directory must be absolute")
	var rollback_path := _rollback_path(slot_id)
	var target_exists := FileAccess.file_exists(_target_path(slot_id))
	if target_exists and FileAccess.file_exists(rollback_path):
		return _read_path(rollback_path)
	return _read_path(_backup_path(slot_id))


func _read_path(readable_path: String) -> SaveReadResult:
	if not FileAccess.file_exists(readable_path):
		return SaveReadResult.missing()
	var file := FileAccess.open(readable_path, FileAccess.READ)
	if file == null:
		return SaveReadResult.failed("save slot could not be opened")
	var payload := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		return SaveReadResult.failed("save slot could not be read")
	return SaveReadResult.found(payload)


func write(slot_id: StringName, payload: String) -> SaveWriteResult:
	if not _is_valid_slot_id(slot_id):
		return SaveWriteResult.failed("invalid save slot ID")
	if not _has_valid_base_directory():
		return SaveWriteResult.failed("save base directory must be absolute")
	var directory_error := DirAccess.make_dir_recursive_absolute(_base_directory)
	if directory_error != OK:
		return SaveWriteResult.failed("save base directory could not be created")
	var target_path := _target_path(slot_id)
	var temporary_path := _temporary_path(slot_id)
	var rollback_path := _rollback_path(slot_id)
	var reconciliation_error := _reconcile_interrupted_rotation(
		slot_id,
	)
	if reconciliation_error != OK:
		return SaveWriteResult.failed(
			"interrupted save rotation could not be reconciled"
		)
	if FileAccess.file_exists(temporary_path):
		var cleanup_error := DirAccess.remove_absolute(temporary_path)
		if cleanup_error != OK:
			return SaveWriteResult.failed("stale temporary save could not be removed")
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return SaveWriteResult.failed("temporary save could not be opened")
	file.store_string(payload)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary_path)
		return SaveWriteResult.failed("temporary save could not be written")
	if FileAccess.file_exists(target_path):
		var backup_path := _backup_path(slot_id)
		var rotation_error := DirAccess.rename_absolute(
			target_path,
			rollback_path,
		)
		if rotation_error != OK:
			DirAccess.remove_absolute(temporary_path)
			return SaveWriteResult.failed("current save could not be protected")
		var replace_error := DirAccess.rename_absolute(temporary_path, target_path)
		if replace_error != OK:
			DirAccess.rename_absolute(rollback_path, target_path)
			DirAccess.remove_absolute(temporary_path)
			return SaveWriteResult.failed("temporary save could not replace current save")
		_finalize_rotation(backup_path, rollback_path)
		return SaveWriteResult.written()
	var rename_error := DirAccess.rename_absolute(temporary_path, target_path)
	if rename_error != OK:
		DirAccess.remove_absolute(temporary_path)
		return SaveWriteResult.failed("temporary save could not be promoted")
	return SaveWriteResult.written()


func remove(slot_id: StringName) -> SaveWriteResult:
	if not _is_valid_slot_id(slot_id):
		return SaveWriteResult.failed("invalid save slot ID")
	if not _has_valid_base_directory():
		return SaveWriteResult.failed("save base directory must be absolute")
	var paths: Array[String] = [
		_temporary_path(slot_id),
		_rollback_path(slot_id),
		_target_path(slot_id),
		_backup_path(slot_id),
	]
	for path: String in paths:
		if not FileAccess.file_exists(path):
			continue
		var remove_error := DirAccess.remove_absolute(path)
		if remove_error != OK:
			return SaveWriteResult.failed("save slot could not be removed")
	return SaveWriteResult.written()


func _is_valid_slot_id(slot_id: StringName) -> bool:
	return _slot_id_pattern.search(String(slot_id)) != null


func _has_valid_base_directory() -> bool:
	return (
		not _base_directory.is_empty()
		and _base_directory.is_absolute_path()
	)


func _target_path(slot_id: StringName) -> String:
	return _base_directory.path_join("%s.json" % slot_id)


func _temporary_path(slot_id: StringName) -> String:
	return _target_path(slot_id) + ".tmp"


func _backup_path(slot_id: StringName) -> String:
	return _target_path(slot_id) + ".bak"


func _rollback_path(slot_id: StringName) -> String:
	return _target_path(slot_id) + ".rollback"


func _reconcile_interrupted_rotation(slot_id: StringName) -> Error:
	var rollback_path := _rollback_path(slot_id)
	if not FileAccess.file_exists(rollback_path):
		return OK
	var target_path := _target_path(slot_id)
	if not FileAccess.file_exists(target_path):
		return DirAccess.rename_absolute(rollback_path, target_path)
	var backup_path := _backup_path(slot_id)
	if FileAccess.file_exists(backup_path):
		var backup_cleanup_error := DirAccess.remove_absolute(backup_path)
		if backup_cleanup_error != OK:
			return backup_cleanup_error
	return DirAccess.rename_absolute(rollback_path, backup_path)


func _finalize_rotation(
	backup_path: String,
	rollback_path: String,
) -> void:
	if FileAccess.file_exists(backup_path):
		var backup_cleanup_error := DirAccess.remove_absolute(backup_path)
		if backup_cleanup_error != OK:
			return
	DirAccess.rename_absolute(rollback_path, backup_path)
