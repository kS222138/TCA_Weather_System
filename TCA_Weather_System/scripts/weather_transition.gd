extends Node
class_name WeatherTransition

@export var transition_time: float = 5.0
@export var transition_curve: Curve

var _current_weather: String = ""
var _target_weather: String = ""
var _transition_progress: float = 0.0
var _is_transitioning: bool = false
var _on_complete: Callable = Callable()
var _on_progress: Callable = Callable()

signal transition_started(from: String, to: String)
signal transition_completed(weather: String)
signal transition_progress(progress: float)

func _ready():
	if not transition_curve:
		transition_curve = Curve.new()
		transition_curve.add_point(Vector2(0, 0))
		transition_curve.add_point(Vector2(1, 1))

func start_transition(from: String, to: String, duration: float = -1, on_complete: Callable = Callable()) -> void:
	if duration > 0:
		transition_time = duration
	
	_current_weather = from
	_target_weather = to
	_transition_progress = 0.0
	_is_transitioning = true
	_on_complete = on_complete
	
	transition_started.emit(from, to)

func update_transition(delta: float) -> Dictionary:
	if not _is_transitioning:
		return {
			"progress": 1.0,
			"from": _current_weather,
			"to": _current_weather,
			"blend": 1.0,
			"active": false
		}
	
	_transition_progress += delta / transition_time
	
	var completed = false
	if _transition_progress >= 1.0:
		_transition_progress = 1.0
		_is_transitioning = false
		completed = true
		transition_completed.emit(_target_weather)
		if _on_complete.is_valid():
			_on_complete.call()
	
	var curve_progress = transition_curve.sample(_transition_progress)
	transition_progress.emit(curve_progress)
	
	return {
		"progress": curve_progress,
		"from": _current_weather,
		"to": _target_weather,
		"blend": curve_progress,
		"active": true,
		"completed": completed
	}

func get_current_weather() -> String:
	if not _is_transitioning:
		return _current_weather
	return _target_weather if _transition_progress >= 0.5 else _current_weather

func get_blend_factor() -> float:
	if not _is_transitioning:
		return 1.0
	return transition_curve.sample(_transition_progress)

func is_transitioning() -> bool:
	return _is_transitioning

func cancel_transition() -> void:
	_is_transitioning = false
	_transition_progress = 0.0
	_on_complete = Callable()

func reverse_transition() -> void:
	if _is_transitioning:
		start_transition(_target_weather, _current_weather, transition_time)

func reset() -> void:
	_is_transitioning = false
	_transition_progress = 0.0
	_current_weather = ""
	_target_weather = ""
	_on_complete = Callable()

func set_transition_curve(curve: Curve) -> void:
	transition_curve = curve