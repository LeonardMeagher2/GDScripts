extends Node
class_name Pathing

class DijkstraMap extends Reference:
	var costs:Dictionary
	var came_from:Dictionary
	
	func _init(costs:Dictionary, came_from:Dictionary):
		self.costs = costs
		self.came_from = came_from

class DijkstraPath extends Reference:
	var total_cost:float = 0.0
	var path:Array
	
	func _init(path:Array, total_cost:float):
		self.path = path
		self.total_cost = total_cost
		

static func _vector_distance(start, current, goal):
	var d = goal.distance_squared_to(start)
	if d == 0:
		return 0.0
	# converting things to a 0-1 range makes the impact easier to predict
	return goal.distance_squared_to(current) / d

static func build_path(from, map:DijkstraMap) -> DijkstraPath:
	var total_cost:float = 0.0
	var path = [{
		"value": from,
		"cost": 0.0
	}]
	
	var current = from if map.came_from.has(from) else null
	var prev = map.came_from.get(current)
	
	while current != null and prev != null:
		var cost = map.costs.get(current) - map.costs.get(prev)
		
		path.append({
			"value": prev,
			"cost": cost
		})
		
		total_cost += cost
		current = prev
		prev = map.came_from.get(prev)
			
	return DijkstraPath.new(path, total_cost)

static func dijkstra(start, goals, options:Dictionary, early_exit:bool = false) -> DijkstraMap:
	
	var get_neighbors:FuncRef = options.get("get_neighbors")
	var get_cost:FuncRef = options.get("get_cost", null)
	var get_distance:FuncRef = options.get("get_distance", null)
	var distance_factor:float = options.get("distance_factor", 0.01)
	var max_cost:float = options.get("max_cost", INF)
	
	var que = PriorityQueue.new()
	var came_from = {}
	var cost_so_far = {}
	
	# Add goals to que
	for g in goals:
		came_from[g] = null
		cost_so_far[g] = 0.0
		que.insert(0.0, g)
		
	while not que.empty():
		var current = que.pop_front()
		
		if early_exit and current == start:
			break
		
		for next in get_neighbors.call_func(current):
			
			var new_cost = cost_so_far[current]
			var prev = came_from.get(current)
			if prev == null:
				prev = current
			
			if get_cost:
				new_cost += get_cost.call_func(prev, current, next, goals)
			else:
				new_cost += 1.0
			
			if new_cost < cost_so_far.get(next, INF):
				cost_so_far[next] = new_cost
				if new_cost < max_cost:
					var smallest_distance = 0.0
					if get_distance:
						smallest_distance = INF
						for g in goals:
							var distance = get_distance.call_func(start, next, g)
							if distance < smallest_distance:
								smallest_distance = distance
					
					que.insert(new_cost + smallest_distance * distance_factor, next)
					came_from[next] = current
	
	return DijkstraMap.new(cost_so_far, came_from)

static func astar(from, to, options:Dictionary) -> DijkstraPath:
	var map = dijkstra(from, to, options, true)
	return build_path(from, map)
