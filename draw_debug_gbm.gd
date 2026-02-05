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
	var b: Vector3 = Vector3(ballistics.bx, ballistics.by, ballistics.bz)
	var g: float = ballistics.gravity_acceleration.y
	for i in range(n):
		path.x = b.x*cos(yaw) - sin(yaw)*(b.y*cos(pitch) - b.z*sin(pitch)) - s*(i*interval)*sin(yaw)*cos(pitch)
		path.y = b.x*sin(yaw) + cos(yaw)*(b.y*cos(pitch) - b.z*sin(pitch)) + s*(i*interval)*cos(yaw)*cos(pitch)
		path.z = b.y*sin(pitch) + b.z*cos(pitch) + s*(i*interval)*sin(pitch) + 0.5*(g)*(i*interval)**2
		pos_array.push_back(ballistics._YXZ_to_ZXY(Vector3(path.x, path.y, path.z)))
	return pos_array
