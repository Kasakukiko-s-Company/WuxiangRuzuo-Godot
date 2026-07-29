class_name TradeOfferCatalogDecodeResult
extends RefCounted

var catalog: TradeOfferCatalog
var issues: Array[DataValidationIssue] = []


static func valid(
	decoded_catalog: TradeOfferCatalog,
) -> TradeOfferCatalogDecodeResult:
	var result := TradeOfferCatalogDecodeResult.new()
	result.catalog = decoded_catalog
	return result


static func invalid(
	decode_issues: Array[DataValidationIssue],
) -> TradeOfferCatalogDecodeResult:
	var result := TradeOfferCatalogDecodeResult.new()
	result.issues = decode_issues
	return result


func is_valid() -> bool:
	return catalog != null and issues.is_empty()


func describe_issues() -> String:
	var descriptions: Array[String] = []
	for issue: DataValidationIssue in issues:
		descriptions.append(issue.describe())
	return "\n".join(descriptions)
