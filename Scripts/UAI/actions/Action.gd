extends Resource
class_name UAIAction

signal executed(execution)
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
	var _locks = 0
	
	var name:String setget ,get_name
	var original_action:Resource
	var context:UAIBehaviorContext
	var created_at:float
	var completed_at:float
	var status = STATUS_PENDING
	
	func get_name() -> String:
		return original_action.get_name()
	
	func _init(action:Resource, context:UAIBehaviorContext):
		self.created_at = OS.get_ticks_msec()
		self.original_action = action
		self.context = context
	
	func lock() -> void:
		_locks += 1
		
	func unlock(succeeded:bool = true) -> void:
		if status == STATUS_PENDING and _locks > 0:
			_locks -= 1
		else:
			push_warning("Attempt to unlock UAIAction, when it was not locked!")
		complete(succeeded)
		
	func cancel() -> bool:
		if status == STATUS_PENDING:
			# complete regardless if it is locked
			status = STATUS_FAILED
			completed_at = OS.get_ticks_msec()
			# deferred in case the task is cancelled before someone was able to yield for completed
			call_deferred("emit_signal","completed")
			return true
		return false
	
	func complete(succeeded:bool = true) -> bool:
		if not _locks and status == STATUS_PENDING:
			status = STATUS_SUCCEEDED if succeeded else STATUS_FAILED
			completed_at = OS.get_ticks_msec()
			call_deferred("emit_signal", "completed")
			return true
		return false
	

func execute(context:UAIBehaviorContext) -> ActionExecution:
	var execution = ActionExecution.new(self, context)
	execution.connect("completed", self, "emit_signal", ["completed", execution], CONNECT_ONESHOT)
	context.history.add_execution(execution)
	
	# Ai handlers should test to see if they are the agent
	emit_signal("executed", execution)
	# Attempt to complete the execution, in case nothing is actually going to handle the action
	execution.call_deferred("complete")
	
	return execution
