class_name EstateMapCatalogDecodeResult
extends RefCounted

var catalog: EstateMapCatalog
var issues: Array[DataValidationIssue]


static func valid(decoded_catalog: EstateMapCatalog) -> EstateMapCatalogDecodeResult:
	var result := EstateMapCatalogDecodeResult.new()
	result.catalog = decoded_catalog
	return result


static func invalid(
	decode_issues: Array[DataValidationIssue],
) -> EstateMapCatalogDecodeResult:
	var result := EstateMapCatalogDecodeResult.new()
	result.issues = decode_issues
	return result


func is_valid() -> bool:
	return catalog != null and issues.is_empty()


func describe_issues() -> String:
	var descriptions: Array[String] = []
	for issue: DataValidationIssue in issues:
		descriptions.append(issue.describe())
	return "\n".join(descriptions)
