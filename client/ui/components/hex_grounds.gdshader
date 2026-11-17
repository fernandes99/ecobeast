shader_type canvas_item;
// O terreno das linhas do mapa. A malha de chão (free-trails/02) traz no CUSTOM0 o
// ponto no chão plano a partir da origem da página (xy), os lados com degrau sem
// paredão (z, um bit por lado) e o código 3 (w); no CUSTOM1, o centro plano do
// hexágono na página (xy) e a página (zw). A máscara da página é a TEXTURE, com o id
// do chão no vermelho. As outras malhas chegam com o CUSTOM0 zerado e passam direto.
// Tudo é medido em pixels inteiros da arte.

uniform float rim = 2.0;
uniform float rim_shade = 0.74;
uniform float shadow = 0.2;
uniform sampler2DArray ground_textures : filter_nearest, repeat_enable;
uniform float hardness[32];
// A janela em volta do Domador (terrain-height/03): x, y, fim x e fim y, em pixels da arte.
uniform bool reveal_on = false;
uniform vec4 reveal_rect = vec4(0.0);
uniform float reveal_alpha = 0.4;
// O relógio das animações, passado pelo HexMapView: parado, a água para (editor-performance/01).
uniform float map_time = 0.0;

const float PAGE = 2048.0;
const float TEXEL = 2.0;
const float MARGIN = 32.0;
const float TEXTURE_SIZE = 512.0;
const float WARP = 3.0;
const float SEAM_STEP = 5.0;
const vec2 CORNERS[6] = {
	vec2(0.0, -29.0), vec2(32.0, -13.0), vec2(32.0, 13.0),
	vec2(0.0, 29.0), vec2(-32.0, 13.0), vec2(-32.0, -13.0)
};
// A água (water-motion): o código 4 é a superfície, com a funda no z; o 5, a
// cachoeira, com a altura da lateral no x e a borda do mapa no y; o 6, a espuma do
// pé; o 7, a espuma da praia. As velocidades fecham voltas inteiras em 3.600 s, quando o map_time
// volta a zero, para não dar salto.
const float WATER_STEPS = 6.0;
const vec2 SHALLOW_DRIFT = vec2(21.0, 10.0) * 512.0 / 3600.0;
const vec2 DEEP_DRIFT = vec2(14.0, 7.0) * 512.0 / 3600.0;
const float WAVE_LENGTH = 16.0;
const float WAVE_SPEED = 0.5;
const float FALL_STEPS = 8.0;
const float FALL_STEP = 4.0;
const float LIP = 2.0;
const float FALL_FOAM = 4.0;
const float FALL_FADE = 8.0;
const float FOAM_WIDTH = 6.0;
const vec4 FOAM = vec4(0.93, 0.98, 1.0, 1.0);
// A espuma da praia (código 7): mais fraca, e uma onda que corre pela costa a
// apaga e acende pixel a pixel. 0,25 volta por segundo fecha no map_time de 3.600 s.
const float SHORE_ALPHA = 0.55;
const float SHORE_STEPS = 6.0;
const float SHORE_SPEED = 0.25;
const float SHORE_LENGTH = 40.0;
// A leitura da altura (terrain-height/05): o código 8 é a beirada clara do alto; o 9, a
// sombra no pé do paredão, com a distância até o pé no x, esmaecendo em pontilhado.
const vec3 LIP_COLOR = vec3(1.0, 1.0, 0.82);
const float LIP_OUTER = 0.34;
const float LIP_INNER = 0.14;
const float SHADOW_ALPHA = 0.28;
const float SHADOW_SOLID = 2.0;
const float SHADOW_WIDTH = 6.0;
const float BAYER[16] = {
	0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0
};
const vec2 DIRECTIONS[8] = {
	vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0),
	vec2(0.7, 0.7), vec2(-0.7, 0.7), vec2(0.7, -0.7), vec2(-0.7, -0.7)
};

varying vec4 ground;
varying vec4 extra;
varying vec4 shade;
varying vec2 art_point;

void vertex() {
	ground = CUSTOM0;
	extra = CUSTOM1;
	shade = COLOR;
	art_point = VERTEX;
}

