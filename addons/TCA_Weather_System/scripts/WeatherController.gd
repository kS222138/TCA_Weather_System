class_name WeatherController
extends Node3D

@export var world_environment: WorldEnvironment
@export var directional_light: DirectionalLight3D
@export var seasons: Array[SeasonResource] = []
@export var day_duration: float = 86400.0
@export var time_speed_multiplier: float = 100.0
@export var start_time: float = 40000.0
@export var start_season: int = 0
@export var start_weather: int = 0

signal season_changed(season: SeasonResource)
signal weather_changed(weather: WeatherResource)
signal weather_ended(weather: WeatherResource)

var time_of_day: float = 0.0
var current_season_index: int = 0
var current_weather_index: int = 0
var next_weather_index: int = 0
var current_weather_length: float = 0.0
var current_weather_time: float = 0.0
var current_season_length: float = 0.0
var current_season_time: float = 0.0
var particle_system: GPUParticles3D

func set_season(season_index: int, weather_index: int = -1):
	if seasons.is_empty():
		return
	current_season_index = season_index
	current_season_length = seasons[season_index].duration_in_days * day_duration
	current_season_time = 0.0
	if weather_index != -1 and weather_index < seasons[season_index].weathers.size():
		set_weather(weather_index)
	else:
		set_random_weather()
	season_changed.emit(seasons[current_season_index])

func set_random_weather():
	var season = seasons[current_season_index]
	var total = 0.0
	for w in season.weathers:
		total += w.probability_ratio
	var rand = randf() * total
	var accumulated = 0.0
	for i in range(season.weathers.size()):
		accumulated += season.weathers[i].probability_ratio
		if rand <= accumulated:
			set_weather(i)
			return

func set_weather(weather_index: int):
	if seasons.is_empty():
		return
	var season = seasons[current_season_index]
	if season.weathers.is_empty():
		return
	if weather_index >= season.weathers.size():
		weather_index = 0
	current_weather_index = weather_index
	next_weather_index = randi() % season.weathers.size()
	var weather = season.weathers[current_weather_index].weather
	current_weather_length = randf_range(weather.min_duration, weather.max_duration)
	current_weather_time = 0.0
	_update_particle_system(weather)
	weather_changed.emit(weather)

func _update_particle_system(weather: WeatherResource):
	if particle_system:
		particle_system.queue_free()
		particle_system = null
	if weather.precipitation and weather.precipitation.particles:
		particle_system = weather.precipitation.particles.instantiate()
		add_child(particle_system)

func _ready():
	if world_environment == null:
		push_error("WeatherController.world_environment is null! Please assign it.")
	if directional_light == null:
		push_error("WeatherController.directional_light is null! Please assign it.")
	set_season(start_season, start_weather)
	current_season_time += start_time
	time_of_day += start_time

