class_name AppCatalogSource
extends RefCounted


func load_game_catalog() -> CatalogDecodeResult:
	var issues: Array[DataValidationIssue] = [
		DataValidationIssue.new(
			"bootstrap.gameCatalog",
			"catalog source does not implement game catalog loading",
		),
	]
	return CatalogDecodeResult.invalid(issues)


func load_estate_map_catalog() -> EstateMapCatalogDecodeResult:
	var issues: Array[DataValidationIssue] = [
		DataValidationIssue.new(
			"bootstrap.estateMapCatalog",
			"catalog source does not implement estate map catalog loading",
		),
	]
	return EstateMapCatalogDecodeResult.invalid(issues)


func load_trade_offer_catalog(
	_game_catalog: GameCatalog,
) -> TradeOfferCatalogDecodeResult:
	var issues: Array[DataValidationIssue] = [
		DataValidationIssue.new(
			"bootstrap.tradeOfferCatalog",
			"catalog source does not implement trade offer catalog loading",
		),
	]
	return TradeOfferCatalogDecodeResult.invalid(issues)