float hash(vec2 p) {
	uvec2 q = uvec2(ivec2(floor(p)) + ivec2(1 << 20));
	uint h = (q.x * 1597334677u) ^ (q.y * 3812015801u);
	h = (h ^ (h >> 16u)) * 2246822519u;
	h ^= h >> 13u;
	return float(h & 16777215u) / 16777215.0;
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float top = mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x);
	float bottom = mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x);
	return mix(top, bottom, f.y);
}

int id_at(sampler2D mask, vec2 local) {
	ivec2 texel = ivec2(floor(local / TEXEL)) + ivec2(int(MARGIN));
	return int(round(texelFetch(mask, texel, 0).r * 255.0));
}

bool has_bit(int bits, int bit) {
	return ((bits >> bit) & 1) == 1;
}

// Se o pedaço do mais duro solto neste ponto aparece: pedaços maiores e mais comuns
// perto da divisa (`reach` em pixels), menores e mais raros longe dela.
bool loose(vec2 world, vec2 warp, float reach) {
	float size = reach < SEAM_STEP * 1.5 ? 4.0 : (reach < SEAM_STEP * 2.5 ? 3.0 : 2.0);
	vec2 chunk = floor((world + warp * 0.7) / size);
	return hash(chunk + size * 13.0) < 1.15 - reach / SEAM_STEP * 0.3;
}

vec4 ground_color(vec2 world, int id) {
	return texture(ground_textures, vec3(fract(world / TEXTURE_SIZE), float(id)));
}

vec4 water_texel(sampler2D tex, vec2 texel, vec2 pixel_size) {
	return texture(tex, (texel + 0.5) * pixel_size);
}

