extends Resource
class_name GEdge

# An edge connecting to verticies
export var index:int= -1
export var smooth:bool = false

export(Array, Resource) var verts:Array # the verticies this edge uses (always 2)
export(Array, Resource) var loops:Array # the loops this edge connects
export(Array, Resource) var faces:Array # faces connected to this edge (0-2)

export var gmesh:Resource

func _to_string():
	return "Edge{index}".format({
		"index": index
	})

func _init(verts:Array, index:int = -1):
	self.index = index
	self.verts = verts.duplicate()
	loops = []
	faces = []

static func create_key(v1:GVertex, v2:GVertex) -> Array:
	if v1.index < v2.index:
		return [v1,v2]
	return [v2,v1]

func get_key():
	return create_key(verts[0],verts[1])

func make_dirty() -> GEdge:
	if is_valid():
		for loop in loops:
			loop.dirty = true
	return self

func copy_from(other:GEdge) -> GEdge:
	smooth = other.smooth

	verts = other.verts.duplicate()
	loops = other.loops.duplicate()
	faces = other.faces.duplicate()
	return self

func get_face_angle() -> float:
	if faces.size() == 2:
		return acos(clamp(faces[0].normal.normalized().dot(faces[1].normal.normalized()),-1.0,1.0))
	return 0.0

func length() -> float:
	return verts[0].position.distance_to(verts[1].position)
func length_squared() -> float:
	return verts[0].position.distance_squared_to(verts[1].position)

func remove() -> GEdge:
	index = -1
	verts[0].edges.erase(self)
	verts[1].edges.erase(self)
	for loop in loops:
		loop.edge = null
	for face in faces:
		face.edges.erase(self)
	verts.clear()
	loops.clear()
	faces.clear()

	gmesh.edges.erase(get_key())
	gmesh = null

	return self

func is_valid() -> bool:
	return gmesh != null and verts.size() == 2

func set_smooth(smooth:bool) -> GEdge:
	for loop in loops:
		loop.set_smooth(smooth)
	return self

func get_normal() -> Vector3:
	return (verts[1].position - verts[0].position).normalized()
