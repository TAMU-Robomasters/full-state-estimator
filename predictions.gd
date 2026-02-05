extends Node3D

@onready var target = $"../Target/RigidBody3D" 
@onready var center_prediction = $"center_predictions"
@onready var center_prediction_cv =$"center_prediction_cv"

var estimator: RadiiKF
var x_center_IMMF: CenterIMM
var y_center_IMMF: CenterIMM
var x_center_CVKF: CenterCVKF
var y_center_CVKF: CenterCVKF

var radii_found: bool = false
var radii_estimate: Vector2

var radii_std_dev_threshold = 0.015 # 1.5cm

var first_two_panels: bool = true
var first_center_estimate: bool = true

var count: int = 0

func _process(delta: float) -> void:
	var project_time: float = 0.1
	
	if not first_center_estimate:
		var prediction1: Vector2
		var prediction2: Vector2
		#prediction1 = Vector2(
			#x_center_IMMF.predict_estimate(project_time).x,
			#y_center_IMMF.predict_estimate(project_time).x
		#)
		prediction1 = Vector2(
			x_center_IMMF.get_estimation().x,
			y_center_IMMF.get_estimation().x
		)
		
		#prediction2 = Vector2(
			#x_center_CVKF.predict_estimate(project_time).x,
			#y_center_CVKF.predict_estimate(project_time).x
		#)
		prediction2 = Vector2(
			x_center_CVKF.get_estimation().x,
			y_center_CVKF.get_estimation().x
		)
		
		center_prediction.position = Vector3(
			prediction1.x,
			0,
			prediction1.y
		)
		
		center_prediction_cv.position = Vector3(
			prediction2.x,
			0,
			prediction2.y
		)
			
		


func _on_target_two_panels_visible(radii: Vector2, center: Vector2) -> void:
	if first_two_panels:
		estimator = RadiiKF.new(radii)
		first_two_panels = false
		return
	estimator.update(radii)
	count += 1
	
	var radii_std_dev: Vector2 = estimator.get_std_dev()
	var estimate = estimator.get_estimation()
	
	if (radii_std_dev.x < radii_std_dev_threshold) and \
	   (radii_std_dev.y < radii_std_dev_threshold) and \
		not radii_found:
		radii_found = true
		radii_estimate = estimate
	
	if radii_found:
		if first_center_estimate:
			x_center_IMMF = CenterIMM.new(Vector2(center.x, 0))
			y_center_IMMF = CenterIMM.new(Vector2(center.y, 0))
			x_center_CVKF = CenterCVKF.new(Vector2(center.x, 0))
			y_center_CVKF = CenterCVKF.new(Vector2(center.y, 0))
			first_center_estimate = false
		else:
			x_center_IMMF.update(center.x)
			y_center_IMMF.update(center.y)
			x_center_CVKF.update(center.x)
			y_center_CVKF.update(center.y)
			
			#print("_____center_____")	
			#print("pos estimation: ", Vector2(x_center_IMMF.get_estimation().x, y_center_IMMF.get_estimation().x))
			#print("std_dev: ", Vector2(x_center_IMMF.get_std_dev().x, y_center_IMMF.get_std_dev().x), count)
			#print("vel estimation: ", Vector2(x_center_IMMF.get_estimation().y, y_center_IMMF.get_estimation().y))
			#print("std_dev: ", Vector2(x_center_IMMF.get_std_dev().y, y_center_IMMF.get_std_dev().y), count)
			#print()
			#print("_____Model_Probs_____")
			#print("mu: ", Vector2(x_center_IMMF.get_model_probablities().x, x_center_IMMF.get_model_probablities().y))
			#print()
	
	#print("_____radii_____")
	#print("estimation: ", estimate)
	#print("std_dev: ", radii_std_dev, count)
	#print()


func _on_target_one_panel_visible(pos: Vector2, unit_vec: Vector2, which_radii: String) -> void:
	if radii_found:
		var center: Vector2 = Vector2.ZERO
		if which_radii == "a":
			center = pos + unit_vec * radii_estimate.x
		elif which_radii == "b":
			center = pos + unit_vec * radii_estimate.y
		else:
			push_error("uhhhh...")
			
		if first_center_estimate:
			x_center_IMMF = CenterIMM.new(Vector2(center.x, 0))
			y_center_IMMF = CenterIMM.new(Vector2(center.y, 0))
			x_center_CVKF = CenterCVKF.new(Vector2(center.x, 0))
			y_center_CVKF = CenterCVKF.new(Vector2(center.y, 0))
			first_center_estimate = false
		else:
			x_center_IMMF.update(center.x)
			y_center_IMMF.update(center.y)
			x_center_CVKF.update(center.x)
			y_center_CVKF.update(center.y)
			
			#print("_____center_____")	
			#print("pos estimation: ", Vector2(x_center_IMMF.get_estimation().x, y_center_IMMF.get_estimation().x))
			#print("std_dev: ", Vector2(x_center_IMMF.get_std_dev().x, y_center_IMMF.get_std_dev().x), count)
			#print("vel estimation: ", Vector2(x_center_IMMF.get_estimation().y, y_center_IMMF.get_estimation().y))
			#print("std_dev: ", Vector2(x_center_IMMF.get_std_dev().y, y_center_IMMF.get_std_dev().y), count)
			#print()
			#print("_____Model_Probs_____")
			#print("mu: ", Vector2(x_center_IMMF.get_model_probablities().x, x_center_IMMF.get_model_probablities().y))
			#print()


# Define the target location
const TARGET_IP = "127.0.0.1" # Localhost
const TARGET_PORT = 4242      # Change this to match your receiver's port

# Create the peer once to avoid overhead per frame
var _udp_peer := PacketPeerUDP.new()

func _send_udp_message(model_probabilities: Vector2) -> void:
	# 1. Set the destination address
	_udp_peer.set_dest_address(TARGET_IP, TARGET_PORT)
	
	# 2. Prepare the data (JSON is best for AI/Python interoperability)
	var data_dict = {
		"prob_x": model_probabilities.x,
		"prob_y": model_probabilities.y
	}
	
	# 3. Serialize to a String, then to a PackedByteArray
	var json_string = JSON.stringify(data_dict)
	var packet = json_string.to_utf8_buffer()
	
	# 4. Send the packet
	var error = _udp_peer.put_packet(packet)
	
	if error != OK:
		push_error("Failed to send UDP message: %s" % error)


func _on_timer_timeout() -> void:
	if not first_center_estimate:
		_send_udp_message(Vector2(x_center_IMMF.get_model_probablities().x, x_center_IMMF.get_model_probablities().y))
