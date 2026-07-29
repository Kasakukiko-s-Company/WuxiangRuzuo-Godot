class_name AppCompositionRoot
extends RefCounted

const LOGICAL_VIEWPORT: Vector2i = Vector2i(640, 360)
const ESTATE_PILOT_MAP_ID: StringName = &"home_h01_open_meadow"
const ESTATE_PILOT_TRADE_ENDPOINT_ID: StringName = (
	&"economy.h01.north_meadow_crate"
)
const ESTATE_PILOT_SELL_OFFER_ID: StringName = (
	&"economy.h01.sell_mistleaf"
)
const ESTATE_PILOT_BUY_OFFER_ID: StringName = (
	&"economy.h01.buy_mistleaf_seed"
)
const P2_ESTATE_PILOT_SCENE: String = (
	"res://scenes/vertical_slices/p2_estate_pilot.tscn"
)
const DEVELOPMENT_SAVE_DIRECTORY: String = "res://builds/save-dev"

var platform_descriptor: PlatformDescriptor
var game_catalog: GameCatalog
var estate_map_catalog: EstateMapCatalog
var trade_offer_catalog: TradeOfferCatalog
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
		trade_offer_catalog = null
		return "G2 bootstrap failed · %d catalog issue(s)" % bootstrap_issues.size()
	var estate_result := EstateMapCatalogFileLoader.load_catalog()
	if not estate_result.is_valid():
		bootstrap_issues = estate_result.issues
		game_catalog = null
		estate_map_catalog = null
		trade_offer_catalog = null
		return "P2 estate bootstrap failed · %d catalog issue(s)" % bootstrap_issues.size()
	var trade_result := TradeOfferCatalogFileLoader.load_catalog(
		catalog_result.catalog,
	)
	if not trade_result.is_valid():
		bootstrap_issues = trade_result.issues
		game_catalog = null
		estate_map_catalog = null
		trade_offer_catalog = null
		return "P2 economy bootstrap failed · %d catalog issue(s)" % bootstrap_issues.size()
	var trade_contract_issues := validate_h01_trade_contract(
		trade_result.catalog,
		catalog_result.catalog,
	)
	if not trade_contract_issues.is_empty():
		bootstrap_issues = trade_contract_issues
		game_catalog = null
		estate_map_catalog = null
		trade_offer_catalog = null
		return "P2 economy bootstrap failed · %d H01 contract issue(s)" % bootstrap_issues.size()
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
		trade_offer_catalog = null
		return "P2 estate bootstrap failed · %d catalog issue(s)" % bootstrap_issues.size()
	bootstrap_issues = []
	game_catalog = catalog_result.catalog
	estate_map_catalog = estate_result.catalog
	trade_offer_catalog = trade_result.catalog
	return "P2 H01 ready · G2 domain active · %d items · %d world maps · %d estate candidates · %d trade offers" % [
		game_catalog.items.size(),
		game_catalog.maps.size(),
		estate_map_catalog.maps.size(),
		trade_offer_catalog.offers.size(),
	]


func is_ready() -> bool:
	return (
		platform_descriptor != null
		and game_catalog != null
		and estate_map_catalog != null
		and trade_offer_catalog != null
		and bootstrap_issues.is_empty()
	)


static func validate_h01_trade_contract(
	offer_catalog: TradeOfferCatalog,
	catalog: GameCatalog,
) -> Array[DataValidationIssue]:
	var issues: Array[DataValidationIssue] = []
	if offer_catalog == null or catalog == null:
		issues.append(DataValidationIssue.new(
			"tradeOffers.h01",
			"validated trade and game catalogs are required",
		))
		return issues
	var endpoint_offers := offer_catalog.offers_for_endpoint(
		ESTATE_PILOT_TRADE_ENDPOINT_ID,
	)
	if endpoint_offers.size() != 2:
		issues.append(DataValidationIssue.new(
			"tradeOffers.%s" % ESTATE_PILOT_TRADE_ENDPOINT_ID,
			"H01 endpoint must expose exactly two offers",
		))
	var sell_offer := offer_catalog.get_offer(
		ESTATE_PILOT_SELL_OFFER_ID,
	)
	var buy_offer := offer_catalog.get_offer(
		ESTATE_PILOT_BUY_OFFER_ID,
	)
	var mistleaf := catalog.get_item(&"mistleaf")
	var seed := catalog.get_item(&"mistleaf_seed")
	if (
		sell_offer == null
		or sell_offer.endpoint_id != ESTATE_PILOT_TRADE_ENDPOINT_ID
		or sell_offer.cost_item_id != &"mistleaf"
		or sell_offer.cost_quantity != 1
		or sell_offer.reward_item_id != &"village_scrip"
		or mistleaf == null
		or sell_offer.reward_quantity != mistleaf.sell_price
	):
		issues.append(DataValidationIssue.new(
			"tradeOffers.%s" % ESTATE_PILOT_SELL_OFFER_ID,
			"must exchange one mistleaf for its catalog sell price in village scrip",
		))
	if (
		buy_offer == null
		or buy_offer.endpoint_id != ESTATE_PILOT_TRADE_ENDPOINT_ID
		or buy_offer.cost_item_id != &"village_scrip"
		or seed == null
		or buy_offer.cost_quantity != seed.buy_price
		or buy_offer.reward_item_id != &"mistleaf_seed"
		or buy_offer.reward_quantity != 1
	):
		issues.append(DataValidationIssue.new(
			"tradeOffers.%s" % ESTATE_PILOT_BUY_OFFER_ID,
			"must exchange the seed catalog buy price in village scrip for one seed",
		))
	return issues


