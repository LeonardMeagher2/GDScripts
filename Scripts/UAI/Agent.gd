extends Node
class_name UAIAgent

signal status_changed(status)

enum STATUS {
	OK = 0
	EXECUTING = 1
	STALLED = 2
}

export var archetype:Resource
export var blackboard:Resource

onready var random:RandomNoiseGenerator = RandomNoiseGenerator.new()

var history:UAIHistory = UAIHistory.new()
var status:int = OK setget set_status
var targets:Array = []

func set_status(value:int):
	var changed = status != value
	status = value
	if changed:
		emit_signal("status_changed", status)

func pick_behavior(count:int = 3) -> void:
	if status == STATUS.EXECUTING:
		return
	
	var behavior_contexts:Array = archetype.get_best_behaviors(get_parent(), targets, blackboard, history, count)
	
	if behavior_contexts.size():
		# select one at random
		var weights:PoolRealArray
		for context in behavior_contexts:
			weights.append(context.behavior_score.final_score)
		var i = random.weighted_random(weights)
		var context = behavior_contexts[i]
		
		set_status(STATUS.EXECUTING)
		
		var execution = context.behavior.action.execute(context)
		yield(execution, "completed")
		set_status(STATUS.OK)
	else:
		set_status(STATUS.STALLED)

func _enter_tree():
	if not is_in_group("uai_agent"):
		add_to_group("uai_agent")
