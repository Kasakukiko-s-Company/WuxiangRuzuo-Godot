@abstract
class_name PlatformService
extends RefCounted

enum LifecycleState {
	ACTIVE,
	BACKGROUND,
}


@abstract
func descriptor() -> PlatformDescriptor


@abstract
func safe_area() -> SafeAreaInsets


## Returns a callable that removes this subscription.
@abstract
func subscribe_lifecycle(listener: Callable) -> Callable
