class_name CenterCVKF
extends Node

var accel_std_dev: float = 1

var past_t: float

func _get_F(dt: float) -> Transform2D:
	return Transform2D(
	Vector2(1,0),
	Vector2(dt,1),
	Vector2.ZERO
	)

var P0: Transform2D = Transform2D(
	Vector2(pow(0.1, 2),pow(0.12, 2)),
	Vector2(pow(0.12, 2),pow(0.4, 2)),
	Vector2.ZERO
	)
var P: Transform2D

var H_t: Vector2 = Vector2(1, 0) 


func _get_Q(dt: float) -> Transform2D:
	return Transform2D(
	Vector2(pow(dt, 4) / 4, pow(dt, 3) / 2),
	Vector2(pow(dt, 3) / 2, pow(dt, 2)),
	Vector2.ZERO
	) * pow(accel_std_dev,2)
var x: Vector2

var R: float = pow(0.05, 2)

var S: float

var innovation: float

func _init(x0: Vector2) -> void:
	past_t = Time.get_unix_time_from_system()
	x = x0
	P = P0

func update(z: float, del_t: float = 0) -> void:
	# find extrapolated state and state covariance
	var dt: float
	if del_t == 0:
		var curr_t: float = Time.get_unix_time_from_system()
		dt = (curr_t - past_t)
		past_t = curr_t
	else:
		dt= del_t 
	var F: Transform2D = _get_F(dt)
	var Q: Transform2D = _get_Q(dt)
	
	# extrapolate
	var x_ext: Vector2 = F * x
	var P_ext: Transform2D = _add(F * P * _transpose(F), Q)
	
	# compute kalman gain
	S = ((P_ext*H_t).x + R)
	var K: Vector2 = P_ext * H_t * (S ** (-1))
	
	# update state estimation
	innovation = z - x_ext.x
	x = x_ext + K * (innovation)
	x.y = sign(x.y) * max(0.21,abs(x.y))
	
	# update state covariance
	P = _add(P_ext, _column_times_row_vec(K, Vector2(P_ext.x.x, P_ext.y.x)) * -1.0)
	

	
func get_estimation() -> Vector2:
	return x

func predict_estimate(dt: float) -> Vector2:
	return _get_F(dt) * x
	
func get_std_dev() -> Vector2:
	return Vector2(sqrt(P.x.x), sqrt(P.y.y))

func get_S() -> float:
	return S
func get_innovation() -> float:
	return innovation

func _add(A: Transform2D, B: Transform2D) -> Transform2D:
	return Transform2D(
		A.x + B.x,
		A.y + B.y,
		Vector2.ZERO
	)

func _column_times_row_vec(colv: Vector2, rowv: Vector2) -> Transform2D:
	return Transform2D(
	Vector2(colv.x * rowv.x,colv.y * rowv.x),
	Vector2(colv.x * rowv.y,colv.y * rowv.y),
	Vector2.ZERO
	)
	
func _transpose(mat: Transform2D) -> Transform2D:
	return Transform2D(
	Vector2(mat.x.x , mat.y.x),
	Vector2(mat.x.y, mat.y.y),
	Vector2.ZERO
	)
