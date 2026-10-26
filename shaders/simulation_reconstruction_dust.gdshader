shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
#include "res://shaders/simulation_assembly.gdshaderinc"
uniform sampler2D source_texture : source_color, filter_linear_mipmap;
uniform float effect_time = 0.0;
uniform float envelope = 0.0;
uniform bool trails = false;
varying float opacity;
varying vec3 tone;
varying vec2 tile;
void vertex() {
	float seed=INSTANCE_CUSTOM.x;
	vec3 origin=(MODEL_MATRIX*vec4(0,0,0,1)).xyz;
	float arrival=simulation_threshold(origin);
	float remaining=arrival-simulation_progress;
	float approach=clamp(remaining/0.14,0.0,1.0);
	opacity=smoothstep(-0.045,0.005,remaining)*(1.0-smoothstep(0.07,0.17,remaining));
	vec3 direction=normalize(vec3(sin(seed*37.0),0.6+seed,cos(seed*61.0)));
	origin+=direction*(approach*approach)*4.8;
	origin+=vec3(sin(effect_time*1.7+seed*27.0),0,cos(effect_time*1.3+seed*31.0))*sin(approach*3.14159265)*0.22;
	vec2 quad=VERTEX.xy*INSTANCE_CUSTOM.w*(trails ? vec2(0.20,2.6) : vec2(1.0));
	vec3 world=origin+INV_VIEW_MATRIX[0].xyz*quad.x+INV_VIEW_MATRIX[1].xyz*quad.y;
	POSITION=PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
	tone=mix(vec3(0.11,0.55,1.0),vec3(1.0,0.36,0.16),simulation_progress);
	float frame=floor(seed*3.99);
	tile=vec2(mod(frame,2.0),floor(frame/2.0));
}
void fragment() {
	vec4 source=texture(source_texture,(UV+tile)*0.5);
	float mask=max(source.r,max(source.g,source.b))*source.a;
	float radial=1.0-smoothstep(0.15,0.51,length(UV-0.5));
	ALBEDO=tone*2.1;
	ALPHA=mask*radial*opacity*envelope*(trails ? 0.24 : 0.75);
}
