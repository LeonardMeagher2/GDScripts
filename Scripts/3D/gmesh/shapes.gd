extends Reference

static func add_pyramid_tetrahedron(mesh:GMesh, radius:float = 1.0, transform:Transform = Transform(), smooth:bool = false) -> Array:
	var sqr3 : = sqrt(3.0)
	var sqr6 : = sqrt(6.0)
	
	var v1 : = mesh.add_vertex(transform.xform(Vector3( sqr3/3.0,   0,-sqr6/12.0) * radius))
	var v2 : = mesh.add_vertex(transform.xform(Vector3(-sqr3/6.0, 0.5,-sqr6/12.0) * radius))
	var v3 : = mesh.add_vertex(transform.xform(Vector3(        0,   0, sqr6/4.0 ) * radius))
	var v4 : = mesh.add_vertex(transform.xform(Vector3(-sqr3/6.0,-0.5,-sqr6/12.0) * radius))
	
	var faces = []
	faces.append(mesh.add_face(v2,v1,v3)) # bottom
	faces.append(mesh.add_face(v3,v4,v2)) # left
	faces.append(mesh.add_face(v2,v4,v1)) # right front
	faces.append(mesh.add_face(v1,v4,v3)) # right back
	
	for face in faces:
		face.calc_normal()
		face.set_smooth(smooth)
	
	var verts = [v1,v2,v3,v4]
	for vert in verts:
		vert.calc_normal()
	return verts
	
static func add_cube_tetrahedron(mesh:GMesh, radius:float = 1.0, transform:Transform = Transform(), smooth:bool = false) -> Array:
	var sqr2 : = sqrt(2.0)/4.0
	
	var v1 : = mesh.add_vertex(transform.xform(Vector3(-sqr2,-sqr2,-sqr2) * radius))
	var v2 : = mesh.add_vertex(transform.xform(Vector3( sqr2,-sqr2, sqr2) * radius))
	var v3 : = mesh.add_vertex(transform.xform(Vector3(-sqr2, sqr2, sqr2) * radius))
	var v4 : = mesh.add_vertex(transform.xform(Vector3( sqr2, sqr2,-sqr2) * radius))
	
	var faces = []
	faces.append(mesh.add_face(v2,v1,v3)) # bottom
	faces.append(mesh.add_face(v3,v4,v2)) # left
	faces.append(mesh.add_face(v2,v4,v1)) # right front
	faces.append(mesh.add_face(v1,v4,v3)) # right back
	
	for face in faces:
		face.calc_normal()
		face.set_smooth(smooth)
	
	var verts = [v1,v2,v3,v4]
	for vert in verts:
		vert.calc_normal()
	return verts

static func add_cube(mesh:GMesh, radius:float = 1.0, transform:Transform = Transform(), smooth:bool = false) -> Array:
	
	var v1 : = mesh.add_vertex(transform.xform(Vector3(-radius, radius,-radius)))
	var v2 : = mesh.add_vertex(transform.xform(Vector3( radius, radius,-radius)))
	var v3 : = mesh.add_vertex(transform.xform(Vector3( radius, radius, radius)))
	var v4 : = mesh.add_vertex(transform.xform(Vector3(-radius, radius, radius)))
	
	var v5 : = mesh.add_vertex(transform.xform(Vector3(-radius, -radius,-radius)))
	var v6 : = mesh.add_vertex(transform.xform(Vector3( radius, -radius,-radius)))
	var v7 : = mesh.add_vertex(transform.xform(Vector3( radius, -radius, radius)))
	var v8 : = mesh.add_vertex(transform.xform(Vector3(-radius, -radius, radius)))
	
	var faces = []
	faces += mesh.add_quad(v1,v2,v3,v4) # top
	faces += mesh.add_quad(v2,v6,v7,v3) # right
	faces += mesh.add_quad(v5,v8,v7,v6) # bottom
	faces += mesh.add_quad(v5,v1,v4,v8) # left
	faces += mesh.add_quad(v1,v5,v6,v2) # back
	faces += mesh.add_quad(v4,v3,v7,v8) # front
	
	for face in faces:
		face.calc_normal()
		face.set_smooth(smooth)
	
	var verts = [v1,v2,v3,v4,v5,v6,v7,v8]
	for vert in verts:
		vert.calc_normal()
	return verts
