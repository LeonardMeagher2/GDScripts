extends Node2D

signal search_completed()

var _pathing_context:Pathing.PathingContext = Pathing.PathingContext.new()
var _last_execution:Pathing.PathingSearchExecution = null
var targets:Dictionary = {}
var is_searching:bool = false

var last_move = null
var current_move = null

func _ready():
	_pathing_context.set_meta("agent", get_path())
	# warning-ignore:return_value_discarded
	Pathing.connect("search_starting", self, "_on_Pathing_search_starting")

func cancel_search():
	if _last_execution:
		_pathing_context.reset()
		_last_execution.cancel()
		_last_execution = null
		is_searching = false

func add_target(target, cost:float = 0.0):
	
	if typeof(target) == TYPE_NODE_PATH:
		var node:Node2D = get_node_or_null(target) as Node2D
		if not node:
			return
	
	cancel_search()
	targets[target] = cost
	
func remove_target(target):
	cancel_search()
	# warning-ignore:return_value_discarded
	targets.erase(target)

func clear_targets():
	cancel_search()
	targets.clear()

func search(max_total_cost:float = INF) -> void:
	if targets.size() == 0:
		return
	
	cancel_search()
	var start = OS.get_ticks_msec()
	is_searching = true
	_pathing_context.setup_astar(global_transform.origin, max_total_cost)
	var execution = Pathing.search(_pathing_context)
	_last_execution = execution
	yield(execution, "completed")
	is_searching = false
	if execution.is_cancelled == false:
		prints(get_path(),"pathing took", OS.get_ticks_msec() - start, "ms")
		emit_signal("search_completed")
	
func move():
	
	if _last_execution:
		if last_move == null:
			last_move = global_position
		
		if current_move == null:
			var pos:Vector2 = last_move
			var tilemap:TileMap
			if _pathing_context.has_meta("tilemap"):
				 tilemap = get_node_or_null(_pathing_context.get_meta("tilemap")) as TileMap
			
			if tilemap:
				pos = tilemap.world_to_map(pos)
			
			var next_move = _last_execution.get_next(pos)
			if tilemap and next_move != null:
				next_move = tilemap.map_to_world(next_move) + tilemap.cell_size * 0.5
			
			if next_move == null:
				last_move = null
			else:
				current_move = next_move
		
		if current_move != null and current_move.distance_squared_to(global_position) < 1:
			last_move = current_move
			current_move = null
			return last_move
		
		return current_move
	
	return null

func get_next_move_from(from:Vector2 = global_position):
	if _last_execution:
		var pos:Vector2 = from
		var tilemap:TileMap
		if _pathing_context.has_meta("tilemap"):
			 tilemap = get_node_or_null(_pathing_context.get_meta("tilemap")) as TileMap
		
		if tilemap:
			pos = tilemap.world_to_map(pos)
		
		var next_move = _last_execution.get_next(pos)
		if tilemap and next_move != null:
			next_move = tilemap.map_to_world(next_move) + tilemap.cell_size * 0.5
		
		return next_move
	return null

func _on_Pathing_search_starting(task:Pathing.PathingTask):
	if task.context == _pathing_context:
		yield(task, "completing")
		var tilemap:TileMap = null
		var bounds:Rect2
		if task.context.has_meta("tilemap"):
			tilemap = get_node_or_null(task.context.get_meta("tilemap")) as TileMap
		if task.context.has_meta("bounds"):
			bounds = task.context.get_meta("bounds") as Rect2
		
		task.context.start = global_transform.origin
		if tilemap:
			task.context.start = tilemap.world_to_map(task.context.start)
		if bounds:
			bounds = bounds.expand(task.context.start)
		
		for target in targets:
			var position:Vector2
			var cost:float = targets[target]
			
			match typeof(target):
				TYPE_NODE_PATH:
					var target_node:Node2D = get_node_or_null(target) as Node2D
					if target_node:
						position = target_node.global_transform.origin
				TYPE_VECTOR2:
					position = target
			
			if tilemap:
				position = tilemap.world_to_map(position)
			if bounds:
				bounds = bounds.expand(position)
			
			task.context.add_goal(position, cost)
		
		if bounds:
			task.context.set_meta("bounds", bounds)
