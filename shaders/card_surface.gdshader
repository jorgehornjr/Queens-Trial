shader_type canvas_item;
#include "res://shaders/card_paper.gdshaderinc"
uniform float false_mark : hint_range(0.0, 1.0) = 0.0;
varying vec4 vertex_color;

void vertex() { vertex_color = COLOR; }

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	art.rgb = balance_paper(art.rgb);
	float diagonal = min(abs(UV.x - UV.y), abs(UV.x + UV.y - 1.0));
	float cross = (1.0 - smoothstep(0.012, 0.027, diagonal)) * false_mark;
	COLOR = vec4(mix(art.rgb, vec3(0.82, 0.025, 0.06), cross * 0.95), art.a) * vertex_color;
}
