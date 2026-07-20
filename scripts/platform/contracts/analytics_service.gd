@abstract
class_name AnalyticsService
extends RefCounted


## Properties are restricted by adapters to String, number, or bool values.
@abstract
func track(event_name: StringName, properties: Dictionary = {}) -> void
