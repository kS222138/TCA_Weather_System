shader_type fog;

uniform float fog_intensity : hint_range(0, 1) = 0.0;
uniform float fog_height : hint_range(0, 100) = 10.0;
uniform float fog_density = 0.1;
uniform vec3 fog_color : source_color = vec3(0.6, 0.65, 0.7);

void fog() {
    float height_factor = exp(-WORLD_POSITION.y / fog_height);
    float density = fog_density * fog_intensity * height_factor;
    DENSITY = clamp(density, 0.0, 1.0);
    ALBEDO = fog_color;
}
