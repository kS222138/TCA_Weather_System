extends Node
class_name WeatherForecast

@export var weather_patterns: Array[String] = ["clear", "clouded", "rain", "snow"]
@export var pattern_weights: Array[float] = [0.4, 0.3, 0.2, 0.1]
@export var change_interval: float = 300.0
@export var auto_change: bool = false
@export var random_seed: int = 0

var _timer: Timer
var _next_weather: String = ""
var _current_weather: String = ""
var _rng: RandomNumberGenerator
var _on_weather_change: Callable = Callable()

signal weather_forecast_changed(weather: String)
signal weather_changed(from: String, to: String)

func _ready():
	_rng = RandomNumberGenerator.new()
	if random_seed != 0:
		_rng.seed = random_seed
	else:
		_rng.randomize()
	
	_normalize_weights()
	
	if auto_change:
		_setup_timer()
		_predict_next()

func _normalize_weights() -> void:
	if pattern_weights.size() != weather_patterns.size():
		pattern_weights.resize(weather_patterns.size())
		var equal_weight = 1.0 / weather_patterns.size()
		for i in range(weather_patterns.size()):
			pattern_weights[i] = equal_weight

func _setup_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = change_interval
	_timer.autostart = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

func _predict_next() -> void:
	var total_weight = 0.0
	for w in pattern_weights:
		total_weight += w
	
	if total_weight <= 0:
		_next_weather = weather_patterns[0]
		weather_forecast_changed.emit(_next_weather)
		return
	
	var rand = _rng.randf_range(0, total_weight)
	var cumulative = 0.0
	for i in range(weather_patterns.size()):
		cumulative += pattern_weights[i]
		if rand <= cumulative:
			_next_weather = weather_patterns[i]
			break
	
	if _next_weather.is_empty():
		_next_weather = weather_patterns[0]
	
	weather_forecast_changed.emit(_next_weather)

func _on_timer_timeout() -> void:
	var old = _current_weather
	_current_weather = _next_weather
	if old != _current_weather:
		weather_changed.emit(old, _current_weather)
		if _on_weather_change.is_valid():
			_on_weather_change.call(old, _current_weather)
	_predict_next()

func get_next_weather() -> String:
	return _next_weather

func get_current_weather() -> String:
	return _current_weather

func set_current_weather(weather: String, emit_signal: bool = false) -> void:
	var old = _current_weather
	_current_weather = weather
	if emit_signal and old != weather:
		weather_changed.emit(old, weather)

func set_pattern_weights(weights: Array[float]) -> void:
	if weights.size() == weather_patterns.size():
		pattern_weights = weights
		_normalize_weights()

func set_change_interval(interval: float) -> void:
	change_interval = interval
	if _timer:
		_timer.wait_time = interval

func force_change_weather(weather: String) -> void:
	var old = _current_weather
	_current_weather = weather
	if old != weather:
		weather_changed.emit(old, weather)
	_predict_next()

func set_random_seed(seed: int) -> void:
	random_seed = seed
	_rng.seed = seed

func set_on_weather_change(callback: Callable) -> void:
	_on_weather_change = callback

func get_weather_display_name(weather: String) -> String:
	match weather:
		"clear":
			return "☀️ Clear"
		"clouded":
			return "☁️ Clouded"
		"rain":
			return "🌧️ Rain"
		"snow":
			return "❄️ Snow"
		_:
			return weather