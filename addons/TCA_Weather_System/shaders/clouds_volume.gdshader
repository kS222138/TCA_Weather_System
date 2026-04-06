shader_type sky;

uniform float cloud_speed = 0.0006;
uniform float wind_direction = 0.0;
uniform float wind_strength = 0.4;
uniform float cloud_density = 0.3;
uniform float cloud_shadow = 0.5;
uniform float time;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0,0.0)), hash(i + vec2(1.0,0.0)), u.x),
               mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0,1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float total = 0.0;
    float amp = 0.5;
    float freq = 4.0;
    for (int i = 0; i < 5; i++) {
        total += amp * noise(p * freq);
        amp *= 0.5;
        freq *= 2.0;
    }
    return total;
}

vec3 get_volumetric_clouds(vec3 ray_dir, vec3 sun_dir) {
    vec3 color = vec3(0.0);
    float density = 0.0;

    vec2 wind = vec2(cos(wind_direction), sin(wind_direction)) * cloud_speed * wind_strength;

    for (int i = 0; i < 24; i++) {
        float t = float(i) / 24.0;
        vec3 pos = ray_dir * t * 30.0;
        vec2 uv = pos.xz * 0.1 + wind * time;
        
        float n = fbm(uv);
        density += n * (1.0 - t) * 0.02;
    }

    density *= cloud_density;
    density = clamp(density, 0.0, 1.0);

    float sun_facing = max(dot(ray_dir, sun_dir), 0.0);
    color = mix(vec3(0.7), vec3(1.0), sun_facing) * density;
    color *= 1.0 - cloud_shadow * density;

    return color;
}

void sky() {
    vec3 clouds = get_volumetric_clouds(EYEDIR, LIGHT0_DIRECTION);
    COLOR.rgb += clouds;
}