extends Resource
class_name QualityPreset

enum QualityLevel { LOW, MEDIUM, HIGH, ULTRA }

@export var preset_name: String = ""
@export var description: String = ""
@export var quality_level: QualityLevel = QualityLevel.HIGH

@export var cloud_quality: float = 1.0
@export var water_quality: float = 1.0
@export var particle_quality: float = 1.0
@export var shadow_quality: float = 1.0
@export var reflection_quality: float = 1.0
@export var fog_quality: float = 1.0
@export var aa_enabled: bool = true
@export var ssao_enabled: bool = true
@export var bloom_enabled: bool = true
@export var recommended_for: String = ""

func apply_to(performance_controller: PerformanceController) -> void:
	if not performance_controller:
		return
	
	var quality_map = {
		QualityLevel.LOW: PerformanceController.Quality.LOW,
		QualityLevel.MEDIUM: PerformanceController.Quality.MEDIUM,
		QualityLevel.HIGH: PerformanceController.Quality.HIGH,
		QualityLevel.ULTRA: PerformanceController.Quality.ULTRA
	}
	var target_quality = quality_map.get(quality_level, PerformanceController.Quality.HIGH)
	
	performance_controller.apply_quality(target_quality)
	
	if performance_controller.sky_material:
		performance_controller.sky_material.set_shader_parameter("cloud_quality", cloud_quality)
		performance_controller.sky_material.set_shader_parameter("bloom_enabled", bloom_enabled)
	
	if performance_controller.water_material:
		performance_controller.water_material.set_shader_parameter("water_quality", water_quality)
		performance_controller.water_material.set_shader_parameter("reflection_quality", reflection_quality)
	
	if performance_controller.has_method("set_particle_quality"):
		performance_controller.set_particle_quality(particle_quality)
	
	if performance_controller.has_method("set_shadow_quality"):
		performance_controller.set_shadow_quality(shadow_quality)
	
	if performance_controller.has_method("set_fog_quality"):
		performance_controller.set_fog_quality(fog_quality)
	
	if performance_controller.has_method("set_ssao_enabled"):
		performance_controller.set_ssao_enabled(ssao_enabled)

func get_quality_name() -> String:
	if preset_name != "":
		return preset_name
	match quality_level:
		QualityLevel.LOW:
			return "Low"
		QualityLevel.MEDIUM:
			return "Medium"
		QualityLevel.HIGH:
			return "High"
		QualityLevel.ULTRA:
			return "Ultra"
	return "High"

func is_high_quality() -> bool:
	return quality_level >= QualityLevel.HIGH

func is_low_quality() -> bool:
	return quality_level <= QualityLevel.MEDIUM

func get_recommendation() -> String:
	if recommended_for != "":
		return recommended_for
	match quality_level:
		QualityLevel.LOW:
			return "Low-end devices, integrated graphics"
		QualityLevel.MEDIUM:
			return "Mid-range devices, stable 60fps"
		QualityLevel.HIGH:
			return "High-end devices, visual quality"
		QualityLevel.ULTRA:
			return "Ultra settings, best visual experience"
	return ""

func is_valid() -> bool:
	return cloud_quality >= 0 and cloud_quality <= 1 and water_quality >= 0 and water_quality <= 1