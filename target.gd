extends Node3D

signal two_panels_visible(radii: Vector2, center: Vector2)
signal one_panel_visible(pos: Vector2, unit_vec: Vector2)

@onready var panel_1 = $"RigidBody3D/ap1"
@onready var panel_2 = $"RigidBody3D/ap2"
@onready var panel_3 = $"RigidBody3D/ap3"
@onready var panel_4 = $"RigidBody3D/ap4"


func _process(delta: float) -> void:
	var count: int = 2
	var p1: Vector2
	var p2: Vector2
	var u: Vector2
	var u_perp: Vector2
	var u2: Vector2
	var rot: float
	var rot_noise: float = deg_to_rad(randfn(0, 10))
	var rot_offsets: Array = [deg_to_rad(10), deg_to_rad(-10)]
	var position_noise: Vector2 = Vector2(randfn(0, 0.05),randfn(0, 0.05)) # 5 cm
	var config: int = -1
	var panel_id: int = -1
	 
	if panel_1.is_panel_visible():
		p1 = Vector2(panel_1.global_position.x, panel_1.global_position.z) + position_noise
		rot = panel_1.global_rotation.y + rot_noise + rot_offsets.pick_random()
		u = -Vector2(sin(rot), cos(rot))
		u_perp = Vector2(-u.y, u.x)
		config = 1
		panel_id = 1
	elif panel_3.is_panel_visible(): 
		p1 = Vector2(panel_3.global_position.x, panel_3.global_position.z) + position_noise
		rot = panel_3.global_rotation.y + rot_noise + rot_offsets.pick_random()
		u = Vector2(sin(rot), cos(rot))
		u_perp = Vector2(-u.y, u.x)
		config = 3
		panel_id = 3
	else:
		config = -1
		count -= 1
	
	if panel_2.is_panel_visible():
		p2 = Vector2(panel_2.global_position.x, panel_2.global_position.z) + position_noise
		rot = panel_2.global_rotation.y + rot_noise + rot_offsets.pick_random()
		u2 = -Vector2(sin(rot), cos(rot))
		panel_id = 2
	elif panel_4.is_panel_visible():
		p2 = Vector2(panel_4.global_position.x, panel_4.global_position.z) + position_noise
		rot = panel_4.global_rotation.y + rot_noise + rot_offsets.pick_random()
		u2 = Vector2(sin(rot), cos(rot))
		panel_id = 4
	else:
		count -= 1
	
	if count == 2: # two panels found
		var r1: float
		var r2: float
		var center: Vector2
		
		#NOTE when i switch where p1 and p2 are it switches which ellipise center
		# it's calculating for
		center = p2.dot(u) * u + p1.dot(u_perp) * u_perp
		if config == 1:
			r1 = (center - p1).length()
			r2 = (center - p2).length()
			two_panels_visible.emit(Vector2(r1, r2), center)
		elif config == 3:
			r1 = (center - p2).length()
			r2 = (center - p1).length()
			two_panels_visible.emit(Vector2(r2, r1), center)
			
	if count == 1: # one panel found
		
		match panel_id:
			1, 3:
				one_panel_visible.emit(p1, u, "a")
			2, 4:
				one_panel_visible.emit(p2, u2, "b")
		
		
		
