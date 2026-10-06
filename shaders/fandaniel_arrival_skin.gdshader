shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color : source_color, hint_default_white, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D emission_map : source_color, hint_default_black, filter_linear_mipmap_anisotropic;
uniform vec4 tint : source_color = vec4(1.0);
uniform float normal_strength = 1.0;
uniform vec3 emission_tint : source_color = vec3(1.0);
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform bool throat_shadow_enabled = false;
varying float throat_shadow;

void vertex() {
    throat_shadow = throat_shadow_enabled ? COLOR.r : 0.0;
}

void fragment() {
    vec4 color = texture(base_color, UV) * tint;
    // Continue the hood's darkness onto the upper collar, retaining its folds.
    // The mesh's bind-pose gradient follows its existing neck/torso weights.
    ALBEDO = mix(color.rgb, vec3(0.0020, 0.0016, 0.0026), throat_shadow);
    NORMAL_MAP = texture(normal_map, UV).rgb;
    NORMAL_MAP_DEPTH = normal_strength;
    ROUGHNESS = mix(0.52, 0.95, throat_shadow);
    SPECULAR = mix(0.16, 0.015, throat_shadow);
    METALLIC = 0.0;
    EMISSION = texture(emission_map, UV).rgb * emission_tint * (1.0 - throat_shadow);
    // Preserve the original cutout exactly when fully revealed. Hash only
    // the arrival opacity, so intermediate texture alpha never perforates cloth.
    ALPHA = step(0.4, color.a) * reveal;
    ALPHA_HASH_SCALE = 1.0;
}
