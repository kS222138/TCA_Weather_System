🌊 TCA Weather System - Complete Environment System

Version: 1.1.0
Godot Version: 4.6+
License: MIT

---

📦 What's New in v1.1.0

✅ Performance Optimization System

Module Class Description
Performance Controller PerformanceController Auto-adjusts graphics quality based on FPS. 4 quality levels (Low/Medium/High/Ultra).
Quality Preset QualityPreset Save/load quality presets as .tres files for different devices.

✅ Wind & Cloud System

Module Class Description
Wind Controller WindController Global wind system with gust, turbulence, and direction smoothing.
Cloud Driver CloudDriver Cloud movement driven by wind direction. Smooth cloud offset animation.

✅ Weather Transition System

Module Class Description
Weather Transition WeatherTransition Smooth weather transitions with custom curves and callbacks.
Weather Forecast WeatherForecast Probability-based weather prediction with auto-change timer.

---

✅ Existing Features (v1.0.0)

Cinematic Water Rendering System

Module Class Description
Gerstner Waves WaterShader 3-layer physical waves with crest curling
Dynamic Normals WaterShader 4-layer procedural normals + wave normals
Caustics WaterShader Real-time procedural caustics
Foam System WaterShader Crest foam + breaking foam + shoreline foam
God Rays WaterShader Volumetric light shafts
Spectral Highlights WaterShader Rainbow-colored dispersion
Underwater Effects WaterShader Fog + distortion + caustics + god rays

Sky & Atmosphere System

Module Class Description
Atmospheric Scattering SkyShader Rayleigh + Mie scattering
Cloud System SkyShader 3-layer dynamic clouds
Stars & Moon SkyShader Procedural stars with twinkling, moon with glow
Weather Integration SkyShader Rain/snow/fog affects sky color

Environment Management System

Module Class Description
Weather Controller EnvironmentManager 10+ weather presets
Season Controller EnvironmentManager Summer/autumn/winter/spring transition
Time Controller EnvironmentManager Day/night cycle
Reflection System EnvironmentManager Automatic cubemap update

Particle Systems

Module Scene Description
Rain Particles rain_particles.tscn Dynamic rain
Snow Particles snow_particles.tscn Dynamic snow

---

📁 File Structure

```
TCA_Weather_System/
├── materials/
│   ├── water_material.tres
│   └── water_material.tscn
├── nodes/
│   └── world_environment.tscn
├── particles/
│   ├── rain_particles.tscn
│   └── snow_particles.tscn
├── precipitation/
│   ├── heavy_rain.tres
│   ├── heavy_snow.tres
│   ├── rain.tres
│   └── snow.tres
├── presets/                          # New in v1.1.0
│   ├── low_quality.tres
│   ├── medium_quality.tres
│   └── high_quality.tres
├── scripts/
│   ├── EnvironmentManager.gd
│   ├── PerformanceController.gd      # New
│   ├── WindController.gd              # New
│   ├── CloudDriver.gd                 # New
│   ├── WeatherTransition.gd           # New
│   ├── WeatherForecast.gd             # New
│   ├── QualityPreset.gd               # New
│   ├── PrecipitationResource.gd
│   ├── SeasonResource.gd
│   ├── SkyColourResource.gd
│   ├── WeatherController.gd
│   ├── WeatherOccurrenceResource.gd
│   └── WeatherResource.gd
├── seasons/
│   ├── summer.tres
│   └── winter.tres
├── shaders/
│   ├── tca_water_shader.gdshader
│   └── weather_system_sky.gdshader
├── textures/
├── weather/
│   ├── clouded.tres
│   ├── fine.tres
│   ├── heavy_rain.tres
│   ├── heavy_snow.tres
│   ├── rain.tres
│   └── snow.tres
└── weather_controller.tscn
```

---

🚀 Quick Start

1️⃣ Add to Your Scene

Simply drag weather_controller.tscn into your scene.

2️⃣ Configure Environment Manager

