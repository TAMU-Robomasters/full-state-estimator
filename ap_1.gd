extends MeshInstance3D

@onready var light1 = $"VisibleOnScreenNotifier3D"
@onready var light2 = $"VisibleOnScreenNotifier3D2"
@onready var cam = $"../../../Camera3D"

func is_panel_visible() -> bool:
	var cam_dir_vec: Vector3 = -cam.get_global_transform().basis.z
	var light_dir_vec: Vector3 = get_global_transform().basis.z 
	 
	cam_dir_vec.y = 0
	light_dir_vec.y = 0
	
	var cam_dir_unit_vec: Vector3 = cam_dir_vec.normalized()
	var light_dir_unit_vec: Vector3 = -light_dir_vec.normalized()
	
	
	if cam_dir_unit_vec.dot(light_dir_unit_vec) > 0.4:
		return true
	return false
