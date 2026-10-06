shader_type canvas_item;
render_mode unshaded;

// Printed pigment over the page, retaining the approved source bitmap.
uniform vec4 source_paper : source_color = vec4(0.97, 0.93, 0.83, 1.0);
uniform float paint_progress : hint_range(0.0, 1.0) = 1.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

float brush_mask(vec2 uv) {
	if (paint_progress <= 0.0001) return 0.0;
	if (paint_progress >= 0.999) return 1.0;
	float painted = 0.0;
	// Broad, overlapping vertical gestures; each brush bends on its own path.
	// Continuous curves and soft wet edges avoid a visible grid of pixels.
	for (int stroke = 0; stroke < 7; stroke++) {
		float n = float(stroke);
		float upwards = stroke == 2 || stroke == 5 ? 1.0 : 0.0;
		float travel = mix(uv.y, 1.0 - uv.y, upwards);
		float center = (n + 0.5) / 7.0;
		center += sin(uv.y * (4.0 + n * 0.21) + n * 1.73) * 0.055;
		center += (uv.y - 0.5) * (0.12 * sin(n * 1.9 + 0.7));
		float width = 0.135 + 0.018 * sin(n * 2.1);
		float feather = 0.035 + 0.008 * sin(uv.y * 12.0 + n);
		float side = 1.0 - smoothstep(width - feather, width + feather, abs(uv.x - center));
		float tip = (paint_progress - 0.018 - n * 0.088) / 0.35;
		float wet_edge = sin(uv.x * 21.0 + uv.y * 9.0 + n) * 0.025;
		float reach = smoothstep(-0.13, 0.16, tip - travel + wet_edge);
		painted = 1.0 - (1.0 - painted) * (1.0 - side * reach);
	}
	return mix(painted, 1.0, smoothstep(0.88, 1.0, paint_progress));
}

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	vec3 paper = source_paper.rgb;
	vec3 ratio = clamp(ink.rgb / max(paper, vec3(0.001)), vec3(0.0), vec3(1.0));
	float opacity = 1.0 - min(ratio.r, min(ratio.g, ratio.b));
	vec3 pigment = clamp((ink.rgb - paper * (1.0 - opacity)) / max(opacity, 0.001), vec3(0.0), vec3(1.0));
	float paper_fade = smoothstep(0.025, 0.12, opacity);
	COLOR = vec4(pigment, ink.a * opacity * paper_fade * brush_mask(UV)) * vertex_tint;
}
