shader_type sky;
render_mode use_debanding;

uniform vec4 sky_top_color : source_color = vec4(0.02,0.05,0.12,1);
uniform vec4 sky_mid_color : source_color = vec4(0.15,0.25,0.45,1);
uniform vec4 sky_horizon_color : source_color = vec4(0.55,0.65,0.85,1);
uniform float sky_curve = 0.3;
uniform float sky_energy = 1.0;

uniform vec4 ground_bottom_color : source_color = vec4(0.02,0.03,0.05,1);
uniform vec4 ground_mid_color : source_color = vec4(0.12,0.18,0.25,1);
uniform vec4 ground_horizon_color : source_color = vec4(0.35,0.45,0.55,1);
uniform float ground_curve = 0.2;
uniform float ground_energy = 0.9;

uniform float sun_glow_intensity = 1.0;
uniform float sunset_intensity = 0.8;
uniform float rayleigh_scatter = 1.0;
uniform float mie_scatter = 0.6;
uniform float mie_g = 0.8;
uniform vec3 sunset_color = vec3(1.0,0.4,0.2);
uniform float sun_disk_size = 1.8;
uniform float sun_glow_size = 28.0;

uniform bool stars_enabled = true;
uniform vec4 star_color = vec4(1,0.95,0.85,1);
uniform float star_density = 40.0;
uniform float star_uv_scale = 8.0;
uniform float star_twinkle_speed = 0.35;

uniform bool moon_enabled = true;
uniform vec4 moon_color = vec4(0.98,0.96,0.92,1);
uniform float moon_size = 0.05;
uniform float moon_glow = 0.4;
uniform float moon_angle = 0.0;
uniform float moon_altitude = 0.6;

uniform sampler2D cloud_texture;
uniform sampler2D cloud_texture2;
uniform float cloud_uv_scale = 1.0;
uniform float cloud_uv_scale2 = 1.3;
uniform float small_cloud_cover = 0.45;
uniform float large_cloud_cover = 0.35;
uniform vec3 cloud_inner_colour = vec3(1,1,1);
uniform vec3 cloud_outer_colour = vec3(0.7,0.72,0.75);
uniform float cloud_speed = 0.0006;
uniform float cloud_lighting = 0.7;

uniform bool volumetric_clouds = true;
uniform float volumetric_clouds_density = 0.3;
uniform float volcloud_min_steps = 8.0;
uniform float volcloud_max_steps = 28.0;

uniform float wind_direction = 0.0;
uniform float wind_strength = 0.4;
uniform float rain_intensity = 0.0;
uniform float fog_intensity = 0.0;
uniform vec3 season_tint = vec3(1,1,1);
uniform float atmosphere_depth = 1.0;
uniform bool output_reflection = false;

uniform float lod_factor = 0.0;
uniform float cloud_lod_factor = 0.5;
uniform float star_lod_factor = 0.3;
uniform float atmosphere_lod_factor = 0.6;

float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}

float star_field(vec2 uv,float time){
    float stars=0.0;
    float density_adj = mix(star_density, star_density * star_lod_factor, lod_factor);
    vec2 grid=floor(uv*density_adj);
    vec2 fract_uv=fract(uv*density_adj);
    for(int i=-1;i<=1;i++)for(int j=-1;j<=1;j++){
        vec2 n=vec2(float(i), float(j));
        float rand=hash(grid+n);
        float size=0.002*(0.5+rand*1.5);
        float twinkle=0.5+0.5*sin(time*star_twinkle_speed+rand*100.0);
        vec2 diff=fract_uv-n-0.5;
        float dist=length(diff);
        if(dist<size){stars+=(1.0-smoothstep(0.0,size,dist))*(0.6+rand*0.6)*twinkle;}
    }
    return clamp(stars,0.0,1.0);
}

float rayleigh_phase(float cos_theta){return(3.0/(16.0*3.14159))*(1.0+cos_theta*cos_theta);}
float mie_phase(float cos_theta,float g){return(1.0-g*g)/(4.0*3.14159*pow(1.0+g*g-2.0*g*cos_theta,1.5));}

