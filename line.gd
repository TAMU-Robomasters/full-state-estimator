extends Node3D

@export var x = -1
@export var y = -1
@export var z = 1

func _process(delta: float) -> void:
	var vec = Vector3(x,y,z)
	look_at(vec,Vector3.UP, true)
