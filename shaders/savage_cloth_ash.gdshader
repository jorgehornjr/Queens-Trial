shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
varying float age;

void vertex() {
	age = INSTANCE_CUSTOM.y;
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	float angle = INSTANCE_CUSTOM.z;
	VERTEX.xy = mat2(vec2(cos(angle),sin(angle)),vec2(-sin(angle),cos(angle)))*VERTEX.xy;
	VERTEX *= scale;
	MODELVIEW_MATRIX = VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = (UV-0.5)*2.0;
	float chipped = length(p*vec2(1.0,0.85))+0.11*sin(p.x*15.0+p.y*8.0);
	float flake = 1.0-smoothstep(0.30,0.75,chipped);
	float halo = exp(-dot(p,p)*5.0)*0.22;
	float life = smoothstep(0.0,0.08,age)*(1.0-smoothstep(0.28,1.0,age));
	ALBEDO = mix(vec3(3.7,0.90,0.12),vec3(1.3,0.035,0.003),smoothstep(0.1,0.85,age));
	ALPHA = (flake+halo)*life;
}
