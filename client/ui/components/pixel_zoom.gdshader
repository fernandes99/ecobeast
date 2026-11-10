shader_type canvas_item;
// A transição de zoom pixelado da luta (battle-intro/01). Lê a tela já desenhada
// por baixo e a mostra em blocos, aproximada de um ponto, com clarão e escuro.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
// O centro do zoom, em UV da tela.
uniform vec2 focus = vec2(0.5);
// 1 sem zoom; acima de 1, aproxima do foco.
uniform float zoom = 1.0;
// O lado de cada bloco, em pixels de verdade. 1 é a tela como ela é.
uniform float block = 1.0;
// De 0 a 1: quanto a tela fica branca e quanto fica preta.
uniform float flash = 0.0;
uniform float darken = 0.0;

void fragment() {
	// Os blocos ficam presos na tela: cada pixel lê a cor do centro do seu bloco.
	vec2 pixel = SCREEN_UV / SCREEN_PIXEL_SIZE;
	vec2 cell = (floor(pixel / block) + 0.5) * block;
	vec2 uv = focus + (cell * SCREEN_PIXEL_SIZE - focus) / zoom;
	vec3 color = texture(screen_tex, clamp(uv, vec2(0.0), vec2(1.0))).rgb;
	color = mix(color, vec3(1.0), flash);
	color = mix(color, vec3(0.0), darken);
	COLOR = vec4(color, 1.0);
}
