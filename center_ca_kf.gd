class_name CenterCAKF
extends Node

var jerk_std_dev: float = 10 # 3

var past_t: float

func _get_F(dt: float) -> Basis:
	return Basis(
		Vector3(1, 0, 0),
		Vector3(dt, 1, 0),
		Vector3(0.5 * dt * dt, dt, 1)
	)

var P0: Basis = Basis(
	Vector3(pow(0.1, 2), pow(0.12, 2), 0.0),
	Vector3(pow(0.12, 2), pow(0.4, 2), 0.0),
	Vector3(0.0, 0.0, pow(0.4, 2))
)
var P: Basis

var H_t: Vector3 = Vector3(1, 0, 0)

func _get_Q(dt: float) -> Basis:
	return Basis(
		Vector3(pow(dt, 5) / 20.0, pow(dt, 4) / 8.0, pow(dt, 3) / 6.0),
		Vector3(pow(dt, 4) / 8.0, pow(dt, 3) / 3.0, pow(dt, 2) / 2.0),
		Vector3(pow(dt, 3) / 6.0, pow(dt, 2) / 2.0, dt)
	) * pow(jerk_std_dev, 2)

var x: Vector3

var R: float = pow(0.4, 2)

var S: float

var innovation: float

func _init(x0: Vector3) -> void:
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
		dt = del_t 
	var F: Basis = _get_F(dt)
	var Q: Basis = _get_Q(dt)
	
	# extrapolate
	var x_ext: Vector3 = F * x
	var P_ext: Basis = _add(F * P * _transpose(F), Q)
	
	# compute kalman gain
	S = ((P_ext * H_t).x + R)
	var K: Vector3 = P_ext * H_t * (1.0 / S)
	
	# update state estimation
	innovation = z - x_ext.x
	x = x_ext + K * innovation
	x.y = sign(x.y) * max(0.21, abs(x.y))
	
	# update state covariance
	P = _add(P_ext, _column_times_row_vec(K, Vector3(P_ext.x.x, P_ext.y.x, P_ext.z.x)) * -1.0)

func get_estimation() -> Vector3:
	return x

func predict_estimate(dt: float) -> Vector3:
	return _get_F(dt) * x
	
func get_std_dev() -> Vector3:
	return Vector3(sqrt(P.x.x), sqrt(P.y.y), sqrt(P.z.z))

func get_S() -> float:
	return S

func get_innovation() -> float:
	return innovation

func _add(A: Basis, B: Basis) -> Basis:
	return Basis(
		A.x + B.x,
		A.y + B.y,
		A.z + B.z
	)

func _column_times_row_vec(colv: Vector3, rowv: Vector3) -> Basis:
	return Basis(
		Vector3(colv.x * rowv.x, colv.y * rowv.x, colv.z * rowv.x),
		Vector3(colv.x * rowv.y, colv.y * rowv.y, colv.z * rowv.y),
		Vector3(colv.x * rowv.z, colv.y * rowv.z, colv.z * rowv.z)
	)
	
func _transpose(mat: Basis) -> Basis:
	return Basis(
		Vector3(mat.x.x, mat.y.x, mat.z.x),
		Vector3(mat.x.y, mat.y.y, mat.z.y),
		Vector3(mat.x.z, mat.y.z, mat.z.z)
	)
