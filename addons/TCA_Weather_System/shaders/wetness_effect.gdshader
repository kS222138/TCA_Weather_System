shader_type spatial;

uniform float wetness_intensity = 1.0;
uniform vec3 wet_color = vec3(0.0, 0.5, 0.8);

void fragment() {
    ALBEDO = mix(ALBEDO, wet_color, wetness_intensity);
}
