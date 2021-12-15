extends Resource
class_name UAIBehaviorSet

export(Array, Resource) var behaviors:Array setget set_behaviors

func set_behaviors(value:Array):
	behaviors = []
	for behavior in value:
		if behavior is UAIBehavior:
			behaviors.append(behavior)
		else:
			printerr("BehaviorSets can only contain Behaviors")

