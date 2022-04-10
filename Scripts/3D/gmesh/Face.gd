extends Resource
class_name GFace

# face with 3 loops
export var index:int = -1
export var normal:Vector3 = Vector3()
export var area:float = 0.0

export(Array, Resource) var verts:Array # verts of this face
export(Array, Resource) var edges:Array # edges of this face
export(Array, Resource) var loops:Array # loops of this face

export var gmesh:Resource

func _to_string():
	return "Face{index}".format({
		"index": index
	})

func _init(loops:Array, index:int = -1):
	self.index = index
	self.verts = []
	self.edges = []
	self.loops = loops.duplicate()

static func create_key(v1:GVertex,v2:GVertex,v3:GVertex) -> Array:
	if v1.index < v2.index:
		if v1.index < v3.index:
			return [v1, v2, v3]
		else:
			return [v3, v1, v2]
	if v1.index < v3.index:
		return [v2, v1, v3]
	if v2.index < v3.index:
		return [v2,v3,v1]
	return [v3,v2,v1]

func get_key():
	return create_key(verts[0], verts[1], verts[2])

func make_dirty() -> GFace:
	if is_valid():
		for loop in loops:
			loop.dirty = true
	return self


func copy_from(other:GFace) -> GFace:
	self.normal = other.normal

	self.verts = other.verts.duplicate()
	self.edges = other.edges.duplicate()
	self.loops = other.loops.duplicate()
	return self

func remove() -> GFace:
	
	loops[0].remove()
	loops[0].remove()
	loops[0].remove()

	verts.clear()
	edges.clear()
	loops.clear()

	gmesh.faces.erase(get_key())
	gmesh = null
	return self

func calc_normal() -> Vector3:
	normal = Vector3()
	if is_valid():
		normal = (-(verts[1].position - verts[0].position).cross(verts[2].position - verts[0].position)).normalized()
	return normal

func flip() -> GFace:
	if is_valid():
		loops[0].flip()
		loops[1].flip()
		loops[2].flip()

		loops.invert()
		verts.invert()
	return self

func is_valid() -> bool:
	return gmesh != null and loops.size() == 3  and verts.size() == 3 and edges.size() == 3

func set_smooth(smooth) -> GFace:
	if is_valid():
		loops[0].set_smooth(smooth)
		loops[1].set_smooth(smooth)
		loops[2].set_smooth(smooth)
	return self

func get_center() -> Vector3:
	return (verts[0].position + verts[1].position + verts[2].position) / 3.0;

func vector_to_uv(v:Vector3) -> Vector3:
	var bc:Vector3 = get_barycentric(v,loops[0].vert.position, loops[1].vert.position, loops[2].vert.position)
	return (loops[0].uv * bc.x) + (loops[1].uv * bc.y) + (loops[2].uv * bc.z);

func uv_to_vector(uv:Vector2) -> Vector3:
	var bc:Vector3 = get_barycentric(Vector3(uv.x,uv.y,0),Vector3(loops[0].uv.x,loops[0].ux.y,0), Vector3(loops[1].uv.x,loops[1].ux.y,0), Vector3(loops[2].uv.x,loops[2].ux.y,0))
	return (loops[0].vert.position * bc.x) + (loops[1].vert.position * bc.y) + (loops[2].vert.position * bc.z);

func is_backfacing(normal:Vector3) -> bool:
	return self.normal.dot(normal) < 0.0

func calc_area() -> float:
	var ab:Vector3 = loops[1].vert.position - loops[0].vert.position
	var ac:Vector3 = loops[2].vert.position - loops[0].vert.position
	self.area = ab.cross(ac).length() * 0.5
	return self.area
	
func ray_intersects(from:Vector3, dir:Vector3):
	return Geometry.ray_intersects_triangle(from,dir,verts[0].position,verts[1].position,verts[2].position)
	
static func get_barycentric(v:Vector3, a:Vector3, b:Vector3, c:Vector3) -> Vector3:
	var mat1 : = Basis(a, b, c)
	var det : = mat1.determinant()
	var mat2 : = Basis(v, b, c)
	var factor_alpha : = mat2.determinant()
	var mat3 : = Basis(v, c, a)
	var factor_beta : = mat3.determinant()
	var alpha : = factor_alpha / det
	var beta : = factor_beta / det
	var gamma : = 1.0 - alpha - beta
	return Vector3(alpha, beta, gamma)
