class_name DailyRestCycle
extends RefCounted


static func attempt(
	session: FarmingSessionState,
	command: DailyRestCommand,
	rest_points: DailyRestPointCatalog,
	catalog: GameCatalog,
) -> DailyRestResult:
	var rest_point: DailyRestPointDefinition = rest_points.get_point(
		command.rest_point_id
	)
	if rest_point == null:
		return DailyRestResult.new(
			DailyRestResult.Status.INVALID_REST_POINT,
			session,
		)
	if rest_point.map_id != session.state.farm.map_id:
		return DailyRestResult.new(
			DailyRestResult.Status.MAP_MISMATCH,
			session,
		)

	var advance := FarmDayCycle.advance_one_day(
		session,
		FarmDayAdvanceCommand.new(command.completed_day),
		catalog,
	)
	match advance.status:
		FarmDayAdvanceResult.Status.ADVANCED:
			return DailyRestResult.new(
				DailyRestResult.Status.RESTED,
				advance.session,
				advance.grown_crop_count,
			)
		FarmDayAdvanceResult.Status.ALREADY_APPLIED:
			return DailyRestResult.new(
				DailyRestResult.Status.ALREADY_RESTED,
				session,
			)
		FarmDayAdvanceResult.Status.DAY_GAP:
			return DailyRestResult.new(
				DailyRestResult.Status.DAY_GAP,
				session,
			)
		FarmDayAdvanceResult.Status.UNKNOWN_CROP:
			return DailyRestResult.new(
				DailyRestResult.Status.UNKNOWN_CROP,
				session,
			)
		_:
			return DailyRestResult.new(
				DailyRestResult.Status.DAY_GAP,
				session,
			)
