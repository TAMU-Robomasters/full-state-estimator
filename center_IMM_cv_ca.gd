class_name CenterIMM_CV_CA
extends Node

# Acceleration bounds for the uniform augmentation distribution
var max_acceleration: float = 0.2 # m/s^2 (adjust to your needs)
var a_a: float = -max_acceleration
var a_b: float = max_acceleration

var _past_t: float

# Filter One: constant velocity (2D state, 2x2 covariance)
var _f1: CenterCVKF

# Filter Two: constant acceleration (3D state, 3x3 covariance)
var _f2: CenterCAKF

# Overall IMM state
var _P: Basis
var _x: Vector3

var _mu: Vector2

# a priori state switching matrix
var _pi: Transform2D = Transform2D( 
	Vector2(0.01, 0.02), 
	Vector2(0.99, 0.98), 
	Vector2.ZERO
)
#Vector2(0.01, 0.02), 
#Vector2(0.99, 0.98), 

func _init(x0: Vector3) -> void:
	_past_t = Time.get_unix_time_from_system()
	_mu = Vector2(0.99, 0.01) # init prior model probabilities
	
	# init filters
	_f1 = CenterCVKF.new(Vector2(x0.x, x0.y))
	_f2 = CenterCAKF.new(x0)

func update(z: float) -> void:
	var psi: Vector2 # normalization vector
	var mu_tilde: Transform2D
	var innovation: Vector2
	var S_tilde: Vector2
	var log_mu: Vector2 
	
	# compute conditional model probabilities
	psi = _compute_psi()
	mu_tilde = _compute_mu_tilde(psi)
	
	_mix_filters(mu_tilde)
	
	# update filters
	_f1.update(z)
	_f2.update(z)
	
	# gather innovations
	innovation = Vector2(
		_f1.get_innovation(),
		_f2.get_innovation()
	)
	S_tilde = Vector2(
		_f1.get_S(),
		_f2.get_S()
	)
	
	# update model probabilities
	log_mu = _compute_mu_log(psi, innovation, S_tilde)
	_mu = Vector2(exp(log_mu.x), exp(log_mu.y))
	assert(not is_zero_approx(_mu.x) or not is_zero_approx(_mu.y), "Model probabilities went to zero")
	
	# update IMM state estimate and covariance
	_x = _x_aug12(_f1.x) * _mu.x + _f2.x * _mu.y
	
	var diff1: Vector3 = _x_aug12(_f1.x) - _x
	var diff2: Vector3 = _f2.x - _x
	
	_P = _add(
		_add(_P_aug12(_f1.P), _column_times_row_vec(diff1, diff1)) * _mu.x, 
		_add(_f2.P, _column_times_row_vec(diff2, diff2)) * _mu.y
	)

func _mix_filters(mu_tilde: Transform2D) -> void:
	var _f_x: Array = [Vector2.ZERO, Vector3.ZERO]
	var _f_P: Array = [Transform2D(), Basis()]
	
	# mix means
	_f_x[0] = _f1.x
	_f_x[1] = _f2.x
	_f1.x = _f_x[0] * mu_tilde.x.x + _x_aug21(_f_x[1]) * mu_tilde.x.y
	_f2.x = _x_aug12(_f_x[0]) * mu_tilde.y.x  + _f_x[1] * mu_tilde.y.y
	
	# mix covariances
	_f_P[0] = _f1.P
	_f_P[1] = _f2.P
	
	# f1 (2D) update
	var diff1_2d: Vector2 = _f_x[0] - _f1.x
	var diff2_2d: Vector2 = _x_aug21(_f_x[1]) - _f1.x
	
	_f1.P = _add_2d(
		_add_2d(_f_P[0], _column_times_row_vec_2d(diff1_2d, diff1_2d)) * mu_tilde.x.x,
		_add_2d(_P_aug21(_f_P[1]), _column_times_row_vec_2d(diff2_2d, diff2_2d)) * mu_tilde.x.y
	)
			
	# f2 (3D) update
	var diff1_3d: Vector3 = _x_aug12(_f_x[0]) - _f2.x
	var diff2_3d: Vector3 = _f_x[1] - _f2.x
	
	_f2.P = _add(
		_add(_P_aug12(_f_P[0]), _column_times_row_vec(diff1_3d, diff1_3d)) * mu_tilde.y.x,
		_add(_f_P[1], _column_times_row_vec(diff2_3d, diff2_3d)) * mu_tilde.y.y
	)

# --- MATH / PROBABILITY HELPERS ---

func _compute_psi() -> Vector2:
	return Vector2(
		_pi.x.x*_mu.x + _pi.x.y*_mu.y,
		_pi.y.x*_mu.x + _pi.y.y*_mu.y
	)

