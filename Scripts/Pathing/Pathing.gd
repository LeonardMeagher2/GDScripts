extends Node

signal search_starting(task)
signal get_neighbors(task)
signal get_cost(task)
signal get_distance(task)
signal search_completing(result)

# A generic dynamic weighted graph, that allows you to do dijkstra or astar on any dataset.
# As long as you can claculate a cost and neighbors you can create a dijkstra map.
# If you can calculate distance and provide a starting item you can get astar.

class PathingTask extends Reference:
	signal completed()
	signal completing()
	
	var context:PathingContext
	var status: = STATUS_PENDING
	var _locks = 0
	
	enum {
		STATUS_PENDING
		STATUS_COMPLETING
		STATUS_COMPLETED
	}
	
	# warning-ignore:shadowed_variable
	func _init(context:PathingContext):
		self.context = context
		call_deferred("complete")
	
	func lock():
		# lock the task to do async work
		if status == STATUS_PENDING:
			_locks += 1

	func unlock():
		# when you're done doing async work unlock the task so it can complete
		if status == STATUS_PENDING and _locks > 0:
			_locks -= 1
			call_deferred("complete")
		else:
			push_warning("Attempt to unlock task, when it was not locked!")
			
	func is_locked():
		return _locks > 0
			
	func complete():
		if not _locks and status == STATUS_PENDING:
			status = STATUS_COMPLETING
			# synchronous events can change the value before completion here
			emit_signal("completing") 
			
			# any locking after this will have no effect
			if status == STATUS_COMPLETING:
				status = STATUS_COMPLETED
				emit_signal("completed")

class GetNeighborsTask extends PathingTask:
	var current = null
	var neighbors:Dictionary = {}
	
	func _init(context:PathingContext).(context):
		pass
	
	func add_neighbor(value):
		neighbors[value] = null
	func remove_neighbor(value):
		# warning-ignore:return_value_discarded
		neighbors.erase(value)

class GetCostTask extends PathingTask:
	var previous = null
	var current = null
	var next = null
	
	var cost:float = 0
	
	func _init(context:PathingContext).(context):
		pass
	
class GetDistanceTask extends PathingTask:
	var start = null
	var current = null
	var goal = null
	
	var distance:float = INF
	
	func _init(context:PathingContext).(context):
		pass
	
class PathingCompletedTask extends PathingTask:
	var execution:PathingSearchExecution
	
	func _init(context:PathingContext).(context):
		pass

class ParallelTask extends Reference:
	
	signal completed()
	
	var tasks:Array = []
	var _tasks_completed = 0
	
	func add_task(task:PathingTask):
		tasks.append(task)
		# warning-ignore:return_value_discarded
		task.connect("completed", self, "_on_task_completed")
		
	func _on_task_completed():
		_tasks_completed += 1
		if _tasks_completed == tasks.size():
			emit_signal("completed")

class PathingContext extends Reference:
	# use meta data to store additional info to pass around with the context
	var max_total_cost: float = INF
	var early_break:bool = false
	var start = null
	var goals:Dictionary = {}
	
	func add_goal(value, cost:float = 0) -> void:
		goals[value] = cost
	
	func remove_goal(value):
		# warning-ignore:return_value_discarded
		goals.erase(value)
		
	# warning-ignore:shadowed_variable
	# warning-ignore:shadowed_variable
	func setup_astar(start, max_total_cost:float = INF):
		self.start = start
		self.max_total_cost = max_total_cost
		self.early_break = true
	
	# warning-ignore:shadowed_variable
	func set_dijkstra(max_total_cost:float = INF):
		self.start = null
		self.max_total_cost = max_total_cost
		self.early_break = false
		
	func reset():
		goals.clear()
		start = null

class PathingSearchExecution extends Reference:
	signal completed()
	
	var context:PathingContext = null
	var map:Dictionary = {}
	var is_cancelled:bool = false
	
	# warning-ignore:shadowed_variable
	func _init(context:PathingContext):
		self.context = context
		
	func get_next(from):
		if map.has(from):
			var node:PathingNode = map[from]
			if node.next:
				return node.next.value
		return null
		
	func cancel():
		is_cancelled = true
		emit_signal("completed")

