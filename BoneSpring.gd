tool
extends Spatial
class_name BoneSpring

# Bone Spring is a node that allows bones to rotate to their resting position
# but uses a spring force to make it more wiggly

export var enabled:bool = true setget set_enabled
export(int, "idle", "physics") var process_mode = 0
export(float, 0.0, 1.0) var interpolation:float = 1.0
export(int, "-Z", "+Z", "-Y", "+Y", "-X", "+X") var forward = 0
export var up:Vector3 = Vector3.UP
export var roll_degrees:float = 0.0
export(float, 0.1, 16.0) var stiffness:float = 1.0
export(float, 0.0, 16.0) var damping:float = 0.0
export var gravity_direction:Vector3 = Vector3.DOWN
export(float, -128, 128) var gravity_strength:float = 9.81
export var reset_bone_transform:bool = true

var previous_position:Vector3

func set_enabled(value:bool):
	enabled = value
	set_process(enabled and process_mode == 0)
	set_physics_process(enabled and process_mode == 1)
	if not enabled and is_inside_tree():
		var parent = get_parent() as Skeleton
		if parent:
			var bone_index = parent.find_bone(get("bone_name"))
			if bone_index >= 0:
				parent.set_bone_global_pose_override(bone_index, Transform(), 0.0, false)

func _get(property):
	if property == "bone_name" and has_meta(property):
		return get_meta(property)
	return null

func _set(property, value):
	if property == "bone_name":
		set_meta(property, value)
		if is_inside_tree():
			var parent = get_parent() as Skeleton
			if parent: parent.clear_bones_global_pose_override()
		return true

func _get_property_list():
	var parent = get_parent() as Skeleton
	if parent:
		var bone_names:PoolStringArray = PoolStringArray()
		for i in parent.get_bone_count():
			bone_names.append(parent.get_bone_name(i))
		return [
			{
				"name": "bone_name",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": bone_names.join(",")
			}
		]
	
	return [{"name": "bone_name", "type": TYPE_STRING, "hint": PROPERTY_HINT_NONE, "hint_string":""}]

func _track_target(delta):
	
	var parent = get_parent() as Skeleton
	
	if parent and delta:
		var bone_index = parent.find_bone(get("bone_name"))
		if bone_index >= 0:
			if reset_bone_transform:
				parent.set_bone_global_pose_override(bone_index, Transform(), 0.0, false)
			var bone_parent_index = parent.get_bone_parent(bone_index)
			var bone_transform = parent.get_bone_global_pose(bone_index)
			
			match forward:
				1: bone_transform.basis = Basis(-bone_transform.basis.x, bone_transform.basis.y, -bone_transform.basis.z)
				2: bone_transform.basis = Basis(-bone_transform.basis.x, bone_transform.basis.z, bone_transform.basis.y)
				3: bone_transform.basis = Basis(-bone_transform.basis.x, -bone_transform.basis.z, -bone_transform.basis.y)
				4: bone_transform.basis = Basis(bone_transform.basis.z, bone_transform.basis.y, -bone_transform.basis.x)
				5: bone_transform.basis = Basis(-bone_transform.basis.z, bone_transform.basis.y, bone_transform.basis.x)
				
			var bone_rest_transform = parent.global_transform * bone_transform
			
			var gravity:Vector3 = Vector3()
			var velocity = (global_transform.origin - previous_position) / delta
			
			if gravity_direction:
				gravity = gravity_direction * gravity_strength
			else:
				gravity = bone_rest_transform.basis.xform(Vector3.FORWARD).normalized() * gravity_strength
			
			gravity *= stiffness
			velocity += gravity
			velocity -= velocity * damping * delta
			
			previous_position = global_transform.origin
			global_transform.origin += velocity * delta
			
			var goal_position = parent.global_transform.xform(bone_transform.origin)
			var diff = (global_transform.origin - goal_position).normalized()
			if not diff:
				diff = Vector3.FORWARD
			var clamped_goal_position = goal_position + diff
			global_transform.origin = clamped_goal_position
			
			bone_transform = bone_transform.looking_at(parent.global_transform.xform_inv(clamped_goal_position), up)
			
			match forward:
				1: bone_transform.basis = Basis(-bone_transform.basis.x, bone_transform.basis.y, -bone_transform.basis.z)
				2: bone_transform.basis = Basis(-bone_transform.basis.x, bone_transform.basis.z, bone_transform.basis.y)
				3: bone_transform.basis = Basis(-bone_transform.basis.x, -bone_transform.basis.z, -bone_transform.basis.y)
				4: bone_transform.basis = Basis(bone_transform.basis.z, bone_transform.basis.y, -bone_transform.basis.x)
				5: bone_transform.basis = Basis(-bone_transform.basis.z, bone_transform.basis.y, bone_transform.basis.x)
			
			var rot_axis = (clamped_goal_position - bone_transform.origin).normalized()
			if rot_axis:
				bone_transform.basis = bone_transform.basis.rotated(rot_axis, deg2rad(roll_degrees))
			
			parent.set_bone_global_pose_override(bone_index, bone_transform, interpolation, true)

func _ready():
	set_enabled(enabled)
	set_as_toplevel(true)
	previous_position = global_transform.origin
	
func _exit_tree():
	var parent = get_parent() as Skeleton
	if parent:
		parent.clear_bones_global_pose_override()

func _notification(what):
	if enabled and (what == NOTIFICATION_PHYSICS_PROCESS or what == NOTIFICATION_PROCESS):
		var delta
		if what == NOTIFICATION_PROCESS:
			delta = get_process_delta_time()
		else:
			delta = get_physics_process_delta_time()
		_track_target(delta)
