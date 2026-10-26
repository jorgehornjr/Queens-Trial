shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D orm_map : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 metal_color : source_color = vec4(0.90, 0.94, 1.0, 1.0);
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
varying vec3 model_position;

float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453); }
float noise(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(mix(hash(i), hash(i+vec3(1,0,0)), f.x), mix(hash(i+vec3(0,1,0)), hash(i+vec3(1,1,0)), f.x), f.y),
		mix(mix(hash(i+vec3(0,0,1)), hash(i+vec3(1,0,1)), f.x), mix(hash(i+vec3(0,1,1)), hash(i+vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() { model_position = VERTEX; }
void fragment() {
	float field = noise(model_position * 0.30) * 0.76 + UV.y * 0.24;
	if (reveal < 0.999 && (reveal <= 0.001 || field > reveal)) { discard; }
	float grain = dot(texture(base_color, UV).rgb, vec3(0.2126, 0.7152, 0.0722));
	ALBEDO = metal_color.rgb * tint.rgb * mix(0.86, 1.0, smoothstep(0.02, 0.55, grain));
	vec3 orm = texture(orm_map, UV).rgb;
	METALLIC = 0.94;
	ROUGHNESS = mix(0.17, 0.27, orm.g);
	AO = mix(1.0, orm.r, 0.65);
	NORMAL_MAP = texture(normal_map, UV).rgb;
	NORMAL_MAP_DEPTH = 0.4;
	float edge = reveal < 0.999 ? 1.0 - smoothstep(0.0, 0.065, reveal - field) : 0.0;
	float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 4.0);
	EMISSION = ALBEDO * (0.06 + rim * 0.24) + vec3(0.40, 0.66, 1.0) * edge * 3.2;
}
