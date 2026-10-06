shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform float age = 0.0;
uniform float intensity = 1.0;
uniform sampler2D turbulence : repeat_enable, filter_linear_mipmap;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float angle = atan(p.y, p.x);
	float waviness = 0.015 * sin(angle * 9.0 + age * 2.1) + 0.014 * sin(angle * 17.0 - age * 1.4);
	float r = length(p) + waviness;
	if (r > 0.88) { discard; }
	// Several moving depths share one small baked turbulence atlas.
	float spiral_angle = angle + (1.0-r) * 3.8 + age * 0.16;
	vec2 spiral = vec2(cos(spiral_angle),sin(spiral_angle))*r;
	vec3 far_smoke = texture(turbulence,spiral*.80+vec2(age*-.021,age*.014)).rgb;
	vec3 near_smoke = texture(turbulence,spiral*1.75+far_smoke.rg*.21+vec2(age*.037,-age*.023)).rgb;
	float edge = smoothstep(0.46,0.87,r);
	float depth = smoothstep(0.10,0.80,r);
	float cloud = smoothstep(.20,.72,far_smoke.r)*near_smoke.g;
	float ribbon = pow(max(0.0,1.0-abs(sin(angle*3.0+r*14.0+far_smoke.r*2.2-age*.4))),4.0);
	float filament = pow(max(0.0,1.0-abs(sin(r*39.0-angle*4.0+near_smoke.r*5.0-age*.8))),13.0);
	filament *= depth * (.2+near_smoke.b);
	float rim = exp(-abs(r-.866)*175.0)*(0.45+near_smoke.g*.75);
	// Small engraved fragments drift around the inner lip of the opening.
	float angular_cell = fract(angle/6.2831853*36.0-age*.045);
	float radial_cell = (r-.73)/.072;
	float stem = 1.0-smoothstep(.015,.070,abs(angular_cell-.5));
	float slash = 1.0-smoothstep(.025,.090,abs(angular_cell-.5-(radial_cell-.5)*.4));
	float glyph = max(stem,slash*.75)*step(0.0,radial_cell)*step(radial_cell,1.0);
	glyph *= smoothstep(.37,.61,far_smoke.b)*.28;
	vec3 void_color = vec3(.003,.002,.009);
	vec3 smoke_color = mix(vec3(.065,.028,.12),vec3(.32,.17,.52),near_smoke.r);
	vec3 silver_violet = vec3(.43,.26,.58);
	vec3 radiance = void_color + intensity * (smoke_color*cloud*(.32+depth*.95)+vec3(.12,.19,.26)*ribbon*cloud*depth+vec3(.38,.22,.58)*filament*depth+silver_violet*(rim*.40+glyph));
	radiance = mix(void_color, radiance*.58, smoothstep(.14,.66,r));
	// Unshaded surfaces display ALBEDO directly; all layers must feed it.
	ALBEDO = radiance;
	EMISSION = radiance;
}
