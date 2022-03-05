extends Resource
class_name UAIInput

var name:String setget set_name, get_name
func set_name(value:String):
		return
func get_name() -> String:
	if not name:
		if resource_name:
			name = resource_name
		else:
			name = resource_path.get_file().get_basename()
	return name

func get_value(context:UAIBehaviorContext) -> float:
	return 0.0
