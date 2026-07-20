extends SceneTree

const PlatformDescriptorScript = preload("res://scripts/platform/contracts/platform_descriptor.gd")
const PlatformServiceScript = preload("res://scripts/platform/contracts/platform_service.gd")
const SaveServiceScript = preload("res://scripts/platform/contracts/save_service.gd")
const InputServiceScript = preload("res://scripts/platform/contracts/input_service.gd")
const AudioServiceScript = preload("res://scripts/platform/contracts/audio_service.gd")
const AnalyticsServiceScript = preload("res://scripts/platform/contracts/analytics_service.gd")

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var standalone := PlatformDescriptorScript.create(
		PlatformDescriptor.RuntimeEnvironment.WINDOWS_NATIVE,
		PlatformDescriptor.DistributionChannel.STANDALONE,
	)
	var steam := PlatformDescriptorScript.create(
		PlatformDescriptor.RuntimeEnvironment.WINDOWS_NATIVE,
		PlatformDescriptor.DistributionChannel.STEAM,
	)
	var browser := PlatformDescriptorScript.create(
		PlatformDescriptor.RuntimeEnvironment.WEB,
		PlatformDescriptor.DistributionChannel.STANDALONE,
	)
	var wechat := PlatformDescriptorScript.create(
		PlatformDescriptor.RuntimeEnvironment.WEB,
		PlatformDescriptor.DistributionChannel.WECHAT,
	)
	_check(standalone != null, "standalone Windows descriptor is valid")
	_check(steam != null, "Steam remains a Windows distribution channel")
	_check(browser != null, "standalone Web descriptor is valid")
	_check(wechat != null, "WeChat remains a Web distribution channel")
	_check(
		PlatformDescriptorScript.create(
			PlatformDescriptor.RuntimeEnvironment.WEB,
			PlatformDescriptor.DistributionChannel.STEAM,
		) == null,
		"Steam cannot be mislabeled as a Web runtime",
	)
	_check(
		PlatformDescriptorScript.create(
			PlatformDescriptor.RuntimeEnvironment.WINDOWS_NATIVE,
			PlatformDescriptor.DistributionChannel.WECHAT,
		) == null,
		"WeChat cannot be mislabeled as a Windows channel",
	)

	var neutral := InputSnapshot.neutral()
	_check(neutral.move == Vector2.ZERO, "neutral input has no movement")
	_check(neutral.quickbar_slot_index == -1, "neutral input has no absolute quickbar selection")
	_check(SafeAreaInsets.zero().is_zero(), "zero safe area is explicit")
	_check(SaveReadResult.missing().status == SaveReadResult.Status.MISSING, "save read contract represents a missing slot")
	_check(SaveWriteResult.written().status == SaveWriteResult.Status.WRITTEN, "save write contract represents success")

	_check(PlatformServiceScript != null, "PlatformService contract parses")
	_check(SaveServiceScript != null, "SaveService contract parses")
	_check(InputServiceScript != null, "InputService contract parses")
	_check(AudioServiceScript != null, "AudioService contract parses")
	_check(AnalyticsServiceScript != null, "AnalyticsService contract parses")

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("G2_PLATFORM_CONTRACTS_OK")
		quit(0)
		return
	push_error("G2 platform-contract test failed: %d check(s)" % _failures)
	quit(1)
