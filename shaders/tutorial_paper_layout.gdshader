shader_type canvas_item;
render_mode unshaded;

uniform float footer_offset = 87.0;
varying vec4 paper_tint;

void vertex() {
	paper_tint = COLOR;
}

void fragment() {
	vec2 paper_uv = UV;
	// Reposiciona o ornamento impresso sem alterar as bordas ou a outra página.
	float column = smoothstep(0.165, 0.182, UV.x) * (1.0 - smoothstep(0.383, 0.4, UV.x));
	float footer = smoothstep(0.62, 0.82, UV.y) * (1.0 - smoothstep(0.885, 0.925, UV.y));
	paper_uv.y -= footer_offset / 1067.0 * column * footer;
	COLOR = texture(TEXTURE, paper_uv) * paper_tint;
}
