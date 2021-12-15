tool
extends Resource
class_name UAIBlackboard

signal property_changed(property, value, previous_value)

export var parent:Resource
export var local_data:Dictionary

func _get(property):
	if local_data.has(property):
		return local_data.get(property)
	if parent:
		return parent.get(property)
	return null

func _set(property, value):
	var previous_value = local_data.get(property)
	local_data[property] = value
	call_deferred("emit_signal","property_changed", property, value, previous_value)

func get_state() -> Dictionary:
	# Useful for keeping track of what the state was when an execution finished
	var result:Dictionary
	if parent:
		result = parent.get_state()
		for key in local_data:
			result[key] = local_data[key]
	else:
		result = local_data.duplicate(true)
	
	return result

func _get_property_list():
	var res = []
	for name in local_data:
		var value = local_data[name]
		var type = typeof(value)
		var hint_string = ""
		if type == TYPE_OBJECT:
			hint_string = value.get_class()
		res.append({
			name = name,
			type = type,
			hint_string = hint_string,
			usage = PROPERTY_USAGE_DEFAULT
		})
	return res
