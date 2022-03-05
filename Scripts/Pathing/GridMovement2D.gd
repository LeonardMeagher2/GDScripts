extends Node2D

export var enabled:bool = true
export var diagonals:bool = false

func _ready():
	# warning-ignore:return_value_discarded
	Pathing.connect("get_neighbors", self, "_on_Pathing_get_neighbors")
	# warning-ignore:return_value_discarded
	Pathing.connect("get_cost", self, "_on_Pathing_get_cost")
	# warning-ignore:return_value_discarded
	Pathing.connect("get_distance", self, "_on_Pathing_get_distance")

func context_has_agent(context) -> bool:
	if context.has_meta("agent"):
		var agent = get_parent().get_path()
		if context.get_meta("agent") == agent:
			return true
	return false

func context_has_tilemap(context) -> bool:
	if context.has_meta("tilemap"):
		var tilemap:TileMap = get_node_or_null(context.get_meta("tilemap")) as TileMap
		if tilemap:
			return true
	return false

func context_is_valid(context) -> bool:
	return enabled and context_has_agent(context) and context_has_tilemap(context)

func _on_Pathing_get_neighbors(task:Pathing.GetNeighborsTask):
	if not context_is_valid(task.context):
		return
	
	var pos:Vector2 = task.current
	
	var neighbors:PoolVector2Array = [
		pos + Vector2.LEFT,
		pos + Vector2.UP,
		pos + Vector2.RIGHT,
		pos + Vector2.DOWN
	]
	
	if diagonals:
		neighbors.append_array([
			pos + Vector2.LEFT + Vector2.UP,
			pos + Vector2.RIGHT + Vector2.UP,
			pos + Vector2.RIGHT + Vector2.DOWN,
			pos + Vector2.LEFT + Vector2.DOWN
		])
		
	for neighbor in neighbors:
		task.add_neighbor(neighbor)

func _on_Pathing_get_cost(task:Pathing.GetCostTask):
	if not context_is_valid(task.context):
		return
	task.cost += 1

func _on_Pathing_get_distance(task:Pathing.GetDistanceTask):
	if not context_is_valid(task.context):
		return
	
	var current_distance = task.current.distance_to(task.goal)
	task.distance = current_distance * 0.1
