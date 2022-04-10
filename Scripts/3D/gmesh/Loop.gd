extends Resource
class_name GLoop


# per face vertex data, and a corner of a face
export var dirty:bool = true setget set_dirty,get_dirty
export var index:int = -1
export var edge:Resource # GEdge
export var vert:Resource # GVert
export var face:Resource # GFace
export var gmesh:Resource # GMesh

export var next:Resource # GLoop
export var prev:Resource # GLoop

export var color:Color = Color()
export var tangent:Plane = Plane()
export var uv:Vector2 = Vector2()
export var uv2:Vector2 = Vector2()
export var smooth:bool = false

var normal:Vector3 setget ,get_normal

func _to_string():
	return "Loop{index}".format({
		"index": index
	})

func _init(vert, index = -1):
	self.index = index
	self.vert = vert
	
func get_key():
	return [face.get_key(), vert]

func set_dirty(d:bool) -> GLoop:
	if is_valid():
		if dirty == false and d == true:
			pass #mesh.update_mesh_data(self)

		dirty = d
	else:
		dirty = true
	return self

func get_dirty() -> bool:
	return dirty


func copy_from(other:GLoop) -> GLoop:
	self.edge = other.edge
	self.vert = other.vert
	self.face = other.face
	self.next = other.next
	self.prev = other.prev

	self.color = other.color
	self.tangent = other.tangent
	self.uv = other.uv
	self.uv2 = other.uv2
	self.normal = other.normal
	self.smooth = other.smooth

	return self

func remove() -> GLoop:
	index = -1
	vert.loops.erase(self)
	vert = null
	edge.loops.erase(self)
	edge = null
	face.loops.erase(self)
	face = null
	if next:
		next.prev = null
		next = null
	if prev:
		prev.next = null
		prev = null

	gmesh.loops.erase(get_key())
	gmesh = null
	return self

func is_valid() -> bool:
	return gmesh != null and vert != null and edge != null and face != null and next != null and prev != null

func flip() -> GLoop:
	var n:GLoop = next
	next = prev
	prev = n
	return self

func set_smooth(smooth:bool) -> GLoop:
	self.smooth = smooth
	return self

func get_normal() -> Vector3:
	normal = Vector3()
	if is_valid():
		if smooth:
			normal = vert.normal
		else:
			normal = face.normal
	return normal