```gdscript
var env = $EnvironmentManager
env.set_weather("rain")
env.set_wind(Vector2(1, 0), 0.6)
env.set_time(14.5)
env.set_season("summer")
env.auto_time = true
```

3️⃣ Performance Control (New in v1.1.0)

```gdscript
var perf = $PerformanceController
perf.apply_quality(PerformanceController.Quality.LOW)   # Low-end devices
perf.apply_quality(PerformanceController.Quality.ULTRA) # High-end devices
perf.auto_adjust = true  # Auto-adjust based on FPS
```

4️⃣ Wind Control (New in v1.1.0)

```gdscript
var wind = $WindController
wind.set_wind(Vector2(1, 0), 8.0)  # East wind, 8 m/s
wind.add_affected_node($CloudDriver)
wind.gust_strength = 3.0
```

5️⃣ Weather Forecast (New in v1.1.0)

```gdscript
var forecast = $WeatherForecast
forecast.auto_change = true
forecast.change_interval = 300.0  # Change every 5 minutes
forecast.weather_changed.connect(func(from, to):
    print("Weather changing from ", from, " to ", to)
)
```

6️⃣ Weather Transition (New in v1.1.0)

```gdscript
var transition = $WeatherTransition
transition.start_transition("clear", "rain", 3.0)  # 3 second transition
transition.transition_completed.connect(func(weather):
    print("Transition complete: ", weather)
)
```

---

📝 Performance Tuning

Quality Levels

Setting Low Medium High Ultra
Wave Layers 1 2 3 3
Cloud Layers 1 2 3 3
God Rays Off On On On
Spectral Highlights Off Off On On
Particle Count 30% 60% 100% 100%
Shadow Quality Off Low Medium High
Anti-Aliasing Off FXAA FXAA MSAA 2x

Mobile Devices (Low Quality)

· 1-layer waves
· No god rays
· No spectral highlights
· 30% particle count

Desktop (Ultra Quality)

· 3-layer waves
· Full god rays
· Spectral highlights
· 100% particle count

---

🎮 Environment Manager API

```gdscript
# Weather
env.set_weather("heavy_rain")
env.rain_intensity = 0.8
env.fog_intensity = 0.5

# Wind
env.set_wind(Vector2(0.8, 0.5), 0.7)

# Time
env.set_time(6, 30)
env.time_speed = 0.1
env.auto_time = true

# Season
env.set_season("autumn")
env.season_progress = 0.5

# Queries
print(env.get_weather_description())  # "Heavy Rain"
print(env.get_wind_description())     # "Strong Breeze"
print(env.get_current_time_string())  # "14:30"
```

---

🔧 Integration with Existing Projects

Connect Custom Water

```gdscript
var env = $EnvironmentManager
env.water_material = $WaterPlane.material_override
env.sky_material = $WorldEnvironment.environment.sky.sky_material
```

Connect Performance Controller

```gdscript
var perf = $PerformanceController
perf.set_sky_material(env.sky_material)
perf.set_water_material(env.water_material)
perf.set_rain_particles($RainParticles)
perf.set_snow_particles($SnowParticles)
```

Listen to Events

```gdscript
func _ready():
    env.weather_changed.connect(_on_weather_changed)
    env.time_changed.connect(_on_time_changed)
    forecast.weather_forecast_changed.connect(_on_forecast)

func _on_weather_changed(type, rain, snow, fog):
    print("Weather: ", type)

func _on_forecast(next):
    print("Next weather: ", next)
```

---

📄 License

MIT License - Free for commercial and personal use.

---

🙏 Credits

· Author: ks222 
· Sky Shader: Inspired by UE5 atmospheric scattering
· Water Shader: Custom Gerstner wave implementation reaching 95% of UE5 quality
· Performance: Optimized for mobile devices

---

🚀 Roadmap

· v1.0.0 - Core water + sky + environment system
· v1.1.0 - Performance optimization + Wind system + Weather transition + Weather forecast
· v1.2.0 - Dynamic terrain wetness + Vegetation interaction
· v1.3.0 - Audio system integration
· v2.0.0 - Volumetric clouds + Weather forecasting UI