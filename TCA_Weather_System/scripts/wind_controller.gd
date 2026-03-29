extends Node
class_name WindController

@export var wind_direction: Vector2 = Vector2(1, 0)
@export var wind_speed: float = 5.0
@export var gust_strength: float = 2.0
@export var gust_frequency: float = 0.2
@export var turbulence: float = 0.5
@export var speed_smoothing: float = 0.1
@export var direction_smoothing: float = 0.1
@export var affected_nodes: Array[Node] = []

var _current_gust: float = 0.0
var _gust_timer: float = 0.0
var _noise: float = 0.0
var _current_speed: float = 0.0
var _current_direction: Vector2 = Vector2.ZERO
var _rng: RandomNumberGenerator

signal wind_changed(direction: Vector2, speed: float)

func _ready():
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_gust_timer = _rng.randf_range(0, 1.0 / max(gust_frequency, 0.01))
	_current_direction = wind_direction.normalized()
	_current_speed = wind_speed

func _process(delta):
	_update_gust(delta)
	_update_noise(delta)
	_update_smoothing(delta)
	_apply_wind()

func get_wind_vector() -> Vector2:
	var dir = _current_direction
	if dir.length() <= 0:
		dir = Vector2(1, 0)
	return dir * _current_speed

func get_wind_speed() -> float:
	return _current_speed

func get_wind_direction() -> Vector2:
	return _current_direction

func get_wind_3d() -> Vector3:
	var vec = get_wind_vector()
	return Vector3(vec.x, 0, vec.y)

func _update_gust(delta: float) -> void:
	_gust_timer -= delta
	if _gust_timer <= 0:
		_current_gust = _rng.randf_range(-gust_strength, gust_strength)
		if gust_frequency > 0:
			_gust_timer = 1.0 / gust_frequency
		else:
			_gust_timer = 0.0

func _update_noise(delta: float) -> void:
	_noise = sin(Time.get_ticks_msec() * 0.001) * turbulence * 0.5

func _update_smoothing(delta: float) -> void:
	var target_speed = wind_speed + _current_gust + _noise
	_current_speed = lerp(_current_speed, target_speed, speed_smoothing)
	
	var target_dir = wind_direction.normalized()
	if target_dir.length() <= 0:
		target_dir = Vector2(1, 0)
	_current_direction = _current_direction.lerp(target_dir, direction_smoothing)

func _apply_wind() -> void:
	var wind_vec = get_wind_vector()
	var wind_speed_total = _current_speed
	wind_changed.emit(_current_direction, wind_speed_total)
	
	for node in affected_nodes:
		if node and node.has_method("set_wind"):
			node.set_wind(wind_vec)

func set_wind(direction: Vector2, speed: float) -> void:
	wind_direction = direction
	wind_speed = speed

func set_gust_strength(strength: float) -> void:
	gust_strength = strength

func set_turbulence(value: float) -> void:
	turbulence = value

func add_affected_node(node: Node) -> void:
	if node not in affected_nodes:
		affected_nodes.append(node)

func remove_affected_node(node: Node) -> void:
	affected_nodes.erase(node)