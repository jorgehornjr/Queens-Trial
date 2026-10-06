shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/tutorial_ink_reveal.gdshaderinc"
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float blue = smoothstep(0.015, 0.06, ink.b - ink.r) * smoothstep(0.003, 0.025, ink.g - ink.r);
	COLOR = vec4(ink.rgb, ink.a * blue * book_ink_mask(SCREEN_UV)) * vertex_tint;
}
