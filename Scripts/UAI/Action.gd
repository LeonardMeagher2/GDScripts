extends Resource
class_name UAIAction

signal completed(execution)

class ActionExecution extends Reference:
	signal completed()
	var name:String setget set_name,get_name
	var original_action:Resource
	var context:UAIBehaviorContext
	
	func set_name(value:String):
		return
	
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
	var execution = ActionExecution.new(self, context)
	execution.connect("completed", self, "emit_signal", ["completed", execution], CONNECT_ONESHOT)
	
	var agent = context.agent_ref.get_ref()
	if agent and agent.has_method("do_action"):
		agent.do_action(execution)
	return execution
