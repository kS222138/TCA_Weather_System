extends GPUParticles3D

@export var intensity : float = 0.0

func _ready():
    set_process(true)

func _process(delta):
    amount = int(1000 * intensity)
    lifetime = 0.8 - intensity * 0.3
    var base_velocity = Vector3(0, -5 - intensity * 3, 0)
    
    if intensity > 0.1:
        var horizontal = randf_range(-2.0, 2.0) * intensity
        process_material.velocity_min = base_velocity + Vector3(horizontal, 0, horizontal)
        process_material.velocity_max = base_velocity + Vector3(-horizontal, 0, -horizontal)
    else:
        process_material.velocity_min = base_velocity
        process_material.velocity_max = base_velocity
    
    process_material.gravity = Vector3(0, -2.0 - intensity * 2, 0)
    explosiveness = 0.2 - intensity * 0.15
    randomness = 0.4 - intensity * 0.2