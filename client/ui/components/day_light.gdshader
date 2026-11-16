shader_type canvas_item;
// A luz da hora por cima do mapa (.specs/day-night/architecture.md#o-filtro-da-luz).

const int MAX_LIGHTS = 32;
const float BANDS = 4.0;
const float EMISSION = 0.15;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec3 ambient = vec3(1.0);
uniform float saturation = 1.0;
uniform float light_strength = 0.0;
uniform vec2 rect_size = vec2(1.0);
uniform vec2 art_origin = vec2(0.0);
uniform float art_scale = 1.0;
uniform int light_count = 0;
// x, y e raio em pixels da arte.
uniform vec4 lights[MAX_LIGHTS];
uniform vec4 light_colors[MAX_LIGHTS];

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, saturation);
	vec3 light = ambient;
	vec3 glow = vec3(0.0);
	if (light_strength > 0.0 && light_count > 0) {
		// FRAGCOORD é da janela; com o stretch canvas_items, o ponto vem do UV.
		vec2 art_pixel = floor((UV * rect_size - art_origin) / art_scale) + 0.5;
		for (int i = 0; i < light_count; i++) {
			vec4 source = lights[i];
			float t = 1.0 - distance(art_pixel, source.xy) / source.z;
			if (t > 0.0) {
				float step_value = ceil(t * BANDS) / BANDS;
				vec3 lit = light_colors[i].rgb * step_value * step_value * light_strength;
				light += lit;
				glow += lit * EMISSION;
			}
		}
	}
	COLOR = vec4(color * min(light, vec3(1.0)) + glow, 1.0);
}
