extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node.new()
	host.name = "AudioHost"
	root.add_child(host)
	var service := GodotAudioService.new(host)
	_check(service.is_ready(), "Godot audio adapter loads the versioned audio catalog")
	_check(
		service.get_registered_cue_count() == 9,
		"Godot audio adapter registers one music cue and eight P2 sound cues",
	)
	_check(
		host.get_child_count() == 5,
		"Godot audio adapter creates one music player and a four-player SFX pool",
	)
	var till_stream := load(
		"res://assets/audio/p2/farm_till.wav"
	) as AudioStreamWAV
	_check(
		till_stream != null
		and till_stream.stereo
		and till_stream.mix_rate == 48000
		and absf(till_stream.get_length() - 1.2) < 0.03,
		"selected till SFX imports as 48 kHz stereo with the expected duration",
	)
	var music_stream := load(
		"res://assets/audio/p2/h01_spring_day.mp3"
	) as AudioStreamMP3
	_check(
		music_stream != null
		and absf(music_stream.get_length() - 60.0) < 0.1,
		"H01 music imports as the expected sixty-second MP3",
	)
	service.play_music(&"music.h01.spring_day")
	_check(
		service.get_current_music_id() == &"music.h01.spring_day",
		"Godot audio adapter resolves the stable H01 music ID",
	)
	service.play_sound(&"sfx.farm.till")
	service.play_sound(&"sfx.farm.water")
	_check(
		service.get_last_sound_id() == &"sfx.farm.water",
		"Godot audio adapter resolves typed sound IDs through its player pool",
	)
	service.set_muted(true)
	_check(service.is_muted(), "Godot audio adapter exposes deterministic mute state")
	service.set_muted(false)
	_check(not service.is_muted(), "Godot audio adapter restores unmuted state")
	service.stop_music()
	_check(
		service.get_current_music_id() == &"",
		"Godot audio adapter clears its active music cue",
	)
	var invalid_catalog_path := "user://p2_invalid_audio_catalog.json"
	var invalid_catalog := FileAccess.open(
		invalid_catalog_path,
		FileAccess.WRITE,
	)
	invalid_catalog.store_string(JSON.stringify({
		"schemaVersion": 1,
		"cues": [
			{
				"id": "sfx.valid.before.failure",
				"kind": "sound",
				"godotPath": "res://assets/audio/p2/farm_till.wav",
			},
			{
				"id": "sfx.invalid",
				"kind": "sound",
				"godotPath": "res://assets/audio/p2/missing.wav",
			},
		],
	}))
	invalid_catalog.close()
	var invalid_host := Node.new()
	root.add_child(invalid_host)
	var invalid_service := GodotAudioService.new(
		invalid_host,
		invalid_catalog_path,
	)
	_check(
		not invalid_service.is_ready()
		and invalid_service.get_registered_cue_count() == 0,
		"catalog validation fails atomically without partially registered cues",
	)
	DirAccess.remove_absolute(
		ProjectSettings.globalize_path(invalid_catalog_path)
	)

	host.queue_free()
	invalid_host.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_GODOT_AUDIO_SERVICE_OK")
		quit(0)
		return
	push_error("P2 Godot audio service test failed: %d check(s)" % _failures)
	quit(1)
