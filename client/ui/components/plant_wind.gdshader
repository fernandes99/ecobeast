shader_type canvas_item;

uniform float strength = 1.0;
uniform vec2 direction = vec2(1.0, 0.4);
uniform float sway_period = 2.8;
uniform float sway_length = 240.0;
uniform float gust_period = 9.0;
uniform float gust_length = 700.0;
// A copa das árvores (vegetation-wind/02): o tamanho dos grupos de pixels que andam
// juntos, a velocidade do ruído e quanto ele empurra.
uniform float clump = 5.0;
uniform float flow_speed = 9.0;
uniform float churn = 0.2;
uniform float reach = 0.8;
uniform float vertical = 0.5;

// xy: o ponto de apoio, no mapa. z: quanto o topo anda, negativo na planta espelhada,
// porque a textura dela corre ao contrário. w: a altura da planta.
varying flat vec4 plant;
// A árvore dos pacotes (vegetation-wind/02): x é 1 e y a linha da base da copa na arte.
varying flat vec4 canopy;
varying float map_y;

void vertex() {
	plant = CUSTOM0;
	canopy = CUSTOM1;
	map_y = VERTEX.y;
}

float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 at) {
	vec2 cell = floor(at);
	vec2 part = smoothstep(0.0, 1.0, fract(at));
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, part.x), mix(c, d, part.x), part.y);
}

void fragment() {
	float along = dot(plant.xy, direction);
	float sway = sin(TAU * (TIME / sway_period - along / sway_length));
	float gust = 0.75 + 0.25 * sin(TAU * (TIME / gust_period - along / gust_length));
	if (canopy.x > 0.5) {
		vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
		vec2 p = floor(UV * size);
		float weight = clamp((canopy.y - p.y) / 4.0, 0.0, 1.0);
		vec2 flow = normalize(direction) * vec2(sign(plant.z), 1.0) * TIME * flow_speed;
		vec2 at = (p + vec2(plant.x * sign(plant.z), plant.y) - flow) / clump;
		vec2 push = vec2(noise(at + vec2(0.0, TIME * churn)), noise(at * 1.31 + vec2(17.3, -TIME * churn))) - 0.5;
		vec2 offset = round(push * vec2(1.0, vertical) * 2.0 * reach * weight * (0.6 + 0.4 * gust));
		vec2 uv = (p - offset + 0.5) * TEXTURE_PIXEL_SIZE;
		COLOR = textureGrad(TEXTURE, uv, dFdx(UV), dFdy(UV));
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
			COLOR = vec4(0.0);
		}
	} else {
		float rise = clamp((plant.y - floor(map_y)) / plant.w, 0.0, 1.0);
		float pixels = round(strength * plant.z * sway * gust * rise * rise);
		vec2 uv = UV - vec2(pixels * TEXTURE_PIXEL_SIZE.x, 0.0);
		// O degrau entre as linhas não pode escolher o mipmap, no mapa inteiro.
		COLOR = textureGrad(TEXTURE, uv, dFdx(UV), dFdy(UV));
		// A peça que balança tem folga fora da arte, e a textura do mapa repete.
		if (plant.z != 0.0 && (uv.x < 0.0 || uv.x > 1.0)) {
			COLOR = vec4(0.0);
		}
	}
}
