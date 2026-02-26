class_name CenterIMM_CP_CA
extends Node

# Velocity bounds for the uniform augmentation distribution
var max_velocity: float = 0.01 # m/s
var v_a: float = -max_velocity
var v_b: float = max_velocity

# Acceleration bounds for the uniform augmentation distribution
var max_acceleration: float = 0.02 # m/s^2 (adjust to your needs)
var a_a: float = -max_acceleration
var a_b: float = max_acceleration

var _past_t: float

# Filter One: constant position (1D state, 1D covariance)
var _f1: CenterCPKF

# Filter Two: constant acceleration (3D state, 3x3 covariance)
var _f2: CenterCAKF

# Overall IMM state
var _P: Basis
var _x: Vector3

var _mu: Vector2

# a priori state switching matrix
var _pi: Transform2D = Transform2D( 
	Vector2(0.40, 0.02), 
	Vector2(0.60, 0.98), 
	Vector2.ZERO
)

func _init(x0: Vector3) -> void:
	_past_t = Time.get_unix_time_from_system()
	_mu = Vector2(0.99, 0.01) # init prior model probabilities
	
	# init filters (assuming f1 takes a float, f2 takes a Vector3)
	_f1 = CenterCPKF.new(x0.x)
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
	var _f_x: Array = [0.0, Vector3.ZERO]
	var _f_P: Array = [0.0, Basis()]
	
	# mix means
	_f_x[0] = _f1.x
	_f_x[1] = _f2.x
	_f1.x = _f_x[0] * mu_tilde.x.x + _x_aug21(_f_x[1]) * mu_tilde.x.y
	_f2.x = _x_aug12(_f_x[0]) * mu_tilde.y.x  + _f_x[1] * mu_tilde.y.y
	
	# mix covariances
	_f_P[0] = _f1.P
	_f_P[1] = _f2.P
	
	# f1 (1D) update
	_f1.P = mu_tilde.x.x * (_f_P[0] + pow(_f_x[0] - _f1.x, 2)) + \
			mu_tilde.x.y * (_P_aug21(_f_P[1]) + pow(_x_aug21(_f_x[1]) - _f1.x, 2))
			
	# f2 (3D) update
	var diff1: Vector3 = _x_aug12(_f_x[0]) - _f2.x
	var diff2: Vector3 = _f_x[1] - _f2.x
	
	_f2.P = _add(
		_add(_P_aug12(_f_P[0]), _column_times_row_vec(diff1, diff1)) * mu_tilde.y.x,
		_add(_f_P[1], _column_times_row_vec(diff2, diff2)) * mu_tilde.y.y
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

# augment estimate from filter two (CA 3D) to filter one (CP 1D)
func _x_aug21(mean: Vector3) -> float:
	return mean.x

# augment estimate from filter one (CP 1D) to filter two (CA 3D)
func _x_aug12(mean: float) -> Vector3:
	return Vector3(mean, (v_a + v_b)/2.0, (a_a + a_b)/2.0)
	
# augment covariance from filter two (CA 3D) to filter one (CP 1D)
func _P_aug21(cov: Basis) -> float:
	return cov.x.x

# augment covariance from filter one (CP 1D) to filter two (CA 3D)
func _P_aug12(cov: float) -> Basis:
	return Basis(
		Vector3(cov, 0, 0),
		Vector3(0, pow(v_b - v_a, 2)/12.0, 0),
		Vector3(0, 0, pow(a_b - a_a, 2)/12.0)
	)

# --- 3D MATRIX HELPERS ---

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

func _column_times_row_vec(colv: Vector3, rowv: Vector3) -> Basis:
	return Basis(
		Vector3(colv.x * rowv.x, colv.y * rowv.x, colv.z * rowv.x),
		Vector3(colv.x * rowv.y, colv.y * rowv.y, colv.z * rowv.y),
		Vector3(colv.x * rowv.z, colv.y * rowv.z, colv.z * rowv.z)
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
