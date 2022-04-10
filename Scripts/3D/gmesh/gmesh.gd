extends Resource
class_name GMesh

export(Array, Resource) var verts # all the verts in this mesh
export(Array, Resource) var edges # all the edges in this mesh
export(Array, Resource) var loops # all the loops in this mesh
export(Array, Resource) var faces # all the faces in this mesh

func _init():
	verts = []
	edges = []
	loops = []
	faces = []
	pass

func clear() -> GMesh:
	verts.clear()
	edges.clear()
	loops.clear()
	faces.clear()
	
	return self

func make_dirty() -> GMesh:
	for loop in loops:
		loop.dirty = true
	return self

func add_vertex(v:GVertex) -> GMesh:
	var index = verts.size()
	verts.append(v)
	v.index = index
	return self

func add_edge(e:GEdge) -> GMesh:
	var index = edges.size()
	edges.append(e)
	e.index = index
	return self
	
func add_loop(l:GLoop) -> GMesh:
	var index = loops.size()
	loops.append(l)
	l.index = index
	return self

func add_face(f:GFace) -> GMesh:
	var index = faces.size()
	faces.append(f)
	f.index = index
	return self

func get_triangles_arrays() -> Array:
	var arrays = Array()
	arrays.resize(VisualServer.ARRAY_MAX)
	var verts_array = PoolVector3Array()
	var normals_array = PoolVector3Array()
	var tangents_array = PoolRealArray()
	var colors_array = PoolColorArray()
	var uvs_array = PoolVector2Array()
	var uv2s_array = PoolVector2Array()
	var bones_array = PoolIntArray()
	var weights_array = PoolRealArray()
	
	for loop in loops:
		verts_array.append(loop.vert.position)
		normals_array.append(loop.normal)
		tangents_array.append_array([loop.tangent.x,loop.tangent.y,loop.tangent.z,loop.tangent.d])
		colors_array.append(loop.color)
		uvs_array.append(loop.uv)
		uv2s_array.append(loop.uv2)
		bones_array.append_array(loop.vert.bones)
		weights_array.append_array(loop.vert.weights)
		
	arrays[VisualServer.ARRAY_VERTEX] = verts_array
	arrays[VisualServer.ARRAY_NORMAL] = normals_array
	arrays[VisualServer.ARRAY_TANGENT] = tangents_array
	arrays[VisualServer.ARRAY_COLOR] = colors_array
	arrays[VisualServer.ARRAY_TEX_UV] = uvs_array
	arrays[VisualServer.ARRAY_TEX_UV2] = uv2s_array
	if bones_array.size():
		arrays[VisualServer.ARRAY_BONES] = bones_array
	if weights_array.size():
		arrays[VisualServer.ARRAY_WEIGHTS] = weights_array
		
	return arrays
	
func get_lines_arrays() -> Array:
	var arrays = Array()
	arrays.resize(VisualServer.ARRAY_MAX)
	var verts_array = PoolVector3Array()
	var normals_array = PoolVector3Array()
	var bones_array = PoolIntArray()
	var weights_array = PoolRealArray()
	
	for edge in edges:
		verts_array.append(edge.verts[0].position)
		verts_array.append(edge.verts[1].position)
		
		normals_array.append(edge.verts[0].normal)
		normals_array.append(edge.verts[1].normal)
		
		bones_array.append_array(edge.verts[0].bones)
		bones_array.append_array(edge.verts[1].bones)
		
		weights_array.append_array(edge.verts[0].weights)
		weights_array.append_array(edge.verts[1].weights)
		
	arrays[VisualServer.ARRAY_VERTEX] = verts_array
	arrays[VisualServer.ARRAY_NORMAL] = normals_array
	if bones_array.size():
		arrays[VisualServer.ARRAY_BONES] = bones_array
	if weights_array.size():
		arrays[VisualServer.ARRAY_WEIGHTS] = weights_array
	
	return arrays
	

func flip() -> GMesh:
	for face in faces:
		face.flip()
	return self

func calc_normals() -> GMesh:
	for face in faces:
		face.calc_normal()
	for vert in verts:
		vert.calc_normal()

	for loop in loops:
		loop.calc_normal()
	return self

func grow(amount:float = 1.0) -> GMesh:
	for vert in verts:
		vert.position += vert.normal * amount
	return self
		
func translate(offset:Vector3) -> GMesh:
	for vert in verts:
		vert.position += offset
	return self
	
func get_center() -> Vector3:
	var center : = Vector3()
	for vert in verts:
		center += vert.position
	return center / verts.size()
	
func center_geometry() -> GMesh:
	var center = get_center()
	translate(-center)
	return self

