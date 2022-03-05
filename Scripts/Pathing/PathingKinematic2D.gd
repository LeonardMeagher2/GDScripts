extends Node2D

# must be a child of a KinematicBody2D, uses it's test_move functions to remove neighbors it can't walk through

export var enabled:bool = true
export var body:NodePath = @""
export var infinite_inertia:bool = true

func _ready():
	# warning-ignore:return_value_discarded
	Pathing.connect("get_neighbors", self, "_on_Pathing_get_neighbors")
	
func _on_Pathing_get_neighbors(task: Pathing.GetNeighborsTask):
	if not enabled:
		return
	
	var body_node:KinematicBody2D = get_node_or_null(body) as KinematicBody2D
	if not body_node:
		return
	
	yield(task, "completing")
	
	var tilemap:TileMap = null
	if task.context.has_meta("tilemap"):
		tilemap = get_node_or_null(task.context.get_meta("tilemap")) as TileMap
	
	# test move to see if there are collisions
	var from:Vector2 = task.current
	if tilemap:
		from = tilemap.map_to_world(from) + tilemap.cell_size * 0.5
	
	var transform = Transform2D(body_node.global_rotation, from)
	
	var still_collision = body_node.test_move(transform, Vector2.ZERO, infinite_inertia)
	if still_collision:
		#STUCK
		task.neighbors.clear()
	
	for neighbor in task.neighbors:
		var to:Vector2 = neighbor
		if tilemap:
			to = tilemap.map_to_world(to) + tilemap.cell_size * 0.5
		
		var velocity = from-to
		var moving_collision = body_node.test_move(transform, velocity, infinite_inertia)
		if moving_collision:
			task.remove_neighbor(neighbor)
