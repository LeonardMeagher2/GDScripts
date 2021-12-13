extends Object
class_name UAIAgent

static func choose_behavior(agent, achetype:UAIArchetype, targets:Array) -> UAIContext:
	var queue = PriorityQueue.new()
	
	achetype.sort()
	var highest_priority:int = 0
	for behavior_set in achetype.behavior_sets:
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
