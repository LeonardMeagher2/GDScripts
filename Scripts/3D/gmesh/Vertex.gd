extends Resource
class_name GVertex
	
# A Vertex in a mesh
export var index:int = -1
export var position:Vector3 = Vector3()
export var normal:Vector3 = Vector3()
export var pointiness:float = 0.0
export var crease:float = 0.0

export(Array, Resource) var edges:Array # edges connected to this vertex
export(Array, Resource) var loops:Array # loops that use this vertex
export(Array, Resource) var faces:Array # faces connected to this vertex

export var gmesh:Resource

export var bones:PoolIntArray = PoolIntArray()
export var weights:PoolRealArray = PoolRealArray()

func _to_string():
	return "Vertex{index}".format({
		"index": index
	})

func get_key():
	return position

func _init(position:Vector3 = Vector3(), index:int = -1):
	self.index = index
	self.position = position
	edges = []
	loops = []
	faces = []

func make_dirty() -> GVertex:
	if is_valid():
		for loop in loops:
			loop.dirty = true
	return self

func copy_from(other:GVertex) -> GVertex:
	position = other.position
	normal = other.normal
	pointiness = other.pointiness
	crease = other.crease

	edges = other.edges.duplicate()
	loops = other.loops.duplicate()
	faces = other.faces.duplicate()
	
	bones = other.bones
	weights = other.weights
	
	return self

func calc_normal() -> GVertex:
	normal = Vector3()
	if faces.size() > 0:
		for face in faces:
			normal += face.normal
		normal = normal.normalized()
	return self

func remove() -> GVertex:
	index = -1
	gmesh.verts.erase(self)
	gmesh = null
	for edge in edges:
		edge.remove()
	for loop in loops:
		loop.remove()
	for face in faces:
		face.remove()
	return self

func is_valid() -> bool:
	return gmesh != null

func set_smooth(smooth:bool) -> GVertex:
	for loop in loops:
		loop.set_smooth(smooth)
	return self

func calc_pointiness() -> float:
	var p : = 0.0
	var fPI : = 1.0/PI
	if loops.size() > 0:
		var n : = Vector3()
		for loop in loops:
			n += (loop.next.vert.position - loop.vert.position).normalized()
		p = (acos(clamp(normal.dot(n/(loops.size())),-1.0,1.0)) * fPI)
	pointiness = p
	return pointiness

func calc_crease() -> float:
	var c : = 0.0
	var fPI : = 1.0/PI
	if edges.size() > 0:
		for edge in edges:
			c += edge.get_face_angle() * fPI
		c /= edges.size()
	crease = c
	return crease

func set_color(color:Color) -> GVertex:
	for loop in loops:
		loop.color = color
	return self
