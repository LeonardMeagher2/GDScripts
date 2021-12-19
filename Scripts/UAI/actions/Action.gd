extends Resource
class_name UAIAction

signal completed(execution)

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


class ActionExecution extends Reference:
	signal completed()
	enum {
		STATUS_PENDING,
		STATUS_SUCCEEDED,
		STATUS_FAILED
	}
	var name:String setget set_name,get_name
	var original_action:Resource
	var context:UAIBehaviorContext
	var created_at:float
	var completed_at:float
	var status = STATUS_PENDING
	
	func set_name(value:String):
		return
	
	func get_name() -> String:
		return original_action.get_name()
	
	func _init(action:Resource, context:UAIBehaviorContext):
		self.created_at = OS.get_ticks_msec()
		self.original_action = action
		self.context = context
	
	func complete(success:bool = true) -> void:
		if status == STATUS_PENDING:
			status = STATUS_SUCCEEDED if success else STATUS_FAILED
			completed_at = OS.get_ticks_msec()
		call_deferred("emit_signal", "completed")

func execute(context:UAIBehaviorContext) -> ActionExecution:
	var execution = ActionExecution.new(self, context)
	execution.connect("completed", self, "emit_signal", ["completed", execution], CONNECT_ONESHOT)
	context.history.add_execution(execution)
	
	var agent = context.agent_ref.get_ref()
	if agent and agent.has_method("do_action"):
		agent.do_action(execution)
	
	return execution
