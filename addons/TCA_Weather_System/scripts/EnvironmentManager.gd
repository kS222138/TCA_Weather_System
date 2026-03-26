extends Node3D
class_name EnvironmentManager

# ==================== 组件引用 ====================
@export var sky_material: ShaderMaterial
@export var water_material: ShaderMaterial
@export var directional_light: DirectionalLight3D
@export var reflection_probe: ReflectionProbe
@export var world_environment: WorldEnvironment
@export var camera: Camera3D

# ==================== 风系统 ====================
@export_group("Wind System")
@export var wind_direction: Vector2 = Vector2(1.0, 0.0):
    set(value):
        wind_direction = value.normalized()
        _update_wind()
@export var wind_strength: float = 0.5:
    set(value):
        wind_strength = clamp(value, 0.0, 1.0)
        _update_wind()
@export var wind_gust_frequency: float = 0.2
@export var wind_gust_strength: float = 0.3
@export var wind_turbulence: float = 0.2

# ==================== 天气系统 ====================
@export_group("Weather System")
@export var weather_type: String = "clear":
    set(value):
        weather_type = value
        _update_weather_by_type()
@export var rain_intensity: float = 0.0:
    set(value):
        rain_intensity = clamp(value, 0.0, 1.0)
        _update_weather()
@export var snow_intensity: float = 0.0:
    set(value):
        snow_intensity = clamp(value, 0.0, 1.0)
        _update_weather()
@export var fog_intensity: float = 0.0:
    set(value):
        fog_intensity = clamp(value, 0.0, 1.0)
        _update_weather()
@export var cloud_cover: float = 0.3:
    set(value):
        cloud_cover = clamp(value, 0.0, 1.0)
        _update_weather()

# ==================== 季节系统 ====================
@export_group("Season System")
@export var season: String = "summer":
    set(value):
        season = value
        _update_season()
@export var season_progress: float = 0.0:
    set(value):
        season_progress = clamp(value, 0.0, 1.0)
        _update_season()

# ==================== 时间系统 ====================
@export_group("Time System")
@export var time_of_day: float = 0.5:
    set(value):
        time_of_day = clamp(value, 0.0, 1.0)
        _update_time()
@export var time_speed: float = 0.1
@export var auto_time: bool = false

# ==================== 后处理 ====================
@export_group("Post Processing")
@export var bloom_intensity: float = 0.8:
    set(value):
        bloom_intensity = value
        _update_post_processing()
@export var glow_intensity: float = 0.6:
    set(value):
        glow_intensity = value
        _update_post_processing()
@export var exposure: float = 1.0:
    set(value):
        exposure = value
        _update_post_processing()
@export var vignette_intensity: float = 0.2:
    set(value):
        vignette_intensity = value
        _update_post_processing()

# ==================== 内部变量 ====================
var current_gust: float = 0.0
var gust_timer: float = 0.0
var wind_noise: float = 0.0
var last_reflection_update: float = 0.0
var reflection_update_interval: float = 0.5

# ==================== 信号 ====================
signal wind_changed(direction: Vector2, strength: float, gust: float)
signal weather_changed(weather_type: String, rain: float, snow: float, fog: float)
signal season_changed(season: String, progress: float)
signal time_changed(time: float, hour: int, minute: int)
signal environment_ready()

func _ready():
    _setup_references()
    _setup_environment()
    _update_all()
    emit_signal("environment_ready")
    print("✅ EnvironmentManager 已启动")

func _process(delta):
    if auto_time:
        time_of_day += delta * time_speed / 86400.0
        if time_of_day >= 1.0:
            time_of_day -= 1.0
    
    _update_wind_gust(delta)
    _update_wind_noise(delta)

# ==================== 初始化 ====================
func _setup_references():
    if not world_environment:
        world_environment = get_node_or_null("/root/WorldEnvironment")
        if not world_environment:
            world_environment = WorldEnvironment.new()
            add_child(world_environment)
            world_environment.environment = Environment.new()
    
    if not directional_light:
        directional_light = get_node_or_null("../DirectionalLight3D")
        if not directional_light:
            directional_light = DirectionalLight3D.new()
            directional_light.name = "Sun"
            add_child(directional_light)
    
    if not camera:
        camera = get_viewport().get_camera_3d()
    
    if not reflection_probe and camera:
        reflection_probe = _create_reflection_probe()

