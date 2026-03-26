shader_type sky;
render_mode use_debanding;

uniform vec4 sky_top_color : source_color = vec4(0.02, 0.05, 0.12, 1.0);
uniform vec4 sky_mid_color : source_color = vec4(0.15, 0.25, 0.45, 1.0);
uniform vec4 sky_horizon_color : source_color = vec4(0.55, 0.65, 0.85, 1.0);
uniform float sky_curve : hint_range(0, 3) = 0.35;
uniform float sky_energy = 1.2;

uniform vec4 ground_bottom_color : source_color = vec4(0.02, 0.03, 0.05, 1.0);
uniform vec4 ground_mid_color : source_color = vec4(0.12, 0.18, 0.25, 1.0);
uniform vec4 ground_horizon_color : source_color = vec4(0.35, 0.45, 0.55, 1.0);
uniform float ground_curve : hint_range(0, 2) = 0.25;
uniform float ground_energy = 0.9;

uniform float sun_glow_intensity : hint_range(0, 2) = 1.2;
uniform float sunset_intensity : hint_range(0, 1.5) = 0.9;
uniform float rayleigh_scatter : hint_range(0, 3) = 1.2;
uniform float mie_scatter : hint_range(0, 2) = 0.8;
uniform float mie_g : hint_range(0.5, 0.98) = 0.82;
uniform vec3 sunset_color : source_color = vec3(1.0, 0.35, 0.15);
uniform float sun_disk_size : hint_range(0.5, 4.0) = 2.0;
uniform float sun_glow_size : hint_range(10, 60) = 32.0;

uniform bool stars_enabled = true;
uniform vec4 star_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float star_density = 45.0;
uniform float star_twinkle_speed = 0.4;
uniform float star_size = 0.0025;
uniform float star_uv_scale = 10.0;

uniform bool moon_enabled = true;
uniform vec4 moon_color : source_color = vec4(0.98, 0.96, 0.92, 1.0);
uniform float moon_size : hint_range(0.01, 0.15) = 0.055;
uniform float moon_glow = 0.45;
uniform vec2 moon_direction = vec2(0.75, 0.55);
uniform float moon_max_angle : hint_range(30, 150) = 95.0;

uniform sampler2D cloud_texture;
uniform sampler2D cloud_texture2;
uniform sampler2D cloud_texture3;
uniform float cloud_uv_scale = 1.2;
uniform float cloud_uv_scale2 = 1.5;
uniform float cloud_uv_scale3 = 2.0;
uniform float small_cloud_cover : hint_range(0.0, 1.0) = 0.5;
uniform float large_cloud_cover : hint_range(0.0, 1.0) = 0.4;
uniform float cirrus_cloud_cover : hint_range(0.0, 1.0) = 0.3;
uniform vec3 cloud_inner_colour : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_outer_colour : source_color = vec3(0.65, 0.68, 0.72);
uniform vec2 cloud_direction = vec2(1.0, 0.3);
uniform float cloud_speed = 0.0008;
uniform float cloud_shape_change_speed = 0.0005;
uniform float cloud_lighting : hint_range(0, 1.5) = 0.8;
uniform float cloud_self_shadow = 0.4;

uniform bool cloud_depth_effect = true;
uniform float cloud_depth_intensity : hint_range(0, 1) = 0.45;
uniform float cloud_depth_uv_scale = 0.6;

uniform float rain_intensity = 0.0;
uniform float snow_intensity = 0.0;
uniform float fog_intensity = 0.0;
uniform vec3 season_tint : source_color = vec3(1.0, 1.0, 1.0);
uniform float atmosphere_depth = 1.2;
uniform bool output_reflection = false;

