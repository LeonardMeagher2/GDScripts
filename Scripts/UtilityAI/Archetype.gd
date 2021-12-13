extends Resource
class_name UAIArchetype

export(Array, Resource) var behavior_sets:Array setget set_behavior_sets

func set_behavior_sets(value:Array):
	behavior_sets = []
	for behavior_set in value:
		if behavior_set is UAIBehaviorSet:
			behavior_sets.append(behavior_set)
		else:
			printerr("Achetypes can only contain BehaviorSets")


func choose_behavior(agent, targets:Array) -> UAIContext:
	var queue = PriorityQueue.new()
	
	var highest_priority:int = 0
	for behavior_set in behavior_sets:
		behavior_set = behavior_set as UAIBehaviorSet
		
		if not behavior_set or behavior_set.enabled == false:
			continue
		
		for behavior in behavior_set.behaviors:
			behavior = behavior as UAIBehavior
			
			if not behavior or behavior.enabled == false:
				continue
				
			if behavior.priority > highest_priority:
				queue = PriorityQueue.new()
				highest_priority = behavior.priority
			elif behavior.priority < highest_priority:
				continue

			for target in targets:
				var context = UAIContext.new()
				context.behavior = behavior
				context.target = weakref(target)
				context.agent = weakref(agent)
				
				if behavior.evaluate_preconditions(context):
					var score:UAIBehavior.Score = behavior.score(context)
					context.behavior_score = score
					queue.insert(score.final_score, context)
	
	var winner:UAIContext = queue.front()
	if winner.behavior_score.final_score > 0.0:
		return winner
	
	return null
