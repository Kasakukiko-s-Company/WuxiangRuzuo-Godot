class_name CropGrowth
extends RefCounted


static func required_progress(definition: CatalogDefinitions.Crop) -> int:
	var total: int = 0
	for duration: int in definition.growth_stages:
		total += duration
	return total


static func stage_for_progress(
	definition: CatalogDefinitions.Crop,
	progress: int,
) -> int:
	var threshold: int = 0
	var stage: int = 0
	for duration: int in definition.growth_stages:
		threshold += duration
		if progress < threshold:
			break
		stage += 1
	return mini(stage, definition.growth_stages.size())


static func is_mature(
	crop: CropState,
	definition: CatalogDefinitions.Crop,
) -> bool:
	return crop.growth_progress >= required_progress(definition)


static func evaluate_one_day(
	crop: CropState,
	definition: CatalogDefinitions.Crop,
	watered_on_day: int,
	completed_day: int,
) -> CropState:
	assert(
		crop.last_growth_day == completed_day - 1,
		"crop days must be evaluated exactly once and in order",
	)
	var next_progress := crop.growth_progress
	var eligible := (
		not definition.requires_water
		or watered_on_day == completed_day
	)
	if eligible and not is_mature(crop, definition):
		next_progress += 1
	return CropState.new(
		crop.crop_id,
		crop.planted_on_day,
		next_progress,
		stage_for_progress(definition, next_progress),
		completed_day,
	)
