shader_type canvas_item;
render_mode unshaded;
varying vec4 ornament_tint;

void vertex() { ornament_tint = COLOR; }

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float gold = smoothstep(0.045, 0.16, ink.r - ink.b)
		* smoothstep(0.05, 0.15, ink.g - ink.b)
		* smoothstep(0.48, 0.68, ink.g / max(ink.r, 0.001));
	COLOR = vec4(vec3(0.62, 0.44, 0.23), ink.a * gold) * ornament_tint;
}
