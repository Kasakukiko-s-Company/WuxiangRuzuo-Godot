class_name CatalogFileLoader
extends RefCounted

const DOCUMENT_PATHS: Dictionary = {
	"items": "res://data/items.json",
	"crops": "res://data/crops.json",
	"tools": "res://data/tools.json",
	"npcs": "res://data/npcs.json",
	"localization": "res://data/localization.json",
	"world": "res://data/demo_world.json",
	"resources": "res://data/runtime_resources.json",
}


static func load_catalog() -> CatalogDecodeResult:
	var documents: Dictionary = {}
	var issues: Array[DataValidationIssue] = []
	for document_name: String in DOCUMENT_PATHS:
		var path := String(DOCUMENT_PATHS[document_name])
		if not FileAccess.file_exists(path):
			issues.append(DataValidationIssue.new(document_name, "missing file %s" % path))
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK:
			issues.append(DataValidationIssue.new(
				document_name,
				"JSON parse failed: %s" % json.get_error_message(),
			))
			continue
		documents[document_name] = json.data
	if not issues.is_empty():
		return CatalogDecodeResult.invalid(issues)
	return GameCatalogCodec.decode_documents(documents)