vec3 atmospheric_scattering(vec3 ray_dir,vec3 sun_dir,float sun_angle_deg){
    float rayleigh_adj = mix(rayleigh_scatter, rayleigh_scatter * atmosphere_lod_factor, lod_factor);
    float mie_adj = mix(mie_scatter, mie_scatter * atmosphere_lod_factor, lod_factor);
    float cos_theta=dot(ray_dir,sun_dir);
    float rayleigh=rayleigh_phase(cos_theta)*rayleigh_adj;
    float mie=mie_phase(cos_theta,mie_g)*mie_adj;
    float sunset_factor=clamp(1.0-abs(sun_angle_deg)/30.0,0.0,1.0);
    vec3 sun_set_col=sunset_color*sunset_factor*sunset_factor;
    return (rayleigh*vec3(0.95,0.82,0.68)+mie*vec3(0.98,0.94,0.85))*(1.0+sun_set_col);
}

vec3 volumetric_cloud(vec3 ray_dir,vec3 sun_dir,float time){
    if(!volumetric_clouds)return vec3(0.0);
    float density=0.0;
    int steps = int(mix(volcloud_min_steps, volcloud_max_steps, 1.0 - lod_factor));
    for(int i=0;i<int(volcloud_max_steps);i++){
        if(i>=steps)break;
        float t=float(i)/float(steps);
        vec3 pos=ray_dir*t*40.0;
        vec3 cloud_pos=pos*0.15+vec3(time*0.04,0.0,time*0.02);
        float noise=sin(cloud_pos.x*0.7)*cos(cloud_pos.z*0.5);
        noise+=sin(cloud_pos.x*2.0)*cos(cloud_pos.z*1.8)*0.5;
        noise=clamp(noise*0.6+0.3,0.0,1.0);
        density+=noise*(1.0-t)*0.03;
    }
    density*=volumetric_clouds_density;
    float sun_facing=max(0.0,dot(ray_dir,sun_dir));
    vec3 cloud_color=vec3(0.95,0.92,0.88)*(0.6+0.5*sun_facing);
    return cloud_color*density;
}

