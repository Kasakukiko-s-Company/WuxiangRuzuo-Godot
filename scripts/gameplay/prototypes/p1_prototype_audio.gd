class_name P1PrototypeAudio
extends Node

const MIX_RATE: int = 22050

var _ambient_player: AudioStreamPlayer
var _interaction_player: AudioStreamPlayer
var _footstep_player: AudioStreamPlayer
var _last_footstep_msec: int = 0
var _playback_enabled: bool = false


func _ready() -> void:
	_playback_enabled = DisplayServer.get_name() != "headless"
	_ambient_player = _create_player("Ambient", -22.0)
	_interaction_player = _create_player("Interaction", -12.0)
	_footstep_player = _create_player("Footstep", -18.0)
	_ambient_player.stream = _generate_wave(2.0, &"ambient", true)
	_interaction_player.stream = _generate_wave(0.38, &"interaction", false)
	_footstep_player.stream = _generate_wave(0.09, &"footstep", false)
	# Headless verification has no audible output and can terminate before the
	# audio server receives a cleanup frame. Keep samples available to tests,
	# but only start playback when a real display/runtime is present.
	if _playback_enabled:
		_ambient_player.play()


func _exit_tree() -> void:
	_stop_and_release(_ambient_player)
	_stop_and_release(_interaction_player)
	_stop_and_release(_footstep_player)


func play_interaction() -> void:
	if not _playback_enabled:
		return
	_interaction_player.play()


func set_walking(walking: bool) -> void:
	if not _playback_enabled or not walking:
		return
	var now := Time.get_ticks_msec()
	if now - _last_footstep_msec < 310:
		return
	_last_footstep_msec = now
	_footstep_player.pitch_scale = 0.94 + float((now / 310) % 3) * 0.04
	_footstep_player.play()


func get_generated_sample_count() -> int:
	var total_bytes: int = 0
	for player in [_ambient_player, _interaction_player, _footstep_player]:
		if player != null and player.stream is AudioStreamWAV:
			total_bytes += (player.stream as AudioStreamWAV).data.size()
	return total_bytes / 2


func _create_player(player_name: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = volume_db
	add_child(player)
	return player


func _stop_and_release(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.stream = null


func _generate_wave(duration: float, kind: StringName, looped: bool) -> AudioStreamWAV:
	var sample_count := maxi(roundi(duration * float(MIX_RATE)), 1)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time := float(sample_index) / float(MIX_RATE)
		var sample := _sample_value(kind, time, duration, sample_index)
		bytes.encode_s16(sample_index * 2, clampi(roundi(sample * 32767.0), -32768, 32767))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream


func _sample_value(kind: StringName, time: float, duration: float, sample_index: int) -> float:
	if kind == &"ambient":
		var slow_breath := 0.7 + sin(time * TAU * 0.18) * 0.3
		return (
			sin(time * TAU * 110.0) * 0.045
			+ sin(time * TAU * 165.0) * 0.025
			+ sin(time * TAU * 220.0 + 0.7) * 0.012
		) * slow_breath
	if kind == &"interaction":
		var envelope := pow(maxf(1.0 - time / duration, 0.0), 2.0)
		return (sin(time * TAU * 660.0) * 0.12 + sin(time * TAU * 990.0) * 0.05) * envelope
	var step_envelope := pow(maxf(1.0 - time / duration, 0.0), 3.0)
	var deterministic_noise := sin(float(sample_index * 73 % 257) * 1.618)
	return (sin(time * TAU * 88.0) * 0.16 + deterministic_noise * 0.05) * step_envelope
