extends Node
class_name VegetationWindDriver

func _process(delta):
    var env = get_parent()
    if env is EnvironmentManager:
        var dir = env.wind_direction
        var str = env.wind_strength + env.current_gust
        var materials = get_tree().root.find_children_by_type("ShaderMaterial", true, false)
        for mat in materials:
            if mat.has_parameter("wind_dir"):
                mat.set_shader_parameter("wind_dir", dir)
            if mat.has_parameter("wind_strength"):
                mat.set_shader_parameter("wind_strength", str)
