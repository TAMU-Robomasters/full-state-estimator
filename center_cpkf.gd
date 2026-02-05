class_name CenterCPKF
extends Node


var P0: float = pow(0.03, 2)
var P: float
var Q: float = pow(0.005, 2)
var x: float

var R: float = pow(0.05, 2)

var innovation: float 
var S: float

func _init(x0: float) -> void:
	x = x0
	P = P0

func update(z: float) -> void:
	var P_extrapolate: float = P + Q
	 
	# compute kalman gain
	S = P_extrapolate + R
	var K: float = P_extrapolate * S ** (-1)
	
	# update state estimation
	innovation = z - x
	x = x + K * innovation
	
	# update state covariance
	P = P_extrapolate - K * P_extrapolate

func get_innovation() -> float:
	return innovation
	
func get_S() -> float:
	return S

func get_estimation() -> float:
	return x
	
func get_std_dev() -> float:
	return sqrt(P)
