shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
#include "res://shaders/queen_aether_field.gdshaderinc"
uniform sampler2D source_texture : source_color, filter_linear_mipmap;
uniform float effect_time = 0.0;
uniform bool trails = false;
uniform bool remnant = false;
uniform float envelope = 1.0;
uniform float bottom = -20.0;
uniform float height = 50.0;
uniform float dissolve_length = 20.0;
varying float opacity;
varying vec3 tone;
varying vec2 tile;
void vertex() {
	float seed = INSTANCE_CUSTOM.x;
	vec3 origin = (MODEL_MATRIX*vec4(0,0,0,1)).xyz;
	float birth = remnant ? INSTANCE_CUSTOM.y : aether_release(origin,bottom,height)*dissolve_length;
	float age = effect_time-birth;
	float life = max(INSTANCE_CUSTOM.z,0.1);
	float t = clamp(age/life,0.0,1.0);
	opacity = smoothstep(-0.16,0.035,age)*(1.0-smoothstep(0.35,1.0,t))*step(-0.16,age);
	float drift = max(age,0.0);
	if (remnant) {
		opacity = smoothstep(0.0,5.0,effect_time)*(0.8+0.2*sin(effect_time*0.7+seed*80.0));
	} else {
		vec3 drift_axis = vec3(sin(seed*37.0),0.65+seed,cos(seed*61.0));
		origin += drift_axis*drift*(0.20+seed*0.36);
		origin += vec3(sin(drift*0.75+seed*17.0)-sin(seed*17.0),
			drift*drift*0.025,cos(drift*0.60+seed*23.0)-cos(seed*23.0))*0.22;
	}
	vec2 quad = VERTEX.xy*INSTANCE_CUSTOM.w;
	if (trails) { quad*=vec2(0.18,2.0); }
	float angle = seed*6.2831853;
	quad = mat2(vec2(cos(angle),sin(angle)),vec2(-sin(angle),cos(angle)))*quad;
	vec3 world = origin+INV_VIEW_MATRIX[0].xyz*quad.x+INV_VIEW_MATRIX[1].xyz*quad.y;
	POSITION = PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
	tone = mix(vec3(0.10,0.32,0.95),vec3(0.46,0.79,1.0),seed);
	float frame = floor(seed*3.99);
	tile = vec2(mod(frame,2.0),floor(frame/2.0));
}
void fragment() {
	vec4 source = texture(source_texture,(UV+tile)*0.5);
	float mask = max(source.r,max(source.g,source.b))*source.a;
	float radial = 1.0-smoothstep(0.24,0.51,length(UV-0.5));
	ALBEDO = tone*(remnant ? 4.0 : 2.8);
	ALPHA = mask*radial*opacity*envelope*(trails ? 0.22 : 0.85);
}
