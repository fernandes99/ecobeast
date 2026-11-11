class_name Result
extends RefCounted

var ok: bool = false
var data: Variant = null
var error: String = ""


static func success(value: Variant = null) -> Result:
	var result := Result.new()
	result.ok = true
	result.data = value
	return result


static func failure(message: String) -> Result:
	var result := Result.new()
	result.error = message
	return result
