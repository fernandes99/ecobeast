# 02. As cachoeiras

- **Status:** concluída
- **Depende de:** [01-water-surface](01-water-surface.md)

## Contexto

Com a [01](01-water-surface.md), a superfície da água se mexe. A lateral de um hexágono de água alto ainda é o barranco de terra (`side.png`). Esta fase troca essa lateral por uma cachoeira que desce, com espuma onde ela bate.

## Escopo

- A textura da cachoeira e a da espuma do pé.
- A lateral da água como cachoeira, com o movimento para baixo.
- A espuma no pé, sobre água e sobre terra.
- A queda para fora do mapa.

## Fora do escopo

- A espuma da praia (fica como está) e a lateral de quem não é água.
- Água no alto correndo para a beira.

## Requisitos

- **RF-01:** toda lateral de um hexágono de água rasa ou funda é cachoeira, em vez de terra. Isso vale para as duas bordas da frente, quando a água é mais alta que o vizinho (de qualquer bioma) e na borda do mapa. Onde hoje não há lateral (vizinho da mesma altura ou mais alto), continua não havendo.
- **RF-02:** a cachoeira tem a altura exata da lateral de hoje, de 8 a 80 px entre hexágonos e a altura do hexágono mais 26 px na borda do mapa. A textura se repete na vertical sem costura, então qualquer altura fica certa.
- **RF-03:** a água da cachoeira desce sem parar, em pixels inteiros e em passos de tempo, mais rápido que a superfície. As duas bordas da frente mantêm a diferença de sombra de hoje (a da direita mais escura, `FACE_COLORS`).
- **RF-04:** no alto da queda, uma linha de 2 a 3 px mais clara e parada mostra a água dobrando a beira.
- **RF-05:** no pé da queda entre hexágonos, a espuma aparece em dois lugares, e se mexe:
  - nos últimos pixels da própria queda;
  - numa faixa sobre a superfície do vizinho de baixo, ao longo da borda onde a água cai, tanto na água como na terra.
- **RF-06:** na borda do mapa não há espuma: os últimos pixels da queda somem num pontilhado até o transparente.
- **RF-07:** a espuma do pé fica por cima da superfície e do chão do vizinho de baixo, e por baixo das decorações e dos atores. Quando o vizinho é mais alto que a borda, não há queda nem espuma.
- **RF-08:** o corte de altura do editor e a janela em volta do Domador tratam a cachoeira como o resto do terreno do hexágono de água, e a espuma sobre o vizinho como o terreno do vizinho (escolha do planejamento: ela é montada na linha dele, então uma cachoeira acima do corte, transparente, pode ter a espuma inteira embaixo).

Números de partida (acertados olhando): queda de 32 px/s, 4 px a cada 1/8 s (fecha 1.800 voltas da textura de 64 px por hora); espuma do pé com 6 px de largura sobre o vizinho e 4 px na queda; pontilhado de 8 px na borda do mapa.

## Critérios de aceite

- [x] Água alta ao lado de água mais baixa: cachoeira descendo, com a linha clara no alto e espuma no pé.
- [x] Água alta ao lado de grama mais baixa: cachoeira, com espuma sobre a grama.
- [x] Água na borda do mapa: cachoeira caindo e sumindo no pontilhado, sem espuma.
- [x] Quedas de 2, 7 e 10 níveis e as de 26 e 50 px da borda do mapa ficam sem costura na textura (a de 1 nível não foi montada).
- [x] Nenhum barranco de terra sob a água em lugar nenhum; a grama, a pedra e a espuma da praia como antes.
- [ ] O Domador e as decorações passam por cima da espuma do pé (as decorações, conferidas; o Domador, não).

## Desenho técnico

- **A arte:** `assets/terrain/surfaces/waterfall.png` (512 px de largura e altura que se repete sem costura, as cores da `wshallow` com riscos claros verticais) e a espuma do pé (uma faixa que se repete na horizontal, ou desenhada pelo shader com ruído). Desenhadas por um script do Godot rodado à mão (`godot --headless -s`), nas cores das texturas de água de hoje; o dono pode trocar os PNGs depois.
- **`hex_map_view.gd`:**
  - `face_texture(biome)` devolve `waterfall` para a água;
  - a água sai do `_add_faces` e vai para o `_add_waterfalls`, que manda uma malha só por lateral, da altura inteira (sem os pedaços do `face_segments`), com o código 5 no `CUSTOM0` e, nele, a altura da lateral e se ela é na borda do mapa;
  - a espuma sobre o vizinho é montada na linha do vizinho de baixo, perto do `_add_transitions` (quem está atrás e mais alto entre os hexágonos acima dele), com o código 6. As linhas se desenham de trás para frente, então uma espuma montada na linha da cachoeira ficaria coberta pela superfície do vizinho.
- **`hex_grounds.gdshader`:**
  - o código 5: o deslocamento para baixo no tempo quantizado, a linha clara no alto, a espuma nos últimos pixels ou o pontilhado na borda do mapa;
  - o código 6: a espuma do pé, mexendo.
- **`HexTransitions.drip_cell`** já não põe pingos na água; conferir que continua assim.

## Verificação

- O aviso do Godot sem avisos novos.
- Uma ilha temporária no editor com os casos dos critérios (água alta sobre água, sobre grama, na borda, quedas de 1 e de 10 níveis), conferida em fotos de uma cena temporária e apagada depois.
- O dono olha no jogo e acerta os números.

## Tarefas

- [x] O script da arte e os PNGs.
- [x] A cachoeira no `_add_waterfalls` e o código 5.
- [x] A espuma do pé na linha do vizinho e o código 6.
- [x] A borda do mapa.
- [ ] Conferir os casos e o corte de altura no editor (conferidos numa cena temporária; o editor não foi aberto).

## Resultado

- A arte é `assets/terrain/surfaces/waterfall.png` (512 × 64, mipmaps ligados como a `side.png`), gerada por `make_waterfall.gd` na mesma pasta. A espuma do pé não tem PNG: o shader a desenha com ruído (`hash`), em blocos de 2 px.
- Conferido numa cena temporária com um mapa de teste, em fotos com 0,35 s de intervalo: lago raso de altura 4 caindo sobre a grama, lago fundo de altura 8 caindo sobre a grama e sobre água rasa de altura 1, uma coluna de altura 10 sobre o mar e a água das bordas caindo para fora do mapa com o pontilhado. A queda desce e a espuma muda entre as fotos.
- A tela de conteúdo (F1) lista a `waterfall` entre as superfícies comuns.
- **Não conferido:** o editor aberto, o corte de altura e a janela em volta do Domador com a cachoeira e a espuma. Os dois usam o mesmo material do terreno, por linha.