void sky(){
    float v_angle=acos(clamp(EYEDIR.y,-1.0,1.0));
    float c=(1.0-v_angle/(3.14159*0.5));
    float t1=clamp(1.0-pow(1.0-c,1.0/sky_curve),0.0,1.0);
    float t2=clamp(c*2.0,0.0,1.0);
    vec3 sky=mix(sky_horizon_color.rgb,sky_mid_color.rgb,t2);
    sky=mix(sky,sky_top_color.rgb,t1);
    sky*=sky_energy;
    
    vec3 sun_dir=vec3(0.0);
    float sun_angle_deg=0.0;
    bool has_sun=false;
    if(LIGHT0_ENABLED){
        sun_dir=LIGHT0_DIRECTION;
        sun_angle_deg=degrees(acos(dot(sun_dir,EYEDIR)));
        has_sun=true;
        if(sun_angle_deg<sun_glow_size){
            if(sun_angle_deg<sun_disk_size){
                float disk=pow(1.0-sun_angle_deg/sun_disk_size,2.0);
                sky+=LIGHT0_COLOR*LIGHT0_ENERGY*disk*1.5;
            }else{
                float glow=pow(1.0-sun_angle_deg/sun_glow_size,1.5);
                sky+=LIGHT0_COLOR*LIGHT0_ENERGY*glow;
            }
        }
    }
    if(has_sun){
        float scat_int=sun_glow_intensity*clamp(1.0-sun_angle_deg/90.0,0.0,1.0);
        sky+=atmospheric_scattering(EYEDIR,sun_dir,sun_angle_deg)*scat_int;
        if(sun_angle_deg>0.5&&sun_angle_deg<15.0){
            float sunset=1.0-abs(sun_angle_deg-8.0)/8.0;
            sky+=sunset_color*sunset*sunset_intensity;
        }
    }
    
    c=(v_angle-3.14159*0.5)/(3.14159*0.5);
    float gt1=clamp(1.0-pow(1.0-c,1.0/ground_curve),0.0,1.0);
    float gt2=clamp(c*1.5,0.0,1.0);
    vec3 ground=mix(ground_horizon_color.rgb,ground_mid_color.rgb,gt2);
    ground=mix(ground,ground_bottom_color.rgb,gt1);
    ground*=ground_energy;
    
    vec2 sky_uv=EYEDIR.xz/max(abs(EYEDIR.y),0.02);
    float cloud_uv_scale_adj = mix(cloud_uv_scale, cloud_uv_scale * cloud_lod_factor, lod_factor);
    float cloud_uv_scale2_adj = mix(cloud_uv_scale2, cloud_uv_scale2 * cloud_lod_factor, lod_factor);
    vec2 cloud_offset = vec2(cos(wind_direction), sin(wind_direction)) * cloud_speed * TIME * wind_strength;
    float clouds1=texture(cloud_texture,sky_uv*cloud_uv_scale_adj+cloud_offset).r;
    float clouds2=texture(cloud_texture2,sky_uv*cloud_uv_scale2_adj+cloud_offset*0.7).r;
    float clouds=clouds1*small_cloud_cover+clouds2*large_cloud_cover;
    clouds=clamp(clouds,0.0,0.9);
    
    float sun_facing=max(0.0,dot(EYEDIR,sun_dir));
    float cloud_brightness=0.5+0.6*sun_facing*cloud_lighting;
    vec3 cloud_color=mix(cloud_outer_colour,cloud_inner_colour,clouds)*cloud_brightness;
    sky=mix(sky,cloud_color,clouds);
    
    sky+=volumetric_cloud(EYEDIR,sun_dir,TIME);
    
    sky=mix(sky,vec3(0.5,0.6,0.7),rain_intensity*0.4);
    sky=mix(sky,vec3(0.6,0.65,0.7),fog_intensity*0.3);
    sky*=season_tint;
    ground*=season_tint;
    
    if(stars_enabled){
        float star_vis=clamp((sun_angle_deg-5.0)/20.0,0.0,1.0);
        star_vis=1.0-star_vis;
        star_vis=0.2+0.8*star_vis;
        if(star_vis>0.05){
            vec2 star_uv = vec2(atan(EYEDIR.x, EYEDIR.z), asin(EYEDIR.y)) / (2.0 * 3.14159);
            star_uv.x = fract(star_uv.x + 0.5);
            star_uv.y = star_uv.y + 0.5;
            float stars=star_field(star_uv * star_uv_scale, TIME);
            sky+=star_color.rgb*stars*star_vis;
        }
    }
    
    if(moon_enabled){
        float moon_vis = 1.0 - clamp(sun_angle_deg / 95.0, 0.0, 0.8);
        if(moon_vis > 0.05){
            vec2 moon_sphere = vec2(atan(EYEDIR.x, EYEDIR.z), asin(EYEDIR.y)) / 3.14159;
            moon_sphere.x = moon_sphere.x * 0.5 + 0.5;
            moon_sphere.y = moon_sphere.y * 0.5 + 0.5;
            
            vec2 moon_dir = vec2(cos(moon_angle), sin(moon_angle));
            vec2 moon_pos = moon_dir * (1.0 - moon_altitude);
            moon_pos = moon_pos * 0.5 + 0.5;
            
            float dist = distance(moon_sphere, moon_pos);
            float moon_val = 1.0 - smoothstep(0.0, moon_size, dist);
            float moon_glow_val = moon_glow * (1.0 - smoothstep(moon_size, moon_size * 3.0, dist));
            sky += moon_color.rgb * (moon_val + moon_glow_val) * moon_vis;
        }
    }
    
    float horizon_blend=clamp(EYEDIR.y*8.0+0.2,0.0,1.0);
    COLOR=mix(ground,sky,horizon_blend);
    
    float atmosphere_factor=clamp(1.0-EYEDIR.y,0.0,1.0);
    float atmosphere_adj = mix(atmosphere_depth, atmosphere_depth * atmosphere_lod_factor, lod_factor);
    vec3 atmosphere=vec3(0.55,0.65,0.78)*atmosphere_factor*atmosphere_adj;
    COLOR.rgb=mix(COLOR.rgb,atmosphere,atmosphere_factor*0.35);
    
    if(output_reflection)COLOR.rgb=sky;
}