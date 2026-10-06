shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform float strength : hint_range(0.0,1.0) = 0.0;
uniform float flow_direction = 1.0;
uniform float effect_time = 0.0;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 flow = vec2(UV.x-flow_direction*effect_time*0.46,UV.y);
	vec2 grid = flow*vec2(73.0,85.0);
	vec2 id = floor(grid);
	float seed = hash(id);
	vec2 p = fract(grid)-vec2(0.18+hash(id+5.3)*0.64,0.18+hash(id+12.4)*0.64);
	// Short strands move along the platform, with separate glitter flashes.
	float strand = exp(-p.x*p.x*13.0-p.y*p.y*210.0)*smoothstep(0.36,0.81,seed);
	float flash = pow(max(0.0,sin(effect_time*9.0+seed*57.0)),9.0);
	float glint = exp(-dot(p,p)*130.0)*flash;
	float weave = noise(flow*vec2(8.0,12.0));
	float wisp = pow(max(0.0,sin(UV.y*155.0+weave*9.0)),15.0)*weave;
	vec2 boundary = min(UV,1.0-UV);
	float edge_fade = smoothstep(0.0,0.045,min(boundary.x,boundary.y));
	vec3 gold = mix(vec3(1.0,0.43,0.045),vec3(1.0,0.91,0.49),flash);
	ALBEDO = gold;
	EMISSION = gold*1.7;
	ALPHA = strength*edge_fade*(strand*0.26+glint*0.35+wisp*0.055);
}
