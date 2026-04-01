🌊 TCA Weather System - Complete Environment System
 
Version: 1.2.0
Godot Version: 4.6+
License: MIT
 
 
 
🆕 What's New in v1.2.0
 
✅ Dynamic Terrain Wetness System
 
- Automatically applies wetness texture based on rain intensity
- Supports wetness drying over time after rain stops
- Blendable wetness effect for landscape / ground meshes
 
✅ Vegetation Interaction System
 
- Grass & foliage bending from wind
- Leaf sway & branch movement synced to global wind
- Rain impact effects on vegetation
- Performance-friendly vertex animation only
 
✅ Improved Performance Controller
 
- Auto-quality now adjusts wetness / vegetation effects
- Added mobile-specific optimizations for terrain effects
- Reduced overall shader instruction count
 
✅ Weather System Improvements
 
- Faster weather transitions
- Better cloud smoothing
- Optimized particle culling for mobile
- Fixed floating point precision on low-end devices
 
 
 
✅ What's New in v1.1.0 (Previous)
 
✅ Performance Optimization System
 
- PerformanceController: Auto-adjusts graphics based on FPS (Low/Medium/High/Ultra)
- QualityPreset: Save/load preset settings
 
✅ Wind & Cloud System
 
- Global wind with gust & turbulence
- Cloud movement synced to wind
 
✅ Weather Transition & Forecast
 
- Smooth weather blending
- Probability-based forecast system
 
 
 
✅ Core Features (v1.0.0)
 
Cinematic Water Rendering System
 
- Gerstner Waves (3-layer physical waves)
- Dynamic Normals & Procedural Caustics
- Multi-layer foam system
- God Rays & Spectral Highlights
- Full underwater effects (fog, distortion, caustics)
 
Sky & Atmosphere System
 
- Rayleigh + Mie atmospheric scattering
- 3-layer dynamic clouds
- Procedural stars & moon
- Weather-driven sky color
 
Environment Management
 
- 10+ built-in weather presets
- Season system (summer / autumn / winter / spring)
- Day/night cycle
- Automatic cubemap reflections
 
Particle Systems
 
- Dynamic rain & snow particles
- Density controlled by weather intensity
 
 
 
📁 File Structure (v1.2.0 Updated)
 
plaintext
  
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
│   ├── TerrainWetness.gd       # NEW in 1.2.0
│   └── VegetationInteraction.gd # NEW in 1.2.0
├── seasons/
├── shaders/
├── textures/
├── weather/
└── weather_controller.tscn
 
 
 
 
🚀 Quick Start
 
1. Add to Scene
 
Drag  weather_controller.tscn  into your world.
 
2. Basic Setup
 
gdscript
  
var env = $EnvironmentManager
env.set_weather("rain")
env.set_wind(Vector2(1, 0), 0.6)
env.set_time(14.5)
env.set_season("summer")
env.auto_time = true
 
 
3. Performance Control
 
gdscript
  
var perf = $PerformanceController
perf.apply_quality(PerformanceController.Quality.LOW)
perf.auto_adjust = true
 
 
4. Wind Control
 
gdscript
  
var wind = $WindController
wind.set_wind(Vector2(1, 0), 8.0)
wind.gust_strength = 3.0
 
 
5. Weather Forecast
 
gdscript
  
var forecast = $WeatherForecast
forecast.auto_change = true
forecast.change_interval = 300.0
 
 
6. NEW — Terrain Wetness (v1.2.0)
 
gdscript
  
var wetness = $TerrainWetness
wetness.enable_auto_wetness = true
wetness.dry_speed = 0.2
wetness.set_terrain_material($Terrain.material_override)
 
 
7. NEW — Vegetation Interaction (v1.2.0)
 
gdscript
  
var vegetation = $VegetationInteraction
vegetation.add_grass_node($GrassCluster)
vegetation.wind_sway_strength = 1.5
vegetation.rain_impact = true
 
 
 
 
📱 Performance Tuning
 
Setting Low Medium High Ultra 
Wave Layers 1 2 3 3 
Cloud Layers 1 2 3 3 
God Rays Off On On On 
Wetness Effects Off Low Full Full 
Vegetation Sway Off Simple Full Full 
Particle Count 30% 60% 100% 100% 
 
Mobile Recommended: Low Quality
 
 
 
📄 License
 
MIT License — Free for commercial & personal use.
 
 
 
🙏 Credits
 
- Author: ks222
- Sky Shader: Inspired by UE5 atmospheric scattering
- Water Shader: Custom Gerstner wave implementation
- Fully optimized for mobile & low-end devices
 

 
🛣️ Roadmap
 
- v1.0.0 – Core water + sky + weather
- v1.1.0 – Performance, wind, transition, forecast
- v1.2.0 – Terrain wetness + Vegetation interaction
- v1.3.0 – Audio system integration
- v2.0.0 – Volumetric clouds + Weather UI
 
