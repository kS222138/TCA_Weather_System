extends Node
class_name VegetationWindDriver

var _registered_materials: Array[ShaderMaterial] = []

func register_material(mat: ShaderMaterial) -> void:
	if mat not in _registered_materials:
		_registered_materials.append(mat)

func unregister_material(mat: ShaderMaterial) -> void:
	_registered_materials.erase(mat)

func clear_materials() -> void:
	_registered_materials.clear()

func _process(delta):
	var env = get_parent()
	if not env is EnvironmentManager:
		return
	
	var dir = env.wind_direction
	var str = env.wind_strength + env.current_gust
	
	for i in range(_registered_materials.size() - 1, -1, -1):
		var mat = _registered_materials[i]
		if not is_instance_valid(mat):
			_registered_materials.remove_at(i)
			continue
		
		if mat.has_parameter("wind_dir"):
			mat.set_shader_parameter("wind_dir", dir)
		if mat.has_parameter("wind_strength"):
			mat.set_shader_parameter("wind_strength", str)