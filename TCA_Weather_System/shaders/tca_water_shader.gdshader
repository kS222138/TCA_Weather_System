shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec4 water_deep : source_color = vec4(0.01,0.04,0.10,1);
uniform vec4 water_shallow : source_color = vec4(0.12,0.45,0.68,1);
uniform float transparency = 0.92;
uniform float smoothness = 0.99;
uniform float metallic = 0.96;

uniform float spd1 = 1.2;
uniform float str1 = 0.28;
uniform float len1 = 14.0;
uniform float stp1 = 0.42;
uniform float spd2 = 1.8;
uniform float str2 = 0.18;
uniform float len2 = 8.5;
uniform float stp2 = 0.28;
uniform float spd3 = 2.6;
uniform float str3 = 0.10;
uniform float len3 = 5.5;
uniform float stp3 = 0.16;
uniform float wind_effect = 0.6;
uniform vec2 wind_dir = vec2(1,0.3);
uniform float norm_scale = 1.4;
uniform float norm_speed = 0.3;
uniform float caustic_int = 0.9;
uniform float caustic_scale = 6.0;
uniform float caustic_spd = 0.45;
uniform float foam_int = 0.7;
uniform float foam_thresh = 0.52;
uniform float foam_spd = 0.35;
uniform float foam_break = 0.6;
uniform sampler2D refl_tex : source_color, filter_linear;
uniform float refl_str = 0.88;
uniform float fresnel_pow = 5.2;
uniform sampler2D sky_tex : source_color, filter_linear;
uniform vec3 sun_dir = vec3(1,0.75,0.5);
uniform float sun_int = 1.2;
uniform float ripple_int = 0.0;
uniform float depth_fall = 4.0;
uniform float shore_foam = 0.9;
uniform float shore_dist = 1.5;
uniform float under_fog = 0.6;
uniform vec3 under_col = vec3(0.05,0.14,0.24);
uniform float under_warp = 0.045;
uniform float godray_int = 0.6;
uniform float godray_decay = 1.6;
uniform float godray_dense = 0.9;
uniform float spectral = 0.35;
uniform vec3 spectral_col = vec3(0.92,0.88,0.75);
uniform float season = 0.0;
uniform vec3 sum_tint = vec3(1,1.05,0.95);
uniform vec3 win_tint = vec3(0.88,0.9,1.08);
uniform vec3 aut_tint = vec3(1.08,0.82,0.68);
uniform vec3 spr_tint = vec3(0.88,1.08,0.92);

varying vec2 v_uv;
varying vec3 v_wpos;
varying vec2 v_wuv;
varying float v_depth;
varying float v_break;
varying vec3 v_normal;

float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}

vec3 gerstner(vec2 pos,float t,float spd,float str,float len,float stp,vec2 wind){
    float k=6.28318/len;vec2 d=normalize(wind);float p=k*dot(pos,d)-spd*t;
    float y=str*sin(p);float x=stp*str*cos(p)*d.x;float z=stp*str*cos(p)*d.y;
    return vec3(x,y,z);
}

vec3 calc_normal(vec2 pos,float t,vec2 wind){
    float e=0.01;
    vec3 p0=gerstner(pos,t,spd1,str1,len1,stp1,vec2(1,0.55)+wind);
    p0+=gerstner(pos,t,spd2,str2,len2,stp2,vec2(0.65,1)+wind*0.75);
    p0+=gerstner(pos,t,spd3,str3,len3,stp3,vec2(1.25,0.35)+wind*0.6);
    vec3 px=gerstner(pos+vec2(e,0),t,spd1,str1,len1,stp1,vec2(1,0.55)+wind);
    px+=gerstner(pos+vec2(e,0),t,spd2,str2,len2,stp2,vec2(0.65,1)+wind*0.75);
    px+=gerstner(pos+vec2(e,0),t,spd3,str3,len3,stp3,vec2(1.25,0.35)+wind*0.6);
    vec3 pz=gerstner(pos+vec2(0,e),t,spd1,str1,len1,stp1,vec2(1,0.55)+wind);
    pz+=gerstner(pos+vec2(0,e),t,spd2,str2,len2,stp2,vec2(0.65,1)+wind*0.75);
    pz+=gerstner(pos+vec2(0,e),t,spd3,str3,len3,stp3,vec2(1.25,0.35)+wind*0.6);
    return normalize(cross((px-p0)/e,(pz-p0)/e));
}

