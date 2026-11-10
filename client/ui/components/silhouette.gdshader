shader_type canvas_item;
// A sombra de um Ecobeast que o jogador só viu (codex/02): todo pixel visível
// ganha a mesma cor, e a transparência da arte fica, para o contorno continuar.

uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	COLOR = vec4(color.rgb, color.a * texture(TEXTURE, UV).a);
}