func _setup_environment():
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        
        env.background_mode = Environment.BG_SKY
        env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        env.ambient_light_energy = 0.8
        
        env.glow_enabled = true
        env.glow_intensity = glow_intensity
        env.glow_bloom = bloom_intensity
        
        env.tonemap_mode = Environment.TONE_MAPPER_ACES
        env.tonemap_exposure = exposure
        env.tonemap_white = 1.0
        
        env.ssao_enabled = true
        env.ssao_intensity = 0.5
        env.ssao_radius = 1.0
        env.ssil_enabled = true
        env.sdfgi_enabled = true
        env.sdfgi_cascades = 4
        
        env.volumetric_fog_enabled = true
        env.volumetric_fog_density = fog_intensity * 0.3
        env.volumetric_fog_albedo = Color(0.9, 0.85, 0.8)

func _create_reflection_probe() -> ReflectionProbe:
    var probe = ReflectionProbe.new()
    probe.name = "EnvironmentReflectionProbe"
    probe.extents = Vector3(100, 50, 100)
    probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
    probe.intensity = 1.0
    probe.max_distance = 200.0
    probe.interior = false
    probe.enable_shadows = true
    probe.cull_mask = 4294967295
    add_child(probe)
    return probe

# ==================== 风系统 ====================
func _update_wind():
    var final_strength = wind_strength + current_gust + wind_noise
    final_strength = clamp(final_strength, 0.0, 1.0)
    
    emit_signal("wind_changed", wind_direction, final_strength, current_gust)
    
    if sky_material:
        sky_material.set_shader_parameter("wind_direction", wind_direction)
        sky_material.set_shader_parameter("wind_strength", final_strength)
    
    if water_material:
        water_material.set_shader_parameter("wind_direction", wind_direction)
        water_material.set_shader_parameter("wind_effect", final_strength)

func _update_wind_gust(delta):
    gust_timer += delta
    if gust_timer >= 1.0 / wind_gust_frequency:
        gust_timer = 0.0
        current_gust = randf_range(-wind_gust_strength, wind_gust_strength) * wind_strength
        _update_wind()

func _update_wind_noise(delta):
    wind_noise = sin(Time.get_ticks_msec() * 0.001 * wind_turbulence) * 0.05 * wind_strength
    _update_wind()

func get_current_wind() -> Vector3:
    return Vector3(wind_direction.x, 0.0, wind_direction.y) * (wind_strength + current_gust)

# ==================== 天气系统 ====================
func _update_weather():
    emit_signal("weather_changed", weather_type, rain_intensity, snow_intensity, fog_intensity)
    
    if sky_material:
        sky_material.set_shader_parameter("rain_intensity", rain_intensity)
        sky_material.set_shader_parameter("snow_intensity", snow_intensity)
        sky_material.set_shader_parameter("fog_intensity", fog_intensity)
        sky_material.set_shader_parameter("cloud_cover", cloud_cover)
    
    if water_material:
        water_material.set_shader_parameter("rain_ripple_intensity", rain_intensity * 0.8)
        water_material.set_shader_parameter("rain_ripple_density", 0.8 + rain_intensity * 1.2)
        
        if rain_intensity > 0.5:
            water_material.set_shader_parameter("reflection_strength", 0.85)
            water_material.set_shader_parameter("water_smoothness", 0.92)
        elif snow_intensity > 0.5:
            water_material.set_shader_parameter("reflection_strength", 0.5)
            water_material.set_shader_parameter("water_smoothness", 0.88)
        else:
            water_material.set_shader_parameter("reflection_strength", 0.7)
            water_material.set_shader_parameter("water_smoothness", 0.95)
    
    if world_environment and world_environment.environment:
        world_environment.environment.volumetric_fog_density = fog_intensity * 0.3
        world_environment.environment.fog_density = fog_intensity * 0.1

