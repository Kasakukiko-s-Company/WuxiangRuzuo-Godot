@abstract
class_name SaveService
extends RefCounted

## Platform code stores only opaque payloads; it never owns SaveSnapshot rules.
@abstract
func read(slot_id: StringName) -> SaveReadResult


## Returns the storage adapter's previous physical version, if it has one.
## Application code still validates the opaque payload through SaveCodec.
@abstract
func read_previous(slot_id: StringName) -> SaveReadResult


@abstract
func write(slot_id: StringName, payload: String) -> SaveWriteResult


@abstract
func remove(slot_id: StringName) -> SaveWriteResult
