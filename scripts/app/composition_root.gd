class_name AppCompositionRoot
extends RefCounted

## G1 application assembly seam. Concrete platform services arrive in later milestones.
enum RuntimeEnvironment {
	WINDOWS_NATIVE,
	WEB,
}

enum DistributionChannel {
	STANDALONE,
	STEAM,
	WECHAT,
}

const LOGICAL_VIEWPORT: Vector2i = Vector2i(640, 360)

var runtime_environment: RuntimeEnvironment = RuntimeEnvironment.WINDOWS_NATIVE
var distribution_channel: DistributionChannel = DistributionChannel.STANDALONE


func bootstrap() -> String:
	return "composition root ready · 640×360 · compatibility renderer"
