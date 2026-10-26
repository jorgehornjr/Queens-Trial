float dust_hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float dust_birth(vec2 uv, vec2 bounds, vec2 dimensions) {
	float across = clamp((uv.x - bounds.x) / max(0.01, bounds.y - bounds.x), 0.0, 1.0);
	float grain = dust_hash(floor(uv * dimensions / 1.7));
	return clamp(across * 0.94 + (grain - 0.5) * 0.10, 0.0, 1.0);
}
