uniform float reveal_progress : hint_range(0.0, 1.0) = 1.0;

float book_hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float book_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(book_hash(cell), book_hash(cell + vec2(1.0, 0.0)), f.x), mix(book_hash(cell + vec2(0.0, 1.0)), book_hash(cell + vec2(1.0)), f.x), f.y);
}

float book_ink_mask(vec2 uv) {
	if (reveal_progress >= 0.999) return 1.0;
	float islands = 0.57 * book_noise(uv * vec2(19.0, 11.0));
	islands += 0.28 * book_noise(uv * vec2(51.0, 29.0));
	islands += 0.15 * book_hash(floor(uv * vec2(166.0, 96.0)));
	return smoothstep(0.12 + islands * 0.76 - 0.055, 0.12 + islands * 0.76 + 0.055, reveal_progress);
}
