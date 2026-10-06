shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform mat4 world_to_board;
uniform float strength : hint_range(0.0,1.0) = 0.0;
varying vec3 world_position;

void vertex() {
	world_position = MODEL_MATRIX[3].xyz;
	// Tiny camera-facing glints retain their particle scale and board position.
	float sx = length(MODEL_MATRIX[0].xyz), sy = length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(INV_VIEW_MATRIX[0].xyz*sx,0.0),
		vec4(INV_VIEW_MATRIX[1].xyz*sy,0.0),INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment() {
	vec3 board_position = (world_to_board * vec4(world_position,1.0)).xyz;
	float margin = 19.0-max(abs(board_position.x),abs(board_position.z));
	if (margin <= 0.0) { discard; }
	vec2 p = UV*2.0-1.0;
	float core = exp(-dot(p,p)*22.0);
	float rays = exp(-abs(p.x)*27.0-abs(p.y)*5.0)+exp(-abs(p.y)*27.0-abs(p.x)*5.0);
	float glint = core+rays*0.45;
	float twinkle = 0.65+0.35*sin(TIME*8.0+world_position.x*1.7+world_position.z*2.3);
	vec3 gold = mix(vec3(1.0,0.47,0.08),vec3(1.0,0.94,0.63),core);
	ALBEDO = gold;
	EMISSION = gold*(1.8+core*2.0);
	ALPHA = glint*COLOR.a*strength*twinkle*smoothstep(0.0,1.2,margin);
}
