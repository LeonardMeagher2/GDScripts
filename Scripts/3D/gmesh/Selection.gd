extends Reference
class_name GSelection

var gmesh:Resource # the GMesh you are editing

var verts:Array # all the verts in this mesh
var edges:Array # all the edges in this mesh
var loops:Array # all the loops in this mesh
var faces:Array # all the faces in this mesh

func _init():
	clear()

func clear():
	verts = []
	edges = []
	loops = []
	faces = []
	
func duplicate() -> GSelection:
	var selection = get_script().new()
	selection.verts = verts.duplicate()
	selection.edges = edges.duplicate()
	selection.loops = loops.duplicate()
	selection.faces = faces.duplicate()
	return selection

func set_smooth(smooth:bool) -> GSelection:
	for loop in loops:
		loop.set_smooth(smooth)
	return self

func create_vertex(v:Vector3) -> GVertex:
	var vert:GVertex = GVertex.new(v,verts.size())
	vert.gmesh = gmesh
	vert.index = gmesh.verts.size()
	verts.append(vert)
	return vert

func create_edge(v1:GVertex,v2:GVertex) -> GEdge:
	var edge:GEdge = GEdge.new([v1,v2],edges.size())
	edge.gmesh = gmesh
	edge.index = gmesh.edges.size()
	edges.append(edge)	
	v1.edges.append(edge)
	v2.edges.append(edge)

	return edge

func create_loop(v:GVertex) -> GLoop:
	var loop:GLoop = GLoop.new(v,loops.size())
	v.loops.append(loop)
	loop.gmesh = gmesh
	loops.append(loop)

	return loop

func create_face(v1:GVertex,v2:GVertex,v3:GVertex) -> GFace:
	
	var e1:GEdge = create_edge(v1,v2)
	var e2:GEdge = create_edge(v2,v3)
	var e3:GEdge = create_edge(v3,v1)
	
	var l1:GLoop = create_loop(v1)
	var l2:GLoop = create_loop(v2)
	var l3:GLoop = create_loop(v3)

	var f:GFace = GFace.new([l1,l2,l3],faces.size())

	l1.next = l2
	l2.next = l3
	l3.next = l1
	l3.prev = l2
	l2.prev = l1
	l1.prev = l3

	l1.edge = e1
	l2.edge = e2
	l3.edge = e3
	e1.loops.append(l1)
	e2.loops.append(l2)
	e3.loops.append(l3)

	v1.faces.append(f)
	v2.faces.append(f)
	v3.faces.append(f)

	e1.faces.append(f)
	e2.faces.append(f)
	e3.faces.append(f)

	l1.face = f
	l2.face = f
	l3.face = f

	f.verts.append(v1)
	f.verts.append(v2)
	f.verts.append(v3)

	f.edges.append(e1)
	f.edges.append(e2)
	f.edges.append(e3)

	f.gmesh = gmesh
	
	faces.append(f)

	return f
	
func poke_face(face:GFace, offset:float = 0.0) -> Array:
	if faces.has(face):
		faces.erase(face)
	
	var v:GVertex = create_vertex(face.get_center() + face.calc_normal() * offset)
	var new_faces : = [
		create_face(face.verts[0],face.verts[1],v),
		create_face(face.verts[1],face.verts[2],v),
		create_face(face.verts[0],v,face.verts[2]),
	]
	face.remove()
	return new_faces
	
func commit():
	for vert in verts:
		gmesh.add_vertex(vert)
	for edge in edges:
		gmesh.add_edge(edge)
	for face in faces:
		gmesh.add_face(face)
	for loop in loops:
		gmesh.add_loop(loop)

func create_quad(v1:GVertex,v2:GVertex,v3:GVertex,v4:GVertex) -> Array:
	return [create_face(v1,v2,v3),create_face(v3,v4,v1)]

# TODO, remove auto merge
func create_from_mesh(mesh:Mesh,surface:int = 0,auto_merge:bool = false) -> GSelection:
	
	if mesh is PrimitiveMesh:
		var arr:Array = mesh.get_mesh_arrays()
		mesh = ArrayMesh.new()
		auto_merge = true
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arr)
		surface = mesh.get_surface_count()-1

	clear()
	
	var _data : = MeshDataTool.new()
	_data.create_from_surface(mesh,surface)
	#primitive_type = (mesh as ArrayMesh).surface_get_primitive_type(surface)

	var _vert_hash : = {}

	for i in range(_data.get_face_count()):

		var v1i:int = _data.get_face_vertex(i,0)
		var v2i:int = _data.get_face_vertex(i,1)
		var v3i:int = _data.get_face_vertex(i,2)

		var v1p:Vector3 = _data.get_vertex(v1i)
		var v2p:Vector3 = _data.get_vertex(v2i)
		var v3p:Vector3 = _data.get_vertex(v3i)

		var v1:GVertex
		var v2:GVertex
		var v3:GVertex
		if auto_merge:
			if _vert_hash.has(v1p):
				v1 = _vert_hash[v1p]
			else:
				v1 = add_vertex(v1p)
				_vert_hash[v1p] = v1

			if _vert_hash.has(v2p):
				v2 = _vert_hash[v2p]
			else:
				v2 = add_vertex(v2p)
				_vert_hash[v2p] = v2

			if _vert_hash.has(v3p):
				v3 = _vert_hash[v3p]
			else:
				v3 = add_vertex(v3p)
				_vert_hash[v3p] = v3
		else:
			v1 = add_vertex(v1p)
			v2 = add_vertex(v2p)
			v3 = add_vertex(v3p)

		if v1.index == v2.index or v1.index == v3.index or v2.index == v3.index:
			continue


		var face:GFace = add_face(v1,v2,v3)

		face.normal = _data.get_face_normal(i)
		var l1:GLoop = face.loops[0]
		var l2:GLoop = face.loops[1]
		var l3:GLoop = face.loops[2]

		v1.bones = _data.get_vertex_bones(v1i)
		v2.bones = _data.get_vertex_bones(v2i)
		v3.bones = _data.get_vertex_bones(v3i)

		v1.weights = _data.get_vertex_weights(v1i)
		v2.weights = _data.get_vertex_weights(v2i)
		v3.weights = _data.get_vertex_weights(v3i)

		l1.color = _data.get_vertex_color(v1i)
		l2.color = _data.get_vertex_color(v2i)
		l3.color = _data.get_vertex_color(v3i)

		l1.normal = _data.get_vertex_normal(v1i)
		l2.normal = _data.get_vertex_normal(v2i)
		l3.normal = _data.get_vertex_normal(v3i)

		l1.tangent = _data.get_vertex_tangent(v1i)
		l2.tangent = _data.get_vertex_tangent(v2i)
		l3.tangent = _data.get_vertex_tangent(v3i)

		l1.uv = _data.get_vertex_uv(v1i)
		l2.uv = _data.get_vertex_uv(v2i)
		l3.uv = _data.get_vertex_uv(v3i)

		l1.uv2 = _data.get_vertex_uv2(v1i)
		l2.uv2 = _data.get_vertex_uv2(v2i)
		l3.uv2 = _data.get_vertex_uv2(v3i)

		l1.smooth = l1.normal != face.normal
		l2.smooth = l2.normal != face.normal
		l3.smooth = l3.normal != face.normal

		face.calc_area()
	
	for vert in verts:
		vert.calc_normal()
		vert.calc_pointiness()
		vert.calc_crease()
	
	return self
