extends PhysicalBone
class_name ActivePhysicalBone

export var enabled:bool = true
export var translation_force:float = 100.0
export var torque_force:float = 14.0
export var damping:float = 0.1
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
		
		var local_angular_velocity = state.transform.xform_inv(state.angular_velocity) / state.inverse_inertia
		
		state.add_central_force(-state.linear_velocity * damping )
		state.add_torque(-local_angular_velocity * damping )
		
		var parent_pose:Transform
		var local_pose:Transform
		var local_transform:Transform
		
		if parent_id == -1:
			local_transform = state.transform
			parent_pose = skeleton_transfrom
			local_pose = skeleton.get_bone_global_pose_no_override(bone_id) * body_offset
			# interpolate linear velocity towards goal position
			state.add_central_force(((parent_pose * local_pose).origin - local_transform.origin) * translation_force)
		else:
			var root_bone_pose = skeleton.get_bone_global_pose(root_bone_id).interpolate_with(Transform(), align_globally)
			parent_pose = root_bone_pose * skeleton_transfrom * skeleton.get_bone_global_pose_no_override(parent_id)
			local_transform = parent_pose.affine_inverse() * state.transform
			local_pose = skeleton.get_bone_rest(bone_id) * skeleton.get_bone_pose(bone_id) * body_offset
		
		var desired_rotation = (local_transform.affine_inverse() * local_pose).basis
		var desired_rotquat = desired_rotation.get_rotation_quat()
		var angle = 2.0 * acos(desired_rotquat.w)
		
		if angle and not (is_inf(angle) or is_nan(angle)):
			var axis = Vector3(desired_rotquat.x, desired_rotquat.y, desired_rotquat.z) * (1.0/sin(angle*0.5))
			var torque = axis * angle
			torque = state.transform.basis.xform(torque)
			state.add_torque(torque * torque_force)
		
		state.integrate_forces()
