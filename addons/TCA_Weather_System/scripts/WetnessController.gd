extends Node
class_name WetnessController

@export var wetness: float = 0.0
@export var dry_speed: float = 0.1
@export var max_wetness: float = 1.0

func _process(delta):
    var env = get_parent()
    if env is EnvironmentManager:
        if env.rain_intensity > 0.01:
            wetness = min(wetness + env.rain_intensity * delta * 0.5, max_wetness)
        else:
            wetness = max(wetness - dry_speed * delta, 0.0)
