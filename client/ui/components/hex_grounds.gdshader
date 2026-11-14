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

void fragment() {
	vec4 color = COLOR;
	if (int(round(ground.w)) == 3) {
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