func _process(delta: float):
	if world_environment == null or seasons.is_empty():
		return
	
	time_of_day = fmod(time_of_day + delta * time_speed_multiplier, day_duration)
	current_weather_time += delta * time_speed_multiplier
	current_season_time += delta * time_speed_multiplier
	
	if current_weather_time >= current_weather_length:
		weather_ended.emit(seasons[current_season_index].weathers[current_weather_index].weather)
		set_weather(next_weather_index)
	
	var season = seasons[current_season_index]
	var next_season = seasons[(current_season_index + 1) % seasons.size()]
	
	if season.weathers.is_empty():
		return
	
	if current_season_time >= current_season_length:
		set_season((current_season_index + 1) % seasons.size())
		return
	
	var season_t = current_season_time / current_season_length
	var weather_t = current_weather_time / current_weather_length
	
	var season_params = _interpolate_seasons(season, next_season, season_t)
	var weather_params = _interpolate_weathers(
		season.weathers[current_weather_index].weather,
		season.weathers[next_weather_index].weather,
		weather_t
	)
	
	var t_time_of_day = time_of_day / day_duration
	t_time_of_day = clamp(1.0 - season_params.day_night_cycle_curve.sample(t_time_of_day), 0.0, 1.0)
	
	var sky_colour = season_params.sky_colour_daytime.sky_colour.lerp(season_params.sky_colour_night.sky_colour, t_time_of_day)
	var horizon_colour = season_params.sky_colour_daytime.horizon_colour.lerp(season_params.sky_colour_night.horizon_colour, t_time_of_day)
	var ground_colour = season_params.sky_colour_daytime.ground_colour.lerp(season_params.sky_colour_night.ground_colour, t_time_of_day)
	var cloud_brightness = lerp(season_params.sky_colour_daytime.cloud_brightness, season_params.sky_colour_night.cloud_brightness, t_time_of_day)
	var cloud_inner_colour = weather_params.cloud_inner_colour * cloud_brightness
	var cloud_outer_colour = weather_params.cloud_outer_colour * cloud_brightness
	
	var sky = world_environment.environment.sky
	if sky:
		var sky_material = sky.sky_material as ShaderMaterial
		if sky_material:
			sky_material.set_shader_parameter("small_cloud_cover", weather_params.small_cloud_cover)
			sky_material.set_shader_parameter("large_cloud_cover", weather_params.large_cloud_cover)
			sky_material.set_shader_parameter("cloud_speed", weather_params.cloud_speed)
			sky_material.set_shader_parameter("cloud_shape_change_speed", weather_params.cloud_speed)
			sky_material.set_shader_parameter("cloud_inner_colour", cloud_inner_colour)
			sky_material.set_shader_parameter("cloud_outer_colour", cloud_outer_colour)
			sky_material.set_shader_parameter("sky_top_color", sky_colour)
			sky_material.set_shader_parameter("sky_horizon_color", horizon_colour)
			sky_material.set_shader_parameter("ground_horizon_color", horizon_colour)
			sky_material.set_shader_parameter("ground_bottom_color", ground_colour)
	
	world_environment.environment.volumetric_fog_enabled = weather_params.fog_density > 0.0
	world_environment.environment.volumetric_fog_density = weather_params.fog_density
	
	if particle_system:
		particle_system.amount_ratio = weather_params.particle_amount_ratio
		particle_system.transparency = pow(t_time_of_day, 0.125)
		var camera = get_viewport().get_camera_3d()
		if camera:
			particle_system.global_position = camera.global_position
			particle_system.global_rotation = camera.global_rotation
	
	if directional_light:
		var t_sun_angle = time_of_day / day_duration
		directional_light.global_rotation = Vector3(t_sun_angle * 2.0 * PI + PI * 0.5, 0.0, 0.0)
		directional_light.light_energy = 1.0 - t_time_of_day
	
	world_environment.environment.ambient_light_sky_contribution = t_time_of_day

func _interpolate_seasons(season_a: SeasonResource, season_b: SeasonResource, t: float) -> Dictionary:
	return {
		"sky_colour_daytime": {
			"sky_colour": season_a.day_sky.sky_colour.lerp(season_b.day_sky.sky_colour, t),
			"horizon_colour": season_a.day_sky.horizon_colour.lerp(season_b.day_sky.horizon_colour, t),
			"ground_colour": season_a.day_sky.ground_colour.lerp(season_b.day_sky.ground_colour, t),
			"cloud_brightness": lerp(season_a.day_sky.cloud_brightness, season_b.day_sky.cloud_brightness, t)
		},
		"sky_colour_night": {
			"sky_colour": season_a.night_sky.sky_colour.lerp(season_b.night_sky.sky_colour, t),
			"horizon_colour": season_a.night_sky.horizon_colour.lerp(season_b.night_sky.horizon_colour, t),
			"ground_colour": season_a.night_sky.ground_colour.lerp(season_b.night_sky.ground_colour, t),
			"cloud_brightness": lerp(season_a.night_sky.cloud_brightness, season_b.night_sky.cloud_brightness, t)
		},
		"day_night_cycle_curve": season_a.day_night_cycle_curve
	}

func _interpolate_weathers(weather_a: WeatherResource, weather_b: WeatherResource, t: float) -> Dictionary:
	var precip_a = weather_a.precipitation.amount_ratio if weather_a.precipitation else 0.0
	var precip_b = weather_b.precipitation.amount_ratio if weather_b.precipitation else 0.0
	return {
		"fog_density": lerp(weather_a.fog_density, weather_b.fog_density, t),
		"cloud_speed": lerp(weather_a.cloud_speed, weather_b.cloud_speed, t),
		"small_cloud_cover": lerp(weather_a.small_cloud_cover, weather_b.small_cloud_cover, t),
		"large_cloud_cover": lerp(weather_a.large_cloud_cover, weather_b.large_cloud_cover, t),
		"cloud_inner_colour": weather_a.cloud_inner_colour.lerp(weather_b.cloud_inner_colour, t),
		"cloud_outer_colour": weather_a.cloud_outer_colour.lerp(weather_b.cloud_outer_colour, t),
		"particle_amount_ratio": lerp(precip_a, precip_b, t)
	}
