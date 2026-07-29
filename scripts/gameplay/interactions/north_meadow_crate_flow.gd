class_name NorthMeadowCrateFlow
extends RefCounted

enum Intent {
	OPEN_OR_CONFIRM,
	PREVIOUS,
	NEXT,
	CANCEL,
}

const SELL_OFFER_ID: StringName = &"economy.h01.sell_mistleaf"
const BUY_OFFER_ID: StringName = &"economy.h01.buy_mistleaf_seed"

var _sources: DailyResourceSourceCatalog
var _trade_book: TradeBook
var _game_catalog: GameCatalog
var _seed_source_id: StringName
var _forage_source_id: StringName
var _endpoint_id: StringName
var _trade_offers: Array[TradeOfferDefinition] = []
var _is_open: bool = false
var _open_day: int = 0
var _selected_index: int = 0


func _init(
	source_catalog: DailyResourceSourceCatalog,
	trade_book: TradeBook,
	game_catalog: GameCatalog,
	seed_source_id: StringName,
	forage_source_id: StringName,
	endpoint_id: StringName,
) -> void:
	assert(source_catalog != null, "crate flow requires resource definitions")
	assert(trade_book != null, "crate flow requires a trade book")
	assert(game_catalog != null, "crate flow requires the game catalog")
	assert(
		source_catalog.get_source(seed_source_id) != null,
		"crate flow requires its seed source",
	)
	assert(
		source_catalog.get_source(forage_source_id) != null,
		"crate flow requires its forage source",
	)
	_sources = source_catalog
	_trade_book = trade_book
	_game_catalog = game_catalog
	_seed_source_id = seed_source_id
	_forage_source_id = forage_source_id
	_endpoint_id = endpoint_id
	_trade_offers = _ordered_trade_offers(_trade_book.offers(endpoint_id))
	assert(
		_trade_offers.size() == 2,
		"north-meadow crate requires its two validated trade offers",
	)


