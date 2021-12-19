extends UAIAction
class_name UAIParallelAction

export(Array, Resource) var actions

class ParallelActionExecution extends UAIAction.ActionExecution:
	var count:int = 0
	var all_succeeded:bool = true
	
	func add_action(action:UAIAction) -> void:
		count += 1
		var execution = action.execute(context)
		if execution:
			execution.connect("completed", self, "_async_action_completed", [execution], CONNECT_ONESHOT)
	
	func _async_action_completed(execution:UAIAction.ActionExecution) -> void:
		count -= 1
		if execution.status == execution.STATUS_FAILED:
			all_succeeded = false
		if count <= 0:
			complete(all_succeeded)

func execute(context:UAIBehaviorContext) -> ActionExecution:
	if actions.size():
		# not adding this the execution history since it doesn't actually do anything
		var pending_execution = ParallelActionExecution.new(self, context)
		pending_execution.connect("completed", self, "emit_signal", ["completed", pending_execution], CONNECT_ONESHOT)
		for action in actions:
			pending_execution.add_action(action)
		return pending_execution
	return null
	
