class_name FileAppCatalogSource
extends AppCatalogSource


func load_game_catalog() -> CatalogDecodeResult:
	return CatalogFileLoader.load_catalog()


func load_estate_map_catalog() -> EstateMapCatalogDecodeResult:
	return EstateMapCatalogFileLoader.load_catalog()


func load_trade_offer_catalog(
	game_catalog: GameCatalog,
) -> TradeOfferCatalogDecodeResult:
	return TradeOfferCatalogFileLoader.load_catalog(game_catalog)
