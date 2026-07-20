extends SceneTree

const FarmStateScript = preload("res://scripts/domain/farming/farm_state.gd")

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var empty := FarmStateScript.create_empty(&"hometown_main")
	_check(empty.map_id == &"hometown_main", "farm state belongs to one stable map")
	_check(empty.tile_count() == 0, "untouched ground is absent from farm state")

	var blocked: FarmTransactionResult = empty.try_till(Vector2i(4, 5), false)
	_check(blocked.status == FarmTransactionResult.Status.NOT_FARMABLE, "map rejection blocks tilling")
	_check(blocked.farm == empty, "blocked tilling preserves original state")

	var tilled: FarmTransactionResult = empty.try_till(Vector2i(4, 5), true)
	_check(tilled.status == FarmTransactionResult.Status.TILLED, "farmable target becomes tilled")
	_check(tilled.farm != empty, "successful tilling returns a new state")
	_check(tilled.farm.tile_count() == 1, "only the touched tile enters farm state")
	var tile: FarmTileState = tilled.farm.tile_at(Vector2i(4, 5))
	_check(tile != null, "tilled tile can be queried by domain coordinate")
	_check(tile.watered_on_day == 0, "new tilled tile has no watering day")
	_check(tile.crop == null, "new tilled tile has no crop")

	var repeated: FarmTransactionResult = tilled.farm.try_till(Vector2i(4, 5), true)
	_check(repeated.status == FarmTransactionResult.Status.ALREADY_TILLED, "repeated tilling is idempotent")
	_check(repeated.farm == tilled.farm, "repeated tilling preserves state identity")

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("G2_FARM_STATE_OK")
		quit(0)
		return
	push_error("G2 farm-state test failed: %d check(s)" % _failures)
	quit(1)
