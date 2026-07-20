@abstract
class_name SaveService
extends RefCounted

## Platform code stores only opaque payloads; it never owns SaveSnapshot rules.
@abstract
func read(slot_id: StringName) -> SaveReadResult


@abstract
func write(slot_id: StringName, payload: String) -> SaveWriteResult


@abstract
func remove(slot_id: StringName) -> SaveWriteResult
