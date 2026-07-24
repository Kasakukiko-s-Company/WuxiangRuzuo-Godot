class_name EstateMapCatalogFileLoader
extends RefCounted

const DOCUMENT_PATH: String = "res://data/estate_maps.json"


static func load_catalog(
	path: String = DOCUMENT_PATH,
) -> EstateMapCatalogDecodeResult:
	var issues: Array[DataValidationIssue] = []
	if not FileAccess.file_exists(path):
		issues.append(DataValidationIssue.new(
			"estateMaps",
			"missing file %s" % path,
		))
		return EstateMapCatalogDecodeResult.invalid(issues)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		issues.append(DataValidationIssue.new(
			"estateMaps",
			"JSON parse failed: %s" % json.get_error_message(),
		))
		return EstateMapCatalogDecodeResult.invalid(issues)
	if not json.data is Dictionary:
		issues.append(DataValidationIssue.new(
			"estateMaps",
			"root must be an object",
		))
		return EstateMapCatalogDecodeResult.invalid(issues)
	return EstateMapCatalogCodec.decode_document(json.data as Dictionary)
