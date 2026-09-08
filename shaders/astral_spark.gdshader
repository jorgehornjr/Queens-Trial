shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	vec2 p = abs(UV * 2.0 - 1.0);
	float star = exp(-length(p) * 6.0) + exp(-p.x * 22.0 - p.y * 3.0) * 0.5;
	ALBEDO = vec3(1.55, 0.92, 0.26);
	EMISSION = ALBEDO;
	ALPHA = star * COLOR.a;
}
