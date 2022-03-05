extends Reference
class_name UAIHistory

var last_execution_by_action = {}

func add_execution(execution: UAIAction.ActionExecution) -> void:
	last_execution_by_action[execution.original_action] = execution
