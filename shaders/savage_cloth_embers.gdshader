shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform float effect_time = 0.0;
uniform float lower_height = -14.0;
uniform float upper_height = 4.0;
uniform vec4 fabric_color : source_color = vec4(0.014,0.014,0.02,1.0);
uniform sampler2D fabric_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform bool has_fabric_texture = false;
uniform bool has_normal_texture = false;
uniform float normal_strength = 1.0;
uniform float fabric_roughness = 0.78;
uniform float fabric_metallic = 0.04;
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
varying vec3 world_position;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p),f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
	world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	vec2 fabric_uv = UV*uv_scale+uv_offset;
	vec3 fabric = fabric_color.rgb;
	if (has_fabric_texture) { fabric *= texture(fabric_texture,fabric_uv).rgb; }
	if (has_normal_texture) {
		NORMAL_MAP = texture(normal_texture,fabric_uv).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
	// UV-anchored fissures stay attached when the queen breathes or turns.
	vec2 p = UV*vec2(180.0,220.0);
	vec2 warp = vec2(noise(p*0.24),noise(p*0.24+17.0))*1.8;
	float charred_cavities = noise(p+warp)*0.68+noise(p*2.8+warp)*0.32;
	// Bounded motion within each burn patch, rather than scrolling the whole pattern.
	vec2 stirring = vec2(sin(effect_time*1.35+p.y*0.08),cos(effect_time*1.10+p.x*0.13))*0.48;
	float cavities = noise(p+warp+stirring)*0.68
		+noise(p*2.8+warp+vec2(effect_time*0.80,-effect_time*1.15))*0.32;
	float fuel = smoothstep(0.30,0.62,noise(p*0.08+8.3));
	float edge = smoothstep(lower_height,lower_height+2.5,world_position.y)
		*(1.0-smoothstep(upper_height-2.2,upper_height,world_position.y));
	float threshold = 0.68 + 0.055*sin(effect_time*1.60+noise(p*0.3)*9.0);
	float rim = smoothstep(threshold-0.10,threshold-0.025,cavities)
		*(1.0-smoothstep(threshold+0.01,threshold+0.055,cavities));
	float core = smoothstep(threshold-0.015,threshold+0.09,cavities);
	float flowing_heat = noise(p*0.25+vec2(effect_time*0.75,-effect_time*0.90));
	float pulse = 0.5+0.5*sin(effect_time*3.60+noise(p*0.64)*12.0);
	float temperature = smoothstep(0.20,0.80,flowing_heat*0.78+pulse*0.30);
	float heat = (rim*0.22+core*0.70)*fuel*edge*mix(0.22,1.0,temperature);
	float char = smoothstep(0.50,0.68,charred_cavities)*fuel*edge;
	ALBEDO = mix(fabric,vec3(0.006,0.004,0.004),char*0.82);
	ROUGHNESS = mix(fabric_roughness,0.96,char);
	METALLIC = fabric_metallic*(1.0-char);
	vec3 hot = mix(vec3(1.7,0.015,0.002),vec3(7.0,1.4,0.09),temperature);
	hot = mix(hot,vec3(9.0,2.8,0.35),smoothstep(0.86,1.0,temperature)*core);
	EMISSION = hot*heat;
}
