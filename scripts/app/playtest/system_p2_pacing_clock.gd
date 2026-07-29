class_name SystemP2PacingClock
extends P2PacingClock


func now_msec() -> int:
	return Time.get_ticks_msec()
