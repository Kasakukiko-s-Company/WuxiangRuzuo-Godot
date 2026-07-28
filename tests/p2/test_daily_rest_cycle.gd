extends SceneTree

const REST_POINT_ID: StringName = &"home.h01.rest.home_door"

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog_result := CatalogFileLoader.load_catalog()
	_check(
		catalog_result.is_valid(),
		"daily-rest test loads the validated game catalog",
	)
	if not catalog_result.is_valid():
		_finish()
		return
	var catalog: GameCatalog = catalog_result.catalog
	var rest_definitions: Array[DailyRestPointDefinition] = [
		DailyRestPointDefinition.new(
			REST_POINT_ID,
			&"home_h01_open_meadow",
			&"interaction",
			&"home_door",
		),
	]
	var rest_points := DailyRestPointCatalog.create(rest_definitions)
	_check(rest_points != null, "validated rest definitions build a point catalog")
	if rest_points == null:
		_finish()
		return
	var session := FarmingSessionState.new(
		FarmingTransactionState.new(
			FarmState.create_empty(&"home_h01_open_meadow"),
			InventoryState.create_empty(),
		),
		1,
	)
	var command := DailyRestCommand.new(
		REST_POINT_ID,
		1,
	)

	var rested: DailyRestResult = DailyRestCycle.attempt(
		session,
		command,
		rest_points,
		catalog,
	)
	_check(
		rested.status == DailyRestResult.Status.RESTED
		and rested.session.world_day == 2,
		"a valid rest point completes exactly one world day",
	)

	var replayed := DailyRestCycle.attempt(
		rested.session,
		command,
		rest_points,
		catalog,
	)
	_check(
		replayed.status == DailyRestResult.Status.ALREADY_RESTED
		and replayed.session == rested.session,
		"replaying an already completed rest command is idempotent",
	)

	var future_day := DailyRestCycle.attempt(
		session,
		DailyRestCommand.new(
			REST_POINT_ID,
			3,
		),
		rest_points,
		catalog,
	)
	_check(
		future_day.status == DailyRestResult.Status.DAY_GAP
		and future_day.session == session,
		"a future completed day cannot skip the calendar",
	)

	var wrong_map_session := FarmingSessionState.new(
		FarmingTransactionState.new(
			FarmState.create_empty(&"old_mine"),
			InventoryState.create_empty(),
		),
		1,
	)
	var wrong_map := DailyRestCycle.attempt(
		wrong_map_session,
		command,
		rest_points,
		catalog,
	)
	_check(
		wrong_map.status == DailyRestResult.Status.MAP_MISMATCH
		and wrong_map.session == wrong_map_session,
		"rest rejects a point from a different map",
	)

	var missing_point := DailyRestCycle.attempt(
		session,
		DailyRestCommand.new(
			&"",
			1,
		),
		rest_points,
		catalog,
	)
	_check(
		missing_point.status == DailyRestResult.Status.INVALID_REST_POINT
		and missing_point.session == session,
		"rest requires an explicit semantic rest-point ID",
	)

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_DAILY_REST_CYCLE_OK")
		quit(0)
		return
	push_error("P2 daily-rest cycle test failed: %d check(s)" % _failures)
	quit(1)
