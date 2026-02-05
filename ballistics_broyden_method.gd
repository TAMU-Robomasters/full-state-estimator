extends Node3D

#TODO see if it possible to have wonky robots with different radius for each
# armor panel

var gravity_acceleration: Vector3 = Vector3(0,-9.8,0)
var projectile_speed: float = 25
var _travel_time: float
@export_range(0,5) var bx: float 
@export_range(0,5) var by: float 
@export_range(0,5) var bz: float

@export_range(0,5) var a_radius: float
@export_range(0,5) var b_radius: float
var min_idx: int

#TODO add hieght for different armor panels
var ballistic_solution: Vector3 = Vector3.ZERO
var _impact_pos: Vector3



@onready var target_body: RigidBody3D = $"../Target/RigidBody3D"
@onready var ap1: MeshInstance3D = $"../Target/RigidBody3D/ap1"
@onready var ap2: MeshInstance3D = $"../Target/RigidBody3D/ap2"
@onready var ap3: MeshInstance3D = $"../Target/RigidBody3D/ap3"
@onready var ap4: MeshInstance3D = $"../Target/RigidBody3D/ap4"


var _f_no_spin = func (x: Vector3) -> Vector3:
	# x = [yaw, pitch, time]
	var a_t: Vector3 = _ZXY_to_YXZ(target_body.get_linear_acceleration())
	var v_t: Vector3 = _ZXY_to_YXZ(target_body.get_linear_velocity())
	var p_t: Vector3 = _ZXY_to_YXZ(target_body.get_position())
	var b: Vector3 = Vector3(bx, by, bz)
	var s: float = projectile_speed
	var g: float = gravity_acceleration.y
	var f_x: float
	var f_y: float
	var f_z: float
	
	f_x = b.x*cos(x[0]) - sin(x[0])*(b.y*cos(x[1]) - b.z*sin(x[1])) - s*x[2]*sin(x[0])*cos(x[1]) - p_t.x - v_t.x*x[2] - 0.5*a_t.x*x[2]**2
	f_y = b.x*sin(x[0]) + cos(x[0])*(b.y*cos(x[1]) - b.z*sin(x[1])) + s*x[2]*cos(x[0])*cos(x[1]) - p_t.y - v_t.y*x[2] - 0.5*a_t.y*x[2]**2
	f_z = b.y*sin(x[1]) + b.z*cos(x[1]) + s*x[2]*sin(x[1]) + 0.5*(g-a_t.z)*x[2]**2 - p_t.z - v_t.z*x[2]
	
	return Vector3(f_x, f_y, f_z)
	
	
var _f_spin = func (x: Vector3) -> Vector3:
	# x = [yaw, pitch, time]
	var a_t: Vector3 = _ZXY_to_YXZ(target_body.get_linear_acceleration())
	var v_t: Vector3 = _ZXY_to_YXZ(target_body.get_linear_velocity())
	var p_t: Vector3 = _ZXY_to_YXZ(target_body.get_position())

	var b: Vector3 = Vector3(bx, by, bz)
	var s: float = projectile_speed
	var a_r: float = a_radius
	var b_r: float = b_radius
	
	var tht_t: float = target_body.get_rotation().y
	var omg_t: float = target_body.get_angular_velocity().y
	var alp_t: float = target_body.get_angular_acceleration().y
	var tht: float = tht_t + omg_t*x[2] + alp_t*x[2]**2
	
	# depends of which armor panel were aiming at
	var tht_offset: float 
	var r: float 
	
	if min_idx == 0 or min_idx == 2:
		r = a_r
	else:
		r = b_r
		
	tht_offset = min_idx*(PI/2)
	
	var g: float = gravity_acceleration.y
	
	var f_x: float
	var f_y: float
	var f_z: float
	
	#print(r)
	#print(tht_offset*180/PI)
	
	f_x = b.x*cos(x[0]) - sin(x[0])*(b.y*cos(x[1]) - b.z*sin(x[1])) - s*x[2]*sin(x[0])*cos(x[1]) - p_t.x - v_t.x*x[2] - 0.5*a_t.x*x[2]**2 - r*sin(tht + tht_offset)
	f_y = b.x*sin(x[0]) + cos(x[0])*(b.y*cos(x[1]) - b.z*sin(x[1])) + s*x[2]*cos(x[0])*cos(x[1]) - p_t.y - v_t.y*x[2] - 0.5*a_t.y*x[2]**2 - r*cos(tht + tht_offset)
	f_z = b.y*sin(x[1]) + b.z*cos(x[1]) + s*x[2]*sin(x[1]) + 0.5*(g-a_t.z)*x[2]**2 - p_t.z - v_t.z*x[2]
	
	return Vector3(f_x, f_y, f_z)
	

