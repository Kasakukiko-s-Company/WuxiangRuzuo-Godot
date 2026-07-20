class_name FarmState
extends RefCounted

var map_id: StringName
var _tiles: Array[FarmTileState] = []


static func create_empty(farm_map_id: StringName) -> FarmState:
	assert(not farm_map_id.is_empty(), "farm map ID must not be empty")
	var farm := FarmState.new()
	farm.map_id = farm_map_id
	return farm


static func restore(
	farm_map_id: StringName,
	farm_tiles: Array[FarmTileState],
	catalog: GameCatalog,
) -> FarmState:
	if farm_map_id.is_empty() or catalog.get_map(farm_map_id) == null:
		return null
	var seen: Dictionary = {}
	for tile: FarmTileState in farm_tiles:
		if tile == null or seen.has(tile.coordinate) or tile.watered_on_day < 0:
			return null
		seen[tile.coordinate] = true
		if tile.crop == null:
			continue
		if (
			catalog.get_crop(tile.crop.crop_id) == null
			or tile.crop.planted_on_day < 1
			or tile.crop.growth_progress < 0
			or tile.crop.stage_index < 0
			or tile.crop.last_growth_day < 0
		):
			return null
	var farm := FarmState.new()
	farm.map_id = farm_map_id
	farm._tiles = _copy_tiles(farm_tiles)
	return farm


func tile_count() -> int:
	return _tiles.size()


func tile_at(coordinate: Vector2i) -> FarmTileState:
	for tile: FarmTileState in _tiles:
		if tile.coordinate == coordinate:
			return tile
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


func _with_tiles(farm_tiles: Array[FarmTileState]) -> FarmState:
	var farm := FarmState.new()
	farm.map_id = map_id
	farm._tiles = _copy_tiles(farm_tiles)
	return farm


static func _copy_tiles(farm_tiles: Array[FarmTileState]) -> Array[FarmTileState]:
	var copies: Array[FarmTileState] = []
	for tile: FarmTileState in farm_tiles:
		copies.append(tile.copy())
	return copies
