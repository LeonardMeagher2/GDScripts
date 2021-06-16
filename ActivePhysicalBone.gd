extends PhysicalBone
class_name ActivePhysicalBone

export var enabled:bool = true
export(float, 0.0, 1.0) var force_multiplier = 1.0
export var max_force:float = 14.0
export var linear_damping:float = 0.9
export var angular_damping:float = 0.2
export(float, 0.0, 1.0) var align_globally:float = 1.0

onready var skeleton:Skeleton = get_parent()
onready var parent_id = skeleton.get_bone_parent(get_bone_id())
onready var root_bone_id = get_root_bone_id()

func get_root_bone_id():
	if skeleton:
		var bone_id = get_bone_id()
		while true:
			var next = skeleton.get_bone_parent(bone_id)
			if next == -1:
				return bone_id
			bone_id = next

func _physics_process(delta):
	if enabled and skeleton and is_simulating_physics() and not is_static_body():

		var skeleton_transfrom = skeleton.global_transform
		var state = PhysicsServer.body_get_direct_state(get_rid())
		var bone_id = get_bone_id()
		
		state.add_central_force(-state.linear_velocity  * linear_damping)
		state.add_torque(-state.angular_velocity * angular_damping)
		
		var parent_pose:Transform
		var local_pose:Transform
		var local_transform:Transform
		
		if parent_id == -1:
			parent_pose = skeleton_transfrom
			local_transform = parent_pose.affine_inverse() * state.transform
			local_pose = skeleton.get_bone_global_pose_no_override(bone_id) * body_offset
		else:
			var root_bone_pose = skeleton.get_bone_global_pose(root_bone_id).interpolate_with(Transform(), align_globally)
			parent_pose = skeleton_transfrom * skeleton.get_bone_global_pose_no_override(parent_id)
			local_transform = (root_bone_pose * parent_pose).affine_inverse() * state.transform
			local_pose = skeleton.get_bone_rest(bone_id) * skeleton.get_bone_pose(bone_id) * body_offset
			
		
		var final_parent_pose = parent_pose.interpolate_with(Transform(parent_pose.basis, Vector3.ZERO), 1.0 - align_globally)
		var final_transform:Transform = final_parent_pose * local_transform
		var final_pose:Transform = final_parent_pose * local_pose
		
		if align_globally and parent_id == -1:
				state.add_central_force((final_pose.origin - final_transform.origin) / delta / state.inverse_mass * max_force * force_multiplier * align_globally)
		
		var desired_rotquat = (final_transform.affine_inverse() * final_pose).basis.get_rotation_quat()
		
		var angle = 2.0 * acos(desired_rotquat.w)
		
		if angle and not (is_inf(angle) or is_nan(angle)):
			var axis:Vector3 = Vector3(desired_rotquat.x, desired_rotquat.y, desired_rotquat.z) * (1.0/sin(angle*0.5))
			var torque:Vector3 = axis * angle
			
			torque = state.transform.basis.xform(torque)
			
			state.add_torque(torque * max_force * force_multiplier  / state.inverse_mass)
		
		state.integrate_forces()
