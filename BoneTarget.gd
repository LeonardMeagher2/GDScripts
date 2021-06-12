tool
extends Spatial
class_name BoneTarget

# BoneTarget points a bone towards it's self
# You can move this node to the actual target you want it to point to

export var enabled:bool = true setget set_enabled
export(int, "idle", "physics") var process_mode = 0
export(float, 0.0, 1.0) var interpolation:float = 1.0
export(int, "-Z", "+Z", "-Y", "+Y", "-X", "+X") var forward = 0
export var up:Vector3 = Vector3.UP
export var roll_degrees:float = 0.0
export var min_distance:float = 0.0

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

func _track_target():
	
	var parent = get_parent() as Skeleton
	if parent and up:
		var bone_index = parent.find_bone(get("bone_name"))
		if bone_index >= 0:
			# Get Animation pose by removing the pose override
			parent.set_bone_global_pose_override(bone_index, Transform(), 0.0, false)
			var bone_transform = parent.get_bone_global_pose(bone_index)
			var relative_target_position = parent.global_transform.xform_inv(global_transform.origin)
			
			var diff:Vector3 = relative_target_position - bone_transform.origin
			var interp = interpolation
			if diff.length_squared() < min_distance * min_distance:
				interp = min(diff.length_squared() / (min_distance * min_distance), interpolation)
			bone_transform = bone_transform.looking_at(relative_target_position, up)
			
			match forward:
				1: bone_transform.basis = Basis(-bone_transform.basis.x, bone_transform.basis.y, -bone_transform.basis.z)
				2: bone_transform.basis = Basis(-bone_transform.basis.x, bone_transform.basis.z, bone_transform.basis.y)
				3: bone_transform.basis = Basis(-bone_transform.basis.x, -bone_transform.basis.z, -bone_transform.basis.y)
				4: bone_transform.basis = Basis(bone_transform.basis.z, bone_transform.basis.y, -bone_transform.basis.x)
				5: bone_transform.basis = Basis(-bone_transform.basis.z, bone_transform.basis.y, bone_transform.basis.x)
			bone_transform.basis = bone_transform.basis.rotated((relative_target_position - bone_transform.origin).normalized(), deg2rad(roll_degrees))
			
			parent.set_bone_global_pose_override(bone_index, bone_transform, interp, true)

func _ready():
	set_enabled(enabled)
	
func _exit_tree():
	var parent = get_parent() as Skeleton
	if parent:
		parent.clear_bones_global_pose_override()

func _notification(what):
	if enabled and (what == NOTIFICATION_PHYSICS_PROCESS or what == NOTIFICATION_PROCESS):
		_track_target()
