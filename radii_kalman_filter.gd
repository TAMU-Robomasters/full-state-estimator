class_name RadiiKF
extends Node


var F: Transform2D = Transform2D.IDENTITY
var P0: Transform2D = Transform2D(
	Vector2(pow(0.5, 2),0),
	Vector2(0,pow(0.5, 2)),
	Vector2.ZERO
)
var P: Transform2D
var Q: Transform2D = Transform2D(
	Vector2(pow(0.001, 2),0),
	Vector2(0,pow(0.001, 2)),
	Vector2.ZERO
)
var x: Vector2 = Vector2.ZERO

var R: Transform2D = Transform2D(
	Vector2(pow(0.1, 2),0),
	Vector2(0,pow(0.1, 2)),
	Vector2.ZERO
)

func _init(x0: Vector2) -> void:
	
	x = x0
	P = P0

func update(z: Vector2) -> void:
	var P_extrapolate = _add(P, Q)
	 
	# compute kalman gain
	var K: Transform2D = P_extrapolate * _add(P_extrapolate, R).affine_inverse()
	
	# update state estimation
	x = x + K * (z - x)
	
	# update state covariance
	P = _add(P_extrapolate, (K * P_extrapolate) * -1.0)
	
func get_estimation() -> Vector2:
	return x
	
func get_std_dev() -> Vector2:
	return Vector2(sqrt(P.x.x), sqrt(P.y.y))


func _add(A: Transform2D, B: Transform2D) -> Transform2D:
	return Transform2D(
		A.x + B.x,
		A.y + B.y,
		Vector2.ZERO
	)
