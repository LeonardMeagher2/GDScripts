extends UAIInput
class_name UAIActionThrottleInput

export var duration_seconds:float
export var action:Resource


func get_value(context:UAIBehaviorContext) -> float:
	var selected_action:UAIAction = (action if action else context.behavior.action) as UAIAction
	
	if selected_action:
		var last_execution:UAIAction.ActionExecution = context.history.last_execution_by_action.get(selected_action.name, null)
		
		if last_execution:
			var diff = (OS.get_ticks_msec() - last_execution.created_at) / 1000.0
			if diff >= duration_seconds:
				return 1.0
		else:
			return 1.0
	
	return 0.0