func _ZXY_to_YXZ(v: Vector3) -> Vector3:
	return Vector3(v[0], v[2], v[1])

func _YXZ_to_ZXY(v: Vector3) -> Vector3:
	return Vector3(v[0], v[2], v[1])
	

func _process(delta: float) -> void:
	ap3.position = Vector3(0,0,a_radius)
	ap4.position = Vector3(b_radius,0,0)
	ap1.position = Vector3(0,0,-a_radius)
	ap2.position = Vector3(-b_radius,0,0)
	
	_estimate_ballistic_solution(5, 0.001)
	var t: float = get_travel_time()
	var a: Vector3 = target_body.get_linear_acceleration()
	var v: Vector3 = target_body.get_linear_velocity()
	var p: Vector3 = target_body.get_position()
	

	_impact_pos = p + v*t + 0.5*a*t**2
	

func _get_target_pos_at(time: float) -> Vector3:
	# x = [yaw, pitch, time]
	#var a_t: Vector3 = _ZXY_to_YXZ(target_body.get_linear_acceleration())
	#var v_t: Vector3 = _ZXY_to_YXZ(target_body.get_linear_velocity())
	var p_t: Vector3 = _ZXY_to_YXZ(target_body.get_position())
	
	var a_r: float = a_radius
	var b_r: float = b_radius
	
	var tht_t: float = target_body.get_rotation().y
	#var omg_t: float = target_body.get_angular_velocity().y
	#var alp_t: float = target_body.get_angular_acceleration().y
	#var tht: float = tht_t + omg_t*time + alp_t*time**2
	
	# depends of which armor panel were aiming at
	var tht_offset: float 
	var r: float 
	
	if min_idx == 0 or min_idx == 2:
		r = a_r
	else:
		r = b_r
		
	tht_offset = min_idx*(PI/2)
	
	var g: float = gravity_acceleration.y
	
	var f_x: float
	var f_y: float
	var f_z: float
	
	#f_x = p_t.x + v_t.x*time + 0.5*a_t.x*time**2 + r*cos(tht + tht_offset)
	#f_y = p_t.y + v_t.y*time + 0.5*a_t.y*time**2 - r*sin(tht + tht_offset)
	#f_z = p_t.z + v_t.z*time + 0.5*a_t.z*time**2
	
	f_x = p_t.x + r*sin(tht_t + tht_offset)
	f_y = p_t.y + r*cos(tht_t + tht_offset)
	f_z = p_t.z
	
	return _YXZ_to_ZXY(Vector3(f_x, f_y, f_z))
	
func get_impact_pos() -> Vector3:
	return _impact_pos

func get_yaw() -> float:
	return ballistic_solution[0]

func get_pitch() -> float:
	return ballistic_solution[1]


func get_travel_time() -> float:
	return ballistic_solution[2]

func _estimate_ballistic_solution(iterations: int, max_error: float):
	var init_guess: Vector3
	var solver_result: Vector3
	
	init_guess = _simple_init_guess()
	
	solver_result = _good_broyden_solver(init_guess, iterations, max_error, _f_no_spin)
	
	if solver_result != Vector3(-1, -1, -1):
		_set_min_idx(solver_result)
		solver_result = _good_broyden_solver(solver_result, iterations, max_error, _f_spin)
		if solver_result != Vector3(-1, -1, -1):
			ballistic_solution = solver_result


func _set_min_idx(state: Vector3): 
	var x = state
	var a_t: Vector3 = _ZXY_to_YXZ(target_body.get_linear_acceleration())
	var v_t: Vector3 = _ZXY_to_YXZ(target_body.get_linear_velocity())
	var p_t: Vector3 = _ZXY_to_YXZ(target_body.get_position())
	var p: Vector2 = Vector2(
			p_t.x + v_t.x*x[2] + a_t.x*x[2]**2, 
			p_t.y + v_t.y*x[2] + a_t.y*x[2]**2
		)
	var p_u: Vector2 = -p.normalized()
	
	var tht_t: float = target_body.get_rotation().y
	var omg_t: float = target_body.get_angular_velocity().y
	var alp_t: float = target_body.get_angular_acceleration().y
	var tht: float = tht_t + omg_t*x[2] + alp_t*x[2]**2
	tht = -tht
	
	var ap3_u: Vector2 = Vector2.from_angle(tht)
	var ap4_u: Vector2 = Vector2.from_angle(tht+PI/2)
	var ap1_u: Vector2 = Vector2.from_angle(tht+PI)
	var ap2_u: Vector2 = Vector2.from_angle(tht-PI/2)
	
	var dot_array: Array = [p_u.dot(ap4_u), p_u.dot(ap3_u), p_u.dot(ap2_u), p_u.dot(ap1_u)]
	var max_dot: float = dot_array.max()

	#TODO change all min to max 
	min_idx = dot_array.find(max_dot)

	
	
