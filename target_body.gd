extends RigidBody3D


# keyboard state
var _up = false
var _left = false
var _down = false
var _right = false
var _spin_pos = false
var _spin_neg = false

var prevLinearVelocity: Vector3
var prevAngularVelocity: Vector3
var linearAcceleration: Vector3
var angularAcceleration: Vector3


var _force_velocity = 1000
var _torque_velocity = 700

var current_force: Vector3 = Vector3.ZERO
var current_torque: Vector3 = Vector3.ZERO

var torque_y: float = 0

func _ready() -> void:
	set_inertia(Vector3.ONE)
	position = Vector3(0, -1, 1)
	prevLinearVelocity = get_linear_velocity()
	prevAngularVelocity = get_angular_velocity()

func _input(event: InputEvent) -> void:
	
	if event is InputEventKey:
		match event.keycode:
			KEY_I:
				_up = event.pressed
			KEY_J:
				_left = event.pressed
			KEY_K:
				_down = event.pressed
			KEY_L:
				_right = event.pressed
			KEY_X:
				_spin_pos = event.pressed
			KEY_C:
				_spin_neg = event.pressed
				
				
	
				
				
func _process(delta: float) -> void:
	var force_x = (_left as float) - (_right as float)
	var force_z = (_up as float) - (_down as float)
	var torque_y = (_spin_pos as float) - (_spin_neg as float)

	current_force = _force_velocity*delta*Vector3(force_x, 0, force_z)
	current_torque =_torque_velocity*delta*Vector3(0,torque_y,0)
	apply_force(current_force)
	apply_torque(current_torque)

func _physics_process(delta: float) -> void:
	var position: Vector3 = global_transform.origin
	var linearVelocity: Vector3 = get_linear_velocity()
	var angularVelocity: Vector3 = get_angular_velocity()
	linearAcceleration = (linearVelocity - prevLinearVelocity) / delta
	angularAcceleration = (angularVelocity - prevAngularVelocity) / delta
	prevLinearVelocity = linearVelocity
	prevAngularVelocity = angularVelocity
	#printKinematics(position, linearVelocity, linearAcceleration, angularVelocity, angularAcceleration)

func printKinematics(position: Vector3, linear_velocity: Vector3, linear_acceleration: Vector3, angular_velocity: Vector3, angular_acceleration: Vector3) -> void:
	print("--- KINEMATIC DATA ---")
	print("Position: ", position)
	print("Linear Velocity: ", linear_velocity)
	print("Linear Acceleration: ", linear_acceleration)
	print("Angular Velocity: ", angular_velocity)
	print("Angular Acceleration: ", angular_acceleration)

	
func get_linear_acceleration() -> Vector3:
	return get_constant_force() / get_mass()
	
func get_angular_acceleration() -> Vector3:
	return get_constant_torque() / get_inertia()


func _on_ap_1_visibility_changed() -> void:
	pass # Replace with function body.


func _on_ap_2_visibility_changed() -> void:
	pass # Replace with function body.


func _on_ap_3_visibility_changed() -> void:
	pass # Replace with function body.


func _on_ap_4_visibility_changed() -> void:
	pass # Replace with function body.
