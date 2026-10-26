shader_type canvas_item;
render_mode unshaded;
uniform sampler2D previous_frame : source_color, filter_linear;
uniform sampler2D live_frame : hint_screen_texture, filter_linear;
uniform float progress : hint_range(0.0,1.0) = 0.0;
uniform float effect_time = 0.0;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void fragment() {
	vec2 uv=SCREEN_UV;
	vec2 aspect=vec2(SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x,1.0);
	vec2 cell=floor(uv*vec2(256.0*aspect.x,256.0));
	float seed=hash(cell);

	float row=1.0-uv.y;
	float curvature=sin(uv.x*8.0+0.3)*0.022+noise(uv*vec2(12,9))*0.025;
	float arrival=0.06+row*0.77+curvature;
	float phase=progress-arrival;
	float band=exp(-pow((phase-0.025)/0.075,2.0));
	float grain=(seed-0.5)*0.037;
	float resolved=smoothstep(-0.012,0.055,phase+grain);
	float activity=sin(clamp(progress,0.0,1.0)*3.14159265);
	vec2 drift=vec2(noise(vec2(uv.y*110.0,effect_time*4.0))-0.5,
		noise(uv*60.0+effect_time*1.7)-0.5)*band*activity;
	vec2 refract_uv=clamp(uv+drift*vec2(0.004,0.0012),vec2(0.001),vec2(0.999));
	vec3 old=texture(previous_frame,refract_uv).rgb;
	vec3 next=texture(live_frame,refract_uv-drift*0.0015).rgb;
	vec3 color=mix(old,next,resolved);
	float scatter=step(0.82,seed)*band*activity;
	color*=1.0-scatter*0.16;
	vec3 energy=mix(vec3(0.12,0.62,0.95),vec3(1.0,0.29,0.095),smoothstep(0.0,0.10,phase));
	float leading=exp(-pow((phase+0.006)/0.0055,2.0));
	float fine_scan=0.75+0.25*sin(uv.y/SCREEN_PIXEL_SIZE.y*3.14159265);
	color+=energy*(leading*0.18+band*0.022)*activity*fine_scan;

	vec2 particles=(uv+vec2(effect_time*0.006,-effect_time*0.024))*vec2(370.0*aspect.x,370.0);
	vec2 id=floor(particles),local=fract(particles)-0.5;
	float particle_seed=hash(id);
	float dot_mask=exp(-dot(local*vec2(1.1,0.75),local*vec2(1.1,0.75))*85.0);
	float flecks=dot_mask*step(0.89,particle_seed)*band;
	vec2 large=(uv+vec2(-effect_time*0.011,-effect_time*0.018))*vec2(133.0*aspect.x,133.0);
	vec2 large_id=floor(large),large_local=fract(large)-0.5;
	float streak=exp(-dot(large_local*vec2(4.0,0.85),large_local*vec2(4.0,0.85))*38.0);
	flecks+=streak*step(0.965,hash(large_id))*band*0.65;
	color+=mix(energy,vec3(0.80,0.91,1.0),0.65)*flecks*activity*1.1;
	if (progress<=0.0001) { color=texture(previous_frame,uv).rgb; }
	if (progress>=0.9999) { color=texture(live_frame,uv).rgb; }
	COLOR=vec4(color,1.0);
}
