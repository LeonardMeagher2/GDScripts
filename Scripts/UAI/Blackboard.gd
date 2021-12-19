tool
extends Resource
class_name UAIBlackboard

signal property_changed(property, value, previous_value)

export var parent:Resource
export var local_data:Dictionary setget set_local_data

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
	property_list_changed_notify()
	
func set_local_data(value:Dictionary) -> void:
	local_data = value
	property_list_changed_notify()

func get_snapshot() -> Dictionary:
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
	var res = [{
		name = "Blackboard Local Data",
		type = TYPE_NIL,
		hint_string = "properties_",
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	}]
	for name in local_data:
		var value = local_data[name]
		var type = typeof(value)
		var hint_string = ""
		if type == TYPE_OBJECT and value:
			hint_string = value.get_class()
		res.append({
			name = name,
			type = type,
			hint_string = hint_string,
			usage = PROPERTY_USAGE_DEFAULT
		})
	return res
