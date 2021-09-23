extends Resource
class_name DijkstraMapGenerator

# A generic dynamic weighted graph, that allows you to do dijkstra or astar on any dataset.
# As long as you can claculate a cost and neighbors you can create a dijkstra map.
# If you can calculate distance and provide a starting item you can get astar.

class DijkstraNode extends Reference:
	# A linked list of values and costs.
	# Can be used in a for loop to get a path.
	var next:DijkstraNode = null
	var cost: float = 0.0
	var value = null

	func _init(value, cost:float):
		self.value = value
		self.cost = cost

	func _iter_init(iter) -> bool:
		iter[0] = self
		return next != null
	
	func _iter_next(iter) -> bool:
		iter[0] = iter[0].next
		return iter[0] != null
	
	func _iter_get(node):
		return node

func get_neighbors(current) -> Array:
	# Should return an array of items that are "neighboring" this current one.
	return []

func get_cost(prev, current, next, goals) -> float:
	# Should return a cost for the current item, other values are provided to allow more flexible costs.
	return 1.0

func get_distance(start, current, goal) -> float:
	# If distance can be calculated this will encourage the search algorithm to move towards your goals.
	# An example of a 2d/3d vector distance might be:
	# -----------
	# var d  = goal.distance_squared_to(current)
	# if d == 0.0: return 0.0
	# return (d / goal.distance_squared_to(start)) * 0.01
	# -----------
	# We convert the distance to a 0-1 value and multiply by a small number
	# so the influence of distance is only just enough to influence the results.
	
	return 0.0

func search(goals:Dictionary, start = null, max_cost:float = INF) -> Dictionary:
	# We use a priority queue which is a binary heap
	# it helps sorting the values as they go in so the search is faster.
	
	var que = PriorityQueue.new()
	var result = {}
	var goal_items = goals.keys()
	
	for g in goals:
		# Goals should be like {item: cost, item2: cost2}.
		# Generally you want values from 0 and above.
		result[g] = DijkstraNode.new(g, goals[g])
		que.insert(goals[g], result[g])
	
	while not que.empty():
		var current:DijkstraNode = que.pop_front()
		
		if start != null and current.value == start:
			# This is an early exit if you provided a start item
			break
		
		for next in get_neighbors(current.value):
			# The cost of our new item will be the previous items cost + the cost for this one.
			var new_cost = current.cost
			var prev = current.next # We start from a goal and create nodes that point back towards the goals.
			if prev == null:
				prev = current
			
			new_cost += get_cost(prev.value, current.value, next, goal_items)
			
			# We're checking to see if we've been to this item before.
			var node = result.get(next, null)
			if node == null:
				node = DijkstraNode.new(next, INF)

			if new_cost < node.cost:
				node.cost = new_cost
				# We don't add a new node to the results unless the cost is lower than the max_cost.
				if new_cost < max_cost:
					var smallest_distance = 0.0
					if start != null:
						# If you provide a start, this attempts to add a distance heuristic, improving the time it takes to get to your goals.
						smallest_distance = INF
						for g in goal_items:
							var distance = get_distance(start, next, g)
							if distance < smallest_distance:
								smallest_distance = distance
					
					que.insert(new_cost + smallest_distance, node)
					node.next = current
					result[next] = node
	
	# To walk down from a specifc node do:
	# -----------
	# for n in result[item]:
	# 	print(n)
	# -----------
	# It's the same as doing:
	# -----------
	# var n = result[item]
	# while n != null:
	# 	print(n)
	# 	n = n.next
	# -----------
	return result
