class_name FarmState
extends RefCounted

var map_id: StringName:
	get:
		return _map_id
	set(_attempted_value):
		push_error("FarmState.map_id is read-only")

var _map_id: StringName
var _tiles: Array[FarmTileState] = []


static func create_empty(farm_map_id: StringName) -> FarmState:
	assert(not farm_map_id.is_empty(), "farm map ID must not be empty")
	var farm := FarmState.new()
	farm._map_id = farm_map_id
	return farm


static func restore(
	farm_map_id: StringName,
	farm_tiles: Array[FarmTileState],
	catalog: GameCatalog,
) -> FarmState:
	if farm_map_id.is_empty() or catalog == null:
		return null
	var seen: Dictionary = {}
	for tile: FarmTileState in farm_tiles:
		if tile == null or seen.has(tile.coordinate) or tile.watered_on_day < 0:
			return null
		seen[tile.coordinate] = true
		if tile.crop == null:
			continue
		var definition: CatalogDefinitions.Crop = catalog.get_crop(
			tile.crop.crop_id
		)
		if (
			definition == null
			or tile.crop.planted_on_day < 1
			or tile.crop.growth_progress < 0
			or tile.crop.stage_index < 0
			or tile.crop.last_growth_day < 0
		):
			return null
		if (
			tile.crop.last_growth_day < tile.crop.planted_on_day - 1
			or tile.crop.growth_progress > CropGrowth.required_progress(definition)
			or tile.crop.stage_index != CropGrowth.stage_for_progress(
				definition,
				tile.crop.growth_progress,
			)
		):
			return null
		var evaluated_day_count := (
			tile.crop.last_growth_day
			- tile.crop.planted_on_day
			+ 1
		)
		if tile.crop.growth_progress > evaluated_day_count:
			return null
	var farm := FarmState.new()
	farm._map_id = farm_map_id
	farm._tiles = _copy_tiles(farm_tiles)
	return farm


func tile_count() -> int:
	return _tiles.size()


func tile_at(coordinate: Vector2i) -> FarmTileState:
	for tile: FarmTileState in _tiles:
		if tile.coordinate == coordinate:
			return tile.copy()
	return null


func copy_tiles() -> Array[FarmTileState]:
	return _copy_tiles(_tiles)


func try_till(coordinate: Vector2i, is_farmable: bool) -> FarmTransactionResult:
	if not is_farmable:
		return FarmTransactionResult.new(FarmTransactionResult.Status.NOT_FARMABLE, self)
	if tile_at(coordinate) != null:
		return FarmTransactionResult.new(FarmTransactionResult.Status.ALREADY_TILLED, self)
	var next_tiles := _copy_tiles(_tiles)
	next_tiles.append(FarmTileState.new(coordinate))
	return FarmTransactionResult.new(
		FarmTransactionResult.Status.TILLED,
		_with_tiles(next_tiles),
	)


func _with_planted_crop(
	coordinate: Vector2i,
	crop: CropState,
) -> FarmState:
	assert(crop != null, "planted crop state must be present")
	assert(
		crop.planted_on_day >= 1
		and crop.growth_progress >= 0
		and crop.stage_index >= 0
		and crop.last_growth_day >= 0,
		"planted crop state must satisfy base invariants",
	)
	var current: FarmTileState = _tile_reference_at(coordinate)
	assert(current != null, "crop can only be planted on a tilled tile")
	assert(current.crop == null, "tilled tile must be empty before planting")
	var next_tiles := _copy_tiles(_tiles)
	for index: int in next_tiles.size():
		if next_tiles[index].coordinate != coordinate:
			continue
		next_tiles[index] = FarmTileState.new(
			coordinate,
			current.watered_on_day,
			crop,
		)
		break
	return _with_tiles(next_tiles)


func _with_watered_on_day(
	coordinate: Vector2i,
	world_day: int,
) -> FarmState:
	assert(world_day >= 1, "watering day must be a valid world day")
	var current: FarmTileState = _tile_reference_at(coordinate)
	assert(current != null, "only a tilled tile can be watered")
	assert(
		world_day >= current.watered_on_day,
		"watering cannot move a tilled tile backwards in time",
	)
	return _with_crop_state(
		coordinate,
		null if current.crop == null else current.crop.copy(),
		world_day,
	)


func _with_crop_state(
	coordinate: Vector2i,
	crop: CropState,
	watered_on_day: int = -1,
) -> FarmState:
	var current: FarmTileState = _tile_reference_at(coordinate)
	assert(current != null, "crop state requires a tilled tile")
	if crop != null:
		assert(
			crop.planted_on_day >= 1
			and crop.growth_progress >= 0
			and crop.stage_index >= 0
			and crop.last_growth_day >= 0,
			"crop update must satisfy base invariants",
		)
	if watered_on_day >= 0:
		assert(
			watered_on_day >= current.watered_on_day,
			"crop update cannot move watering backwards in time",
		)
	var next_watered_day := (
		current.watered_on_day
		if watered_on_day < 0
		else watered_on_day
	)
	var next_tiles := _copy_tiles(_tiles)
	for index: int in next_tiles.size():
		if next_tiles[index].coordinate != coordinate:
			continue
		next_tiles[index] = FarmTileState.new(
			coordinate,
			next_watered_day,
			null if crop == null else crop.copy(),
		)
		break
	return _with_tiles(next_tiles)


func _tile_reference_at(coordinate: Vector2i) -> FarmTileState:
	for tile: FarmTileState in _tiles:
		if tile.coordinate == coordinate:
			return tile
	return null


func _with_tiles(farm_tiles: Array[FarmTileState]) -> FarmState:
	var farm := FarmState.new()
	farm._map_id = map_id
	farm._tiles = _copy_tiles(farm_tiles)
	return farm


static func _copy_tiles(farm_tiles: Array[FarmTileState]) -> Array[FarmTileState]:
	var copies: Array[FarmTileState] = []
	for tile: FarmTileState in farm_tiles:
		copies.append(tile.copy())
	return copies
