shader_type canvas_item;
// Using code from

// "Seascape" by Alexander Alekseev aka TDM - 2014
// https://www.shadertoy.com/view/Ms2SD1
// Ported to Godot and customized for FragmentForge by Db0

// Licence: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US
uniform bool is_card = true;
uniform float iTime;
uniform bool AA = false;

const int NUM_STEPS = 8;
const float PI	 	= 3.141592;
const float EPSILON	= 1e-3;

// sea
const int ITER_GEOMETRY = 3;
const int ITER_FRAGMENT = 5;
uniform float SEA_HEIGHT = 0.6;
uniform float SEA_CHOPPY = 4.0;
uniform float SEA_SPEED = 1.5;
const float SEA_FREQ = 0.16;
uniform int WATER_TYPE = 0;
const mat2 octave_m = mat2(vec2(1.6,1.2),vec2(-1.2,1.6));

// math
mat3 fromEuler(vec3 ang) {
	vec2 a1 = vec2(sin(ang.x),cos(ang.x));
    vec2 a2 = vec2(sin(ang.y),cos(ang.y));
    vec2 a3 = vec2(sin(ang.z),cos(ang.z));
    mat3 m;
    m[0] = vec3(a1.y*a3.y+a1.x*a2.x*a3.x,a1.y*a2.x*a3.x+a3.y*a1.x,-a2.y*a3.x);
	m[1] = vec3(-a2.y*a1.x,a1.y*a2.y,a2.x);
	m[2] = vec3(a3.y*a1.x*a2.x+a1.y*a3.x,a1.x*a3.x-a1.y*a3.y*a2.x,a2.y*a3.y);
	return m;
}
float hash( vec2 p ) {
	float h = dot(p,vec2(127.1,311.7));	
    return fract(sin(h)*43758.5453123);
}
float noise( in vec2 p ) {
    vec2 i = floor( p );
    vec2 f = fract( p );	
	vec2 u = f*f*(3.0-2.0*f);
    return -1.0+2.0*mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

// lighting
float diffuse(vec3 n,vec3 l,float p) {
    return pow(dot(n,l) * 0.4 + 0.6,p);
}
float specular(vec3 n,vec3 l,vec3 e,float s) {    
    float nrm = (s + 8.0) / (PI * 8.0);
    return pow(max(dot(reflect(e,n),l),0.0),s) * nrm;
}

// sky
vec3 getSkyColor(vec3 e) {
    e.y = (max(e.y,0.0)*0.8+0.2)*0.8;
    return vec3(pow(1.0-e.y,2.0), 1.0-e.y, 0.6+(1.0-e.y)*0.4) * 1.1;
}

// sea
float sea_octave(vec2 uv, float choppy) {
    uv += noise(uv);        
    vec2 wv = 1.0-abs(sin(uv));
    vec2 swv = abs(cos(uv));    
    wv = mix(wv,swv,wv);
    return pow(1.0-pow(wv.x * wv.y,0.65),choppy);
}

float map(vec3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz; uv.x *= 0.75;
    
    float d, h = 0.0;    
    for(int i = 0; i < ITER_GEOMETRY; i++) {        
		float SEA_TIME = 1.0 + iTime * SEA_SPEED;
    	d = sea_octave((uv+SEA_TIME)*freq,choppy);
    	d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;        
    	uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

float map_detailed(vec3 p) {
    float freq = SEA_FREQ;
    float amp = SEA_HEIGHT;
    float choppy = SEA_CHOPPY;
    vec2 uv = p.xz; uv.x *= 0.75;
    
    float d, h = 0.0;    
    for(int i = 0; i < ITER_FRAGMENT; i++) {       
		float SEA_TIME = 1.0 + iTime * SEA_SPEED;
    	d = sea_octave((uv+SEA_TIME)*freq,choppy);
    	d += sea_octave((uv-SEA_TIME)*freq,choppy);
        h += d * amp;        
    	uv *= octave_m; freq *= 1.9; amp *= 0.22;
        choppy = mix(choppy,1.0,0.2);
    }
    return p.y - h;
}

vec3 getSeaColor(vec3 p, vec3 n, vec3 l, vec3 eye, vec3 dist) {  
    float fresnel = clamp(1.0 - dot(n,-eye), 0.0, 1.0);
    fresnel = pow(fresnel,3.0) * 0.5;
	vec3 SEA_BASE;
	vec3 SEA_WATER_COLOR;
	switch(WATER_TYPE){
		// Some interesting zoom locations discovered via exploration.
		case 0:
			SEA_BASE = vec3(0.0,0.09,0.18);
			SEA_WATER_COLOR = vec3(0.8,0.9,0.6)*0.6;
			break;
		case 1:
			SEA_BASE = vec3(0.05,0.09,0.10);
			SEA_WATER_COLOR = vec3(0.8,3.0,1.0)*0.6;
			break;
		case 2:
			SEA_BASE = vec3(0.0,0.0,0.0);
			SEA_WATER_COLOR = vec3(1.0,1.0,0.0)*0.4;
			break;
		case 3:
			SEA_BASE = vec3(0.18,0.10,0.05);
			SEA_WATER_COLOR = vec3(2.8,0.8,0.8)*0.6;
			break;
	}
    vec3 reflected = getSkyColor(reflect(eye,n));    
    vec3 refracted = SEA_BASE + diffuse(n,l,80.0) * SEA_WATER_COLOR * 0.12; 
    
    vec3 color = mix(refracted,reflected,fresnel);
    
    float atten = max(1.0 - dot(dist,dist) * 0.001, 0.0);
    color += SEA_WATER_COLOR * (p.y - SEA_HEIGHT) * 0.18 * atten;
    
    color += vec3(specular(n,l,eye,60.0));
    
    return color;
}

// tracing
vec3 getNormal(vec3 p, float eps) {
    vec3 n;
    n.y = map_detailed(p);    
    n.x = map_detailed(vec3(p.x+eps,p.y,p.z)) - n.y;
    n.z = map_detailed(vec3(p.x,p.y,p.z+eps)) - n.y;
    n.y = eps;
    return normalize(n);
}

float heightMapTracing(vec3 ori, vec3 dir, out vec3 p) {  
    float tm = 0.0;
    float tx = 1000.0;    
    float hx = map(ori + dir * tx);
    if(hx > 0.0) return tx;   
    float hm = map(ori + dir * tm);    
    float tmid = 0.0;
    for(int i = 0; i < NUM_STEPS; i++) {
        tmid = mix(tm,tx, hm/(hm-hx));                   
        p = ori + dir * tmid;                   
    	float hmid = map(p);
		if(hmid < 0.0) {
        	tx = tmid;
            hx = hmid;
        } else {
            tm = tmid;
            hm = hmid;
        }
    }
    return tmid;
}

vec3 getPixel(in vec2 coord, float time, vec2 iResolution) {
	vec2 uv;
	if (!is_card){
		uv = coord / iResolution.xy;
	    uv = uv * 2.0 - 1.0;
	    uv.x *= iResolution.x / iResolution.y;
	}
	else{
		uv = coord * 2.0 - 1.0;
	}
        
    // ray
    vec3 ang = vec3(sin(time*3.0)*0.1,sin(time)*0.2+0.3,time);    
    vec3 ori = vec3(0.0,3.5,time*5.0);
    vec3 dir = normalize(vec3(uv.xy,-2.0)); dir.z += length(uv) * 0.14;
    dir = normalize(dir) * fromEuler(ang);
    
    // tracing
    vec3 p;
    heightMapTracing(ori,dir,p);
    vec3 dist = p - ori;
	float EPSILON_NRM = 0.1 / iResolution.x;
    vec3 n = getNormal(p, dot(dist,dist) * EPSILON_NRM);
    vec3 light = normalize(vec3(0.0,0.8,0.8)); 
             
    // color
    return mix(
        getSkyColor(dir),
        getSeaColor(p,n,light,dir,dist),
    	pow(smoothstep(0.0,-0.02,dir.y),0.2));
}

// main
void fragment() {
	vec2 iResolution =  1.0 / SCREEN_PIXEL_SIZE;
    float time = iTime * 0.3;
	vec3 color;
	if (AA){
    color = vec3(0.0);
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
			// I haven't figured out how to make AA work with UV yet
        	vec2 uv = FRAGCOORD.xy+vec2(float(i),float(j))/3.0;
			uv += 1.0;
    		color += getPixel(uv, time,iResolution);
        }
    }
    color /= 9.0;
}else {
	vec2 uv = -UV;
	uv += 1.0;
    color = getPixel(uv, time,iResolution);
	if (!is_card){
		color = getPixel(FRAGCOORD.xy, time, iResolution);
	}
	
}
    
    // post
	COLOR = vec4(color, 1.0);
}