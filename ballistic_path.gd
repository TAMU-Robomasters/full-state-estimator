extends Path3D



func _process(_delta: float) -> void:
	var ballistic_curve = $".".get_curve()
	for point in ballistic_path_func(
		Vector3(0,0,1),
		Vector3(1,1,1),
		Vector3(1,1,4),
		30
		):
			ballistic_curve.add_point(point)


func ballistic_path_func(unit_dir: Vector3, p1: Vector3, p2: Vector3, n: int) -> PackedVector3Array:
	var a = -1
	var b = 1
	var c = 1
	var resize_vec = p2 / (a*unit_dir + b*unit_dir + c*unit_dir)
	
	var a_vec = a*resize_vec
	var b_vec = b*resize_vec
	var c_vec = c*resize_vec
	
	var interval: float = 1.0 / (n - 1)
	var pos_array = PackedVector3Array()
	pos_array.resize(n)
	for i in range(n):
		pos_array.push_back(a_vec*(i*interval)**2 + b_vec*(i*interval) + c_vec + p1)
	return pos_array
