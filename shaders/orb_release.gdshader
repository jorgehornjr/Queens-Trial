shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform sampler2D glow_texture : source_color, filter_linear_mipmap;
uniform sampler2D flow_texture : filter_linear_mipmap, repeat_enable;
uniform sampler2D filament_texture : filter_linear_mipmap, repeat_enable;
uniform float age = -1.0;
uniform bool wave = false;
uniform float delay = 0.0;
uniform float envelope = 1.0;
void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec2 size = vec2(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz));
	vec3 world = origin+INV_VIEW_MATRIX[0].xyz*VERTEX.x*size.x+INV_VIEW_MATRIX[1].xyz*VERTEX.y*size.y;
	POSITION = PROJECTION_MATRIX*VIEW_MATRIX*vec4(world,1.0);
}
void fragment() {
	float t = age-delay;
	float alpha = 0.0;
	vec3 color = vec3(1.0,0.89,0.65);
	if (wave) {
		vec2 p = UV-0.5;
		float noise = texture(flow_texture,UV*2.3+vec2(t*0.02,-t*0.04)).r;
		float r = length(p)*2.0+(noise-0.5)*0.08;
		float radius = pow(clamp(t/2.8,0.0,1.0),0.7);
		alpha = exp(-pow((r-radius)/0.075,2.0))*pow(noise,1.5)
			*smoothstep(0.0,0.08,t)*(1.0-smoothstep(0.25,1.8,t))*0.12;
		alpha *= 0.3+texture(filament_texture,UV*3.0+vec2(t*0.07,-t*0.05)).r*0.7;
		color = mix(vec3(0.65,0.42,0.18),vec3(1.0,0.92,0.73),noise);
	} else {
		float glow = texture(glow_texture,UV).r;
		alpha = glow*smoothstep(-0.04,0.025,t)*(1.0-smoothstep(0.04,0.75,t))*0.17;
	}
	ALBEDO = color*1.7;
	ALPHA = alpha*envelope*step(0.0,t);
}