float ripple(vec2 uv,float t,float ints){
    if(ints<=0.01)return 0.0;
    float rip=0.0;vec2 g=floor(uv*70.0);vec2 f=fract(uv*70.0);
    for(int i=-1;i<=1;i++)for(int j=-1;j<=1;j++){
        vec2 n=vec2(float(i),float(j));float r=hash(g+n);float rt=fract(t*3.0+r);
        if(rt<0.38){vec2 d=f-n-0.5;float dist=length(d);float rad=rt*0.4;
        if(dist<rad){rip+=(1.0-smoothstep(0.0,rad,dist))*(1.0-rt*0.72)*ints;}}
    }return clamp(rip*0.65,0.0,0.28);
}

vec3 detail_normal(vec2 uv,float t,vec2 wind){
    vec2 wu=uv*0.6+wind*t*0.12;
    vec2 u1=uv*2.8+vec2(t*norm_speed,t*norm_speed*0.65)+wu;
    vec2 u2=uv*2.0+vec2(-t*norm_speed*0.72,t*norm_speed*0.48)+wu*0.82;
    float nx=sin(u1.x*13.0)*cos(u1.y*11.0)+sin(u2.x*19.0)*cos(u2.y*16.0);
    float ny=sin(u1.y*15.0)*cos(u1.x*12.0)+sin(u2.y*21.0)*cos(u2.x*17.0);
    nx*=0.5;ny*=0.5;float nz=sqrt(1.0-clamp(nx*nx+ny*ny,0.0,1.0));
    return normalize(vec3(nx,ny,nz))*norm_scale;
}

vec3 caustic(vec2 uv,float t){
    vec2 uv1=uv*caustic_scale+vec2(t*caustic_spd,t*caustic_spd*0.48);
    float c=abs(sin(uv1.x*30.0)*cos(uv1.y*28.0))*0.48;
    c+=abs(sin(uv1.x*55.0+1.6)*sin(uv1.y*52.0))*0.28;
    c+=abs(cos((uv1.x*90.0+uv1.y*82.0)*1.25))*0.18;
    c=pow(c,1.6)*caustic_int;
    return vec3(c*1.25,c*0.92,c*0.65);
}

float foam(vec2 uv,float t,float wave_foam,float breakv){
    vec2 uv1=uv*3.8+vec2(t*foam_spd,t*foam_spd*0.28);
    float f=sin(uv1.x*6.5)*cos(uv1.y*6.5);
    f+=sin(uv1.x*13.0+1.3)*cos(uv1.y*12.0)*0.62;
    f=(f+1.2)*0.44;f=clamp(f*1.18-0.18,0.0,1.0);f=pow(f,1.25)*foam_int;
    return clamp(f+wave_foam*0.55+breakv*foam_break,0.0,1.0);
}

float godray(vec3 view,vec3 sun,float depth){
    float align=max(0.0,dot(view,sun));
    return pow(align,godray_dense*9.0)*exp(-depth*godray_decay)*godray_int;
}

vec3 spectral_h(vec3 n,vec3 v,vec3 l,float rough){
    vec3 h=normalize(v+l);float NdotH=max(0.0,dot(n,h));
    float spec=pow(NdotH,1.0/(rough*0.5+0.12));
    float sp=sin(NdotH*55.0)*0.14+sin(NdotH*125.0+1.3)*0.07;
    return spectral_col*max(0.0,sp)*spectral*spec;
}

vec3 season_tint(vec3 col,float s,float depth){
    vec3 tint=sum_tint;
    if(s<0.25)tint=mix(sum_tint,aut_tint,s*4.0);
    else if(s<0.5)tint=mix(aut_tint,win_tint,(s-0.25)*4.0);
    else if(s<0.75)tint=mix(win_tint,spr_tint,(s-0.5)*4.0);
    else tint=mix(spr_tint,sum_tint,(s-0.75)*4.0);
    return col*mix(tint,vec3(1.0),clamp(depth*0.4,0.0,1.0));
}

