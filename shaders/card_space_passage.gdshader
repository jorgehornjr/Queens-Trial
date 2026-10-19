shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float aspect = 1.77778;

float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 p = UV * vec2(aspect, 1.0);

	float clouds = 0.5 + sin(p.x * 3.1 + p.y * 4.2 - progress * 3.6 + sin(p.y * 5.3 - progress * 2.0) * 0.8) * 0.22;
	clouds += cos(p.x * 6.8 - p.y * 3.3 + sin(p.x * 2.8 - progress) * 1.3) * 0.13;
	clouds += sin(p.x * 10.2 + p.y * 7.3 - progress * 2.1) * 0.06;
	float local = progress + (clouds - 0.5) * 0.09 + (UV.y - 0.5) * 0.035;
	float cover = smoothstep(0.04, 0.42, local) * (1.0 - smoothstep(0.58, 0.97, local));
	vec3 colour = mix(vec3(0.009, 0.017, 0.042), vec3(0.075, 0.14, 0.25), pow(clouds, 2.2));

	vec2 stars = p * 82.0 + vec2(0, progress * 34.0);
	vec2 cell = floor(stars), spot = fract(stars) - 0.5;
	float glint = (1.0 - smoothstep(0.015, 0.12, length(spot))) * step(0.978, hash21(cell));
	colour += vec3(0.55, 0.68, 0.85) * glint * sin(progress * 3.14159);
	COLOR = vec4(colour, cover);
}
