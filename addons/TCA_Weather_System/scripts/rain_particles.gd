extends Node3D

@export var rain_intensity = 1.0
@export var wind_direction = Vector2(0.0, -1.0)
@export var rain_speed = 5.0

func _ready():
    print("✅ 雨粒子系统已初始化")
    update_rain()

func update_rain():
    var rain_pos = Vector3(0.0, 0.0, 0.0)
    var rain_dir = Vector3(wind_direction.x, 0.0, wind_direction.y).normalized()
    
    for i in range(int(rain_intensity)):
        rain_pos.x += randf_range(-1.0, 1.0)  # rand_range → randf_range
        rain_pos.z += randf_range(-1.0, 1.0)  # rand_range → randf_range
        var particle = Vector3(rain_pos.x, rain_pos.y, rain_pos.z)
        particle = particle + rain_dir * rain_speed * get_process_delta_time()  # time → delta time
        print(particle)