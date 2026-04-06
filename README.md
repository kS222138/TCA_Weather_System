🌊 TCA Weather System - Complete Environment System

Version: 1.3.0
Godot Version: 4.6+
License: MIT


🆕 What's New in v1.3.0

✅ Volumetric Cloud System

- Full 3D volumetric clouds with self-shadowing
- Cloud motion synchronized with wind direction & speed
- Adjustable cloud density, shadow strength, and coverage
- Moon illumination on clouds for night scenes
- Cloud shadows that realistically block sunlight

✅ Enhanced Fog System

- Exponential height fog with weather blending
- Fog depth falloff control for atmospheric perspective
- Fog intensity automatically responds to rain
- Separate fog color for sunrise/sunset hours

✅ Day/Night Cycle Enhancement

- Automatic color temperature shift (warm sunset, cool night)
- Sunrise haze effect with light scattering
- Night sky brightness control
- Seamless transition between day phases

✅ Rain Visual Improvements

- Rain tint for sky & clouds (weather-driven color blending)
- Ground wetness shader with roughness & metallic response
- Wetness dries naturally over time after rain stops
- Rain intensity affects fog density and cloud darkness

✅ Particle System Optimization

- Rain & snow particles batch-optimized for performance
- Intensity-based particle count & lifetime adjustment
- Mobile-friendly particle culling

✅ Editor Integration

- Weather parameters exposed in editor panel
- Real-time preview of cloud, fog, and wetness settings
- Quick-switch weather presets


✅ What's New in v1.2.0 (Previous)

✅ Dynamic Terrain Wetness System
- Automatically applies wetness texture based on rain intensity
- Supports wetness drying over time after rain stops

✅ Vegetation Interaction System
- Grass & foliage bending from wind
- Rain impact effects on vegetation

✅ Improved Performance Controller
- Auto-quality adjusts wetness / vegetation effects
- Mobile-specific optimizations


✅ What's New in v1.1.0 (Previous)

✅ Performance Optimization System
- PerformanceController with auto-adjust based on FPS

✅ Wind & Cloud System
- Global wind with gust & turbulence

✅ Weather Transition & Forecast
- Smooth weather blending
- Probability-based forecast system


✅ Core Features (v1.0.0)

Cinematic Water Rendering System
- Gerstner Waves, Dynamic Normals, Multi-layer foam
- God Rays & Spectral Highlights

Sky & Atmosphere System
- Rayleigh + Mie atmospheric scattering
- 3-layer dynamic clouds

Environment Management
- 10+ weather presets, Season system, Day/night cycle


📁 File Structure (v1.3.0 Updated)

TCA_Weather_System/
├── materials/
├── nodes/
├── particles/
├── precipitation/
├── presets/
├── scripts/
│   ├── EnvironmentManager.gd
│   ├── PerformanceController.gd
│   ├── WindController.gd
│   ├── CloudDriver.gd
│   ├── WeatherTransition.gd
│   ├── WeatherForecast.gd
│   ├── QualityPreset.gd
│   ├── TerrainWetness.gd
│   └── VegetationInteraction.gd
├── seasons/
├── shaders/
│   ├── weather_system_sky.gdshader
│   ├── clouds_volume.gdshader      # NEW in 1.3.0
│   ├── wetness_effect.gdshader     # NEW in 1.3.0
│   └── fog.gdshader                # NEW in 1.3.0
├── textures/
├── weather/
└── weather_controller.tscn


🚀 Quick Start (v1.3.0 New Features)

Volumetric Clouds
gdscript
var sky = $EnvironmentManager.sky_material
sky.set_shader_parameter("cloud_density", 0.3)
sky.set_shader_parameter("cloud_shadow", 0.5)
sky.set_shader_parameter("wind_direction", 45.0)

Wetness Effect
gdscript
var wetness = $TerrainWetness
wetness.wetness_strength = 0.8
wetness.dry_speed = 0.1

Fog Control
gdscript
var env = $WorldEnvironment.environment
env.fog_height = 10.0
env.fog_density = 0.15 * rain_intensity


📱 Performance Tuning

Setting         Low    Medium  High   Ultra
Wave Layers     1      2       3      3
Cloud Layers    1      2       3      3
Volumetric Clouds Off    Low     Mid    Full
Wetness Effects  Off    Low     Full   Full
Particle Count  30%    60%     100%   100%

Mobile Recommended: Low Quality


📄 License

MIT License — Free for commercial & personal use.


🙏 Credits

- Author: ks222
- Volumetric Clouds: Custom raymarching implementation
- Sky Shader: Inspired by UE5 atmospheric scattering
- Water Shader: Custom Gerstner wave implementation


🛣️ Roadmap

- v1.0.0 – Core water + sky + weather
- v1.1.0 – Performance, wind, transition, forecast
- v1.2.0 – Terrain wetness + Vegetation interaction
- v1.3.0 – Volumetric clouds + Enhanced fog + Wetness shader  ✅
- v1.4.0 – Audio system integration
- v2.0.0 – Weather UI + Dynamic seasons