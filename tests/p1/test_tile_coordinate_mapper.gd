extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var mapper := TileCoordinateMapper.new(Vector2i(32, 32), Vector2.ZERO)
	_check(mapper.world_to_cell(Vector2(47.9, 64.1)) == Vector2i(1, 2), "world position maps to top-left grid cell")
	_check(mapper.cell_center(Vector2i(3, 4)) == Vector2(112.0, 144.0), "cell center maps back to a stable world position")
	_check(mapper.facing_cell(Vector2(112.0, 144.0), Vector2i.UP) == Vector2i(3, 3), "facing selects the adjacent interaction cell")
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P1_TILE_MAPPER_OK")
		quit(0)
		return
	push_error("P1 tile mapper failed: %d check(s)" % _failures)
	quit(1)
