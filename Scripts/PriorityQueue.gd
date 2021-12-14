extends Reference
class_name PriorityQueue

# Priority Queue implementation with binary min-heap

var heap:Array
var map:Dictionary
var current_size:int

class HeapData extends Reference:
	# data structure for heap
	var priority:float = 0.0
	var data
	var index:int
	func key():
		return data
		
	func _to_string():
		return "({index}, {priority}, {data})".format({
			"priority": priority,
			"data": data,
			"index": index
		})

func _init():
	# initialize the heap
	var empty = HeapData.new()
	heap = [empty]
	map[empty] = [0]
	current_size = 0
	
func _map_add(data,i:int):
	# add a new data to the map
	if map.has(data):
		if not map[data].has(i):
			map[data].append(i)
	else:
		map[data] = [i]
func _map_remove(data, i:int):
	# remove a data from the map
	if map.has(data) and map[data].has(i):
		map[data].erase(i)
		if map[data].size() == 0:
			map.erase(data)
		
func _swap(ia:int,ib:int):
	# swap two elements in the heap
	var tmp = heap[ia]
	heap[ia] = heap[ib]
	heap[ib] = tmp
	heap[ia].index = ia
	heap[ib].index = ib
	_map_remove(heap[ia].data,ib)
	_map_remove(heap[ib].data,ia)
	_map_add(heap[ia].data,ia)
	_map_add(heap[ib].data,ib)
	
func _parent(i:int):
	return i / 2
func _child(i:int, x:int):
	return i * 2 + x

func _minChild(i:int):
	# find the child with the lowest priority
	if _child(i,1) > current_size:
		return _child(i,0)
	else:
		if heap[_child(i,0)].priority < heap[_child(i,1)].priority:
			return _child(i,0)
		else:
			return _child(i,0)

func _percUp(i:int):
	# percolate up the heap
	while _parent(i) > 0:
		if heap[i].priority < heap[_parent(i)].priority:
			_swap(_parent(i),i)
		i = _parent(i)

func _percDown(i:int):
	# percolate down the heap
	while _child(i,0) <= current_size:
		var mc = _minChild(i)
		if heap[i].priority > heap[mc].priority:
			_swap(i,mc)
		i = mc

func insert(priority:float, data):
	var heap_data = HeapData.new()
	heap.append(heap_data)
	current_size += 1
	heap_data.priority = priority
	heap_data.data = data
	heap_data.index = current_size
	_map_add(data,current_size)
	_percUp(current_size)
	return heap_data

func pop_front():
	# return the lowest priority element
	var retval = heap[1].data
	
	_swap(1,current_size)
	_map_remove(retval,current_size)
	heap.pop_back()
	current_size -= 1
	_percDown(1)
	return retval
	
func front():
	# peak at the lowest priority element
	return heap[1].data
	
func remove(data):
	if map.has(data):
		var i = map[data].pop_front()
		_swap(i,current_size)
		_map_remove(data,i)
		heap.pop_back()
		current_size -= 1
		_percDown(i)

func empty():
	return current_size < 1
	
func size() -> int:
	return current_size

func _to_string():
	var s = PoolStringArray()
	for i in range(1,current_size+1):
		s.append(str(heap[i]))
	return s.join(',')