class PathingNode extends Reference:
	# A linked list of values and costs.
	# Can be used in a for loop to get a path.
	var next:PathingNode = null
	var cost: float = 0.0
	var total_cost: float = 0.0
	var value = null

	# warning-ignore:shadowed_variable
	# warning-ignore:shadowed_variable
	# warning-ignore:shadowed_variable
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
		return "PathingNode(value: {value}, cost: {cost})".format({
			"value": value,
			"cost": cost
		})
	func print_path() -> String:
		if next:
			return "{0} -> {1}".format([self, next.print_path()])
		return str(self)
		

func search(context: PathingContext) -> PathingSearchExecution:
	var execution = PathingSearchExecution.new(context)
	call_deferred("execute_search", execution)
	return execution
	
func execute_search(execution:PathingSearchExecution) -> void:
	if execution.is_cancelled:
		return
	
	var que:PriorityQueue = PriorityQueue.new(true)
	var context:PathingContext = execution.context
	var map:Dictionary = execution.map
	
	var starting_task = PathingTask.new(context)
	emit_signal("search_starting", starting_task)
	yield(starting_task, "completed")
	
	if execution.is_cancelled:
		return
	
	for goal in context.goals:
		# do goals need to be based around 0?
		var cost = context.goals[goal]
		var node = PathingNode.new(goal, cost, cost)
		map[goal] = node
		que.insert(cost, node)
	
	
	while not que.is_empty():
		
		if execution.is_cancelled:
			return
		
		var current_node:PathingNode = que.pop_front()
		
		if context.start != null and context.early_break and current_node.value == context.start:
			# This is an early exit if you provided a start item
			break
			
		var neighbors_task:GetNeighborsTask = GetNeighborsTask.new(context)
		neighbors_task.current = current_node.value
		emit_signal("get_neighbors", neighbors_task)
		yield(neighbors_task, "completed")
		
		if neighbors_task.neighbors.size() == 0:
			continue
		
		for next_value in neighbors_task.neighbors:
			if execution.is_cancelled:
				return
			var next_node:PathingNode = map.get(next_value, null)
			if next_node == null:
				next_node = PathingNode.new(next_value, INF, INF)
				
#			if current_node == next_node.next:
#				continue
#
			var previous_node:PathingNode = current_node.next
			if previous_node == null:
				previous_node = current_node
			
			var cost_task = GetCostTask.new(context)
			cost_task.previous = previous_node.value
			cost_task.current = current_node.value
			cost_task.next = next_node.value
			emit_signal("get_cost", cost_task)
			yield(cost_task, "completed")

			if execution.is_cancelled:
				return
			
			if cost_task.cost == INF:
				continue
			
			var new_total_cost = current_node.total_cost + cost_task.cost
			
			if new_total_cost < next_node.total_cost:
				next_node.cost = cost_task.cost
				next_node.total_cost = new_total_cost
				
				# We don't add a new node to the results unless the cost is lower than the max_cost.
				if new_total_cost <= context.max_total_cost:
					var smallest_distance = 0.0
					if context.start != null:
						# If you provide a start, this attempts to add a distance heuristic, improving the time it takes to get to your goals.
						smallest_distance = INF
						var task_group = ParallelTask.new()
						for goal in context.goals:
							if execution.is_cancelled:
								return
							var distance_task = GetDistanceTask.new(context)
							distance_task.start = context.start
							distance_task.current = next_node.value
							distance_task.goal = goal
							emit_signal("get_distance", distance_task)
							task_group.add_task(distance_task)
						
						yield(task_group, "completed")
						for task in task_group.tasks:
							if task.distance < smallest_distance:
								smallest_distance = task.distance
					
					que.insert(new_total_cost + smallest_distance, next_node)
					next_node.next = current_node
					map[next_value] = next_node
	
	var completing_task = PathingCompletedTask.new(context)
	completing_task.execution = execution
	emit_signal("search_completing", completing_task)
	yield(completing_task, "completed")
	
	execution.emit_signal("completed")
