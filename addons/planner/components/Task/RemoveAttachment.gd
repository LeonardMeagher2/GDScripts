@tool
extends Button

func _ready():
	visible = false

func _can_drop_data(at_position, data):
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "files":
		for file in data.files:
			if owner.task.has_attachment(file):
				return true
	return false
	
func _drop_data(at_position, data):
	for file in data.files:
		owner.task.remove_attachment(file)
