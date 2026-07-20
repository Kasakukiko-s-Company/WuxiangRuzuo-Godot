class_name PlatformDescriptor
extends RefCounted

enum RuntimeEnvironment {
	WINDOWS_NATIVE,
	WEB,
}

enum DistributionChannel {
	STANDALONE,
	STEAM,
	WECHAT,
}

var runtime_environment: RuntimeEnvironment
var distribution_channel: DistributionChannel


static func create(
	runtime: RuntimeEnvironment,
	distribution: DistributionChannel,
) -> PlatformDescriptor:
	var is_valid := (
		(runtime == RuntimeEnvironment.WINDOWS_NATIVE and distribution != DistributionChannel.WECHAT)
		or (runtime == RuntimeEnvironment.WEB and distribution != DistributionChannel.STEAM)
	)
	if not is_valid:
		return null
	var descriptor := PlatformDescriptor.new()
	descriptor.runtime_environment = runtime
	descriptor.distribution_channel = distribution
	return descriptor


func runtime_id() -> StringName:
	match runtime_environment:
		RuntimeEnvironment.WINDOWS_NATIVE:
			return &"windows-native"
		RuntimeEnvironment.WEB:
			return &"web"
		_:
			return &""


func distribution_id() -> StringName:
	match distribution_channel:
		DistributionChannel.STANDALONE:
			return &"standalone"
		DistributionChannel.STEAM:
			return &"steam"
		DistributionChannel.WECHAT:
			return &"wechat"
		_:
			return &""
