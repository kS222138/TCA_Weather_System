class_name WeatherSystem
extends Node

@export var day_cycle = 0.5
@export var day_speed = 0.1
@export var cloud_shadow_strength = 0.4
@export var moon_cloud_illumination = 0.25
@export var rain_sky_tint = Color(0.25, 0.3, 0.4)
@export var rain_cloud_tint = Color(0.4, 0.42, 0.46)
@export var fog_depth_falloff = 0.4
@export var sunrise_haze = 0.3
@export var night_sky_brightness = 0.15

@export var rain_intensity = 0.0   
@export var fog_intensity = 0.0    

@export var root_node: Node


signal weather_changed(new_weather)
signal rain_started()
signal fog_started()


func _ready() -> void:
    if not root_node:
        print("⚠️ 请在编辑器中为 root_node 指定一个根节点。")


func update_sky_parameters(sky_mat: ShaderMaterial) -> void:
    sky_mat.set_shader_parameter("day_cycle", day_cycle)
    sky_mat.set_shader_parameter("cloud_shadow_strength", cloud_shadow_strength)
    sky_mat.set_shader_parameter("moon_cloud_illumination", moon_cloud_illumination)
    sky_mat.set_shader_parameter("rain_intensity", rain_intensity)
    sky_mat.set_shader_parameter("fog_intensity", fog_intensity)


func _process(delta: float) -> void:
    day_cycle += delta * day_speed
    day_cycle = fmod(day_cycle, 1.0)


func example_use() -> void:
    var sky_mat = ShaderMaterial.new()
    update_sky_parameters(sky_mat)