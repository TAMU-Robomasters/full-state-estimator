extends Node

@onready var draw_debug: MeshInstance3D = $MeshInstance3D
@onready var ballistics = $"../Ballistics"


func _process(_delta: float) -> void:
	if draw_debug.mesh is ImmediateMesh:
		draw_debug.mesh.clear_surfaces()
	
	var path_array = ballistic_path_func(20)

	for i in range(path_array.size() - 1):
		# Draw Line
		draw_line(path_array[i], path_array[i+1])

func draw_line(point_a: Vector3, point_b: Vector3, color: Color = Color.RED):
	if point_a.is_equal_approx(point_b):
		return
	if draw_debug.mesh is ImmediateMesh:
		draw_debug.mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		draw_debug.mesh.surface_set_color(color)

		draw_debug.mesh.surface_add_vertex(point_a)
		draw_debug.mesh.surface_add_vertex(point_b)

		draw_debug.mesh.surface_end()


func ballistic_path_func(n: int) -> PackedVector3Array:
	var pitch: float = ballistics.get_pitch()
	var yaw: float = ballistics.get_yaw()
	var path: Vector3
	var rot_y: float = ballistics.get_yaw()
	var rot_tran = Transform3D().rotated(Vector3.UP, -rot_y)
	
	var interval: float = ballistics.get_travel_time() / (n - 1)
	var pos_array = PackedVector3Array()
	var s: float = ballistics.projectile_speed
	var g: float = ballistics.gravity_acceleration.y
	var v: Vector3
	
	#i*interval
	for i in range(n):
		v.x = s*cos(pitch)*(i*interval)
		v.y = 0.5*g*(i*interval)**2 + s*sin(pitch)*(i*interval) + 0
		pos_array.push_back(v)
	return pos_array * rot_tran
