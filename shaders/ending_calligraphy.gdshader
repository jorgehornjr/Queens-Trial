shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;
uniform sampler2D ink_mask : filter_linear, repeat_disable;
uniform float write_progress = 0.0;
uniform float letter_start = 0.0;
varying vec4 title_tint;

void vertex() { title_tint = COLOR; }

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float written = texture(ink_mask, UV).r;
	written = max(written, smoothstep(0.94, 0.985, write_progress));
	vec2 point = UV * vec2(1024.0, 640.0);
	float letters = step(200.0, point.y) * step(point.y, 440.0) * smoothstep(551.0, 555.0, point.x);
	written *= mix(1.0, smoothstep(letter_start, letter_start + 0.008, write_progress), letters);
	float dot_area = 1.0 - smoothstep(1.0, 1.08, length((point - vec2(638.0, 151.0)) / vec2(30.0, 38.0)));
	written *= mix(1.0, smoothstep(0.955, 0.985, write_progress), dot_area);
	COLOR = vec4(ink.rgb * written * title_tint.rgb * title_tint.a, ink.a * written * title_tint.a);
}
