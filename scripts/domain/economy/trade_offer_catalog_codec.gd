class_name TradeOfferCatalogCodec
extends RefCounted


static func decode_document(
	document: Dictionary,
	game_catalog: GameCatalog,
) -> TradeOfferCatalogDecodeResult:
	var issues: Array[DataValidationIssue] = []
	if game_catalog == null:
		issues.append(DataValidationIssue.new(
			"offers",
			"validated game catalog is required",
		))
		return TradeOfferCatalogDecodeResult.invalid(issues)
	var schema_version := _read_positive_integer(
		document,
		"schemaVersion",
		"schemaVersion",
		issues,
	)
	if schema_version != TradeOfferCatalog.SCHEMA_VERSION:
		issues.append(DataValidationIssue.new(
			"schemaVersion",
			"expected schema version %d" % TradeOfferCatalog.SCHEMA_VERSION,
		))
	var raw_offers := _read_array(document, "offers", "offers", issues)
	if raw_offers.is_empty():
		issues.append(DataValidationIssue.new(
			"offers",
			"must contain at least one offer",
		))
	var definitions: Array[TradeOfferDefinition] = []
	var seen_ids: Dictionary = {}
	for index: int in raw_offers.size():
		var path := "offers[%d]" % index
		var raw_offer: Variant = raw_offers[index]
		if not raw_offer is Dictionary:
			issues.append(DataValidationIssue.new(path, "must be an object"))
			continue
		var offer := raw_offer as Dictionary
		var offer_id := _read_stable_id(
			offer,
			"id",
			path + ".id",
			issues,
		)
		var endpoint_id := _read_stable_id(
			offer,
			"endpointId",
			path + ".endpointId",
			issues,
		)
		if seen_ids.has(offer_id):
			issues.append(DataValidationIssue.new(
				path + ".id",
				"duplicate offer ID %s" % offer_id,
			))
		elif not offer_id.is_empty():
			seen_ids[offer_id] = true
		var cost := _read_exchange_side(
			offer.get("cost"),
			path + ".cost",
			game_catalog,
			issues,
		)
		var reward := _read_exchange_side(
			offer.get("reward"),
			path + ".reward",
			game_catalog,
			issues,
		)
		var cost_item_id := cost.get("item_id", &"") as StringName
		var reward_item_id := reward.get("item_id", &"") as StringName
		if not cost_item_id.is_empty() and cost_item_id == reward_item_id:
			issues.append(DataValidationIssue.new(
				path,
				"cost and reward must use different items",
			))
		definitions.append(TradeOfferDefinition.new(
			offer_id,
			endpoint_id,
			cost_item_id,
			cost.get("quantity", 0) as int,
			reward_item_id,
			reward.get("quantity", 0) as int,
		))
	if not issues.is_empty():
		return TradeOfferCatalogDecodeResult.invalid(issues)
	var catalog := TradeOfferCatalog.create(definitions, game_catalog)
	if catalog == null:
		issues.append(DataValidationIssue.new(
			"offers",
			"offer catalog failed domain validation",
		))
		return TradeOfferCatalogDecodeResult.invalid(issues)
	return TradeOfferCatalogDecodeResult.valid(catalog)


static func _read_exchange_side(
	value: Variant,
	path: String,
	game_catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> Dictionary:
	if not value is Dictionary:
		issues.append(DataValidationIssue.new(path, "must be an object"))
		return {"item_id": &"", "quantity": 0}
	var side := value as Dictionary
	var item_id := _read_stable_id(
		side,
		"itemId",
		path + ".itemId",
		issues,
	)
	var quantity := _read_positive_integer(
		side,
		"quantity",
		path + ".quantity",
		issues,
	)
	if not item_id.is_empty() and game_catalog.get_item(item_id) == null:
		issues.append(DataValidationIssue.new(
			path + ".itemId",
			"references unknown item %s" % item_id,
		))
	return {"item_id": item_id, "quantity": quantity}


static func _read_array(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> Array:
	var value: Variant = record.get(key)
	if value is Array:
		return value as Array
	issues.append(DataValidationIssue.new(path, "must be an array"))
	return []


static func _read_positive_integer(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> int:
	var value: Variant = record.get(key)
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		var numeric := float(value)
		if is_finite(numeric) and numeric == floor(numeric) and numeric > 0.0:
			return int(numeric)
	issues.append(DataValidationIssue.new(path, "must be a positive integer"))
	return 0


static func _read_stable_id(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> StringName:
	var value: Variant = record.get(key)
	if typeof(value) != TYPE_STRING or String(value).strip_edges().is_empty():
		issues.append(DataValidationIssue.new(
			path,
			"must be a non-empty stable ID",
		))
		return &""
	var text := String(value).strip_edges()
	var pattern := RegEx.new()
	if (
		pattern.compile("^[a-z0-9]+(?:[._-][a-z0-9]+)*$") != OK
		or pattern.search(text) == null
	):
		issues.append(DataValidationIssue.new(
			path,
			"must be a lowercase stable ID",
		))
		return &""
	return StringName(text)
