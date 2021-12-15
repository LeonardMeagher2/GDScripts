extends UAIAction
class_name UAIParallelAction

export(Array, Resource) var actions

class ParallelActionExecution extends UAIAction.ActionExecution:
	var count:int = 0
	
	func add_action(action:UAIAction) -> void:
		count += 1
		var execution = action.execute(context)
		if execution:
			execution.connect("completed", self, "_async_action_completed", [], CONNECT_ONESHOT)
	
	func _async_action_completed() -> void:
		count -= 1
		if count <= 0:
			complete()

func execute(context:UAIBehaviorContext) -> ActionExecution:
	if actions.size():
		var pending_execution = ParallelActionExecution.new(self, context)
		pending_execution.connect("completed", self, "emit_signal", ["completed"], CONNECT_ONESHOT)
		for action in actions:
			pending_execution.add_action(action)
		return pending_execution
	return null
	
