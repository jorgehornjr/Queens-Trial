shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float envelope = 0.0;
uniform float effect_time = 0.0;
uniform float red_mix = 0.0;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=world_position.xz/1.9;
	vec2 d=min(fract(p),1.0-fract(p));
	float lines=1.0-smoothstep(0.006,0.026,min(d.x,d.y));
	float travel=exp(-pow((world_position.z+35.0-effect_time*6.0)/3.0,2.0));
	vec3 tone=mix(vec3(0.08,0.65,1.0),vec3(1.0,0.065,0.015),red_mix);
	ALBEDO=tone*2.0;
	ALPHA=(lines*0.09+travel*lines*0.24)*envelope;
}
