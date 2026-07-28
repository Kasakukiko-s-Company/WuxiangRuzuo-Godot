class_name GodotAudioService
extends AudioService

const DEFAULT_CATALOG_PATH: String = "res://data/audio_catalog.json"
const SOUND_PLAYER_COUNT: int = 4

var _cues: Dictionary[StringName, Dictionary] = {}
var _music_player: AudioStreamPlayer
var _sound_players: Array[AudioStreamPlayer] = []
var _sound_cursor: int = 0
var _muted: bool = false
var _playback_enabled: bool = false
var _ready: bool = false
var _current_music_id: StringName = &""
var _last_sound_id: StringName = &""


func _init(host: Node, catalog_path: String = DEFAULT_CATALOG_PATH) -> void:
	assert(host != null, "GodotAudioService requires a host Node")
	_playback_enabled = DisplayServer.get_name() != "headless"
	_ready = _load_catalog(catalog_path)
	_music_player = _create_player(host, "Music")
	for index: int in SOUND_PLAYER_COUNT:
		_sound_players.append(
			_create_player(host, "Sound%02d" % (index + 1))
		)


func play_music(audio_id: StringName) -> void:
	var cue: Dictionary = _cues.get(audio_id, {})
	if cue.is_empty() or cue["kind"] != &"music":
		push_warning("Unknown or non-music audio cue: %s" % audio_id)
		return
	_current_music_id = audio_id
	_music_player.stream = cue["stream"]
	_music_player.volume_db = _effective_volume(cue["volume_db"])
	if _playback_enabled and not _muted:
		_music_player.play()


func stop_music() -> void:
	_current_music_id = &""
	if _music_player != null:
		_music_player.stop()


func play_sound(audio_id: StringName) -> void:
	var cue: Dictionary = _cues.get(audio_id, {})
	if cue.is_empty() or cue["kind"] != &"sound":
		push_warning("Unknown or non-sound audio cue: %s" % audio_id)
		return
	_last_sound_id = audio_id
	var player: AudioStreamPlayer = _sound_players[_sound_cursor]
	_sound_cursor = (_sound_cursor + 1) % _sound_players.size()
	player.stream = cue["stream"]
	player.volume_db = _effective_volume(cue["volume_db"])
	if _playback_enabled and not _muted:
		player.play()


func set_muted(is_muted: bool) -> void:
	var was_muted := _muted
	_muted = is_muted
	if _music_player != null:
		var music_cue: Dictionary = _cues.get(_current_music_id, {})
		var music_volume: float = 0.0
		if not music_cue.is_empty():
			music_volume = music_cue["volume_db"]
		_music_player.volume_db = _effective_volume(music_volume)
		if (
			was_muted
			and not _muted
			and _playback_enabled
			and _current_music_id != &""
			and _music_player.stream != null
			and not _music_player.playing
		):
			_music_player.play()
	for player: AudioStreamPlayer in _sound_players:
		if _muted:
			player.stop()


func is_ready() -> bool:
	return _ready


func get_registered_cue_count() -> int:
	return _cues.size()


func get_current_music_id() -> StringName:
	return _current_music_id


func get_last_sound_id() -> StringName:
	return _last_sound_id


func is_muted() -> bool:
	return _muted


func _load_catalog(catalog_path: String) -> bool:
	if not FileAccess.file_exists(catalog_path):
		push_error("Audio catalog does not exist: %s" % catalog_path)
		return false
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(catalog_path)
	)
	if not parsed is Dictionary:
		push_error("Audio catalog root must be a Dictionary")
		return false
	var root: Dictionary = parsed
	if root.get("schemaVersion", 0) != 1:
		push_error("Unsupported audio catalog schemaVersion")
		return false
	var raw_cues: Variant = root.get("cues", [])
	if not raw_cues is Array:
		push_error("Audio catalog cues must be an Array")
		return false
	var loaded_cues: Dictionary[StringName, Dictionary] = {}
	for raw_cue: Variant in raw_cues:
		if not _register_cue(raw_cue, loaded_cues):
			return false
	_cues = loaded_cues
	return not _cues.is_empty()


func _register_cue(
	raw_cue: Variant,
	target_cues: Dictionary[StringName, Dictionary],
) -> bool:
	if not raw_cue is Dictionary:
		push_error("Audio catalog cue must be a Dictionary")
		return false
	var cue: Dictionary = raw_cue
	var audio_id := StringName(String(cue.get("id", "")))
	var kind := StringName(String(cue.get("kind", "")))
	var godot_path := String(cue.get("godotPath", ""))
	if audio_id == &"" or target_cues.has(audio_id):
		push_error("Audio catalog cue ID is missing or duplicated: %s" % audio_id)
		return false
	if kind != &"music" and kind != &"sound":
		push_error("Audio catalog cue kind is invalid: %s" % kind)
		return false
	if godot_path.is_empty() or not ResourceLoader.exists(godot_path):
		push_error("Audio catalog resource is unavailable: %s" % godot_path)
		return false
	var stream := load(godot_path) as AudioStream
	if stream == null:
		push_error("Audio catalog resource is not an AudioStream: %s" % godot_path)
		return false
	var runtime_stream := stream.duplicate(true) as AudioStream
	if runtime_stream == null:
		push_error("Audio catalog stream could not be duplicated: %s" % godot_path)
		return false
	var looped := bool(cue.get("loop", false))
	if runtime_stream is AudioStreamMP3:
		(runtime_stream as AudioStreamMP3).loop = looped
	elif runtime_stream is AudioStreamWAV:
		var wav := runtime_stream as AudioStreamWAV
		wav.loop_mode = (
			AudioStreamWAV.LOOP_FORWARD
			if looped
			else AudioStreamWAV.LOOP_DISABLED
		)
		if looped:
			wav.loop_begin = 0
			wav.loop_end = wav.data.size() / 4
	target_cues[audio_id] = {
		"kind": kind,
		"stream": runtime_stream,
		"volume_db": float(cue.get("volumeDb", 0.0)),
	}
	return true


func _create_player(host: Node, player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	host.add_child(player)
	return player


func _effective_volume(configured_volume_db: float) -> float:
	return -80.0 if _muted else configured_volume_db
