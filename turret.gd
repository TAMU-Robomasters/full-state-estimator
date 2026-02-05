extends Node3D

@onready var ballistics = $"../Ballistics"


# keyboard state
var _up = false
var _left = false
var _down = false
var _right = false

var _velocity = 300

func _input(event: InputEvent) -> void:
	
	if event is InputEventKey:
		match event.keycode:
			KEY_UP:
				_up = event.pressed
			KEY_LEFT:
				_left = event.pressed
			KEY_DOWN:
				_down = event.pressed
			KEY_RIGHT:
				_right = event.pressed
				
				
func _process(delta: float) -> void:
	var pitch_direction = (_up as float) - (_down as float)
	var yaw_direction = (_left as float) - (_right as float)
	
	
	rotation_degrees += _velocity*delta*Vector3(0,yaw_direction,pitch_direction)
	
	rotation = Vector3(0, -ballistics.get_yaw() - deg_to_rad(90), ballistics.get_pitch())
	
	
