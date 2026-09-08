shader_type canvas_item;
render_mode unshaded;

uniform float elapsed = -1.0;
uniform vec2 text_bounds = vec2(0.3, 0.7);
uniform vec2 mask_size = vec2(880.0, 210.0);
#include "res://shaders/edict_dust_common.gdshaderinc"

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float born = dust_birth(UV, text_bounds, mask_size);
	float intact = 1.0 - smoothstep(born - 0.035, born + 0.035, elapsed);
	COLOR = vec4(ink.rgb, ink.a * intact);
}
