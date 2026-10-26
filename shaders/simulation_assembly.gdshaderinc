uniform float simulation_progress : hint_range(0.0,1.0) = 1.0;
uniform float simulation_bottom = -22.0;
uniform float simulation_height = 54.0;

float simulation_hash(vec3 p) {
	p = fract(p*0.1031);
	p += dot(p,p.yzx+33.33);
	return fract((p.x+p.y)*p.z);
}
float simulation_threshold(vec3 p) {
	vec3 cell = floor(p/0.28);
	float level = clamp(((cell.y+0.5)*0.28-simulation_bottom)/simulation_height,0.0,1.0);
	return level*0.88+simulation_hash(cell)*0.10;
}
float simulation_edge(vec3 p) {
	float threshold = simulation_threshold(p);
	return (1.0-smoothstep(0.0,0.042,simulation_progress-threshold))
		*(1.0-smoothstep(0.94,1.0,simulation_progress));
}
vec3 simulation_trace(vec3 p) {
	vec3 local = fract(p/0.28);
	vec3 edge = min(local,1.0-local);
	float grid = 1.0-smoothstep(0.018,0.055,min(edge.x,min(edge.y,edge.z)));
	float front = simulation_edge(p);
	return mix(vec3(0.08,0.65,1.25),vec3(1.1,0.14,0.04),simulation_progress)*front*(0.12+grid*0.75);
}
