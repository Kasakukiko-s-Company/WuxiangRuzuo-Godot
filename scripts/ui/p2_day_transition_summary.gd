class_name P2DayTransitionSummary
extends RefCounted

var completed_day: int
var new_day: int
var grown_crop_count: int


func _init(
	p_completed_day: int,
	p_new_day: int,
	p_grown_crop_count: int,
) -> void:
	assert(p_completed_day > 0, "completed day must be positive")
	assert(
		p_new_day == p_completed_day + 1,
		"day transition must advance exactly one day",
	)
	assert(p_grown_crop_count >= 0, "grown crop count must not be negative")
	completed_day = p_completed_day
	new_day = p_new_day
	grown_crop_count = p_grown_crop_count


func completed_day_text() -> String:
	return "第 %d 天结束" % completed_day


func growth_text() -> String:
	if grown_crop_count == 0:
		return "今夜田地静静休息"
	return "雾露滋养了 %d 株作物" % grown_crop_count


func dawn_text() -> String:
	return "第 %d 天 · 清晨" % new_day