func _compute_mu_tilde(psi: Vector2) -> Transform2D:
	return Transform2D( 
		Vector2(_pi.x.x*_mu.x / psi.x, _pi.x.y*_mu.y / psi.x),
		Vector2(_pi.y.x*_mu.x / psi.y, _pi.y.y*_mu.y / psi.y),
		Vector2.ZERO
	)

func _compute_mu_log(norm_vec: Vector2, innovation: Vector2, S_tilde: Vector2) -> Vector2:
	var m: float
	var log_c: float
	var log_psi: Vector2
	var log_lambda: Vector2
	
	assert(S_tilde.x >= 0.001 and S_tilde.y >= 0.001)
	m = max(-0.5*pow(innovation.x, 2)/S_tilde.x, -0.5*pow(innovation.y, 2)/S_tilde.y)
	log_c = m + log(
			(norm_vec.x/sqrt(abs(2*PI*S_tilde.x))) * exp((-0.5*pow(innovation.x,2)/S_tilde.x) - m) + \
			(norm_vec.y/sqrt(abs(2*PI*S_tilde.y))) * exp((-0.5*pow(innovation.y,2)/S_tilde.y) - m)
	)
	
	log_psi = Vector2(log(norm_vec.x), log(norm_vec.y))
	
	log_lambda = Vector2(
		-0.5 * (log(2*PI) + log(abs(S_tilde.x)) + pow(innovation.x, 2)/S_tilde.x),
		-0.5 * (log(2*PI) + log(abs(S_tilde.y)) + pow(innovation.y, 2)/S_tilde.y)
	)
	
	return Vector2(
		log_lambda.x + log_psi.x - log_c,
		log_lambda.y + log_psi.y - log_c
	)

# --- AUGMENTATION METHODS ---

# augment estimate from filter two (CA 3D) to filter one (CV 2D)
func _x_aug21(mean: Vector3) -> Vector2:
	return Vector2(mean.x, mean.y)

# augment estimate from filter one (CV 2D) to filter two (CA 3D)
func _x_aug12(mean: Vector2) -> Vector3:
	return Vector3(mean.x, mean.y, (a_a + a_b)/2.0)
	
# augment covariance from filter two (CA 3D) to filter one (CV 2D)
func _P_aug21(cov: Basis) -> Transform2D:
	return Transform2D(
		Vector2(cov.x.x, cov.y.x),
		Vector2(cov.x.y, cov.y.y),
		Vector2.ZERO
	)

# augment covariance from filter one (CV 2D) to filter two (CA 3D)
func _P_aug12(cov: Transform2D) -> Basis:
	return Basis(
		Vector3(cov.x.x, cov.y.x, 0),
		Vector3(cov.x.y, cov.y.y, 0),
		Vector3(0, 0, pow(a_b - a_a, 2)/12.0)
	)

# --- 3D / 2D MATRIX HELPERS ---

func _get_F(dt: float) -> Basis:
	return Basis(
		Vector3(1, 0, 0),
		Vector3(dt, 1, 0),
		Vector3(0.5 * dt * dt, dt, 1)
	)

func _add(A: Basis, B: Basis) -> Basis:
	return Basis(
		A.x + B.x,
		A.y + B.y,
		A.z + B.z
	)

func _add_2d(A: Transform2D, B: Transform2D) -> Transform2D:
	return Transform2D(
		A.x + B.x,
		A.y + B.y,
		Vector2.ZERO
	)

func _column_times_row_vec(colv: Vector3, rowv: Vector3) -> Basis:
	return Basis(
		Vector3(colv.x * rowv.x, colv.y * rowv.x, colv.z * rowv.x),
		Vector3(colv.x * rowv.y, colv.y * rowv.y, colv.z * rowv.y),
		Vector3(colv.x * rowv.z, colv.y * rowv.z, colv.z * rowv.z)
	)

func _column_times_row_vec_2d(colv: Vector2, rowv: Vector2) -> Transform2D:
	return Transform2D(
		Vector2(colv.x * rowv.x, colv.y * rowv.x),
		Vector2(colv.x * rowv.y, colv.y * rowv.y),
		Vector2.ZERO
	)

# --- GETTERS ---

func get_estimation() -> Vector3:
	return _x

func predict_estimate(dt: float) -> Vector3:
	return _get_F(dt) * _x
	
func get_model_probablities() -> Vector2:
	return _mu	

func get_std_dev() -> Vector3:
	return Vector3(sqrt(_P.x.x), sqrt(_P.y.y), sqrt(_P.z.z))
