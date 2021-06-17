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
		
		# applying damping to the body can supress jitter
		state.add_central_force(-state.linear_velocity  * linear_damping)
		state.add_torque(-state.angular_velocity * angular_damping)
		
		var parent_pose:Transform
		var local_pose:Transform
		var local_transform:Transform
		
		if parent_id == -1:
			parent_pose = skeleton_transfrom
			local_transform = parent_pose.affine_inverse() * state.transform
			# Get where the bone would be globally in the current animation
			local_pose = skeleton.get_bone_global_pose_no_override(bone_id) * body_offset
		else:
			var root_bone_pose = skeleton.get_bone_global_pose(root_bone_id).interpolate_with(Transform(), align_globally)
			
			# Getting the parent bone allows all bone positions to be relative to the position and rotation of the parent
			parent_pose = skeleton_transfrom * skeleton.get_bone_global_pose_no_override(parent_id)
			
			# When align_globally is 0, we align all transforms relative to the root bone, instead of the global animation position
			local_transform = (root_bone_pose * parent_pose).affine_inverse() * state.transform
			
			# Get where the bone would be locally in the current animation
			local_pose = skeleton.get_bone_rest(bone_id) * skeleton.get_bone_pose(bone_id) * body_offset
			
		# We apply back our global position to our local transforms so we can get the difference in global space
		var final_transform:Transform = parent_pose * local_transform
		var final_pose:Transform = parent_pose * local_pose
		
		var diff = (final_transform.affine_inverse() * final_pose)
		
		var force = ( max_force / state.inverse_mass) * force_multiplier;
		
		if parent_id == -1:
			# The root bone will try to interpolate it's position to where it would be if it was not simulating physics
			var target_position = final_pose.origin 
			# add velocity to the current position to slow down sooner rather than over shooting
			var current_position = final_transform.origin + state.linear_velocity * delta
			# We remove divide force by delta to make the force independent of time (making it stronger)
			state.add_central_force((target_position - current_position) * (force / delta) * align_globally)
		
		# We only care about the rotation component
		var desired_rotation = diff.basis.get_rotation_quat()
		# The w component of the quat can describe the angle around the axis
		var angle = 2.0 * acos(desired_rotation.w)
		
		if angle and not (is_inf(angle) or is_nan(angle)):
			var axis:Vector3 = Vector3(desired_rotation.x, desired_rotation.y, desired_rotation.z) * (1.0/sin(angle*0.5))
			# Now that we have the axis and angle of rotation, we just need to multiply them to get the torque
			var torque:Vector3 = (axis * angle) 
			# torque is currently in relative space, but we need to transform it to be a global torque
			# so we just transform it by our current rotation
			torque = state.transform.basis.xform(torque) 
			# we also subtract our current angular velocity to slow down
			state.add_torque(torque * force - state.angular_velocity * delta)
