shader_type canvas_item;

uniform float strength = 1.0;
uniform vec2 direction = vec2(1.0, 0.4);
uniform float sway_period = 2.8;
uniform float sway_length = 240.0;
uniform float gust_period = 9.0;
uniform float gust_length = 700.0;

// xy: o ponto de apoio, no mapa. z: quanto o topo anda, negativo na planta espelhada,
// porque a textura dela corre ao contrário. w: a altura da planta.
varying flat vec4 plant;
varying float map_y;

void vertex() {
	plant = CUSTOM0;
	map_y = VERTEX.y;
}

void fragment() {
	float along = dot(plant.xy, direction);
	float sway = sin(TAU * (TIME / sway_period - along / sway_length));
	float gust = 0.75 + 0.25 * sin(TAU * (TIME / gust_period - along / gust_length));
	float rise = clamp((plant.y - floor(map_y)) / plant.w, 0.0, 1.0);
	float pixels = round(strength * plant.z * sway * gust * rise * rise);
	// O degrau entre as linhas não pode escolher o mipmap, no mapa inteiro.
	COLOR = textureGrad(TEXTURE, UV - vec2(pixels * TEXTURE_PIXEL_SIZE.x, 0.0), dFdx(UV), dFdy(UV));
}
