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
