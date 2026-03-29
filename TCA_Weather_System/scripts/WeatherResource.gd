class_name WeatherResource
extends Resource

## 最小持续时间（秒）
@export var min_duration: float = 40000.0

## 最大持续时间（秒）
@export var max_duration: float = 100000.0

## 云移动速度
@export var cloud_speed: float = 0.001

## 小云覆盖量 (0-1)
@export_range(0.0, 1.0) var small_cloud_cover: float = 0.5

## 大云覆盖量 (0-1)
@export_range(0.0, 1.0) var large_cloud_cover: float = 0.5

## 云内部颜色
@export var cloud_inner_colour: Color = Color(1.0, 1.0, 1.0)

## 云外部颜色
@export var cloud_outer_colour: Color = Color(0.5, 0.5, 0.5)

## 降水效果
@export var precipitation: PrecipitationResource

## 雾浓度
@export_range(0.0, 1.0) var fog_density: float = 0.0