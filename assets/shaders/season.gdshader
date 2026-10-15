shader_type canvas_item;

// Remaps only the green parts of the baked terrain and foliage: richer in summer,
// gold and orange in autumn, frosted in winter. Paths, stone and buildings keep their
// colours. The weights blend smoothly across season boundaries (see WorldAtmosphere).
uniform float summer : hint_range(0.0, 1.0) = 0.0;
uniform float autumn : hint_range(0.0, 1.0) = 0.0;
uniform float winter : hint_range(0.0, 1.0) = 0.0;

vec3 rgb2hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

// Stable per-patch noise in texture space, so patches never shimmer when the camera moves.
float patch(vec2 uv, vec2 size) {
	vec2 cell = floor(uv * size / 7.0);
	return fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 base = COLOR;
	vec3 hsv = rgb2hsv(base.rgb);
	float green = smoothstep(0.16, 0.21, hsv.x) * (1.0 - smoothstep(0.40, 0.46, hsv.x));
	green *= smoothstep(0.10, 0.22, hsv.y);
	float s = summer * green;
	float n = patch(UV, vec2(textureSize(TEXTURE, 0)));
	float a = autumn * green * mix(0.6, 1.0, n);
	float w = winter * green * mix(0.88, 1.0, n);
	hsv.y = mix(hsv.y, min(hsv.y * 1.12, 1.0), s);
	hsv.z = mix(hsv.z, hsv.z * 0.95, s);
	float gold = 0.075 + (hsv.x - 0.17) * 0.5 + (n - 0.5) * 0.05;
	hsv.x = mix(hsv.x, gold, a);
	hsv.y = mix(hsv.y, hsv.y * 0.92 + 0.06, a);
	hsv.z = mix(hsv.z, min(hsv.z * 1.14 + 0.08, 1.0), a);
	hsv.x = mix(hsv.x, 0.57, w);
	hsv.y = mix(hsv.y, hsv.y * 0.16, w);
	hsv.z = mix(hsv.z, min(hsv.z * 0.55 + 0.46, 1.0), w);
	vec3 rgb = hsv2rgb(hsv);
	rgb = mix(rgb, vec3(0.86, 0.9, 0.96), winter * 0.16 * (1.0 - green));
	COLOR = vec4(rgb, base.a);
}
