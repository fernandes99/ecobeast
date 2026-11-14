# 01. A superfície da água se mexendo

- **Status:** concluída
- **Depende de:** [terrain-height](../terrain-height/), [free-trails/02](../free-trails/02-ground-mask.md)

## Contexto

A água rasa (`wshallow`) e a funda (`wdeep`) são texturas de 512 × 512 presas ao ponto do mapa, desenhadas paradas pelo `_add_surface` do `HexMapView`. Esta fase as faz ondular, pelo shader do terreno, sem arte nova.

## Escopo

- O movimento da superfície da água rasa e da funda, no jogo e no editor.

## Fora do escopo

- As cachoeiras ([02](02-waterfalls.md)) e a espuma da praia.

## Requisitos

- **RF-01:** a textura da água desliza devagar na diagonal da tela, para a direita e para baixo, e cada linha da textura balança de lado, 1 pixel para cada lado, numa onda que sobe pela tela. A funda se mexe mais devagar que a rasa.
- **RF-02:** o movimento anda só em pixels inteiros da textura e muda em passos de tempo, perto de 6 por segundo. Nenhum quadro mostra a textura borrada ou entre dois pixels.
- **RF-03:** os vizinhos de mesmo bioma continuam uma superfície só: o movimento depende do ponto do mapa e do tempo, nunca do hexágono, e não abre costura entre eles.
- **RF-04:** a água em alturas diferentes se mexe igual (a altura não muda o ponto da textura, como hoje).
- **RF-05:** os outros biomas, o chão dos caminhos, a espuma da praia, o contorno, o hexágono transparente do corte de altura e a janela em volta do Domador ficam como estão.
- **RF-06:** depois de horas de jogo, o movimento não dá um salto visível. O `TIME` do Godot volta a zero a cada hora (`rendering/limits/time/time_rollover_secs`); o ciclo do movimento tem de fechar nesse tempo, ou o shader usa um relógio próprio que fecha o ciclo.

Números de partida (constantes do shader, acertadas olhando): passo de 1/6 s; deslize de 21 voltas da textura por hora na rasa (cerca de 3 px/s) e 14 na funda (cerca de 2 px/s), na direção (2, 1); onda de 1 px de amplitude, com 16 px de comprimento, a 0,5 volta por segundo. Velocidades em voltas inteiras por hora fecham o ciclo quando o `TIME` volta a zero (RF-06).

## Critérios de aceite

- [x] Numa ilha, a água rasa e a funda ondulam; a funda, mais devagar.
- [x] Ampliando a tela, o movimento pula de pixel em pixel, sem borrar.
- [x] Um lago grande não mostra a grade dos hexágonos na água, parado ou mexendo.
- [ ] No editor, a água também se mexe, e o corte de altura continua deixando transparente a água acima dele.
- [x] A grama, a pedra, os caminhos e a espuma da praia estão iguais a antes.

## Desenho técnico

- `ui/components/hex_grounds.gdshader`: o código 4 (superfície de água) no `CUSTOM0.w`, com a rasa e a funda separadas por um valor no `CUSTOM0` (por exemplo, `z` com a velocidade ou o bioma). O fragmento calcula o deslocamento em texels inteiros a partir do `UV * textura` e do tempo quantizado e lê a `TEXTURE` de novo nesse ponto (a repetição já está ligada no `HexMapView`). O resto do código não muda.
- `ui/components/hex_map_view.gd`: o `_add_surface` da água manda o `CUSTOM0` com o código 4; os outros biomas continuam sem `CUSTOM0`. O `_add_texture_mesh` já aceita o `custom`.
- Medir o quadro antes e depois numa ilha grande (o vento das plantas já usa o `TIME`, então a tela já se redesenha a cada quadro).

## Verificação

- O aviso do Godot (`--headless -d --path client --quit-after 60`) sem avisos novos.
- Uma cena temporária em `client/zz_tmp_check/` com a ilha de teste, fotos em momentos diferentes e uma ampliada, para conferir que muda e não borra; apagar depois.
- O dono olha no jogo e acerta os números.

## Tarefas

- [x] O código 4 no shader, com o tempo quantizado e o deslocamento em texels inteiros.
- [x] O `CUSTOM0` da água no `_add_surface`.
- [x] Conferir o ciclo com o `TIME` voltando a zero.
- [x] Conferir no mapa de teste e medir o quadro (o editor não foi aberto).

## Resultado

- Conferido numa cena temporária com um mapa de teste (água rasa e funda em várias alturas, grama, borda do mapa), em fotos com 0,35 s de intervalo: a água muda entre as fotos, em pixels inteiros, sem costura entre os hexágonos.
- Quadro numa ilha de 3.000 hexágonos (PC, RTX 5060 Ti): 0,335 ms de GPU com o shader novo, contra 0,325 ms com o de antes. Não foi medido num celular.
- **Não conferido:** o editor aberto (F2) e o corte de altura com a água se mexendo. O editor usa o mesmo `HexMapView` e o mesmo material, então deve funcionar igual; fica para o dono olhar.