func _update_weather_by_type():
    match weather_type.to_lower():
        "clear":
            rain_intensity = 0.0
            snow_intensity = 0.0
            fog_intensity = 0.0
            cloud_cover = 0.1
        "light_rain":
            rain_intensity = 0.3
            snow_intensity = 0.0
            fog_intensity = 0.2
            cloud_cover = 0.6
        "rain":
            rain_intensity = 0.7
            snow_intensity = 0.0
            fog_intensity = 0.3
            cloud_cover = 0.8
        "heavy_rain":
            rain_intensity = 1.0
            snow_intensity = 0.0
            fog_intensity = 0.5
            cloud_cover = 0.95
        "light_snow":
            rain_intensity = 0.0
            snow_intensity = 0.4
            fog_intensity = 0.2
            cloud_cover = 0.7
        "snow":
            rain_intensity = 0.0
            snow_intensity = 0.7
            fog_intensity = 0.4
            cloud_cover = 0.85
        "heavy_snow":
            rain_intensity = 0.0
            snow_intensity = 1.0
            fog_intensity = 0.6
            cloud_cover = 0.95
        "fog":
            rain_intensity = 0.0
            snow_intensity = 0.0
            fog_intensity = 0.9
            cloud_cover = 0.5
        "storm":
            rain_intensity = 0.9
            snow_intensity = 0.0
            fog_intensity = 0.4
            cloud_cover = 0.98
        _:
            rain_intensity = 0.0
            snow_intensity = 0.0
            fog_intensity = 0.0
            cloud_cover = 0.1

func set_weather(weather: String):
    weather_type = weather

func set_rain(intensity: float):
    rain_intensity = intensity

func set_fog(intensity: float):
    fog_intensity = intensity

# ==================== 季节系统 ====================
func _update_season():
    emit_signal("season_changed", season, season_progress)
    
    var season_color = _get_season_color()
    
    if sky_material:
        sky_material.set_shader_parameter("season_tint", season_progress)
        sky_material.set_shader_parameter("summer_tint", _get_season_tint("summer"))
        sky_material.set_shader_parameter("winter_tint", _get_season_tint("winter"))
        sky_material.set_shader_parameter("autumn_tint", _get_season_tint("autumn"))
        sky_material.set_shader_parameter("spring_tint", _get_season_tint("spring"))
    
    if water_material:
        water_material.set_shader_parameter("season_tint", season_progress)
        water_material.set_shader_parameter("summer_tint", _get_season_tint("summer"))
        water_material.set_shader_parameter("winter_tint", _get_season_tint("winter"))
        water_material.set_shader_parameter("autumn_tint", _get_season_tint("autumn"))
        water_material.set_shader_parameter("spring_tint", _get_season_tint("spring"))

func _get_season_color() -> Color:
    match season:
        "summer":
            return Color(1.0, 1.05, 0.95)
        "winter":
            return Color(0.9, 0.92, 1.05)
        "autumn":
            return Color(1.05, 0.85, 0.7)
        "spring":
            return Color(0.9, 1.05, 0.9)
        _:
            return Color(1.0, 1.0, 1.0)

func _get_season_tint(season_name: String) -> Vector3:
    match season_name:
        "summer":
            return Vector3(1.0, 1.05, 0.95)
        "winter":
            return Vector3(0.9, 0.92, 1.05)
        "autumn":
            return Vector3(1.05, 0.85, 0.7)
        "spring":
            return Vector3(0.9, 1.05, 0.9)
        _:
            return Vector3(1.0, 1.0, 1.0)

func set_season(new_season: String):
    season = new_season

