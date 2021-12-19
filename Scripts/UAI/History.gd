extends Resource
class_name UAIHistory

export var last_execution_by_action = {}

func add_execution(execution:UAIAction.ActionExecution) -> void:
	last_execution_by_action[execution.name] = execution
