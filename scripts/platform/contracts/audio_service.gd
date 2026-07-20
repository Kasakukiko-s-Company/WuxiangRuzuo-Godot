@abstract
class_name AudioService
extends RefCounted


@abstract
func play_music(audio_id: StringName) -> void


@abstract
func stop_music() -> void


@abstract
func play_sound(audio_id: StringName) -> void


@abstract
func set_muted(is_muted: bool) -> void
