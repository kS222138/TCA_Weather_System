extends Node
class_name PerformanceController

enum Quality { LOW, MEDIUM, HIGH, ULTRA }

@export var current_quality: Quality = Quality.HIGH
@export var auto_adjust: bool = true
@export var target_fps: int = 60
@export var adjust_interval: float = 5.0
@export var low_particle_multiplier: float = 0.2
@export var medium_particle_multiplier: float = 0.5
@export var high_particle_multiplier: float = 0.8
@export var ultra_particle_multiplier: float = 1.0

var _sky_material: ShaderMaterial
var _water_material: ShaderMaterial
var _rain_particles: GPUParticles3D
var _snow_particles: GPUParticles3D
var _timer: Timer
var _base_rain_amount: int = 1000
var _base_snow_amount: int = 600

signal quality_changed(quality: Quality)

func _ready():
	_setup_timer()
	apply_quality(current_quality)

func set_sky_material(mat: ShaderMaterial) -> void:
	_sky_material = mat

func set_water_material(mat: ShaderMaterial) -> void:
	_water_material = mat

func set_rain_particles(particles: GPUParticles3D) -> void:
	_rain_particles = particles

func set_snow_particles(particles: GPUParticles3D) -> void:
	_snow_particles = particles

func apply_quality(quality: Quality) -> void:
	current_quality = quality
	match quality:
		Quality.LOW:
			_apply_low()
		Quality.MEDIUM:
			_apply_medium()
		Quality.HIGH:
			_apply_high()
		Quality.ULTRA:
			_apply_ultra()
	quality_changed.emit(quality)

func _apply_high() -> void:
	if _sky_material:
		_sky_material.set_shader_parameter("cloud_uv_scale", 1.2)
		_sky_material.set_shader_parameter("cloud_uv_scale2", 1.5)
		_sky_material.set_shader_parameter("small_cloud_cover", 0.5)
		_sky_material.set_shader_parameter("large_cloud_cover", 0.4)
		_sky_material.set_shader_parameter("cloud_depth_effect", true)
		_sky_material.set_shader_parameter("stars_enabled", true)
		_sky_material.set_shader_parameter("moon_enabled", true)
	if _water_material:
		_water_material.set_shader_parameter("wave_speed3", 2.5)
		_water_material.set_shader_parameter("wave_strength3", 0.08)
		_water_material.set_shader_parameter("caustic_intensity", 0.9)
		_water_material.set_shader_parameter("god_ray_intensity", 0.6)
		_water_material.set_shader_parameter("spectral_highlight", 0.35)
	if _rain_particles:
		_rain_particles.amount = int(_base_rain_amount * high_particle_multiplier)
	if _snow_particles:
		_snow_particles.amount = int(_base_snow_amount * high_particle_multiplier)
	_apply_aa(true)

func _apply_ultra() -> void:
	if _sky_material:
		_sky_material.set_shader_parameter("cloud_uv_scale", 1.5)
		_sky_material.set_shader_parameter("cloud_uv_scale2", 1.8)
		_sky_material.set_shader_parameter("small_cloud_cover", 0.6)
		_sky_material.set_shader_parameter("large_cloud_cover", 0.5)
	if _water_material:
		_water_material.set_shader_parameter("caustic_intensity", 1.2)
		_water_material.set_shader_parameter("god_ray_intensity", 0.8)
	if _rain_particles:
		_rain_particles.amount = int(_base_rain_amount * ultra_particle_multiplier)
	if _snow_particles:
		_snow_particles.amount = int(_base_snow_amount * ultra_particle_multiplier)
	_apply_aa(true)

func _apply_medium() -> void:
	if _sky_material:
		_sky_material.set_shader_parameter("cloud_uv_scale", 1.0)
		_sky_material.set_shader_parameter("cloud_uv_scale2", 1.2)
		_sky_material.set_shader_parameter("small_cloud_cover", 0.4)
		_sky_material.set_shader_parameter("large_cloud_cover", 0.3)
		_sky_material.set_shader_parameter("cloud_depth_effect", true)
		_sky_material.set_shader_parameter("stars_enabled", true)
		_sky_material.set_shader_parameter("moon_enabled", true)
	if _water_material:
		_water_material.set_shader_parameter("wave_speed3", 0)
		_water_material.set_shader_parameter("wave_strength3", 0)
		_water_material.set_shader_parameter("caustic_intensity", 0.6)
		_water_material.set_shader_parameter("god_ray_intensity", 0.4)
		_water_material.set_shader_parameter("spectral_highlight", 0.2)
	if _rain_particles:
		_rain_particles.amount = int(_base_rain_amount * medium_particle_multiplier)
	if _snow_particles:
		_snow_particles.amount = int(_base_snow_amount * medium_particle_multiplier)
	_apply_aa(false)

func _apply_low() -> void:
	if _sky_material:
		_sky_material.set_shader_parameter("cloud_uv_scale", 0.8)
		_sky_material.set_shader_parameter("cloud_uv_scale2", 1.0)
		_sky_material.set_shader_parameter("small_cloud_cover", 0.3)
		_sky_material.set_shader_parameter("large_cloud_cover", 0.2)
		_sky_material.set_shader_parameter("cloud_depth_effect", false)
		_sky_material.set_shader_parameter("stars_enabled", false)
		_sky_material.set_shader_parameter("moon_enabled", false)
	if _water_material:
		_water_material.set_shader_parameter("wave_speed2", 0)
		_water_material.set_shader_parameter("wave_strength2", 0)
		_water_material.set_shader_parameter("wave_speed3", 0)
		_water_material.set_shader_parameter("wave_strength3", 0)
		_water_material.set_shader_parameter("caustic_intensity", 0.3)
		_water_material.set_shader_parameter("god_ray_intensity", 0.2)
		_water_material.set_shader_parameter("spectral_highlight", 0.1)
	if _rain_particles:
		_rain_particles.amount = int(_base_rain_amount * low_particle_multiplier)
	if _snow_particles:
		_snow_particles.amount = int(_base_snow_amount * low_particle_multiplier)
	_apply_aa(false)

func _apply_aa(enable: bool) -> void:
	var viewport = get_viewport()
	if not viewport:
		return
	if enable:
		viewport.msaa_3d = Viewport.MSAA_2X
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	else:
		viewport.msaa_3d = Viewport.MSAA_DISABLED
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

func _setup_timer() -> void:
	if auto_adjust:
		_timer = Timer.new()
		_timer.wait_time = adjust_interval
		_timer.autostart = true
		_timer.timeout.connect(_auto_adjust)
		add_child(_timer)

func _auto_adjust() -> void:
	var current_fps = Engine.get_frames_per_second()
	if current_fps < target_fps * 0.7 and current_quality > Quality.LOW:
		apply_quality(current_quality - 1)
		print("PerformanceController: Lowering quality to ", get_quality_name())
	elif current_fps > target_fps * 1.2 and current_quality < Quality.ULTRA:
		apply_quality(current_quality + 1)
		print("PerformanceController: Raising quality to ", get_quality_name())

func get_quality_name() -> String:
	match current_quality:
		Quality.LOW:
			return "Low"
		Quality.MEDIUM:
			return "Medium"
		Quality.HIGH:
			return "High"
		Quality.ULTRA:
			return "Ultra"
	return "Unknown"

func set_base_particle_amounts(rain: int, snow: int) -> void:
	_base_rain_amount = rain
	_base_snow_amount = snow
	apply_quality(current_quality)