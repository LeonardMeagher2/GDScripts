extends Node2D

enum ChessTypes {
	PAWN,
	ROOK,
	BISHOP,
	KNIGHT
	QUEEN,
	KING,
}

export var enabled:bool = true
export(ChessTypes) var type
export var first_move:bool = false

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
	# Provide possible neighbors, based on chess moves
	if not context_is_valid(task.context):
		return
	
	var pos:Vector2 = task.current
# warning-ignore:unassigned_variable
	var neighbors:PoolVector2Array
	
	match type:
		ChessTypes.ROOK:
			 neighbors.append_array([
				pos + Vector2.LEFT,
				pos + Vector2.RIGHT,
				pos + Vector2.UP,
				pos + Vector2.DOWN
			])
		ChessTypes.BISHOP:
			 neighbors.append_array([
				pos + Vector2.LEFT + Vector2.UP,
				pos + Vector2.LEFT + Vector2.DOWN,
				pos + Vector2.RIGHT + Vector2.UP,
				pos + Vector2.RIGHT + Vector2.DOWN
			])
		ChessTypes.PAWN, ChessTypes.QUEEN, ChessTypes.KING:
			 neighbors.append_array([
				pos + Vector2.LEFT,
				pos + Vector2.RIGHT,
				pos + Vector2.UP,
				pos + Vector2.DOWN,
				pos + Vector2.LEFT + Vector2.UP,
				pos + Vector2.LEFT + Vector2.DOWN,
				pos + Vector2.RIGHT + Vector2.UP,
				pos + Vector2.RIGHT + Vector2.DOWN
			])
		ChessTypes.KNIGHT:
			# In kingdom originally the knight jumps to these neighbors
			 neighbors.append_array([
				pos + Vector2.UP * 2 + Vector2.LEFT,
				pos + Vector2.UP * 2 + Vector2.RIGHT,
				pos + Vector2.LEFT * 2 + Vector2.UP,
				pos + Vector2.LEFT * 2 + Vector2.DOWN,
				pos + Vector2.DOWN * 2 + Vector2.LEFT,
				pos + Vector2.DOWN  * 2 + Vector2.RIGHT,
				pos + Vector2.RIGHT * 2 + Vector2.UP,
				pos + Vector2.RIGHT * 2 + Vector2.DOWN,
			])
			
	for neighbor in neighbors:
		task.add_neighbor(neighbor)

func _on_Pathing_get_cost(task:Pathing.GetCostTask):
	if not context_is_valid(task.context):
		return
	
	var cost:float = task.cost
	var previous:Vector2 = task.previous
	var current:Vector2 = task.current
	var next:Vector2 = task.next
	var goals:Dictionary = task.context.goals
	
	# Every piece has a cost to it's movement
	cost += 1.0
	
	# but some have special rules
	match type:
		ChessTypes.ROOK, ChessTypes.BISHOP, ChessTypes.QUEEN:
			var da = (previous - current)
			var db = (current - next)

			# these pieces  move in straight lines for free, so we remove the cost we added
			if da == db:
				cost -= 1.0
			
		ChessTypes.PAWN:
			var dir:Vector2 = (current - next)

			if goals.has(current):
				# If we're going to collide with one of our targets, pawns can only do it from a diagonal
				if not (dir.x and dir.y):
					cost = INF
			else:
				# Unless we're attacking, we can only move in non-diagonal directions
				if dir.x and dir.y:
					cost = INF

				elif first_move and next == task.context.start:
					# Pawns on their first move can move an additional space in a straight line
					var da = (previous - current)
					if dir == da:
							cost -= 1.0
	
	# reassign cost back to value for future functions
	task.cost = cost

func _on_Pathing_get_distance(task:Pathing.GetDistanceTask):
	if not context_is_valid(task.context):
		return
	
	var current_distance = task.current.distance_to(task.goal)
	task.distance = current_distance * 0.1
