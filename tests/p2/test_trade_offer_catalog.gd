extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_result := CatalogFileLoader.load_catalog()
	_check(game_result.is_valid(), "trade catalog test loads the game catalog")
	if not game_result.is_valid():
		_finish()
		return
	var file_result := TradeOfferCatalogFileLoader.load_catalog(game_result.catalog)
	_check(
		file_result.is_valid()
		and file_result.catalog.offers.size() == 2
		and file_result.catalog.offers_for_endpoint(
			&"economy.h01.north_meadow_crate",
		).size() == 2,
		"the H01 trade file decodes two offers at one endpoint",
	)
	var exposed_offers: Array[TradeOfferDefinition] = (
		file_result.catalog.offers
	)
	exposed_offers.clear()
	_check(
		file_result.catalog.offers.size() == 2,
		"callers cannot mutate the catalog by editing its exposed offer array",
	)
	var invalid_result := TradeOfferCatalogCodec.decode_document(
		{
			"schemaVersion": 1,
			"offers": [
				{
					"id": "economy.bad",
					"endpointId": "economy.h01.north_meadow_crate",
					"cost": {"itemId": "unknown_item", "quantity": 1},
					"reward": {"itemId": "mistleaf_seed", "quantity": 1},
				},
			],
		},
		game_result.catalog,
	)
	_check(
		not invalid_result.is_valid()
		and invalid_result.describe_issues().contains("unknown item"),
		"trade configuration rejects unknown item references",
	)
	var invalid_domain_catalog := TradeOfferCatalog.create([
		TradeOfferDefinition.new(
			&"Economy.Bad",
			&"economy.h01.north_meadow_crate",
			&"mistleaf",
			1,
			&"village_scrip",
			30,
		),
	], game_result.catalog)
	_check(
		invalid_domain_catalog == null,
		"domain construction cannot bypass stable offer ID validation",
	)
	var wrong_schema := _valid_document()
	wrong_schema["schemaVersion"] = 2
	_check_invalid_document(
		wrong_schema,
		game_result.catalog,
		"unsupported trade schema is rejected",
	)
	_check_invalid_document(
		{"schemaVersion": 1, "offers": []},
		game_result.catalog,
		"empty trade catalog is rejected",
	)
	var duplicate_offer := _valid_document()
	duplicate_offer["offers"].append(
		duplicate_offer["offers"][0].duplicate(true)
	)
	_check_invalid_document(
		duplicate_offer,
		game_result.catalog,
		"duplicate offer IDs are rejected",
	)
	var invalid_endpoint := _valid_document()
	invalid_endpoint["offers"][0]["endpointId"] = "Invalid Endpoint"
	_check_invalid_document(
		invalid_endpoint,
		game_result.catalog,
		"invalid endpoint IDs are rejected",
	)
	var zero_quantity := _valid_document()
	zero_quantity["offers"][0]["cost"]["quantity"] = 0
	_check_invalid_document(
		zero_quantity,
		game_result.catalog,
		"zero trade quantities are rejected",
	)
	var same_item := _valid_document()
	same_item["offers"][0]["reward"]["itemId"] = "mistleaf"
	_check_invalid_document(
		same_item,
		game_result.catalog,
		"offers cannot exchange an item for itself",
	)
	_finish()


func _valid_document() -> Dictionary:
	return {
		"schemaVersion": 1,
		"offers": [
			{
				"id": "economy.test.sell",
				"endpointId": "economy.test.endpoint",
				"cost": {"itemId": "mistleaf", "quantity": 1},
				"reward": {"itemId": "village_scrip", "quantity": 30},
			},
		],
	}


func _check_invalid_document(
	document: Dictionary,
	catalog: GameCatalog,
	label: String,
) -> void:
	_check(
		not TradeOfferCatalogCodec.decode_document(
			document,
			catalog,
		).is_valid(),
		label,
	)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_TRADE_OFFER_CATALOG_OK")
		quit(0)
		return
	push_error("P2 trade-offer catalog test failed: %d check(s)" % _failures)
	quit(1)
