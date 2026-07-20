class_name FarmTransactionResult
extends RefCounted

enum Status {
	TILLED,
	ALREADY_TILLED,
	NOT_FARMABLE,
}

var status: Status
var farm: FarmState


func _init(result_status: Status, result_farm: FarmState) -> void:
	status = result_status
	farm = result_farm