uniform float volumetric_clouds = 0.0;
uniform float aurora_intensity = 0.0;
uniform float rainbow_intensity = 0.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float star_field(vec2 uv, float time) {
    float stars = 0.0;
    vec2 grid = floor(uv * star_density);
    vec2 fract_uv = fract(uv * star_density);
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 neighbor = vec2(float(i), float(j));
            float rand = hash(grid + neighbor);
            float size = star_size * (0.5 + rand * 1.8);
            float twinkle = 0.5 + 0.5 * sin(time * star_twinkle_speed + rand * 100.0);
            
            vec2 diff = fract_uv - neighbor - 0.5;
            float dist = length(diff);
            if (dist < size) {
                stars += (1.0 - smoothstep(0.0, size, dist)) * (0.6 + rand * 0.6) * twinkle;
            }
        }
    }
    return clamp(stars, 0.0, 1.0);
}

float rayleigh_phase(float cos_theta) {
    return (3.0 / (16.0 * 3.14159)) * (1.0 + cos_theta * cos_theta);
}

float mie_phase(float cos_theta, float g) {
    return (1.0 - g * g) / (4.0 * 3.14159 * pow(1.0 + g * g - 2.0 * g * cos_theta, 1.5));
}

vec3 atmospheric_scattering(vec3 ray_dir, vec3 sun_dir, float sun_angle_deg) {
    float cos_theta = dot(ray_dir, sun_dir);
    float rayleigh = rayleigh_phase(cos_theta) * rayleigh_scatter;
    float mie = mie_phase(cos_theta, mie_g) * mie_scatter;
    float sunset_factor = clamp(1.0 - abs(sun_angle_deg) / 35.0, 0.0, 1.0);
    vec3 sun_set_col = sunset_color * sunset_factor * sunset_factor;
    vec3 rayleigh_color = vec3(0.95, 0.82, 0.68);
    vec3 mie_color = vec3(0.98, 0.94, 0.85);
    return (rayleigh * rayleigh_color + mie * mie_color) * (1.0 + sun_set_col * 1.2);
}

vec3 volumetric_cloud(vec3 ray_dir, vec3 sun_dir, float time) {
    if (volumetric_clouds <= 0.01) return vec3(0.0);
    
    float density = 0.0;
    for (int i = 0; i < 16; i++) {
        float t = float(i) / 16.0;
        vec3 pos = ray_dir * t * 50.0;
        vec3 cloud_pos = pos * 0.2 + vec3(time * 0.05, 0.0, time * 0.03);
        float noise = sin(cloud_pos.x * 0.8) * cos(cloud_pos.z * 0.6);
        noise += sin(cloud_pos.x * 2.5) * cos(cloud_pos.z * 2.2) * 0.5;
        noise += sin(cloud_pos.x * 6.0 + cloud_pos.z * 5.0) * 0.25;
        noise = clamp(noise * 0.8 + 0.3, 0.0, 1.0);
        density += noise * (1.0 - t) * 0.0625;
    }
    
    float sun_facing = max(0.0, dot(ray_dir, sun_dir));
    vec3 cloud_color = vec3(0.95, 0.92, 0.88) * (0.6 + 0.5 * sun_facing);
    return cloud_color * density * volumetric_clouds;
}

vec3 aurora(vec3 ray_dir, float time, float lat) {
    if (aurora_intensity <= 0.01) return vec3(0.0);
    if (ray_dir.y < 0.3) return vec3(0.0);
    
    float az = atan(ray_dir.x, ray_dir.z);
    float alt = ray_dir.y;
    float intensity = 0.0;
    
    if (alt > 0.5 && alt < 0.9) {
        float band = sin(az * 8.0 + time) * cos((alt - 0.7) * 30.0);
        intensity = max(0.0, band) * (1.0 - abs(alt - 0.7) * 5.0);
        intensity = pow(intensity, 1.5) * aurora_intensity;
    }
    
    vec3 aurora_color = vec3(0.4, 0.8, 0.9) * intensity;
    aurora_color += vec3(0.2, 0.5, 0.8) * intensity * 0.6;
    return aurora_color;
}

