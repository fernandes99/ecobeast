shader_type canvas_item;
// O terreno das linhas do mapa. As malhas de chão (island-villages/02) trazem no
// CUSTOM0 o ponto no hexágono (xy, a partir do centro), os lados ligados (z, um bit
// por lado, e mais 6 bits para os ligados a uma trilha, no piso) e o tipo (w: 1 trilha, 2 piso); nas outras, sem CUSTOM0, ele chega zerado e
// elas passam direto.
// A forma é medida no centro de cada pixel da arte, para a borda sair em pixels inteiros.

uniform float half_width = 11.0;
uniform float rim = 2.0;
uniform float rim_shade = 0.74;
uniform float shadow = 0.2;
uniform float fillet = 9.0;
// A janela em volta do Domador (terrain-height/03): x, y, fim x e fim y, em pixels da arte.
uniform bool reveal_on = false;
uniform vec4 reveal_rect = vec4(0.0);
uniform float reveal_alpha = 0.4;

const vec2 CORNERS[6] = {
	vec2(0.0, -29.0), vec2(32.0, -13.0), vec2(32.0, 13.0),
	vec2(0.0, 29.0), vec2(-32.0, 13.0), vec2(-32.0, -13.0)
};

varying vec4 ground;
// Quanto a ponta do braço dos lados 1 a 4 desce, para encontrar a do vizinho numa
// altura diferente sem paredão (HexGrounds.arm_shift).
varying vec4 shifts;
varying vec2 art_point;

void vertex() {
	ground = CUSTOM0;
	shifts = CUSTOM1;
	art_point = VERTEX;
}

bool has_link(int links, int edge) {
	return ((links >> (edge % 6)) & 1) == 1;
}

vec2 edge_middle(int edge) {
	return (CORNERS[edge] + CORNERS[(edge + 1) % 6]) * 0.5;
}

vec2 arm_end(int edge) {
	float down = edge == 1 ? shifts.x : (edge == 2 ? shifts.y : (edge == 3 ? shifts.z : (edge == 4 ? shifts.w : 0.0)));
	return edge_middle(edge) + vec2(0.0, down);
}

float segment(vec2 p, vec2 b) {
	float t = clamp(dot(p, b) / dot(b, b), 0.0, 1.0);
	return length(p - b * t);
}

float smooth_min(float a, float b, float k) {
	float h = max(k - abs(a - b), 0.0) / k;
	return min(a, b) - h * h * k * 0.25;
}

// Dentro do ângulo entre dois braços vizinhos: o canto entre eles fica cheio.
float wedge(vec2 p, vec2 a, vec2 b) {
	float side_a = a.x * p.y - a.y * p.x;
	float side_b = p.x * b.y - p.y * b.x;
	return (side_a >= 0.0 && side_b >= 0.0) ? -1e5 : 1e5;
}

// O braço passa do meio do lado, para a ponta redonda não marcar a divisa.
float trail(vec2 p, int links) {
	float d = 1e5;
	for (int edge = 0; edge < 6; edge++) {
		if (has_link(links, edge)) {
			d = smooth_min(d, segment(p, arm_end(edge) * 1.5) - half_width, fillet);
		}
	}
	if (links == 0) {
		d = length(p) - half_width;
	}
	for (int edge = 0; edge < 6; edge++) {
		if (has_link(links, edge) && has_link(links, edge + 1)) {
			d = min(d, wedge(p, arm_end(edge), arm_end((edge + 1) % 6)));
		}
	}
	return d;
}

// Num lado ligado a uma trilha (bit em `narrow`), a borda só abre na largura dela.
float floor_shape(vec2 p, int links, int narrow) {
	float d = -1e5;
	for (int edge = 0; edge < 6; edge++) {
		vec2 a = CORNERS[edge];
		vec2 b = CORNERS[(edge + 1) % 6];
		bool open = has_link(links, edge);
		if (has_link(narrow, edge)) {
			open = abs(dot(p - arm_end(edge), normalize(b - a))) <= half_width;
		}
		if (!open) {
			d = max(d, dot(p - a, normalize(vec2(b.y - a.y, a.x - b.x))));
		}
	}
	return min(d, 0.0);
}

void fragment() {
	vec4 color = COLOR;
	int kind = int(round(ground.w));
	if (kind == 0) {
		COLOR = color;
	} else {
		vec2 p = floor(ground.xy) + 0.5;
		int code = int(round(ground.z));
		int links = code & 63;
		float d = kind == 1 ? trail(p, links) : floor_shape(p, links, code >> 6);
		if (d > 1.0) {
			discard;
		} else if (d > 0.0) {
			COLOR = vec4(0.0, 0.0, 0.0, shadow);
		} else if (d > -rim) {
			COLOR = vec4(color.rgb * rim_shade, color.a);
		} else {
			COLOR = color;
		}
	}
	vec2 pixel = floor(art_point);
	if (reveal_on && pixel.x >= reveal_rect.x && pixel.y >= reveal_rect.y && pixel.x < reveal_rect.z && pixel.y < reveal_rect.w) {
		COLOR.a *= reveal_alpha;
	}
}
