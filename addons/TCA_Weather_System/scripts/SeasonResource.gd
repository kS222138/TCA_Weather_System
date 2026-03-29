class_name SeasonResource
extends Resource

@export var season_id: String = ""
@export var name: String = ""
@export var weathers: Array[WeatherOccurrenceResource] = []
@export var duration_in_days: float = 10.0
@export var day_sky: SkyColourResource
@export var night_sky: SkyColourResource
@export var day_night_cycle_curve: Curve