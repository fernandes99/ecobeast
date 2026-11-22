shader_type canvas_item;
// A luz da hora por cima do mapa (.specs/day-night/architecture.md#o-filtro-da-luz), os
// vagalumes (.specs/fireflies/01-fireflies.md) e a lava acesa (.specs/volcano/01-volcano-art.md).

const int MAX_LIGHTS = 32;
const int MAX_SWARMS = 32;
const int SWARM_DOTS = 6;
const float BANDS = 4.0;
const float EMISSION = 0.15;
const float SWARM_RADIUS = 16.0;
const float SWARM_STRENGTH = 0.5;
const float SWARM_SPREAD = 16.0;
const float SWARM_WANDER = 4.0;
const vec3 SWARM_LIGHT = vec3(0.847, 1.0, 0.541);
const vec3 FIREFLY = vec3(0.957, 1.0, 0.612);
// A lava não escurece: o pixel na chave de cor dentro de um hexágono de lava, achado
// como no fog.gdshader. As bordas do lago soltam a luz laranja.
const int MAX_LAVA_GLOWS = 48;
const float HOT_MIN_RED = 0.33;
const float HOT_MAX_BLUE = 0.06;
const vec3 LAVA_LIGHT = vec3(1.0, 0.55, 0.2);
const float LAVA_RADIUS = 40.0;
const float LAVA_EMISSION = 0.35;
const int MAX_LEVEL = 10;
const float LEVEL_STEP = 8.0;
const float STEP_X = 64.0;
const float STEP_Y = 42.0;
const float ROW_SHIFT = 32.0;
const float SLOPE = 16.0;

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
uniform int swarm_count = 0;
uniform vec2 swarms[MAX_SWARMS];
// R: 1 na lava; G: altura + 1, ou 0 sem hexágono.
uniform bool lava_on = false;
uniform sampler2D lava_data : filter_nearest;
uniform vec2 data_origin = vec2(0.0);
uniform vec2 data_size = vec2(1.0);
uniform int lava_glow_count = 0;
uniform vec2 lava_glows[MAX_LAVA_GLOWS];

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 grid_coord(vec2 point) {
	float r = floor(point.y / STEP_Y);
	float inside_row = point.y - r * STEP_Y;
	float x = point.x - ROW_SHIFT * r;
	float q = floor(x / STEP_X);
	float inside_cell = x - q * STEP_X;
	if (inside_cell < ROW_SHIFT) {
		if (inside_row < SLOPE - inside_cell / 2.0) {
			return vec2(q, r - 1.0);
		}
	} else if (inside_row < (inside_cell - ROW_SHIFT) / 2.0) {
		return vec2(q + 1.0, r - 1.0);
	}
	return vec2(q, r);
}

vec2 hex_at(vec2 coord) {
	vec2 cell = coord - data_origin;
	if (cell.x < 0.0 || cell.y < 0.0 || cell.x >= data_size.x || cell.y >= data_size.y) {
		return vec2(0.0);
	}
	return texture(lava_data, (cell + 0.5) / data_size).rg;
}

// Se o topo visível no ponto é de um hexágono de lava: o primeiro topo, de cima para baixo.
bool on_lava(vec2 point) {
	for (int level = MAX_LEVEL; level >= 0; level--) {
		vec2 hex = hex_at(grid_coord(point + vec2(0.0, float(level) * LEVEL_STEP)));
		if (abs(hex.g * 255.0 - float(level + 1)) < 0.5) {
			return hex.r > 0.5;
		}
	}
	return false;
}

float stepped(float t) {
	float value = ceil(t * BANDS) / BANDS;
	return value * value;
}

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	vec3 original = color;
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(gray), color, saturation);
	vec3 light = ambient;
	vec3 glow = vec3(0.0);
	float firefly = 0.0;
	bool lava = false;
	if (light_strength > 0.0) {
		// FRAGCOORD é da janela; com o stretch canvas_items, o ponto vem do UV.
		vec2 art_pixel = floor((UV * rect_size - art_origin) / art_scale) + 0.5;
		lava = lava_on && original.r >= HOT_MIN_RED && original.b <= HOT_MAX_BLUE && on_lava(art_pixel);
		for (int i = 0; i < lava_glow_count; i++) {
			float t = 1.0 - distance(art_pixel, lava_glows[i]) / LAVA_RADIUS;
			if (t > 0.0) {
				vec3 lit = LAVA_LIGHT * stepped(t) * light_strength;
				light += lit;
				glow += lit * LAVA_EMISSION;
			}
		}
		for (int i = 0; i < light_count; i++) {
			vec4 source = lights[i];
			float t = 1.0 - distance(art_pixel, source.xy) / source.z;
			if (t > 0.0) {
				vec3 lit = light_colors[i].rgb * stepped(t) * light_strength;
				light += lit;
				glow += lit * EMISSION;
			}
		}
		for (int s = 0; s < swarm_count; s++) {
			vec2 center = swarms[s];
			float t = 1.0 - distance(art_pixel, center) / SWARM_RADIUS;
			if (t <= 0.0) {
				continue;
			}
			vec3 lit = SWARM_LIGHT * stepped(t) * SWARM_STRENGTH * light_strength;
			light += lit;
			glow += lit * EMISSION;
			for (int k = 0; k < SWARM_DOTS; k++) {
				vec2 seed = center + float(k) * vec2(13.7, 7.3);
				vec2 home = (vec2(hash(seed), hash(seed + 1.7)) - 0.5) * SWARM_SPREAD;
				vec2 wander = vec2(
					sin(TIME * (0.6 + hash(seed + 3.1) * 0.6) + hash(seed + 5.3) * 6.283),
					cos(TIME * (0.5 + hash(seed + 7.9) * 0.5) + hash(seed + 9.1) * 6.283)) * SWARM_WANDER;
				vec2 dot_pixel = floor(center + home + wander) + 0.5;
				if (distance(art_pixel, dot_pixel) < 0.5) {
					float blink = 0.5 + 0.5 * sin(TIME * (1.5 + hash(seed + 11.3) * 2.0) + hash(seed + 13.7) * 6.283);
					firefly = max(firefly, smoothstep(0.2, 0.9, blink));
				}
			}
		}
	}
	vec3 result = color * min(light, vec3(1.0)) + glow;
	// A lava sai do tom da hora junto com as luzes, sem pular de cor às 17h e às 7h.
	if (lava) {
		result = mix(result, original, light_strength);
	}
	COLOR = vec4(mix(result, FIREFLY, firefly * light_strength), 1.0);
}
