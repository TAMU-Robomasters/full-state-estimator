extends Node3D

var gravity_acceleration: Vector3 = Vector3(0,-9.81,0)
var iterations: int = 10
var projectile_speed: float = 25
var _travel_time: float

@onready var target_body: RigidBody3D = $"../Target/RigidBody3D"

func get_impact_pos() -> Vector3:
	var t: float = get_travel_time()
	var a: Vector3 = target_body.get_linear_acceleration()
	var v: Vector3 = target_body.get_linear_velocity()
	var p: Vector3 = target_body.get_position()
	return p + v*t + 0.5*a*t**2

func get_yaw() -> float:
	var future_pos: Vector3 = get_impact_pos()
	var yaw: float = acos(future_pos.x*sqrt(future_pos.x**2 + future_pos.z**2)/(future_pos.x**2 + future_pos.z**2))
	if future_pos.z > 0:
		yaw *= -1
	return yaw

func get_pitch() -> float:
	var t: float = get_travel_time()
	var future_pos: Vector3 = get_impact_pos()
	var horizontal_dist: float = sqrt(future_pos.x**2 + future_pos.z**2)
	var s: float = projectile_speed
	var g: float = gravity_acceleration.y
	#return atan((s**2 - sqrt(s**4-(-g)*((-g)*horizontal_dist**2 + 2*future_pos.y*s**2)))/ ((-g)*horizontal_dist))
	#return atan2((s**2 - sqrt(s**4-(-g)*((-g)*horizontal_dist**2 + 2*future_pos.y*s**2))), ((-g)*horizontal_dist))
	return atan((future_pos.y-0.5*g*t**2) / horizontal_dist)


func get_travel_time() -> float:
	var s: float = projectile_speed
	var t: float

	t = target_body.get_position().length() / s  # huertistic that should get us close enough in most cases
	for i in range(iterations):
		t = t - f(t) / f_prime(t)
	return t


func f(t: float) -> float:
	var a: Vector3 = target_body.get_linear_acceleration() - gravity_acceleration
	var v_t: Vector3 = target_body.get_linear_velocity()
	var p_t: Vector3 = target_body.get_position()
	var s: float = projectile_speed
	return 0.25*(a.dot(a))*t**4 + (a.dot(v_t))*t**3 + (a.dot(p_t) + v_t.dot(v_t) - s**2)*t**2 + 2*(v_t.dot(p_t))*t + (p_t.dot(p_t))
	

func f_prime(t: float) -> float:
	var a: Vector3 = target_body.get_linear_acceleration() - gravity_acceleration
	var v_t: Vector3 = target_body.get_linear_velocity()
	var p_t: Vector3 = target_body.get_position()
	var s: float = projectile_speed
	return a.length()**2 * t**3 + 3*a.dot(v_t)*t**2 + 2*(a.dot(p_t) - s**2 + v_t.length()**2)*t + 2*p_t.dot(v_t)
