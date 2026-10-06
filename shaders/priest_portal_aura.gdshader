shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float age = 0.0;
uniform float strength = 0.0;
uniform sampler2D turbulence : repeat_enable, filter_linear_mipmap;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float a = atan(p.y, p.x);
	float radius = length(p);
	float ripple = 0.014 * sin(a * 9.0 + age * 2.1) + 0.012 * sin(a * 17.0 - age * 1.4);
	float edge = 0.69 + ripple;
	vec2 flow = vec2(a*.58,radius*1.9-age*.045);
	vec3 curls = texture(turbulence,flow).rgb;
	float twisted_edge = edge+(curls.g-.5)*.023;
	float rim = exp(-abs(radius-twisted_edge)*140.0);
	float thread = exp(-abs(radius-edge-.030*sin(a*11.0+age*.7+curls.r*5.0))*125.0);
	float mist = exp(-abs(radius-edge)*19.0)*smoothstep(.26,.82,curls.r);
	float tongues = pow(max(0.0,sin(a*8.0-radius*21.0+curls.g*7.0+age*1.6)),6.0);
	float lace = pow(max(0.0,sin(a*27.0+age*.9+curls.b*3.0)),14.0);
	float alpha = (rim*.55+thread*.24+mist*(.12+tongues*.45+lace*.19))*strength;
	vec3 violet = mix(vec3(.18,.035,.34),vec3(.63,.40,.78),rim);
	ALBEDO = violet;
	EMISSION = violet*(.65+rim*1.35);
	ALPHA = alpha;
}
