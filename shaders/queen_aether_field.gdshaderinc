// Superfície e partículas usam o mesmo campo no espaço global.
float aether_hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
float aether_noise(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(aether_hash(i), aether_hash(i+vec3(1,0,0)), f.x),
		mix(aether_hash(i+vec3(0,1,0)), aether_hash(i+vec3(1,1,0)), f.x), f.y),
		mix(mix(aether_hash(i+vec3(0,0,1)), aether_hash(i+vec3(1,0,1)), f.x),
		mix(aether_hash(i+vec3(0,1,1)), aether_hash(i+vec3(1,1,1)), f.x), f.y), f.z);
}
float aether_release(vec3 p, float bottom, float height) {
	float level = clamp((p.y - bottom) / height, 0.0, 1.0);
	float islands = aether_noise(p * 0.31);
	float grains = aether_noise(p * 9.0);
	float field = (1.0-level)*0.58 + islands*0.29 + grains*0.13;
	return 0.04 + 0.94 * clamp((field-0.12)/0.72, 0.0, 1.0);
}
