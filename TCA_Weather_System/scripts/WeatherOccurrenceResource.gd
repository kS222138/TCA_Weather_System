class_name WeatherOccurrenceResource
extends Resource

## 天气资源
@export var weather: WeatherResource

## 天气出现概率权重 (0.0 - 1.0)
## 设置为较低的值可使该天气罕见出现
@export_range(0.0, 1.0) var probability_ratio: float = 1.0