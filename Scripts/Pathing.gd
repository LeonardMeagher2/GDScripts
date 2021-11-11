extends Node
class_name Pathing

# Requires: PriorityQueue.gd and Task.gd

signal get_context(task)
signal get_goals(task)
signal get_neighbors(task)
signal get_cost(task)
signal get_distance(task)
signal search_complete(results)

# A generic dynamic weighted graph, that allows you to do dijkstra or astar on any dataset.
# As long as you can claculate a cost and neighbors you can create a dijkstra map.
# If you can calculate distance and provide a starting item you can get astar.

class PathingNode extends Reference:
	# A linked list of values and costs.
	# Can be used in a for loop to get a path.
	var next:PathingNode = null
	var cost: float = 0.0
	var total_cost: float = 0.0
	var value = null

	func _init(value, cost:float, total_cost:float):
		self.value = value
		self.cost = cost
		self.total_cost = total_cost

	func _iter_init(iter) -> bool:
		iter[0] = self
		return next != null
	
	func _iter_next(iter) -> bool:
		iter[0] = iter[0].next
		return iter[0] != null
	
	func _iter_get(node):
		return node
		
	func _to_string():
		return "(value: {value}, cost: {cost})".format({
			"value": value,
			"cost": cost
		})
	func print_path() -> String:
		if next:
			return "{0} -> {1}".format([self, next.print_path()])
		return str(self)

func _fire_task(task_name, data = {}):
	# Send an task to signal listeners and children
	
	data.task_name = task_name
	var task = Task.new(null, data)
	
	# Assign default value based on task name
	match task_name:
		"get_context", "get_goals": task.value = {}
		"get_neighbors": task.value = []
		"get_cost": task.value = 0.0 # start at zero, and add/multiply cost
		"get_distance": task.value = 0.0
	
	emit_signal(task_name, task)
	for child in get_children():
		if child.has_method(task_name):
			child.call(task_name, task)
	
	# try to complete the task if nothing is locking it
	task.done()
	return yield(task, "completed")

func search(max_total_cost:float = INF, early_break:bool = true) -> Dictionary:
	
	# Context is an object used to store data across pathing tasks
	var context = yield(_fire_task("get_context", {
		"max_total_cost": max_total_cost,
		"early_break": early_break
	}), "completed")
	if not context:
		return
	
	var start = context.get("start", null)
	
	# Goals is a dictionary where the key gets turned into the PathingNode, and the value is the cost of that node
	var goals = yield(_fire_task("get_goals", {
		"context": context
	}), "completed")
	if not goals:
		return
	
	# We use a priority queue which is a binary heap
	# it helps sorting the values as they go in so the search is faster.
	# when calling pop_front we get the lowest cost node.
	var que = PriorityQueue.new()
	# Results are a map of values to PathingNodes
	var map = {}
	var goal_items = goals.keys()
	var lowest_cost:float = INF
	
	for g in goals:
		# Goals should be like {item: cost, item2: cost2}.
		# we'll subtract everything by the lowest cost to make the lowest cost 0
		if goals[g] < lowest_cost:
			lowest_cost = goals[g]
	for g in goals:
		
		map[g] = PathingNode.new(g, goals[g] - lowest_cost, goals[g] - lowest_cost)
		que.insert(goals[g] - lowest_cost, map[g])
	
	while not que.empty():
		var current:PathingNode = que.pop_front()
		
		if start != null and early_break and current.value == start:
			# This is an early exit if you provided a start item
			break
		
		var neighbors = yield(_fire_task("get_neighbors", {
			"current": current.value,
			"context": context,
			"goals": goal_items
		}), "completed")
		if not neighbors:
			continue
		neighbors = Utils.dedupe_array(neighbors)
		
		for next in neighbors:
			# The cost of our new item will be the previous items cost + the cost for this one.
			
			var prev = current.next # We start from a goal and create nodes that point back towards the goals.
			if prev == null:
				prev = current
			
			var new_cost = yield(_fire_task("get_cost", {
				"prev": prev.value,
				"current": current.value,
				"next": next,
				"goals": goal_items,
				"context": context
			}), "completed")
			if new_cost == null:
				continue
			var new_total_cost = current.total_cost + new_cost
			
			# We're checking to see if we've been to this item before.
			var node = map.get(next, null)
			if node == null:
				node = PathingNode.new(next, INF, INF)

			if new_total_cost < node.total_cost:
				node.cost = new_cost
				node.total_cost = new_total_cost
				
				# We don't add a new node to the results unless the cost is lower than the max_cost.
				if new_total_cost <= max_total_cost:
					var smallest_distance = 0.0
					if start != null:
						# If you provide a start, this attempts to add a distance heuristic, improving the time it takes to get to your goals.
						smallest_distance = INF
						for g in goal_items:
							var distance = yield(_fire_task("get_distance", {
								"start": start,
								"next": next,
								"goal": g,
								"context": context
							}), "completed")
							if distance == null:
								continue
							if distance < smallest_distance:
								smallest_distance = distance
					
					que.insert(new_total_cost + smallest_distance, node)
					node.next = current
					map[next] = node
	
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

	var result = {
		"start": start,
		"map": map,
		"context": context
	}
	emit_signal("search_complete", result)
	return result
