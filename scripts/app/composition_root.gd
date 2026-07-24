class_name AppCompositionRoot
extends RefCounted

const LOGICAL_VIEWPORT: Vector2i = Vector2i(640, 360)
const ESTATE_PILOT_MAP_ID: StringName = &"home_h01_open_meadow"

var platform_descriptor: PlatformDescriptor
var game_catalog: GameCatalog
var estate_map_catalog: EstateMapCatalog
var bootstrap_issues: Array[DataValidationIssue] = []


func _init() -> void:
	platform_descriptor = PlatformDescriptor.create(
		PlatformDescriptor.RuntimeEnvironment.WINDOWS_NATIVE,
		PlatformDescriptor.DistributionChannel.STANDALONE,
	)


func bootstrap() -> String:
	var catalog_result := CatalogFileLoader.load_catalog()
	if not catalog_result.is_valid():
		bootstrap_issues = catalog_result.issues
		game_catalog = null
		estate_map_catalog = null
		return "G2 bootstrap failed · %d catalog issue(s)" % bootstrap_issues.size()
	var estate_result := EstateMapCatalogFileLoader.load_catalog()
	if not estate_result.is_valid():
		bootstrap_issues = estate_result.issues
		game_catalog = null
		estate_map_catalog = null
		return "P2 estate bootstrap failed · %d catalog issue(s)" % bootstrap_issues.size()
	var pilot_definition: EstateMapDefinition = estate_result.catalog.get_map(
		ESTATE_PILOT_MAP_ID
	)
	if pilot_definition == null:
		bootstrap_issues = [DataValidationIssue.new(
			"estateMaps.%s" % ESTATE_PILOT_MAP_ID,
			"required P2 pilot definition is missing",
		)]
	elif pilot_definition.runtime_scene_path.is_empty():
		bootstrap_issues = [DataValidationIssue.new(
			"estateMaps.%s.runtimeScenePath" % ESTATE_PILOT_MAP_ID,
			"required P2 pilot runtime scene is not integrated",
		)]
	elif not ResourceLoader.exists(pilot_definition.runtime_scene_path, "PackedScene"):
		bootstrap_issues = [DataValidationIssue.new(
			"estateMaps.%s.runtimeScenePath" % ESTATE_PILOT_MAP_ID,
			"integrated runtime scene does not exist",
		)]
	if not bootstrap_issues.is_empty():
		game_catalog = null
		estate_map_catalog = null
		return "P2 estate bootstrap failed · %d catalog issue(s)" % bootstrap_issues.size()
	bootstrap_issues = []
	game_catalog = catalog_result.catalog
	estate_map_catalog = estate_result.catalog
	return "P2 H01 ready · G2 domain active · %d items · %d world maps · %d estate candidates" % [
		game_catalog.items.size(),
		game_catalog.maps.size(),
		estate_map_catalog.maps.size(),
	]


func is_ready() -> bool:
	return (
		platform_descriptor != null
		and game_catalog != null
		and estate_map_catalog != null
		and bootstrap_issues.is_empty()
	)


func create_input_service() -> InputService:
	return GodotInputService.new()


func get_estate_pilot_definition() -> EstateMapDefinition:
	if estate_map_catalog == null:
		return null
	return estate_map_catalog.get_map(ESTATE_PILOT_MAP_ID)
