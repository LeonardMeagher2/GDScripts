extends UAIAction
class_name UAISequenceAction

export(Array, Resource) var actions

func _run(sequence_execution:ActionExecution) -> void:
	# needed to be it's own loop so the yield doesn't stop execute from returning the execution object
	var all_succeeded = true
	sequence_execution.lock()
	for action in actions:
		var execution = action.execute(sequence_execution.context) as UAIAction.ActionExecution
		if execution:
			yield(execution, "completed")
			if execution.status == execution.STATUS_FAILED:
				all_succeeded = false
				break
	sequence_execution.unlock(all_succeeded)

func execute(context:UAIBehaviorContext) -> ActionExecution:
	if actions.size():
		# not adding this the execution history since it doesn't actually do anything
		var sequence_execution = ActionExecution.new(self, context)
		sequence_execution.connect("completed", self, "emit_signal", ["completed", sequence_execution], CONNECT_ONESHOT)
		context.history.add_execution(sequence_execution)
		emit_signal("executed", sequence_execution)
		_run(sequence_execution)
		
		return sequence_execution
	return null
