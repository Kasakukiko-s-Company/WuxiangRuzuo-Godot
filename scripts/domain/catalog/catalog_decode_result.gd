class_name CatalogDecodeResult
extends RefCounted

var catalog: GameCatalog
var issues: Array[DataValidationIssue] = []


static func valid(decoded_catalog: GameCatalog) -> CatalogDecodeResult:
	var result := CatalogDecodeResult.new()
	result.catalog = decoded_catalog
	return result


static func invalid(validation_issues: Array[DataValidationIssue]) -> CatalogDecodeResult:
	var result := CatalogDecodeResult.new()
	result.issues = validation_issues
	return result


func is_valid() -> bool:
	return catalog != null and issues.is_empty()


func describe_issues() -> String:
	var descriptions: PackedStringArray = []
	for issue: DataValidationIssue in issues:
		descriptions.append(issue.describe())
	return "\n".join(descriptions)
