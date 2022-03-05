extends UAIAction
class_name UAIParallelAction

export(Array, Resource) var actions


func _run(parallel_execution:ActionExecution):
	var data:Dictionary = {
		parallel_execution = parallel_execution,
		all_succeeded = true
	}
	for action in actions:
		var execution:ActionExecution = action.execute(parallel_execution.context)
		if execution:
			parallel_execution.lock()
			execution.connect("completed", self, "_async_action_completed", [data], CONNECT_ONESHOT)
	# handle a case where all actions return null for executions
	parallel_execution.call_deferred("complete")

func _async_action_completed(data:Dictionary, execution:ActionExecution) -> void:
	if data.all_scceeded:
		data.all_succeeded = execution.status == execution.STATUS_SUCCEEDED
	data.parallel_execution.unlock(data.all_succeeded)

func execute(context:UAIBehaviorContext) -> ActionExecution:
	if actions.size():
		# not adding this the execution history since it doesn't actually do anything
		var parallel_execution = ActionExecution.new(self, context)
		parallel_execution.connect("completed", self, "emit_signal", ["completed", parallel_execution], CONNECT_ONESHOT)
		context.history.add_execution(parallel_execution)
		emit_signal("executed", parallel_execution)
		_run(parallel_execution)
		
		return parallel_execution
	return null
	
