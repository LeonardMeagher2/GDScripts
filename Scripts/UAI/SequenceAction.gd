extends UAIAction
class_name UAISequenceAction

export(Array, Resource) var actions

func _run(sequence_execution) -> void:
	# needed to be it's own loop so the yield doesn't stop execute from returning the execution object
	for action in actions:
		var execution = action.execute(sequence_execution.context)
		if execution:
			yield(execution, "completed")
	sequence_execution.complete()

func execute(context:UAIBehaviorContext) -> ActionExecution:
	if actions.size():
		var sequence_execution = ActionExecution.new(self, context)
		sequence_execution.connect("completed", self, "emit_signal", ["completed", sequence_execution], CONNECT_ONESHOT)
		_run(sequence_execution)
		return sequence_execution
	return null
