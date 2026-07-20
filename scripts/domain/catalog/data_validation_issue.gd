class_name DataValidationIssue
extends RefCounted

var path: String
var message: String


func _init(issue_path: String, issue_message: String) -> void:
	path = issue_path
	message = issue_message


func describe() -> String:
	return "%s: %s" % [path, message]
