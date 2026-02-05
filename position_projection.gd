extends Node3D

@onready var ballistics = $"../Ballistics"
@onready var target_body: RigidBody3D = $"../Target/RigidBody3D"

func _process(delta: float) -> void:
	#var position_3d: Vector3 = target_body.get_position()
	#var theta: float = target_body.get_rotation().y
	#var position_2d: Vector2 = Vector2(position_3d.x, position_3d.z)
	#var lamda: float = sqrt(1/(((position_2d.x*cos(theta) + position_2d.y*sin(theta)) / ballistics.a_radius)**2+((position_2d.x*sin(theta)-position_2d.y*cos(theta))/ballistics.b_radius)**2))
	#position = Vector3(-lamda*position_2d.x, position_3d.y, -lamda*position_2d.y) + position_3d
	position = ballistics._get_target_pos_at(1)