vec3 rainbow(vec3 ray_dir, vec3 sun_dir) {
    if (rainbow_intensity <= 0.01) return vec3(0.0);
    
    float angle = acos(dot(ray_dir, sun_dir));
    float dist_to_rainbow = abs(angle - 0.7);
    if (dist_to_rainbow > 0.08) return vec3(0.0);
    
    float intensity = (1.0 - dist_to_rainbow / 0.08) * rainbow_intensity;
    float hue = (angle - 0.62) / 0.16;
    vec3 rainbow_color = vec3(
        0.5 + 0.5 * sin(hue * 6.28318),
        0.5 + 0.5 * sin(hue * 6.28318 + 2.094),
        0.5 + 0.5 * sin(hue * 6.28318 + 4.188)
    );
    
    return rainbow_color * intensity * 0.5;
}

void sky() {
    float v_angle = acos(clamp(EYEDIR.y, -1.0, 1.0));
    float c = (1.0 - v_angle / (PI * 0.5));
    
    vec3 sky_top = sky_top_color.rgb;
    vec3 sky_mid = sky_mid_color.rgb;
    vec3 sky_horizon = sky_horizon_color.rgb;
    
    float t1 = clamp(1.0 - pow(1.0 - c, 1.0 / sky_curve), 0.0, 1.0);
    float t2 = clamp(c * 2.0, 0.0, 1.0);
    vec3 sky = mix(sky_horizon, sky_mid, t2);
    sky = mix(sky, sky_top, t1);
    sky *= sky_energy;
    
    vec3 sun_dir = vec3(0.0);
    float sun_angle_deg = 0.0;
    float sun_glow = 0.0;
    float sun_disk = 0.0;
    bool has_sun = false;
    
    if (LIGHT0_ENABLED) {
        sun_dir = LIGHT0_DIRECTION;
        sun_angle_deg = degrees(acos(dot(sun_dir, EYEDIR)));
        has_sun = true;
        
        if (sun_angle_deg < sun_glow_size) {
            if (sun_angle_deg < sun_disk_size) {
                sun_disk = pow(1.0 - sun_angle_deg / sun_disk_size, 2.5);
                sky += LIGHT0_COLOR * LIGHT0_ENERGY * sun_disk * 2.0;
            } else {
                sun_glow = pow(1.0 - sun_angle_deg / sun_glow_size, 1.8);
                sky += LIGHT0_COLOR * LIGHT0_ENERGY * sun_glow;
            }
        }
    }
    
    if (has_sun) {
        float scatter_intensity = sun_glow_intensity * clamp(1.0 - sun_angle_deg / 95.0, 0.0, 1.0);
        vec3 scatter = atmospheric_scattering(EYEDIR, sun_dir, sun_angle_deg);
        sky += scatter * scatter_intensity;
        
        if (sun_angle_deg > 0.5 && sun_angle_deg < 18.0) {
            float sunset = 1.0 - abs(sun_angle_deg - 9.0) / 9.0;
            sky += sunset_color * sunset * sunset_intensity * 1.5;
        }
    }
    
    c = (v_angle - (PI * 0.5)) / (PI * 0.5);
    vec3 ground_bottom = ground_bottom_color.rgb;
    vec3 ground_mid = ground_mid_color.rgb;
    vec3 ground_horizon = ground_horizon_color.rgb;
    
    float gt1 = clamp(1.0 - pow(1.0 - c, 1.0 / ground_curve), 0.0, 1.0);
    float gt2 = clamp(c * 1.5, 0.0, 1.0);
    vec3 ground = mix(ground_horizon, ground_mid, gt2);
    ground = mix(ground, ground_bottom, gt1);
    ground *= ground_energy;
    
    vec2 sky_uv = EYEDIR.xz / max(abs(EYEDIR.y), 0.02);
    vec2 cloud_offset = cloud_direction * cloud_speed * TIME;
    
    float clouds1 = texture(cloud_texture, sky_uv * cloud_uv_scale + cloud_offset).r;
    float clouds2 = texture(cloud_texture2, sky_uv * cloud_uv_scale2 + cloud_offset * 0.8 + cloud_shape_change_speed * TIME).r;
    float clouds3 = texture(cloud_texture3, sky_uv * cloud_uv_scale3 + cloud_offset * 0.5 - cloud_shape_change_speed * TIME * 0.6).r;
    
    float clouds = clouds1 * small_cloud_cover + clouds2 * large_cloud_cover + clouds3 * cirrus_cloud_cover;
    clouds = clamp(clouds, 0.0, 0.95);
    
    if (cloud_depth_effect) {
        vec2 cloud_depth_uv = sky_uv * cloud_depth_uv_scale;
        float cloud_depth = texture(cloud_texture, cloud_depth_uv).r;
        clouds = clouds * (0.65 + 0.35 * cloud_depth) * (0.55 + cloud_depth_intensity);
    }
    
    float sun_facing = max(0.0, dot(EYEDIR, sun_dir));
    float cloud_brightness = 0.45 + 0.65 * sun_facing * cloud_lighting;
    float cloud_shadow = 1.0 - clouds * cloud_self_shadow;
    vec3 cloud_color = mix(cloud_outer_colour, cloud_inner_colour, clouds) * cloud_brightness * cloud_shadow;
    vec4 clouds_out_colour = vec4(cloud_color, clouds);
    
    sky.rgb = mix(sky.rgb, clouds_out_colour.rgb, clouds_out_colour.a);
    
    sky += volumetric_cloud(EYEDIR, sun_dir, TIME);
    sky += aurora(EYEDIR, TIME, EYEDIR.y);
    sky += rainbow(EYEDIR, sun_dir);
    
    sky = mix(sky, vec3(0.45, 0.55, 0.65), rain_intensity * 0.45);
    sky = mix(sky, vec3(0.55, 0.62, 0.68), snow_intensity * 0.35);
    sky = mix(sky, vec3(0.6, 0.65, 0.7), fog_intensity * 0.3);
    
    sky *= season_tint;
    ground *= season_tint;
    
    if (stars_enabled) {
        float star_visibility = clamp((sun_angle_deg - 5.0) / 20.0, 0.0, 1.0);
        star_visibility = 1.0 - star_visibility;
        star_visibility = 0.15 + 0.85 * star_visibility;
        
        if (star_visibility > 0.05) {
            vec2 star_uv = vec2(atan(EYEDIR.x, EYEDIR.z), asin(EYEDIR.y)) / PI;
            star_uv.x = fract(star_uv.x * 0.5 + 0.5 + 0.25);
            star_uv.y = star_uv.y * 0.5 + 0.5;
            float stars = star_field(star_uv * star_uv_scale, TIME);
            sky += star_color.rgb * stars * star_visibility;
        }
    }
    
    if (moon_enabled) {
        float moon_visibility = 1.0 - clamp(sun_angle_deg / moon_max_angle, 0.0, 0.85);
        if (moon_visibility > 0.05) {
            vec2 moon_sphere = vec2(atan(EYEDIR.x, EYEDIR.z), asin(EYEDIR.y)) / PI;
            moon_sphere.x = fract(moon_sphere.x * 0.5 + 0.5 + 0.25);
            moon_sphere.y = moon_sphere.y * 0.5 + 0.5;
            vec2 moon_pos = (moon_direction + 1.0) * 0.5;
            float moon_dist = distance(moon_sphere, moon_pos);
            float moon_val = 1.0 - smoothstep(0.0, moon_size, moon_dist);
            float moon_glow_val = moon_glow * (1.0 - smoothstep(moon_size, moon_size * 4.0, moon_dist));
            sky += moon_color.rgb * (moon_val + moon_glow_val) * moon_visibility;
        }
    }
    
    float horizon_blend = clamp(EYEDIR.y * 10.0 + 0.2, 0.0, 1.0);
    COLOR = mix(ground, sky, horizon_blend);
    
    float atmosphere_factor = clamp(1.0 - EYEDIR.y, 0.0, 1.0);
    vec3 atmosphere = vec3(0.55, 0.65, 0.78) * atmosphere_factor * atmosphere_depth;
    COLOR.rgb = mix(COLOR.rgb, atmosphere, atmosphere_factor * 0.4);
    
    if (output_reflection) {
        COLOR.rgb = sky;
    }
}