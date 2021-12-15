extends Resource
class_name UAIAction

signal completed(execution)

class ActionExecution extends Reference:
	signal completed()
	var name:String setget ,get_name
	var original_action:Resource
	var context:UAIBehaviorContext
	
	func get_name() -> String:
		if not name:
			if original_action:
				if original_action.resource_name:
					name = original_action.resource_name
				else:
					name = original_action.resource_path.get_file().get_basename()
		return name
	
	func _init(action:Resource, context:UAIBehaviorContext):
		self.original_action = action
		self.context = context
	
	func complete() -> void:
		call_deferred("emit_signal", "completed")

func execute(context:UAIBehaviorContext) -> ActionExecution:
	# The base action can be used like a global event
	var execution = ActionExecution.new(self, context)
	# not all the necessary since we call complete right away, but this is just an example of what should be done
	execution.connect("completed", self, "emit_signal", ["completed", execution], CONNECT_ONESHOT)
	execution.complete()
	return execution
