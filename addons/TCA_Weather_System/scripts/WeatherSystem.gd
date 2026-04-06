extends Node3D

@export var world_environment: NodePath
@export var wetness_plane: NodePath
@export var day_cycle: float = 0.5
@export var day_speed: float = 0.1
@export var rain_intensity: float = 0.0
@export var fog_intensity: float = 0.0

var env: WorldEnvironment
var wetness_mat: ShaderMaterial

func _ready():
    if world_environment:
        env = get_node(world_environment)
    if wetness_plane:
        var wp = get_node(wetness_plane)
        if wp:
            wetness_mat = wp.material_override

func _process(delta):
    day_cycle += delta * day_speed
    day_cycle = fmod(day_cycle, 1.0)
    
    if env and env.environment and env.environment.sky and env.environment.sky.sky_material:
        var sky_mat = env.environment.sky.sky_material
        sky_mat.set_shader_parameter("day_cycle", day_cycle)
        sky_mat.set_shader_parameter("rain_intensity", rain_intensity)
        sky_mat.set_shader_parameter("fog_intensity", fog_intensity)
        
        env.environment.fog_enabled = true
        env.environment.fog_density = fog_intensity * 0.1
    
    if wetness_mat:
        wetness_mat.set_shader_parameter("wetness", rain_intensity * 0.8)