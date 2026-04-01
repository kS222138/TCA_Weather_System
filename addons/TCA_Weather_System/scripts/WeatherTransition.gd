extends Node
class_name WeatherTransition

signal transition_completed(to_weather)

var is_transitioning := false
var from_weather := ""
var to_weather := ""
var duration := 0.0
var timer := 0.0

func start_transition(from: String, to: String, dur: float):
    is_transitioning = true
    from_weather = from
    to_weather = to
    duration = dur
    timer = 0.0

func _process(delta):
    if not is_transitioning:
        return
    timer += delta
    var t = clamp(timer / duration, 0.0, 1.0)
    var env = get_parent()
    if env is EnvironmentManager:
        env.rain_intensity = lerp(env.rain_intensity, get_target_rain(to_weather), t)
        env.snow_intensity = lerp(env.snow_intensity, get_target_snow(to_weather), t)
        env.fog_intensity = lerp(env.fog_intensity, get_target_fog(to_weather), t)
        env.cloud_cover = lerp(env.cloud_cover, get_target_cloud(to_weather), t)
    if t >= 1.0:
        is_transitioning = false
        emit_signal("transition_completed", to_weather)

func get_target_weather(weather: String):
    match weather:
        "clear": return {"rain":0.0, "snow":0.0, "fog":0.0, "cloud":0.1}
        "light_rain": return {"rain":0.3, "snow":0.0, "fog":0.2, "cloud":0.6}
        "rain": return {"rain":0.7, "snow":0.0, "fog":0.3, "cloud":0.8}
        "heavy_rain": return {"rain":1.0, "snow":0.0, "fog":0.5, "cloud":0.95}
        "light_snow": return {"rain":0.0, "snow":0.4, "fog":0.2, "cloud":0.7}
        "snow": return {"rain":0.0, "snow":0.7, "fog":0.4, "cloud":0.85}
        "heavy_snow": return {"rain":0.0, "snow":1.0, "fog":0.6, "cloud":0.95}
        "fog": return {"rain":0.0, "snow":0.0, "fog":0.9, "cloud":0.5}
        "storm": return {"rain":0.9, "snow":0.0, "fog":0.4, "cloud":0.98}
        _: return {"rain":0.0, "snow":0.0, "fog":0.0, "cloud":0.1}

func get_target_rain(w): return get_target_weather(w)["rain"]
func get_target_snow(w): return get_target_weather(w)["snow"]
func get_target_fog(w): return get_target_weather(w)["fog"]
func get_target_cloud(w): return get_target_weather(w)["cloud"]
