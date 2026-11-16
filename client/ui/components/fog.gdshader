shader_type canvas_item;
// A névoa por cima do mapa de Explorar (.specs/fog-of-war/02-fog-layer.md). Cada pixel
// da arte acha o hexágono visível nele, como HexMapView.coord_at, e mistura o
// quanto aparecem os 3 centros de hexágono em volta dele, na altura do dono: a névoa
// clareia do anel meio visível até o descoberto, e um paredão alto segue o hexágono dele.

const int MAX_LEVEL = 10;
const float LEVEL_STEP = 8.0;
const float STEP_X = 64.0;
const float STEP_Y = 42.0;
const float ROW_SHIFT = 32.0;
const float SLOPE = 16.0;
const float SIDE_HEIGHT = 26.0;
const vec2 SURFACE_CENTER = vec2(32.0, 29.0);
// O tamanho e o alcance do ruído da borda, em pixels da arte. A revisar.
const float NOISE_CELL = 7.0;
const float NOISE_REACH = 6.0;
// As faixas de transparência da borda. A revisar.
const float BANDS = 6.0;

// R: quanto o hexágono aparece (1 descoberto, 0,5 no anel em volta, 0 escondido);
// G: altura + 1, ou 0 sem hexágono.
uniform sampler2D hex_data : filter_nearest;
// A mistura a partir da qual a névoa some de vez. A revisar.
const float CLEAR_AT = 0.9;
uniform vec2 data_origin = vec2(0.0);
uniform vec2 data_size = vec2(1.0);
uniform vec2 rect_size = vec2(1.0);
uniform vec2 art_origin = vec2(0.0);
uniform float art_scale = 1.0;
uniform vec3 fog_top : source_color = vec3(0.0);
uniform vec3 fog_bottom : source_color = vec3(0.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 t = smoothstep(0.0, 1.0, fract(p));
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
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
	return texture(hex_data, (cell + 0.5) / data_size).rg;
}

// O ponto erguido pela altura do hexágono visível nele (o chão plano dele).
vec2 owner_flat(vec2 point) {
	for (int level = MAX_LEVEL; level >= 0; level--) {
		vec2 lifted = point + vec2(0.0, float(level) * LEVEL_STEP);
		vec2 hex = hex_at(grid_coord(lifted));
		if (abs(hex.g * 255.0 - float(level + 1)) < 0.5) {
			return lifted;
		}
	}
	// Num paredão, nenhum topo bate: o dono é o hexágono da grade plana, como em
	// coord_at; na borda do mapa, o paredão desce além dela, até SIDE_HEIGHT.
	if (hex_at(grid_coord(point)).g < 0.5) {
		return point - vec2(0.0, SIDE_HEIGHT);
	}
	return point;
}

float open_of(vec2 coord) {
	return hex_at(coord).r;
}

// O quanto aparece cada centro de hexágono, misturado no triângulo dos 3
// centros em volta (os vizinhos na grade axial).
float openness(vec2 ground) {
	float r = (ground.y - SURFACE_CENTER.y) / STEP_Y;
	float q = (ground.x - SURFACE_CENTER.x - ROW_SHIFT * r) / STEP_X;
	vec2 base = floor(vec2(q, r));
	vec2 f = vec2(q, r) - base;
	float a = open_of(base + vec2(1.0, 0.0));
	float b = open_of(base + vec2(0.0, 1.0));
	if (f.x + f.y <= 1.0) {
		return open_of(base) * (1.0 - f.x - f.y) + a * f.x + b * f.y;
	}
	return open_of(base + vec2(1.0)) * (f.x + f.y - 1.0) + a * (1.0 - f.y) + b * (1.0 - f.x);
}

void fragment() {
	// FRAGCOORD é da janela; com o stretch canvas_items, o ponto vem do UV.
	vec2 art_pixel = floor((UV * rect_size - art_origin) / art_scale) + 0.5;
	vec2 wobble = vec2(
		value_noise(art_pixel / NOISE_CELL),
		value_noise(art_pixel / NOISE_CELL + vec2(31.7, 17.3))) - 0.5;
	vec2 point = art_pixel + floor(wobble * 2.0 * NOISE_REACH + 0.5);
	vec2 ground = owner_flat(point);
	float fog = 1.0 - clamp(openness(ground) / CLEAR_AT, 0.0, 1.0);
	fog = ceil(fog * BANDS - 0.001) / BANDS;
	COLOR = vec4(mix(fog_top, fog_bottom, SCREEN_UV.y), fog);
}
