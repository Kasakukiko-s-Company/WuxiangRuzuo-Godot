extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var panel_scene := load(
		"res://scenes/ui/p2_crate_choice_panel.tscn"
	) as PackedScene
	_check(
		panel_scene != null,
		"crate choice panel is a reusable packed scene",
	)
	if panel_scene == null:
		_finish()
		return
	var panel := panel_scene.instantiate() as P2CrateChoicePanel
	root.add_child(panel)
	await process_frame

	var actions := _four_actions()
	panel.present(NorthMeadowCratePresentation.new(
		true,
		true,
		actions,
		2,
	))
	await process_frame
	_check(
		panel.is_open()
		and panel.get_visible_action_count() == 4
		and panel.get_selected_action_id()
		== &"economy.h01.sell_mistleaf",
		"open presentation renders all four actions and exact selection",
	)
	_check(
		panel.get_header_text().contains("今日资源可领取")
		and panel.get_card_text(0).contains("雾叶草种子 ×3")
		and panel.get_card_text(2).contains("雾叶 ×1 → 村社券 ×30")
		and panel.get_selected_status_text().contains("可执行"),
		"panel exposes the complete daily and trade choice without status-line truncation",
	)
	var viewport_rect := Rect2(Vector2.ZERO, panel.size)
	var cards_inside_viewport: bool = true
	for card_index: int in panel.get_visible_action_count():
		var card_rect := panel.get_card_rect(card_index)
		if not viewport_rect.encloses(card_rect):
			cards_inside_viewport = false
			break
	_check(
		cards_inside_viewport,
		"all four action cards fit inside the 640x360 logical viewport",
	)

	panel.present(NorthMeadowCratePresentation.new(
		true,
		true,
		actions,
		3,
	))
	_check(
		panel.get_selected_status_text().contains("所需物品不足")
		and panel.get_card_text(3).contains("暂不可执行"),
		"disabled selection translates its stable blocked reason visibly",
	)

	var trade_actions: Array[NorthMeadowCrateAction] = [
		actions[2],
		actions[3],
	]
	panel.present(NorthMeadowCratePresentation.new(
		true,
		false,
		trade_actions,
		0,
	))
	await process_frame
	_check(
		panel.get_visible_action_count() == 2
		and panel.get_header_text().contains("今日资源已领取")
		and panel.get_selected_action_id()
		== &"economy.h01.sell_mistleaf",
		"post-claim presentation collapses cleanly to its two trade actions",
	)

	panel.present(NorthMeadowCratePresentation.new(
		false,
		false,
		trade_actions,
		-1,
	))
	_check(
		not panel.is_open(),
		"closed presentation removes the transient choice panel",
	)

	panel.queue_free()
	await process_frame
	_finish()


func _four_actions() -> Array[NorthMeadowCrateAction]:
	return [
		NorthMeadowCrateAction.new(
			NorthMeadowCrateAction.Kind.DAILY_RESOURCE,
			NorthMeadowCrateAction.VisualRole.DAILY_SEED,
			&"home.h01.resource.north_meadow",
			"雾叶草种子 ×3（每日）",
			true,
		),
		NorthMeadowCrateAction.new(
			NorthMeadowCrateAction.Kind.DAILY_RESOURCE,
			NorthMeadowCrateAction.VisualRole.DAILY_FORAGE,
			&"home.h01.resource.north_meadow.forage",
			"雾叶 ×1（每日）",
			true,
		),
		NorthMeadowCrateAction.new(
			NorthMeadowCrateAction.Kind.TRADE,
			NorthMeadowCrateAction.VisualRole.TRADE_SELL,
			&"economy.h01.sell_mistleaf",
			"雾叶 ×1 → 村社券 ×30",
			true,
		),
		NorthMeadowCrateAction.new(
			NorthMeadowCrateAction.Kind.TRADE,
			NorthMeadowCrateAction.VisualRole.TRADE_BUY,
			&"economy.h01.buy_mistleaf_seed",
			"村社券 ×20 → 雾叶草种子 ×1",
			false,
			&"insufficient_cost",
		),
	]


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_CRATE_CHOICE_PANEL_OK")
		quit(0)
		return
	push_error("P2 crate choice panel test failed: %d check(s)" % _failures)
	quit(1)
