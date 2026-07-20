class_name AppCompositionRoot
extends RefCounted

const LOGICAL_VIEWPORT: Vector2i = Vector2i(640, 360)

var platform_descriptor: PlatformDescriptor
var game_catalog: GameCatalog
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
		return "G2 bootstrap failed · %d catalog issue(s)" % bootstrap_issues.size()
	bootstrap_issues = []
	game_catalog = catalog_result.catalog
	return "G2 ready · %d items · %d maps · pure domain active" % [
		game_catalog.items.size(),
		game_catalog.maps.size(),
	]


func is_ready() -> bool:
	return platform_descriptor != null and game_catalog != null and bootstrap_issues.is_empty()