func _simple_init_guess() -> Vector3:
	var init_guess: Vector3
	var s: float = projectile_speed
	var g: float = gravity_acceleration.y
	var t: float = target_body.get_position().length() / s #big
	init_guess[2] = t
	
	var target_impact_pos = _ZXY_to_YXZ(target_body.get_position())
	var horizontal_dist = sqrt(target_impact_pos.x**2 + target_impact_pos.y**2)
	var pitch: float = atan((target_impact_pos.z-0.5*g*t**2) / horizontal_dist)
	init_guess[1] = pitch
	
	var yaw: float = acos(target_impact_pos.y / horizontal_dist)
	if target_impact_pos.x > 0:
		yaw *= -1
	init_guess[0] = yaw	
	
	return init_guess

func _good_broyden_solver(init_guess: Vector3, iterations: int, max_error: float, f: Callable) -> Vector3:
	var inverse_jacob: Basis
	var x_curr: Vector3
	var x_past: Vector3
	var del_x: Vector3
	var del_f: Vector3
	var err: float
	var min_diff: float = 0.001
	# Good Broyden's Method
	for n in range(iterations):
		if n == 0:
			inverse_jacob = _approximate_inverse_jacobian(0.001, init_guess, f)
			x_curr = init_guess - inverse_jacob*f.call(init_guess)
			x_past = init_guess
			err = x_curr.distance_to(Vector3.ZERO)
		else:
			# Sherman-Morrison Formula 
			del_x = x_curr - x_past
			del_f = f.call(x_curr) - f.call(x_past)
			inverse_jacob = _add(inverse_jacob, _create_matrix(del_x - inverse_jacob*del_f, inverse_jacob.transposed()*del_x)/(del_x.dot(inverse_jacob*del_f)))
			x_past = x_curr
			x_curr = x_curr - inverse_jacob*f.call(x_curr)
			err = x_curr.distance_to(Vector3.ZERO)
		
		if  f.call(x_curr).distance_to(Vector3.ZERO) < max_error or n == iterations - 1 or (x_curr - x_past).length() < min_diff:
			#print(f.call(x_curr).distance_to(Vector3.ZERO))
			return x_curr
	
	# if no solution return all -1
	return Vector3(-1, -1, -1)
			
func _create_matrix(col_v: Vector3, row_v: Vector3) -> Basis:
	var column_1: Vector3 = Vector3(col_v[0]*row_v[0], col_v[1]*row_v[0], col_v[2]*row_v[0])
	var column_2: Vector3 = Vector3(col_v[0]*row_v[1], col_v[1]*row_v[1], col_v[2]*row_v[1])
	var column_3: Vector3 = Vector3(col_v[0]*row_v[2], col_v[1]*row_v[2], col_v[2]*row_v[2])
	
	return Basis(column_1, column_2, column_3)
## I love my gf Faith

func _add(m1: Basis, m2: Basis) -> Basis:
	var column_1: Vector3 = m1.x + m2.x
	var column_2: Vector3 = m1.y + m2.y
	var column_3: Vector3 = m1.z + m2.z
	
	return Basis(column_1, column_2, column_3)

	

func _approximate_inverse_jacobian(step_size: float, x_0: Vector3, f: Callable) -> Basis:
	var column_1: Vector3
	var column_2: Vector3
	var column_3: Vector3
	
	column_1 = (f.call(x_0+Vector3(step_size, 0, 0)) - f.call(x_0)) / step_size
	column_2 = (f.call(x_0+Vector3(0, step_size, 0)) - f.call(x_0)) / step_size
	column_3 = (f.call(x_0+Vector3(0, 0, step_size)) - f.call(x_0)) / step_size
	
	return Basis(column_1, column_2, column_3).inverse()