func create_input_service() -> InputService:
	return GodotInputService.new()


func create_audio_service(host: Node) -> AudioService:
	var service := GodotAudioService.new(host)
	if not service.is_ready():
		push_error(
			"Audio catalog validation failed; continuing with silent audio fallback"
		)
	return service


func get_estate_pilot_definition() -> EstateMapDefinition:
	if estate_map_catalog == null:
		return null
	return estate_map_catalog.get_map(ESTATE_PILOT_MAP_ID)


func create_h01_launch(
	profile_id: StringName,
	storage_override: SaveService = null,
) -> H01LaunchResult:
	if not is_ready():
		return H01LaunchResult.blocked(
			"H01 launch requires a successful composition bootstrap"
		)
	if not SaveSnapshot.PROFILE_IDS.has(profile_id):
		return H01LaunchResult.blocked("unknown player profile: %s" % profile_id)
	var definition := get_estate_pilot_definition()
	var pilot_scene := load(P2_ESTATE_PILOT_SCENE) as PackedScene
	var runtime_scene := load(definition.runtime_scene_path) as PackedScene
	if pilot_scene == null or runtime_scene == null:
		return H01LaunchResult.blocked("H01 scene contract is unavailable")
	var storage := storage_override
	if storage == null:
		var save_directory := ProjectSettings.globalize_path(
			DEVELOPMENT_SAVE_DIRECTORY
		)
		if not _is_d_drive_path(save_directory):
			return H01LaunchResult.blocked(
				"development save directory must remain on the D drive"
			)
		storage = AtomicFileSaveAdapter.new(save_directory)
	var save_module := GameSaveModule.new(
		storage,
		game_catalog,
		estate_map_catalog,
		profile_id,
		ESTATE_PILOT_MAP_ID,
	)
	var load_result := save_module.load()
	if load_result.status == GameSaveLoadResult.Status.UNAVAILABLE:
		return H01LaunchResult.blocked(
			"档位已隔离，未覆盖原文件：%s" % load_result.message
		)
	var pilot := pilot_scene.instantiate() as P2EstatePilot
	var runtime := runtime_scene.instantiate() as EstateMapRuntime
	if pilot == null or runtime == null:
		if pilot != null:
			pilot.free()
		if runtime != null:
			runtime.free()
		return H01LaunchResult.blocked("H01 typed scene contract mismatch")
	pilot.configure_estate_runtime(runtime)
	pilot.configure_input_service(create_input_service())
	pilot.configure_game_catalog(game_catalog)
	pilot.configure_trade_book(TradeBook.new(
		trade_offer_catalog,
		game_catalog,
	))
	pilot.configure_audio_service(create_audio_service(pilot))
	if load_result.status == GameSaveLoadResult.Status.LOADED:
		if not pilot.configure_initial_state(load_result.state):
			pilot.free()
			return H01LaunchResult.blocked(
				"decoded profile state does not match the H01 runtime"
			)
		pilot.configure_persistence_status(_persistence_status(
			profile_id,
			load_result,
		))
	else:
		pilot.configure_persistence_status(
			"%s · 本地自动保存" % profile_id
		)
	var binding := P2PersistenceBinding.new()
	binding.name = "PersistenceBinding"
	binding.configure(
		save_module,
		pilot,
		profile_id,
		load_result.saving_allowed,
	)
	pilot.add_child(binding)
	return H01LaunchResult.ready(pilot)


func _persistence_status(
	profile_id: StringName,
	load_result: GameSaveLoadResult,
) -> String:
	if not load_result.saving_allowed:
		return "%s · 恢复只读（原档未覆盖）" % profile_id
	if load_result.source == GameSaveLoadResult.Source.PROTECTED:
		return "%s · 已从受保护恢复点恢复" % profile_id
	if load_result.source == GameSaveLoadResult.Source.CURRENT_PREVIOUS:
		return "%s · 已从上一份自动保存恢复" % profile_id
	if load_result.source == GameSaveLoadResult.Source.PROTECTED_PREVIOUS:
		return "%s · 已从上一份受保护恢复点恢复" % profile_id
	if load_result.requires_resave:
		return "%s · 已读取旧版档；下次操作升级" % profile_id
	return "%s · 已恢复当前档" % profile_id


func _is_d_drive_path(path: String) -> bool:
	return path.replace("\\", "/").to_lower().begins_with("d:/")
