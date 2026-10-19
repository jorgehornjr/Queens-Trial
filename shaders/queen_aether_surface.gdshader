shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://shaders/queen_aether_field.gdshaderinc"

uniform sampler2D base_texture : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_texture : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform bool use_normal = false;
uniform bool cutout = false;
uniform float normal_strength = 1.0;
uniform float surface_roughness = 0.7;
uniform float surface_metallic = 0.0;
uniform vec4 metallic_channel = vec4(1,0,0,0);
uniform vec4 roughness_channel = vec4(1,0,0,0);
uniform vec3 source_emission = vec3(0.0);
uniform float dissolve = 0.0;
uniform float bottom = -20.0;
uniform float height = 50.0;
varying vec3 world_position;

void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 uv = UV*uv_scale+uv_offset;
	vec4 original = texture(base_texture,uv)*tint;
	if (cutout && original.a < 0.45) { discard; }
	float release = aether_release(world_position,bottom,height);
	if (dissolve >= release) { discard; }
	float grain = aether_hash(floor(world_position/0.065));
	float edge = (1.0-smoothstep(0.0,0.012,release-dissolve))*step(0.06,dissolve);
	vec3 ether = mix(vec3(0.19,0.55,1.0),vec3(0.72,0.93,1.0),grain);
	ALBEDO = mix(original.rgb,ether*0.45,edge*0.55);
	ROUGHNESS = surface_roughness*dot(texture(roughness_texture,uv),roughness_channel);
	METALLIC = surface_metallic*dot(texture(metallic_texture,uv),metallic_channel);
	if (use_normal) { NORMAL_MAP=texture(normal_texture,uv).rgb; NORMAL_MAP_DEPTH=normal_strength; }
	EMISSION = source_emission*texture(emission_texture,uv).rgb+ether*edge*(0.4+grain*1.1);
}