void vertex(){
    v_uv=UV;
    vec2 pos=VERTEX.xz;
    v_wuv=pos*0.12;
    v_wpos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    float t=TIME;
    vec2 wind=wind_dir*wind_effect;
    
    vec3 w1=gerstner(pos,t,spd1,str1,len1,stp1,vec2(1.0,0.55)+wind);
    vec3 w2=gerstner(pos,t,spd2,str2,len2,stp2,vec2(0.65,1.0)+wind*0.75);
    vec3 w3=gerstner(pos,t,spd3,str3,len3,stp3,vec2(1.25,0.35)+wind*0.6);
    
    VERTEX.x+=w1.x+w2.x+w3.x;
    VERTEX.z+=w1.z+w2.z+w3.z;
    VERTEX.y+=w1.y+w2.y+w3.y;
    
    if(ripple_int>0.01)VERTEX.y+=ripple(VERTEX.xz,t,ripple_int);
    
    v_normal=calc_normal(pos,t,wind);
    v_break=clamp((1.0-v_normal.y-0.42)/0.5,0.0,1.0);
    v_depth=max(0.0,CAMERA_POSITION_WORLD.y-v_wpos.y);
}

void fragment(){
    float t=TIME;
    vec3 view=normalize(VIEW);
    vec3 sun=normalize(sun_dir);
    vec2 wind=wind_dir*wind_effect;
    vec3 detail=detail_normal(v_wuv,t,wind);
    NORMAL=normalize(mix(v_normal,detail,0.68));
    
    float sun_fac=clamp(dot(NORMAL,sun)*1.6,0.18,1.3);
    float depth_fac=clamp(1.0-v_depth*depth_fall,0.08,1.0);
    float wave_foam=smoothstep(foam_thresh-0.12,foam_thresh+0.12,NORMAL.y);
    float f=foam(v_wuv,t,wave_foam,v_break);
    
    vec3 cst=caustic(v_wuv,t);
    vec3 water=mix(water_deep.rgb,water_shallow.rgb,depth_fac);
    float fresnel=clamp(pow(1.0-abs(dot(NORMAL,view)),fresnel_pow),0.18,0.98);
    
    vec2 screen_uv=v_uv;
    vec3 refl=textureLod(refl_tex,screen_uv,0.0).rgb;
    refl=mix(refl,textureLod(sky_tex,screen_uv,0.0).rgb,0.55)*sun_fac;
    
    float gr=godray(view,sun,depth_fac);
    vec3 albedo=water+cst*0.55;
    albedo=mix(albedo,vec3(0.99,0.97,0.94),f*0.85);
    
    vec3 col=mix(albedo,refl,fresnel*refl_str);
    col+=cst*0.32+vec3(0.92,0.88,0.75)*gr*0.55;
    col+=spectral_h(NORMAL,view,sun,1.0-smoothness)*sun_int;
    col=season_tint(col,season,v_depth);
    
    float shore_dist_abs=abs(v_wpos.z);
    if(shore_dist_abs<shore_dist){
        float shore=pow(1.0-shore_dist_abs/shore_dist,1.6)*shore_foam;
        col=mix(col,vec3(0.97,0.95,0.92),shore);
    }
    
    ALBEDO=col;
    METALLIC=metallic;
    ROUGHNESS=1.0-smoothness;
    AO=clamp(0.65+NORMAL.y*0.35,0.45,1.0);
    ALPHA=mix(transparency,1.0,depth_fac);
    
    if(v_depth>0.15&&v_depth<6.0){
        float uf=under_fog*clamp(v_depth*0.45,0.0,1.0);
        ALBEDO=mix(ALBEDO,under_col,uf);
        vec2 flow=wind_dir*t*0.45;
        vec2 distort=v_uv+vec2(sin(v_uv.y*45.0+flow.x)*0.35,cos(v_uv.x*45.0+flow.y)*0.35)*under_warp*uf;
        ALBEDO=mix(ALBEDO,textureLod(sky_tex,distort,0.0).rgb,uf*0.45);
        ALBEDO+=cst*0.55*uf;
        ALBEDO+=vec3(0.72,0.82,0.92)*gr*uf*0.55;
    }
}