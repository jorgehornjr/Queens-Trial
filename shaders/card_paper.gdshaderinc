// Ajusta apenas o papel claro e neutro, preservando tinta e pigmentos.
uniform vec3 paper_source = vec3(0.88, 0.85, 0.79);
uniform vec3 paper_target = vec3(0.8941, 0.8667, 0.7922);
uniform bool paper_tone_enabled = false;

vec3 balance_paper(vec3 pigment) {
	float lightness = dot(pigment, vec3(0.2126, 0.7152, 0.0722));
	float chroma = max(max(pigment.r, pigment.g), pigment.b) - min(min(pigment.r, pigment.g), pigment.b);
	float paper = smoothstep(0.44, 0.69, lightness) * (1.0 - smoothstep(0.19, 0.31, chroma));
	vec3 balanced = pigment + paper_target - paper_source;
	return paper_tone_enabled ? mix(pigment, clamp(balanced, vec3(0.0), vec3(1.0)), paper) : pigment;
}
