extends AppCatalogSource

var _files := FileAppCatalogSource.new()


func load_game_catalog() -> CatalogDecodeResult:
	return _files.load_game_catalog()


func load_estate_map_catalog() -> EstateMapCatalogDecodeResult:
	return _files.load_estate_map_catalog()


func load_trade_offer_catalog(
	_game_catalog: GameCatalog,
) -> TradeOfferCatalogDecodeResult:
	return TradeOfferCatalogDecodeResult.invalid([
		DataValidationIssue.new(
			"tradeOffers",
			"injected invalid trade catalog",
		),
	])