# ==================== 时间系统 ====================
func _update_time():
    var hour = int(time_of_day * 24)
    var minute = int((time_of_day * 24 - hour) * 60)
    
    emit_signal("time_changed", time_of_day, hour, minute)
    
    if not directional_light:
        return
    
    var sun_angle = time_of_day * 360.0 - 90.0
    var sun_rotation = Quaternion(Vector3.RIGHT, deg_to_rad(sun_angle))
    var sun_dir = sun_rotation * Vector3.FORWARD
    sun_dir.y = abs(sun_dir.y)
    
    directional_light.rotation = Vector3(deg_to_rad(sun_angle), 0, 0)
    
    var intensity = clamp(1.0 - abs(time_of_day - 0.5) * 2.0, 0.1, 1.2)
    directional_light.light_energy = intensity * 1.2
    
    var sun_color: Color
    if intensity > 0.8:
        sun_color = Color(1.0, 0.95, 0.85)
    elif intensity > 0.4:
        sun_color = Color(1.0, 0.85, 0.65)
    else:
        sun_color = Color(1.0, 0.7, 0.5)
    
    directional_light.light_color = sun_color
    
    if sky_material:
        sky_material.set_shader_parameter("sun_direction", Vector3(sun_dir.x, sun_dir.y, sun_dir.z))
        sky_material.set_shader_parameter("sun_intensity", intensity)
    
    if water_material:
        water_material.set_shader_parameter("sun_direction", Vector3(sun_dir.x, sun_dir.y, sun_dir.z))
        water_material.set_shader_parameter("sun_intensity", intensity)
    
    if world_environment and world_environment.environment:
        world_environment.environment.ambient_light_energy = 0.5 + intensity * 0.5

func set_time(hour: float, minute: float = 0.0):
    time_of_day = (hour + minute / 60.0) / 24.0

# ==================== 后处理 ====================
func _update_post_processing():
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        env.glow_intensity = glow_intensity
        env.glow_bloom = bloom_intensity
        env.tonemap_exposure = exposure
        
        if vignette_intensity > 0.01:
            env.tonemap_white = 1.0 - vignette_intensity * 0.3

# ==================== 反射系统 ====================
func update_reflection():
    if not reflection_probe:
        return
    
    var now = Time.get_ticks_msec() / 1000.0
    if now - last_reflection_update >= reflection_update_interval:
        reflection_probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
        await get_tree().process_frame
        reflection_probe.update_mode = ReflectionProbe.UPDATE_ONCE
        last_reflection_update = now
        
        if water_material and reflection_probe.get_cubemap():
            water_material.set_shader_parameter("reflection_cubemap", reflection_probe.get_cubemap())

# ==================== 全局更新 ====================
func _update_all():
    _update_wind()
    _update_weather()
    _update_season()
    _update_time()
    _update_post_processing()
    update_reflection()

# ==================== 便捷方法 ====================
func get_current_time_string() -> String:
    var hour = int(time_of_day * 24)
    var minute = int((time_of_day * 24 - hour) * 60)
    return "%02d:%02d" % [hour, minute]

func get_weather_description() -> String:
    if rain_intensity > 0.7:
        return "Heavy Rain"
    elif rain_intensity > 0.3:
        return "Rain"
    elif rain_intensity > 0.1:
        return "Light Rain"
    elif snow_intensity > 0.7:
        return "Heavy Snow"
    elif snow_intensity > 0.3:
        return "Snow"
    elif snow_intensity > 0.1:
        return "Light Snow"
    elif fog_intensity > 0.7:
        return "Dense Fog"
    elif fog_intensity > 0.3:
        return "Fog"
    elif cloud_cover > 0.8:
        return "Overcast"
    elif cloud_cover > 0.5:
        return "Cloudy"
    elif cloud_cover > 0.2:
        return "Partly Cloudy"
    else:
        return "Clear"

func get_season_description() -> String:
    if season_progress < 0.25:
        return "Early " + season
    elif season_progress < 0.5:
        return "Mid " + season
    elif season_progress < 0.75:
        return "Late " + season
    else:
        return "Transition to " + _get_next_season()

func _get_next_season() -> String:
    match season:
        "summer":
            return "autumn"
        "autumn":
            return "winter"
        "winter":
            return "spring"
        "spring":
            return "summer"
        _:
            return "summer"

func get_wind_description() -> String:
    var final_strength = wind_strength + current_gust
    if final_strength < 0.1:
        return "Calm"
    elif final_strength < 0.3:
        return "Light Breeze"
    elif final_strength < 0.5:
        return "Moderate Breeze"
    elif final_strength < 0.7:
        return "Strong Breeze"
    elif final_strength < 0.9:
        return "Gale"
    else:
        return "Storm"