extends Node3D

var _slow_down

func _input(event: InputEvent) -> void:
	
	if event is InputEventKey:
		match event.keycode:
			KEY_M:
				_slow_down = event.pressed


func _process(delta: float) -> void:
	if _slow_down:
		Engine.time_scale = 0.2
