shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene_color : hint_screen_texture, filter_linear;
uniform float elapsed = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec2 p = (UV - vec2(0.5, 0.49)) * vec2(2.0, 2.1);
	float shape = exp(-dot(p, p) * 2.8);
	float opening = smoothstep(0.05, 0.55, elapsed) * (1.0 - smoothstep(4.4, 5.45, elapsed));
	float burst = exp(-pow((elapsed - 0.65) / 0.3, 2.0));
	float heat = smoothstep(0.1, 0.9, elapsed) * (1.0 - smoothstep(3.8, 5.1, elapsed));
	vec2 warp = vec2(sin(UV.y * 71.0 - elapsed * 18.0), cos(UV.x * 57.0 + elapsed * 13.0));
	warp *= shape * heat * 0.0015;
	vec3 scene = texture(scene_color, SCREEN_UV + warp).rgb;
	scene += vec3(0.09, 0.014, 0.001) * burst * shape;
	float edge = smoothstep(0.0, 0.15, UV.x) * (1.0 - smoothstep(0.85, 1.0, UV.x));
	edge *= smoothstep(0.0, 0.15, UV.y) * (1.0 - smoothstep(0.85, 1.0, UV.y));
	COLOR = vec4(scene, opening * shape * edge * 0.65) * tint;
}
