extends Reference
class_name UAIBehaviorContext

signal completed

var behavior:Resource
var behavior_score:Reference
var target_ref:WeakRef
var agent_ref:WeakRef
var current_time:Resource

func execute_action() -> UAIAction.ActionExecution:
	var execution = behavior.action.execute(self)
	execution.connect("completed", self, "emit_signal", ["completed"], CONNECT_ONESHOT)
	return execution
