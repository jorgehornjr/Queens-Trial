shader_type canvas_item;
render_mode unshaded, blend_add;
varying vec4 star_tint;

void vertex() { star_tint = COLOR; }

void fragment() {
	vec4 light = texture(TEXTURE, UV);
	float energy = max(max(light.r, light.g), light.b);
	vec2 point = UV * 2.0 - 1.0;
	float core = exp(-dot(point, point) * 28.0);
	float vertical = exp(-abs(point.x) * 16.0) * pow(max(1.0 - abs(point.y), 0.0), 2.6);
	float horizontal = exp(-abs(point.y) * 18.0) * pow(max(1.0 - abs(point.x) * 1.2, 0.0), 3.0);
	float shine = energy * light.a * 0.26 + core + vertical * 0.75 + horizontal * 0.55;
	COLOR = vec4(vec3(shine), 1.0) * star_tint;
}
