shader_type canvas_item;
render_mode unshaded;
uniform float opening = 0.0;

void fragment() {
	vec2 p = SCREEN_UV * 2.0 - 1.0;
	float vignette = smoothstep(0.5, 1.65, length(p * vec2(0.8, 1.0))) * 0.38;
	COLOR = vec4(0.006, 0.009, 0.025, max(1.0 - opening, vignette));
}
