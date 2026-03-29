extends Node
class_name CloudDriver

@export var cloud_material: ShaderMaterial
@export var wind_controller: WindController
@export var cloud_speed_multiplier: float = 1.0
@export var shape_change_speed: float = 0.0003
@export var cloud_texture_scale: float = 1.0
@export var cloud_density: float = 0.5
@export var update_interval: float = 0.0
@export var offset_mod: float = 1000.0

var _current_offset: Vector2 = Vector2.ZERO
var _update_timer: float = 0.0

func _ready():
	if not cloud_material:
		push_warning("CloudDriver: cloud_material not set")
		return
	
	_apply_material_params()
	
	if wind_controller:
		wind_controller.wind_changed.connect(_on_wind_changed)
		_on_wind_changed(wind_controller.get_wind_vector(), wind_controller.get_wind_speed())

func _process(delta: float):
	if not cloud_material:
		return
	
	if update_interval > 0:
		_update_timer += delta
		if _update_timer < update_interval:
			return
		_update_timer = 0.0
	
	_update_clouds(delta)

func _apply_material_params() -> void:
	if not cloud_material:
		return
	cloud_material.set_shader_parameter("cloud_uv_scale", cloud_texture_scale)
	cloud_material.set_shader_parameter("cloud_density", cloud_density)
	cloud_material.set_shader_parameter("cloud_shape_change_speed", shape_change_speed)

func _update_clouds(delta: float) -> void:
	var wind_vec = wind_controller.get_wind_vector() if wind_controller else Vector2.ZERO
	var offset_delta = wind_vec * cloud_speed_multiplier * delta * 0.0005
	_current_offset = Vector2(
		fmod(_current_offset.x + offset_delta.x, offset_mod),
		fmod(_current_offset.y + offset_delta.y, offset_mod)
	)
	
	cloud_material.set_shader_parameter("cloud_direction", _current_offset)

func _on_wind_changed(direction: Vector2, speed: float) -> void:
	if not cloud_material:
		return
	var wind_vec = direction * speed
	cloud_material.set_shader_parameter("wind_direction", wind_vec)

func set_cloud_density(density: float) -> void:
	cloud_density = density
	if cloud_material:
		cloud_material.set_shader_parameter("cloud_density", density)

func set_cloud_texture_scale(scale: float) -> void:
	cloud_texture_scale = scale
	if cloud_material:
		cloud_material.set_shader_parameter("cloud_uv_scale", scale)

func set_shape_change_speed(speed: float) -> void:
	shape_change_speed = speed
	if cloud_material:
		cloud_material.set_shader_parameter("cloud_shape_change_speed", speed)

func get_cloud_offset() -> Vector2:
	return _current_offset