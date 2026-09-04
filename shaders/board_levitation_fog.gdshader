shader_type fog;

uniform float density : hint_range(0.0, 1.0) = 0.25;
uniform float radiance : hint_range(0.0, 20.0) = 1.4;
uniform float motion_speed = 0.18;
uniform vec3 violet : source_color = vec3(0.48, 0.10, 0.9);
uniform vec3 ice_blue : source_color = vec3(0.10, 0.42, 1.0);

float hash3(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1,0,0)), f.x),
		mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), f.x),
		mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 p) {
	return noise3(p) * 0.57 + noise3(p * 2.03 + 7.3) * 0.28 + noise3(p * 4.13 + 19.1) * 0.15;
}
void fog() {
	// Centro do volume seis unidades abaixo do tabuleiro.
	vec3 p = WORLD_POSITION - OBJECT_POSITION - vec3(0, 6, 0);
	float t = TIME * motion_speed;
	vec3 flow = p * vec3(0.30, 0.40, 0.30) + vec3(t * 0.3, t * 0.4, -t * 0.24);
	float curl = noise3(flow * 0.65 + 8.0);
	float clouds = fbm(flow + vec3(curl * 2.8, curl, -curl * 2.0));
	float edge = max(abs(p.x), abs(p.z));
	float rim = exp(-pow((edge - 24.0 + (clouds - 0.5) * 5.0) / 3.4, 2.0));
	float height = exp(-pow((p.y + 3.4 + (curl - 0.5) * 3.5) / 2.5, 2.0));
	float below_board = 1.0 - smoothstep(-1.6, -0.65, p.y);
	float border = smoothstep(0.0, 0.10, min(min(UVW.x, 1.0-UVW.x), min(UVW.z, 1.0-UVW.z)));
	float wisps = pow(smoothstep(0.44, 0.76, clouds), 1.7);
	float core = smoothstep(0.57, 0.76, clouds);
	DENSITY = density * rim * height * below_board * border * wisps;
	ALBEDO = vec3(0.08, 0.10, 0.24);
	EMISSION = mix(violet, ice_blue, smoothstep(0.40, 0.72, clouds)) * radiance * (0.35 + core * 2.4);
}
