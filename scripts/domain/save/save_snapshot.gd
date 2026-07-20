class_name SaveSnapshot
extends RefCounted

const SCHEMA_VERSION: int = 1
const PROFILE_IDS: Array[StringName] = [&"profile-1", &"profile-2", &"profile-3"]


class Player extends RefCounted:
	var anchor_id: StringName
	var position: Vector2
	var facing: StringName
	var health: int


	func _init(
		state_anchor_id: StringName,
		state_position: Vector2,
		state_facing: StringName,
		state_health: int,
	) -> void:
		anchor_id = state_anchor_id
		position = state_position
		facing = state_facing
		health = state_health


class Relationship extends RefCounted:
	var npc_id: StringName
	var affinity: int
	var relationship_state: StringName


	func _init(
		state_npc_id: StringName,
		state_affinity: int,
		state_relationship_state: StringName,
	) -> void:
		npc_id = state_npc_id
		affinity = state_affinity
		relationship_state = state_relationship_state


class MineRun extends RefCounted:
	## Zero means no mine run has been recorded yet.
	var world_day: int = 0
	var broken_node_ids: Array[StringName] = []
	var defeated_encounter_ids: Array[StringName] = []


	func _init(
		state_world_day: int = 0,
		state_broken_node_ids: Array[StringName] = [],
		state_defeated_encounter_ids: Array[StringName] = [],
	) -> void:
		world_day = state_world_day
		broken_node_ids = state_broken_node_ids.duplicate()
		defeated_encounter_ids = state_defeated_encounter_ids.duplicate()


var saved_at: String
var profile_id: StringName
var world_day: int
var current_map_id: StringName
var player: Player
var farm: FarmState
var inventory: InventoryState
var story_flags: Dictionary = {}
var relationships: Array[Relationship] = []
var spouse_character_id: StringName
var mine_run: MineRun