## The menu is transient: every intent recomputes enabled actions from the
## latest immutable session/claims. A day change invalidates the old cursor.
## Only successful delegated domain transactions may replace persistent state;
## recoverable failures retain the menu and return the original references.
func advance(
	intent: Intent,
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> NorthMeadowCrateResult:
	assert(session != null, "crate flow requires a farming session")
	assert(claims != null, "crate flow requires daily claims")
	if _is_open and _open_day != session.world_day:
		_close()
	if intent == Intent.CANCEL:
		_close()
		return _result(
			NorthMeadowCrateResult.Outcome.CANCELLED,
			session,
			claims,
			"",
		)
	if not _is_open:
		if intent != Intent.OPEN_OR_CONFIRM:
			return _result(
				NorthMeadowCrateResult.Outcome.CLOSED,
				session,
				claims,
				"",
			)
		_is_open = true
		_open_day = session.world_day
		var opening_actions := _build_actions(session, claims)
		_selected_index = _first_enabled_index(opening_actions)
		return _result(
			NorthMeadowCrateResult.Outcome.OPENED,
			session,
			claims,
			_open_message(opening_actions[_selected_index]),
		)

	var actions := _build_actions(session, claims)
	if actions.is_empty():
		_close()
		return _result(
			NorthMeadowCrateResult.Outcome.UNAVAILABLE,
			session,
			claims,
			"北草甸物资箱当前没有可用行动",
		)
	_selected_index = clampi(_selected_index, 0, actions.size() - 1)
	if intent == Intent.PREVIOUS or intent == Intent.NEXT:
		var offset := -1 if intent == Intent.PREVIOUS else 1
		_selected_index = posmod(_selected_index + offset, actions.size())
		return _result(
			NorthMeadowCrateResult.Outcome.SELECTION_CHANGED,
			session,
			claims,
			_open_message(actions[_selected_index]),
		)
	return _confirm(actions[_selected_index], session, claims)


func presentation(
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> NorthMeadowCratePresentation:
	if _is_open and _open_day != session.world_day:
		_close()
	return _presentation(session, claims)


func _confirm(
	action: NorthMeadowCrateAction,
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> NorthMeadowCrateResult:
	if action.kind == NorthMeadowCrateAction.Kind.DAILY_RESOURCE:
		return _confirm_resource(action, session, claims)
	return _confirm_trade(action, session, claims)


func _confirm_resource(
	action: NorthMeadowCrateAction,
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> NorthMeadowCrateResult:
	var gathering := DailyResourceGathering.attempt(
		session,
		claims,
		DailyResourceGatheringCommand.new(
			action.definition_id,
			session.world_day,
		),
		_sources,
		_game_catalog,
	)
	if gathering.status == DailyResourceGatheringResult.Status.COLLECTED:
		_close()
		return _result(
			NorthMeadowCrateResult.Outcome.CLAIMED,
			gathering.session,
			gathering.claims,
			"北草甸物资已领取 · %s" % action.label,
			&"resource.claimed",
			&"sfx.resource.gather",
			action.definition_id,
		)
	if gathering.status == DailyResourceGatheringResult.Status.INVENTORY_FULL:
		return _result(
			NorthMeadowCrateResult.Outcome.INVENTORY_FULL,
			session,
			claims,
			"背包无法容纳该选项；资格保留，可切换其他行动",
		)
	return _result(
		NorthMeadowCrateResult.Outcome.UNAVAILABLE,
		session,
		claims,
		"该每日资源当前不可领取",
	)


func _confirm_trade(
	action: NorthMeadowCrateAction,
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> NorthMeadowCrateResult:
	var trade := _trade_book.execute(
		session.state.inventory,
		TradeCommand.new(_endpoint_id, action.definition_id),
	)
	if trade.status == TradeResult.Status.COMPLETED:
		var next_session := session.with_inventory(trade.inventory)
		_close()
		return _result(
			NorthMeadowCrateResult.Outcome.TRADED,
			next_session,
			claims,
			"交换完成 · %s" % action.label,
			&"economy.traded",
			&"sfx.trade.exchange",
			action.definition_id,
		)
	if trade.status == TradeResult.Status.INSUFFICIENT_COST:
		return _result(
			NorthMeadowCrateResult.Outcome.INSUFFICIENT_COST,
			session,
			claims,
			"交换所需物品不足 · %s" % action.label,
		)
	if trade.status == TradeResult.Status.REWARD_CAPACITY:
		return _result(
			NorthMeadowCrateResult.Outcome.REWARD_CAPACITY,
			session,
			claims,
			"背包没有空间容纳交换所得",
		)
	return _result(
		NorthMeadowCrateResult.Outcome.UNAVAILABLE,
		session,
		claims,
		"该交换项目当前不可用",
	)


func _result(
	outcome: NorthMeadowCrateResult.Outcome,
	session: FarmingSessionState,
	claims: DailyResourceClaims,
	message: String,
	durable_reason: StringName = &"",
	audio_id: StringName = &"",
	committed_action_id: StringName = &"",
) -> NorthMeadowCrateResult:
	return NorthMeadowCrateResult.new(
		outcome,
		session,
		claims,
		_presentation(session, claims),
		message,
		durable_reason,
		audio_id,
		committed_action_id,
	)


func _presentation(
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> NorthMeadowCratePresentation:
	var actions := _build_actions(session, claims)
	var selected := -1
	if _is_open and not actions.is_empty():
		_selected_index = clampi(_selected_index, 0, actions.size() - 1)
		selected = _selected_index
	return NorthMeadowCratePresentation.new(
		_is_open,
		_daily_claim_available(session, claims),
		actions,
		selected,
	)


## Stable ordering is part of the H01 interaction contract. Daily actions
## disappear only after a successful claim; trade actions are always present.
func _build_actions(
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> Array[NorthMeadowCrateAction]:
	var actions: Array[NorthMeadowCrateAction] = []
	if _daily_claim_available(session, claims):
		actions.append(_resource_action(_seed_source_id, session, claims))
		actions.append(_resource_action(_forage_source_id, session, claims))
	for offer: TradeOfferDefinition in _trade_offers:
		actions.append(_trade_action(offer, session))
	return actions


func _resource_action(
	source_id: StringName,
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> NorthMeadowCrateAction:
	var source := _sources.get_source(source_id)
	var attempt := DailyResourceGathering.attempt(
		session,
		claims,
		DailyResourceGatheringCommand.new(source_id, session.world_day),
		_sources,
		_game_catalog,
	)
	var enabled := (
		attempt.status == DailyResourceGatheringResult.Status.COLLECTED
	)
	return NorthMeadowCrateAction.new(
		NorthMeadowCrateAction.Kind.DAILY_RESOURCE,
		(
			NorthMeadowCrateAction.VisualRole.DAILY_SEED
			if source_id == _seed_source_id
			else NorthMeadowCrateAction.VisualRole.DAILY_FORAGE
		),
		source_id,
		"%s ×%d（每日）" % [
			_item_display_name(source.item_id),
			source.quantity,
		],
		enabled,
		&"" if enabled else _resource_blocked_reason(attempt.status),
	)


func _trade_action(
	offer: TradeOfferDefinition,
	session: FarmingSessionState,
) -> NorthMeadowCrateAction:
	var attempt := _trade_book.execute(
		session.state.inventory,
		TradeCommand.new(_endpoint_id, offer.id),
	)
	var enabled := attempt.status == TradeResult.Status.COMPLETED
	return NorthMeadowCrateAction.new(
		NorthMeadowCrateAction.Kind.TRADE,
		(
			NorthMeadowCrateAction.VisualRole.TRADE_SELL
			if offer.id == SELL_OFFER_ID
			else NorthMeadowCrateAction.VisualRole.TRADE_BUY
		),
		offer.id,
		"%s ×%d → %s ×%d" % [
			_item_display_name(offer.cost_item_id),
			offer.cost_quantity,
			_item_display_name(offer.reward_item_id),
			offer.reward_quantity,
		],
		enabled,
		&"" if enabled else _trade_blocked_reason(attempt.status),
	)


func _daily_claim_available(
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> bool:
	var source := _sources.get_source(_seed_source_id)
	return claims.last_claimed_day(source.claim_key()) < session.world_day


func _first_enabled_index(
	actions: Array[NorthMeadowCrateAction],
) -> int:
	for index: int in actions.size():
		if actions[index].enabled:
			return index
	return 0


func _ordered_trade_offers(
	offers: Array[TradeOfferDefinition],
) -> Array[TradeOfferDefinition]:
	var ordered: Array[TradeOfferDefinition] = []
	for expected_id: StringName in [SELL_OFFER_ID, BUY_OFFER_ID]:
		for offer: TradeOfferDefinition in offers:
			if offer.id == expected_id:
				ordered.append(offer)
				break
	return ordered


func _resource_blocked_reason(
	status: DailyResourceGatheringResult.Status,
) -> StringName:
	if status == DailyResourceGatheringResult.Status.INVENTORY_FULL:
		return &"inventory_full"
	if status == DailyResourceGatheringResult.Status.ALREADY_COLLECTED:
		return &"already_claimed"
	return &"unavailable"


func _trade_blocked_reason(status: TradeResult.Status) -> StringName:
	if status == TradeResult.Status.INSUFFICIENT_COST:
		return &"insufficient_cost"
	if status == TradeResult.Status.REWARD_CAPACITY:
		return &"reward_capacity"
	return &"unavailable"


func _item_display_name(item_id: StringName) -> String:
	var item := _game_catalog.get_item(item_id)
	if item == null:
		return String(item_id)
	return _game_catalog.get_localized_text(item.display_name_key)


func _open_message(action: NorthMeadowCrateAction) -> String:
	var state := (
		""
		if action.enabled
		else "（不可执行：%s）" % action.blocked_reason_label()
	)
	return "北草甸物资箱 · %s%s · Q/Tab 切换 · E/A 确认" % [
		action.label,
		state,
	]

func _close() -> void:
	_is_open = false
	_open_day = 0
	_selected_index = 0
