shader_type spatial;
render_mode unshaded, blend_add, cull_front, depth_draw_never, shadows_disabled, fog_disabled;
uniform sampler3D cloud_noise : filter_linear, repeat_enable;
uniform vec3 half_size = vec3(15.0,14.0,9.0);
uniform float effect_time = 0.0;
uniform float envelope = 0.0;
varying vec3 local_vertex;
varying flat vec3 local_camera;
void vertex() {
	local_vertex = VERTEX;
	local_camera = (inverse(MODEL_MATRIX)*vec4(CAMERA_POSITION_WORLD,1.0)).xyz;
}
vec2 intersect_box(vec3 origin,vec3 direction) {
	vec3 inv = 1.0/(sign(direction+vec3(1e-7))*max(abs(direction),vec3(1e-6)));
	vec3 a = (-half_size-origin)*inv, b = (half_size-origin)*inv;
	vec3 near_hit = min(a,b), far_hit = max(a,b);
	return vec2(max(max(near_hit.x,near_hit.y),near_hit.z),min(min(far_hit.x,far_hit.y),far_hit.z));
}
void fragment() {
	if (envelope<0.001) { discard; }
	vec3 origin = local_camera;
	vec3 direction = normalize(local_vertex-local_camera);
	vec2 hit = intersect_box(origin,direction);
	float start = max(hit.x,0.0), end = hit.y;
	if (end<=start) { discard; }
	float step_size = (end-start)/28.0;
	vec3 result = vec3(0.0);
	float opacity = 0.0;
	for (int i=0;i<28;i++) {
		vec3 p = origin+direction*(start+(float(i)+0.5)*step_size);
		vec3 q = p*vec3(0.043,0.035,0.047)+vec3(0.23,effect_time*0.0008,0.52);
		float warp = textureLod(cloud_noise,q*0.60,0.0).r;
		float cloud = textureLod(cloud_noise,q+vec3(warp*0.17,warp*0.2,0.0),0.0).r;
		float detail = textureLod(cloud_noise,q*2.7+0.37,0.0).r;
		vec3 s = p/half_size;
		float shape = exp(-dot(s*vec3(1.1,0.9,1.6),s*vec3(1.1,0.9,1.6))*2.2);
		float fold = exp(-pow((p.x+sin(p.y*0.17)*4.0+(warp-0.5)*9.0)/5.0,2.0));
		float dust_lane = smoothstep(0.0,1.8,abs(p.x-p.y*0.15+sin(p.y*0.2)));
		vec3 boundary = half_size-abs(p);
		float edge = smoothstep(0.0,3.0,min(min(boundary.x,boundary.y),boundary.z));
		float density = smoothstep(0.40,0.75,cloud)*shape*fold*edge*(0.35+dust_lane*0.65);
		float filament = pow(clamp(1.0-abs(detail-0.52)*3.0,0.0,1.0),8.0);
		float sample_alpha = 1.0-exp(-density*step_size*0.11);
		vec3 color = mix(vec3(0.075,0.17,0.48),vec3(0.24,0.55,0.87),cloud);
		result += (1.0-opacity)*sample_alpha*color*(0.7+filament*1.8);
		opacity += (1.0-opacity)*sample_alpha;
	}
	ALBEDO = result/max(opacity,0.0001);
	ALPHA = opacity*envelope;
}
