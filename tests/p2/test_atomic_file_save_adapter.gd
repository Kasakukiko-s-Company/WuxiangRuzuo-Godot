extends SceneTree

const AtomicFileSaveAdapterScript = preload(
	"res://scripts/persistence/atomic_file_save_adapter.gd"
)

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var base_directory := ProjectSettings.globalize_path(
		"res://builds/test-save-adapter"
	)
	var adapter: SaveService = AtomicFileSaveAdapterScript.new(base_directory)
	adapter.remove(&"profile-1")
	adapter.remove(&"profile-2")
	adapter.remove(&"profile-3")
	_check(
		base_directory.replace("\\", "/").begins_with("D:/"),
		"the adapter test directory resolves inside the D-drive project",
	)
	var missing := adapter.read(&"profile-1")
	_check(
		missing.status == SaveReadResult.Status.MISSING,
		"a missing stable slot is reported explicitly",
	)
	var first_write := adapter.write(&"profile-1", "{\"day\":1}")
	var first_read := adapter.read(&"profile-1")
	_check(
		first_write.status == SaveWriteResult.Status.WRITTEN
		and first_read.status == SaveReadResult.Status.FOUND
		and first_read.payload == "{\"day\":1}",
		"a first atomic write can be read back through the SaveService seam",
	)
	var second_write := adapter.write(&"profile-1", "{\"day\":2}")
	var second_read := adapter.read(&"profile-1")
	var previous_read := adapter.read_previous(&"profile-1")
	_check(
		second_write.status == SaveWriteResult.Status.WRITTEN
		and second_read.status == SaveReadResult.Status.FOUND
		and second_read.payload == "{\"day\":2}"
		and previous_read.status == SaveReadResult.Status.FOUND
		and previous_read.payload == "{\"day\":1}",
		"a second write exposes the new target and previous physical version",
	)
	var other_write := adapter.write(&"profile-2", "{\"day\":9}")
	var remove_first_profile := adapter.remove(&"profile-1")
	var removed_read := adapter.read(&"profile-1")
	var isolated_read := adapter.read(&"profile-2")
	_check(
		other_write.status == SaveWriteResult.Status.WRITTEN
		and remove_first_profile.status == SaveWriteResult.Status.WRITTEN
		and removed_read.status == SaveReadResult.Status.MISSING
		and isolated_read.status == SaveReadResult.Status.FOUND
		and isolated_read.payload == "{\"day\":9}",
		"removing one profile leaves another profile isolated",
	)
	var invalid_ids: Array[StringName] = [
		&"Profile-1",
		&"profile/1",
		&"profile..1",
		&"_profile-1",
	]
	for invalid_id: StringName in invalid_ids:
		_check(
			adapter.read(invalid_id).status == SaveReadResult.Status.FAILED
			and adapter.read_previous(invalid_id).status
			== SaveReadResult.Status.FAILED
			and adapter.write(invalid_id, "blocked").status
			== SaveWriteResult.Status.FAILED
			and adapter.remove(invalid_id).status == SaveWriteResult.Status.FAILED,
			"invalid slot ID '%s' is rejected by every SaveService operation"
			% invalid_id,
		)
	for invalid_base_directory: String in ["", "relative/save-root"]:
		var invalid_adapter: SaveService = AtomicFileSaveAdapterScript.new(
			invalid_base_directory
		)
		_check(
			invalid_adapter.read(&"profile-1").status
			== SaveReadResult.Status.FAILED
			and invalid_adapter.read_previous(&"profile-1").status
			== SaveReadResult.Status.FAILED
			and invalid_adapter.write(&"profile-1", "blocked").status
			== SaveWriteResult.Status.FAILED
			and invalid_adapter.remove(&"profile-1").status
			== SaveWriteResult.Status.FAILED,
			"non-absolute save root '%s' is rejected by every operation"
			% invalid_base_directory,
		)

	var interrupted_target := base_directory.path_join("profile-3.json")
	var interrupted_temporary := interrupted_target + ".tmp"
	var interrupted_backup := interrupted_target + ".bak"
	_check(
		_write_raw(interrupted_temporary, "{\"stale\":true}")
		and adapter.read(&"profile-3").status == SaveReadResult.Status.MISSING
		and adapter.read_previous(&"profile-3").status
		== SaveReadResult.Status.MISSING,
		"a tmp-only interrupted first write is not exposed as a checkpoint",
	)
	var initial_after_interruption := adapter.write(&"profile-3", "{\"day\":10}")
	_check(
		initial_after_interruption.status == SaveWriteResult.Status.WRITTEN
		and not FileAccess.file_exists(interrupted_temporary)
		and adapter.read(&"profile-3").payload == "{\"day\":10}",
		"the next write cleans a stale tmp-only interruption",
	)
	adapter.write(&"profile-3", "{\"day\":11}")
	_check(
		_write_raw(interrupted_target, "{corrupt-target")
		and adapter.read(&"profile-3").payload == "{corrupt-target"
		and adapter.read_previous(&"profile-3").payload == "{\"day\":10}",
		"a corrupt target does not hide the previous physical candidate",
	)
	DirAccess.remove_absolute(interrupted_target)
	_write_raw(interrupted_temporary, "{\"interrupted\":true}")
	_check(
		adapter.read(&"profile-3").status == SaveReadResult.Status.MISSING
		and adapter.read_previous(&"profile-3").status
		== SaveReadResult.Status.FOUND
		and FileAccess.file_exists(interrupted_backup),
		"a target-to-backup interruption keeps the previous candidate readable",
	)
	var promoted_after_interruption := adapter.write(
		&"profile-3",
		"{\"day\":12}",
	)
	_check(
		promoted_after_interruption.status == SaveWriteResult.Status.WRITTEN
		and adapter.read(&"profile-3").payload == "{\"day\":12}"
		and adapter.read_previous(&"profile-3").payload == "{\"day\":10}"
		and not FileAccess.file_exists(interrupted_temporary),
		"a new write repairs target-missing state without discarding backup",
	)
	_write_raw(interrupted_temporary, "{\"stale\":true}")
	_check(
		adapter.read(&"profile-3").payload == "{\"day\":12}",
		"a target remains authoritative when a stale tmp also exists",
	)
	adapter.write(&"profile-3", "{\"day\":13}")
	_check(
		not FileAccess.file_exists(interrupted_temporary)
		and adapter.read(&"profile-3").payload == "{\"day\":13}"
		and adapter.read_previous(&"profile-3").payload == "{\"day\":12}",
		"a normal replacement cleans tmp and rotates target to previous",
	)
	var interrupted_rollback := interrupted_target + ".rollback"
	DirAccess.rename_absolute(interrupted_target, interrupted_rollback)
	_write_raw(interrupted_temporary, "{\"day\":14}")
	_check(
		adapter.read(&"profile-3").payload == "{\"day\":13}"
		and adapter.read_previous(&"profile-3").payload == "{\"day\":12}",
		"a normal pre-promote interruption exposes the newest rollback before older backup",
	)
	var resumed_normal_rotation := adapter.write(
		&"profile-3",
		"{\"day\":14}",
	)
	_check(
		resumed_normal_rotation.status == SaveWriteResult.Status.WRITTEN
		and adapter.read(&"profile-3").payload == "{\"day\":14}"
		and adapter.read_previous(&"profile-3").payload == "{\"day\":13}",
		"the next write resumes from the newest valid rollback",
	)
	_write_raw(interrupted_target, "{corrupt-target")
	DirAccess.rename_absolute(interrupted_target, interrupted_rollback)
	_write_raw(interrupted_temporary, "{\"day\":15}")
	_check(
		adapter.read(&"profile-3").payload == "{corrupt-target"
		and adapter.read_previous(&"profile-3").payload == "{\"day\":13}",
		"a corrupt pre-promote rollback remains visible before the valid older backup",
	)
	var recovered_rotation := adapter.write(&"profile-3", "{\"day\":15}")
	_check(
		recovered_rotation.status == SaveWriteResult.Status.WRITTEN
		and adapter.read(&"profile-3").payload == "{\"day\":15}"
		and not FileAccess.file_exists(interrupted_rollback),
		"the next write reconciles rollback state before committing a new target",
	)
	_write_raw(interrupted_rollback, "{\"day\":15}")
	_write_raw(interrupted_target, "{\"day\":16}")
	_check(
		adapter.read_previous(&"profile-3").payload == "{\"day\":15}",
		"a post-promote interruption exposes rollback as the immediate previous",
	)
	adapter.write(&"profile-3", "{\"day\":17}")
	_check(
		adapter.read(&"profile-3").payload == "{\"day\":17}"
		and adapter.read_previous(&"profile-3").payload == "{\"day\":16}"
		and not FileAccess.file_exists(interrupted_rollback),
		"the next write finalizes post-promote rotation without losing current",
	)

	adapter.remove(&"profile-2")
	adapter.remove(&"profile-3")
	_finish()


func _write_raw(path: String, payload: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(payload)
	file.flush()
	var write_error := file.get_error()
	file.close()
	return write_error == OK


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_ATOMIC_FILE_SAVE_ADAPTER_OK")
		quit(0)
		return
	push_error("P2 atomic-file save adapter failed: %d check(s)" % _failures)
	quit(1)
