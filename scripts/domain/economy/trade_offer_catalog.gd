class_name TradeOfferCatalog
extends RefCounted

const SCHEMA_VERSION: int = 1

var offers: Array[TradeOfferDefinition]:
	get:
		return _offers.duplicate()
	set(_attempted_value):
		push_error("TradeOfferCatalog.offers is read-only")
var _offers: Array[TradeOfferDefinition] = []
var _offers_by_id: Dictionary = {}
var _offers_by_endpoint: Dictionary = {}


static func create(
	definitions: Array[TradeOfferDefinition],
	game_catalog: GameCatalog,
) -> TradeOfferCatalog:
	if game_catalog == null or definitions.is_empty():
		return null
	var seen_ids: Dictionary = {}
	for definition: TradeOfferDefinition in definitions:
		if not _is_valid_definition(definition, game_catalog, seen_ids):
			return null
		seen_ids[definition.id] = true
	var catalog := TradeOfferCatalog.new()
	catalog._offers = definitions.duplicate()
	for definition: TradeOfferDefinition in catalog._offers:
		catalog._offers_by_id[definition.id] = definition
		if not catalog._offers_by_endpoint.has(definition.endpoint_id):
			catalog._offers_by_endpoint[definition.endpoint_id] = []
		var endpoint_offers: Array = catalog._offers_by_endpoint[definition.endpoint_id]
		endpoint_offers.append(definition)
	return catalog


func get_offer(offer_id: StringName) -> TradeOfferDefinition:
	return _offers_by_id.get(offer_id) as TradeOfferDefinition


func offers_for_endpoint(
	endpoint_id: StringName,
) -> Array[TradeOfferDefinition]:
	var result: Array[TradeOfferDefinition] = []
	var stored: Array = _offers_by_endpoint.get(endpoint_id, [])
	for value: Variant in stored:
		result.append(value as TradeOfferDefinition)
	return result


static func _is_valid_definition(
	definition: TradeOfferDefinition,
	game_catalog: GameCatalog,
	seen_ids: Dictionary,
) -> bool:
	return (
		definition != null
		and _is_stable_id(definition.id)
		and _is_stable_id(definition.endpoint_id)
		and _is_stable_id(definition.cost_item_id)
		and definition.cost_quantity > 0
		and _is_stable_id(definition.reward_item_id)
		and definition.reward_quantity > 0
		and definition.cost_item_id != definition.reward_item_id
		and game_catalog.get_item(definition.cost_item_id) != null
		and game_catalog.get_item(definition.reward_item_id) != null
		and not seen_ids.has(definition.id)
	)


static func _is_stable_id(id: StringName) -> bool:
	if id.is_empty():
		return false
	var pattern := RegEx.new()
	return (
		pattern.compile("^[a-z0-9]+(?:[._-][a-z0-9]+)*$") == OK
		and pattern.search(String(id)) != null
	)
