shader_type canvas_item;

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 artwork = texture(TEXTURE, UV) * COLOR;
	float lightness = dot(artwork.rgb, vec3(0.299, 0.587, 0.114));
	float chroma = max(max(artwork.r, artwork.g), artwork.b) - min(min(artwork.r, artwork.g), artwork.b);
	float paper_mask = smoothstep(0.48, 0.76, lightness) * (1.0 - smoothstep(0.11, 0.26, chroma));
	float age = grain(floor(UV * vec2(390.0, 550.0))) * 0.055;
	vec3 vellum = vec3(0.72, 0.625, 0.485) + vec3(age, age * 0.78, age * 0.52);
	artwork.rgb = mix(artwork.rgb, vellum, paper_mask * 0.94);
	COLOR = artwork;
}
