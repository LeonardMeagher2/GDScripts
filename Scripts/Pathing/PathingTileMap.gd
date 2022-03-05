extends Node

# expects to be a child of a TileMap

func _ready():
	# warning-ignore:return_value_discarded
	Pathing.connect("search_starting", self, "_on_Pathing_search_starting")
	# warning-ignore:return_value_discarded
	Pathing.connect("get_neighbors", self, "_on_Pathing_get_neighbors")
	
func _on_Pathing_search_starting(task:Pathing.PathingTask):
	var tilemap:TileMap = get_parent() as TileMap
	if tilemap:
		task.context.set_meta("tilemap", tilemap.get_path())
		task.context.set_meta("bounds", tilemap.get_used_rect())
	
func _on_Pathing_get_neighbors(task:Pathing.GetNeighborsTask):
	var tilemap:TileMap = get_parent() as TileMap
	if tilemap:
		
		yield(task, "completing")
		
		var bounds:Rect2 = task.context.get_meta("bounds") as Rect2
		if bounds:
			bounds = bounds.grow(5.0)
			for neighbor in task.neighbors:
				if not bounds.has_point(neighbor):
					task.remove_neighbor(neighbor)
