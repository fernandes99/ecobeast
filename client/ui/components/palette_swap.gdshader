shader_type canvas_item;

// tamer-appearance: cada cor-chave da arte vira a cor do mesmo tom da paleta.
uniform vec4 palette[4];

const vec3 KEYS[4] = vec3[4](
	vec3(230.0 / 255.0),
	vec3(180.0 / 255.0),
	vec3(130.0 / 255.0),
	vec3(80.0 / 255.0)
);
const float TOLERANCE = 0.5 / 255.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	for (int i = 0; i < 4; i++) {
		vec3 gap = abs(color.rgb - KEYS[i]);
		if (max(gap.r, max(gap.g, gap.b)) <= TOLERANCE) {
			color.rgb = palette[i].rgb;
		}
	}
	COLOR = color * COLOR;
}
