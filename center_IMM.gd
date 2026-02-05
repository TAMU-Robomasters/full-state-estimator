class_name CenterIMM
extends Node


var max_velocity: float = 0.1 # m/s

var a: float = -max_velocity
var b: float = max_velocity

var _past_t: float

# Filter One: constant position
var _f1: CenterCPKF

# Filter Two: constant velocity
var _f2: CenterCVKF

var _P: Transform2D

var _x: Vector2

func _compute_mu_tilde(psi: Vector2) -> Transform2D:
	return Transform2D( 
		Vector2(_pi.x.x*_mu.x / psi.x, _pi.x.y*_mu.y / psi.x),
		Vector2(_pi.y.x*_mu.x / psi.y, _pi.y.y*_mu.y / psi.y),
		Vector2.ZERO
	)
	
# normalization vector
func _compute_psi() -> Vector2:
	return Vector2(
		_pi.x.x*_mu.x + _pi.x.y*_mu.y,
		_pi.y.x*_mu.x + _pi.y.y*_mu.y
	)
	
func _mix_filters(mu_tilde: Transform2D) -> void:
	var _f_x: Array = [0, 0]
	var _f_P: Array = [0, 0]
	# mix means
	_f_x[0] = _f1.x
	_f_x[1] = _f2.x
	_f1.x = _f_x[0] * mu_tilde.x.x + _x_aug21(_f_x[1]) * mu_tilde.x.y
	_f2.x = _x_aug12(_f_x[0]) * mu_tilde.y.x  + _f_x[1] * mu_tilde.y.y
	
	# mix covariances
	_f_P[0] = _f1.P
	_f_P[1] = _f2.P
	_f1.P = mu_tilde.x.x * (_f_P[0] + pow(_f_x[0] - _f1.x, 2)) + \
			mu_tilde.x.y * (_P_aug21(_f_P[1]) + pow(_x_aug21(_f_x[1]) - _f1.x, 2))
	_f2.P = _add(
		_add(_P_aug12(_f_P[0]), _column_times_row_vec(_x_aug12(_f_x[0]) - _f2.x, _x_aug12(_f_x[0]) - _f2.x)) * mu_tilde.y.x,
		_add(_f_P[1], _column_times_row_vec(_f_x[1] - _f2.x, _f_x[1] - _f2.x)) * mu_tilde.y.y
	)
	
func _compute_lamda(innovation: Vector2, S_tilde: Vector2) -> Vector2:
	var vec: Vector2 = Vector2(
		(1/sqrt(abs(2*PI*S_tilde.x))) * exp(-0.5*pow(innovation.x,2)/S_tilde.x),
		(1/sqrt(abs(2*PI*S_tilde.y))) * exp(-0.5*pow(innovation.y,2)/S_tilde.y)
	)
	assert(not is_zero_approx(vec.x) or not is_zero_approx(vec.y), "f")
	return vec
	
func _compute_mu_log(norm_vec: Vector2, innovation: Vector2, S_tilde: Vector2) -> Vector2:
	var m: float
	var log_c: float
	var log_psi: Vector2
	var log_lambda: Vector2
	
	assert(S_tilde.x >= 0.001 and S_tilde.y >= 0.001)
	# compute log of normalization constant use Log-Sum-Exp trick
	m = max(-0.5*pow(innovation.x, 2)/S_tilde.x, -0.5*pow(innovation.y, 2)/S_tilde.y)
	log_c = m + log(
			(norm_vec.x/sqrt(abs(2*PI*S_tilde.x))) * exp((-0.5*pow(innovation.x,2)/S_tilde.x) - m) + \
			(norm_vec.y/sqrt(abs(2*PI*S_tilde.y))) * exp((-0.5*pow(innovation.y,2)/S_tilde.y) - m)
	)
	
	# compute log of normalization vector (psi)
	log_psi = Vector2(log(norm_vec.x), log(norm_vec.y))
	
	# compute log of likelihood probablities
	log_lambda = Vector2(
		-0.5 * (log(2*PI) + log(abs(S_tilde.x)) + pow(innovation.x, 2)/S_tilde.x),
		-0.5 * (log(2*PI) + log(abs(S_tilde.y)) + pow(innovation.y, 2)/S_tilde.y)
	)
	
	# compute log of updated model probablities
	return Vector2(
		log_lambda.x + log_psi.x - log_c,
		log_lambda.y + log_psi.y - log_c
	)

func _get_F(dt: float) -> Transform2D:
	return Transform2D(
	Vector2(1,0),
	Vector2(dt,1),
	Vector2.ZERO
	)	

var _mu: Vector2

# a prior state switching matrix
var _pi: Transform2D = Transform2D( 
	Vector2(0.999, 0.001), # 0.3, 0.3
	Vector2(0.001, 0.999), # 0.7, 0.7
	Vector2.ZERO
)


func _init(x0: Vector2) -> void:
	_past_t = Time.get_unix_time_from_system()
	_mu = Vector2(0.99, 0.01) # init pior model probablities
	# init filters
	_f1 = CenterCPKF.new(x0.x)
	_f2 = CenterCVKF.new(x0)
	
# potential bug. The dt value for each filter will not be the same
func update(z: float) -> void:
	var psi: Vector2 # normalization vector
	var mu_tilde: Transform2D
	var innovation: Vector2
	var S_tilde: Vector2
	var log_mu: Vector2 # must be computed in log domain for numerical stability
	
	# compute conditional model probablites
	psi = _compute_psi()
	mu_tilde = _compute_mu_tilde(psi)
	
	_mix_filters(mu_tilde)
	
	# update filters
	_f1.update(z)
	_f2.update(z)
	
	# update model probabilities
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
	assert(not is_zero_approx(_mu.x) or not is_zero_approx(_mu.y), "j")
	
	
	# update IMM state estimate and covariance
	_x = _x_aug12(_f1.x) * _mu.x + _f2.x * _mu.y
	_P = _add(
		_add(_P_aug12(_f1.P), _column_times_row_vec(_x_aug12(_f1.x) - _x, _x_aug12(_f1.x) - _x)) * _mu.x, 
		_add(_f2.P, _column_times_row_vec(_f2.x - _x, _f2.x - _x)) * _mu.y
	)
		
func get_estimation() -> Vector2:
	return _x

func predict_estimate(dt: float) -> Vector2:
	return _get_F(dt) * _x
	
func get_model_probablities() -> Vector2:
	return _mu	

func get_std_dev() -> Vector2:
	return Vector2(sqrt(_P.x.x), sqrt(_P.y.y))

### HELPERS
# augment estimate from filter two to filter one
func _x_aug21(mean: Vector2) -> float:
	return mean.x
# augment estimate from filter one to filter two
func _x_aug12(mean: float) -> Vector2:
	return Vector2(mean, (a + b)/2)
	
# augment covariance from filter two to filter one
func _P_aug21(cov: Transform2D) -> float:
	return cov.x.x
# augment covariance from filter two to filter one
func _P_aug12(cov: float) -> Transform2D:
	return Transform2D(
		Vector2(cov, 0),
		Vector2(0, pow(b-a,2)/12),
		Vector2.ZERO
	)


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
