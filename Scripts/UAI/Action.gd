extends Resource
class_name UAIAction

signal completed()

class ActionExecution extends Reference:
	signal completed()
	var name:String setget ,get_name
	var original_action:Resource
	var context:UAIContext
	
	func get_name() -> String:
		if original_action:
			return original_action.resource_name
		return ""
	
	func _init(action:Resource, context:UAIContext):
		self.original_action = action
		self.context = context
	
	func complete() -> void:
		call_deferred("emit_signal", "completed")

func execute(context:UAIContext) -> ActionExecution:
	# The base action can be used like a global event
	var execution = ActionExecution.new(self, context)
	# not all the necessary since we call complete right away, but this is just an example of what should be done
	execution.connect("completed", self, "emit_signal", ["completed"], CONNECT_ONESHOT)
	execution.complete()
	return execution
