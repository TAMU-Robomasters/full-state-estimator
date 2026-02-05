extends MeshInstance3D

@onready var light1 = $"VisibleOnScreenNotifier3D"
@onready var light2 = $"VisibleOnScreenNotifier3D2"
@onready var cam = $"../../../Camera3D"

signal panel_is_visible
signal panel_is_not_visible

var light_one_visible: bool
var light_two_visible: bool

func is_panel_visible() -> bool:
	var cam_dir_vec: Vector3 = -cam.get_global_transform().basis.z
	var light_dir_vec: Vector3 = get_global_transform().basis.x
	 
	cam_dir_vec.y = 0
	light_dir_vec.y = 0
	
	var cam_dir_unit_vec: Vector3 = cam_dir_vec.normalized()
	var light_dir_unit_vec: Vector3 = -light_dir_vec.normalized().rotated(Vector3.UP, deg_to_rad(-90))
	
	
	if cam_dir_unit_vec.dot(light_dir_unit_vec) > 0.4:
		return true
	return false


func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	light_one_visible = true


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	light_one_visible = false


func _on_visible_on_screen_notifier_3d_2_screen_entered() -> void:
	light_two_visible = true


func _on_visible_on_screen_notifier_3d_2_screen_exited() -> void:
	light_two_visible = false
