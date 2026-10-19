shader_type canvas_item;
render_mode unshaded;
uniform float blur = 2.8;
void fragment() {
	vec2 step_uv = TEXTURE_PIXEL_SIZE * blur;
	vec3 scene = texture(TEXTURE, UV).rgb * 0.227027;
	for (int axis = 0; axis < 2; axis++) {
		vec2 direction = axis == 0 ? vec2(step_uv.x, 0.0) : vec2(0.0, step_uv.y);
		scene += texture(TEXTURE, UV + direction * 1.384615).rgb * 0.158108;
		scene += texture(TEXTURE, UV - direction * 1.384615).rgb * 0.158108;
		scene += texture(TEXTURE, UV + direction * 3.230769).rgb * 0.035135;
		scene += texture(TEXTURE, UV - direction * 3.230769).rgb * 0.035135;
	}
	float vignette = smoothstep(0.12, 0.76, distance(UV, vec2(0.5)));
	COLOR = vec4(mix(scene, vec3(0.012, 0.020, 0.040), 0.42 + vignette * 0.22), 1.0);
}
