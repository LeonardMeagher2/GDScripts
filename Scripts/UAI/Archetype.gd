extends Resource
class_name UAIArchetype

export(Array, Resource) var behavior_sets:Array setget set_behavior_sets

func set_behavior_sets(value:Array):
	behavior_sets = []
	for behavior_set in value:
		if behavior_set is UAIBehaviorSet:
			behavior_sets.append(behavior_set)
		else:
			printerr("Archetypes can only contain BehaviorSets")


func get_best_behaviors(agent, targets:Array, current_time:Time, count:int = 1) -> Array:
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
				
			
			if behavior.priority < highest_priority:
				# The queue is set to a higher priority than the current behavior
				continue
			
			var behvior_used:bool = false

			for target in targets:
				var context = UAIContext.new()
				context.behavior = behavior
				context.target = weakref(target)
				context.agent = weakref(agent)
				context.current_time = current_time
				
				if behavior.evaluate_preconditions(context):
					var score:UAIBehavior.Score = behavior.score(context)
					context.behavior_score = score
					if score.final_score > 0.0:
						# Only consider changing the highest_priority if the behavior may have a real chance of being used
						# This should only happen once for the first item with a higher priority than everything else
						if not behvior_used and behavior.priority > highest_priority:
							highest_priority = behavior.priority
							queue = PriorityQueue.new() # Everything in the queue currently has a lower priority, get rid of it
							behvior_used = true
						queue.insert(score.final_score, context)
	
	# Give the top N behaviors, useful for randomly picking one of the best
	var results = []
	var n:int = clamp(count, 0, queue.size())
	if not n:
		n = queue.size()
	for i in n:
		results.append(queue.pop_front())
	
	return results
