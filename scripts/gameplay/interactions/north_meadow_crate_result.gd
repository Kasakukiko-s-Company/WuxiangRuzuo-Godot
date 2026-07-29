class_name NorthMeadowCrateResult
extends RefCounted

enum Outcome {
	OPENED,
	SELECTION_CHANGED,
	CANCELLED,
	CLOSED,
	CLAIMED,
	TRADED,
	INVENTORY_FULL,
	INSUFFICIENT_COST,
	REWARD_CAPACITY,
	UNAVAILABLE,
}

var outcome: Outcome
var session: FarmingSessionState
var claims: DailyResourceClaims
var presentation: NorthMeadowCratePresentation
var durable_reason: StringName
var audio_id: StringName
var committed_action_id: StringName
var message: String


func _init(
	result_outcome: Outcome,
	result_session: FarmingSessionState,
	result_claims: DailyResourceClaims,
	result_presentation: NorthMeadowCratePresentation,
	result_message: String,
	result_durable_reason: StringName = &"",
	result_audio_id: StringName = &"",
	result_committed_action_id: StringName = &"",
) -> void:
	assert(result_session != null, "crate results require a farming session")
	assert(result_claims != null, "crate results require daily claims")
	assert(result_presentation != null, "crate results require a presentation")
	outcome = result_outcome
	session = result_session
	claims = result_claims
	presentation = result_presentation
	message = result_message
	durable_reason = result_durable_reason
	audio_id = result_audio_id
	committed_action_id = result_committed_action_id
