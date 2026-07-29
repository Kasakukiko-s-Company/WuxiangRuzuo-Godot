class_name TradeOfferCatalogFileLoader
extends RefCounted

const DOCUMENT_PATH: String = "res://data/trade_offers.json"


static func load_catalog(
	game_catalog: GameCatalog,
	path: String = DOCUMENT_PATH,
) -> TradeOfferCatalogDecodeResult:
	var issues: Array[DataValidationIssue] = []
	if not FileAccess.file_exists(path):
		issues.append(DataValidationIssue.new(
			"tradeOffers",
			"missing file %s" % path,
		))
		return TradeOfferCatalogDecodeResult.invalid(issues)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		issues.append(DataValidationIssue.new(
			"tradeOffers",
			"JSON parse failed: %s" % json.get_error_message(),
		))
		return TradeOfferCatalogDecodeResult.invalid(issues)
	if not json.data is Dictionary:
		issues.append(DataValidationIssue.new(
			"tradeOffers",
			"root must be an object",
		))
		return TradeOfferCatalogDecodeResult.invalid(issues)
	return TradeOfferCatalogCodec.decode_document(
		json.data as Dictionary,
		game_catalog,
	)