void fragment() {
	vec4 color = COLOR;
	int code = int(round(ground.w));
	vec2 texel = floor(UV / TEXTURE_PIXEL_SIZE);
	if (code == 4) {
		float t = floor(map_time * WATER_STEPS) / WATER_STEPS;
		vec2 drift = floor(t * (ground.z > 0.5 ? DEEP_DRIFT : SHALLOW_DRIFT));
		float wave = round(sin(6.2831853 * (texel.y / WAVE_LENGTH + t * WAVE_SPEED)));
		color = water_texel(TEXTURE, texel - drift - vec2(wave, 0.0), TEXTURE_PIXEL_SIZE) * shade;
	} else if (code == 5) {
		float frame = floor(map_time * FALL_STEPS);
		float height = ground.x;
		bool off_map = ground.y > 0.5;
		if (texel.y < LIP) {
			color = mix(water_texel(TEXTURE, texel, TEXTURE_PIXEL_SIZE), FOAM, texel.y < 1.0 ? 0.6 : 0.3);
		} else {
			color = water_texel(TEXTURE, texel - vec2(0.0, frame * FALL_STEP), TEXTURE_PIXEL_SIZE);
		}
		float from_bottom = height - texel.y;
		if (off_map && from_bottom <= FALL_FADE) {
			ivec2 cell = ivec2(mod(texel, 4.0));
			if (BAYER[cell.y * 4 + cell.x] / 16.0 >= (from_bottom - 1.0) / FALL_FADE) {
				discard;
			}
		} else if (!off_map && from_bottom <= FALL_FOAM) {
			float churn = hash(vec2(floor(texel.x / 2.0), texel.y) + floor(frame / 2.0) * 17.0);
			if (churn < 0.35 + 0.5 * (1.0 - from_bottom / FALL_FOAM)) {
				color = FOAM;
			}
		}
		color.rgb *= shade.rgb;
	} else if (code == 6) {
		float frame = floor(map_time * WATER_STEPS);
		float churn = hash(vec2(floor(texel.x / 2.0), floor(texel.y / 2.0)) + frame * 31.0);
		float density = 0.9 - texel.y / FOAM_WIDTH * 0.75;
		if (churn < density) {
			color = FOAM;
		} else if (churn < density + 0.15) {
			color = vec4(FOAM.rgb, 0.5);
		} else {
			discard;
		}
		color *= shade;
	} else if (code == 7) {
		float t = floor(map_time * SHORE_STEPS) / SHORE_STEPS;
		vec2 pixel = floor(art_point);
		float swell = 0.5 + 0.5 * sin(6.2831853 * (t * SHORE_SPEED + (pixel.x + pixel.y * 0.5) / SHORE_LENGTH));
		if (hash(pixel + vec2(57.0, 13.0)) > 0.25 + 0.75 * swell) {
			discard;
		}
		color.a *= SHORE_ALPHA;
	} else if (code == 8) {
		color.rgb = mix(color.rgb, LIP_COLOR * shade.rgb, ground.x < 1.0 ? LIP_OUTER : LIP_INNER);
	} else if (code == 9) {
		vec2 pixel = floor(art_point);
		ivec2 cell = ivec2(mod(pixel, 4.0));
		float fade = (ground.x - SHADOW_SOLID) / (SHADOW_WIDTH - SHADOW_SOLID);
		if (BAYER[cell.y * 4 + cell.x] / 16.0 < fade) {
			discard;
		}
		color = vec4(0.0, 0.0, 0.0, SHADOW_ALPHA);
	} else if (code == 3) {
		vec2 local = floor(ground.xy) + 0.5;
		vec2 world = local + extra.zw * PAGE;
		vec2 warp = vec2(value_noise(world / 7.0), value_noise(world / 7.0 + 31.7)) * WARP * 2.0 - WARP;
		vec2 p = local + floor(warp + 0.5);
		int id = id_at(TEXTURE, p);
		if (id == 0) {
			bool near = false;
			for (int index = 0; index < 4; index++) {
				near = near || id_at(TEXTURE, p + DIRECTIONS[index]) != 0;
			}
			if (!near) {
				discard;
			}
			color = vec4(0.0, 0.0, 0.0, shadow);
		} else {
			// A emenda: o tipo mais duro por perto se solta em pedrinhas sobre este.
			int other = 0;
			float best = 99.0;
			for (int ring = 1; ring <= 3; ring++) {
				float reach = SEAM_STEP * float(ring);
				for (int index = 0; index < 8; index++) {
					int near_id = id_at(TEXTURE, p + DIRECTIONS[index] * reach);
					bool harder = hardness[near_id] > hardness[id] || (hardness[near_id] == hardness[id] && near_id > id);
					if (near_id != 0 && near_id != id && harder && reach < best) {
						other = near_id;
						best = reach;
					}
				}
			}
			int shown = id;
			bool dropped = false;
			if (other != 0) {
				if (loose(world, warp, best)) {
					shown = other;
				} else {
					dropped = loose(world - vec2(0.0, 1.0), warp, best) || loose(world - vec2(1.0, 1.0), warp, best);
				}
			}
			vec4 texel = ground_color(world, shown);
			if (texel.a < 0.5 && shown != id) {
				texel = ground_color(world, id);
			}
			if (texel.a < 0.5) {
				discard;
			}
			bool edge = false;
			for (int index = 0; index < 4; index++) {
				edge = edge || id_at(TEXTURE, p + DIRECTIONS[index] * rim) == 0;
			}
			int steps = int(round(ground.z));
			vec2 in_hex = local - extra.xy;
			for (int side = 0; side < 6; side++) {
				if (has_bit(steps, side)) {
					vec2 a = CORNERS[side];
					vec2 b = CORNERS[(side + 1) % 6];
					edge = edge || dot(in_hex - a, normalize(vec2(a.y - b.y, b.x - a.x))) < rim;
				}
			}
			color = texel;
			if (dropped) {
				color.rgb *= rim_shade;
			}
			if (edge) {
				color.rgb *= rim_shade;
			}
			color.rgb *= shade.rgb;
		}
	}
	vec2 pixel = floor(art_point);
	if (reveal_on && pixel.x >= reveal_rect.x && pixel.y >= reveal_rect.y && pixel.x < reveal_rect.z && pixel.y < reveal_rect.w) {
		color.a *= reveal_alpha;
	}
	COLOR = color;
}
