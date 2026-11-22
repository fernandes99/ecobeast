# 01. A Arena fortaleza e a Arena coliseu

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [free-objects](../free-objects/) (os prédios como peças soltas), [day-night](../day-night/) (as luzes das peças), [portal-altar](../portal-altar/) (as peças animadas) e [editor-ui](../editor-ui/) (as categorias)

## Contexto

O dono quer o prédio da Arena feito com os tilesets do Fantasy Dreamland Reborn, e escolheu pôr os dois formatos da prévia, com o coliseu também fechado ([README](README.md#contexto)).

## Escopo

- O script `client/assets/props/make_arena.py` e a arte `assets/props/arena_fortress/` (`1.png` e `1_frames.png`) e `assets/props/arena_coliseum/` (`1.png`, `2.png` e os `_frames`).
- O `HexMapView.PROP_FRAMES`, com os dois tipos.
- Os tipos de peça 190 e 191, com o bloqueio e as luzes, na migração `20270211000000_arena_buildings`.
- A prévia em `art-source/arena/`.

## Requisitos

- **RF-01:** `python -I make_arena.py <pasta Tilesets do pacote>`, de dentro de `client/assets/props`, grava a arte, e com `--preview <arquivo>` grava só a folha das três Arenas ao lado do Refúgio, em 2×. Ele imprime o bloqueio e as luzes de cada variante, a partir do pé.
- **RF-02:** A Arena fortaleza (240×161) junta, do `FDR_Castle_Tiles.png`, a muralha com ameias, cortada em 3 colunas e em faixas (as ameias de trás, o topo, as ameias da frente, o tijolo e o rodapé), repetidas para cada largura e altura, com o topo de lajes. Ela tem 2 torres de 3 tiles com 5 linhas de tijolo, 2 muralhas de 3 tiles com 3 linhas e, no meio e mais à frente, a casa do portão, de 5 tiles com 4 linhas. Na casa do portão ficam a grade levadiça fechada (o quadro 0 do `FDR_Castle_Door05.png`), a placa do escudo e 2 estandartes vermelhos (espada e escudo). As torres têm um estandarte e uma janela alta com grade, e as muralhas, uma janela pequena. Há um braseiro de cada lado da casa do portão, no chão.
- **RF-03:** A Arena coliseu é o anel octogonal do `FDR_Dungeon.png` (a caixa de (100, 30) com 72×78), sem o fundo escuro de masmorra, ligado à borda. Ele é esticado pela coluna do meio (x de 128 a 144, repetida 10 vezes) e pela linha 80, que só tem os lados retos (repetida 50 vezes), e fica com 204×120. A parede de fora desce do pé da borda de baixo do anel, coluna por coluna, com o tijolo da parede norte do Dungeon (x de 128 + coluna % 16, y de 40 a 56, repetido) e o rodapé de 8 px (y de 56 a 64). Na diagonal, cada coluna desce 1 px, e as fiadas de tijolo ficam inclinadas.
  - **Variante 1, aberta (204×160):** a parede da frente tem 40 px; a areia do Dungeon (os tiles (32, 0) e (48, 0) alternados) enche o buraco do anel. Na parede de dentro, ao norte, ficam a arquibancada (3 degraus da escadaria do Castle, com as pontas de tijolo dela) e 4 estandartes rasgados (espada, escudo, escudo e espada espelhada). A placa do escudo fica no meio da areia.
  - **Variante 2, fechada (204×176):** a borda é só moldura: a de baixo do anel, espelhada em cima, com a linha dos lados retos entre as duas. As lajes do Castle (o tile (16, 0)) cobrem o buraco. A parede da frente tem 56 px, com a placa do escudo acima do portão e 2 estandartes de espada, um espelhado.
  - Nas duas, a grade levadiça fica no meio da parede da frente, e há um braseiro de cada lado dela, preso à parede.
- **RF-04:** Os braseiros são o `FDR_Castle_Torches.png` (16×32, a fileira de cima), e o quadro `n` de cada variante usa o quadro `n` do braseiro. O `<variante>_frames.png` tem os 8 quadros lado a lado, e o `<variante>.png` é o quadro 0. No mapa, o `HexMapView.PROP_FRAMES` troca os quadros a 10 por segundo, como o altar.
- **RF-05:** O tipo 190 é `arena_fortress`, "Arena fortaleza", com 1 variante, e o 191 é `arena_coliseum`, "Arena coliseu", com 2. Os dois ficam na categoria 2 (Prédios).
- **RF-06:** O bloqueio padrão (variante 0) da fortaleza é a linha fechada pelo pé das torres, das muralhas, da casa do portão e dos braseiros, até 51 px acima do pé das torres: (−120, −14), (−72, −14), (−72, −20), (−54, −20), (−54, −2), (−38, −2), (−38, −10), (38, −10), (38, −2), (54, −2), (54, −20), (72, −20), (72, −14), (120, −14), (120, −65) e (−120, −65). O do coliseu, para as duas variantes, é o octógono do anel no chão: (−80, −120), (80, −120), (102, −98), (102, −24), (80, −2), (−80, −2), (−102, −24) e (−102, −98).
- **RF-07:** As luzes (variante 0) ficam no fogo dos braseiros, com raio 22 e a cor `ff9a3c`, a do fogo da lava: a fortaleza em (−46, −18) e (46, −18), e o coliseu em (−34, −16) e (34, −16).

## Critérios de aceite

- [ ] A ferramenta Peças do F2 mostra a Arena fortaleza e a Arena coliseu na categoria Prédios, e as teclas ← → trocam o coliseu entre o aberto e o fechado.
- [ ] O Domador para no pé das duas e passa atrás delas, coberto.
- [ ] Os braseiros queimam, e à noite a luz deles acende.
- [ ] A ação Arena, dada pela lista Ação, acontece ao tocar no prédio.
- [x] Num mapa montado pelo `HexMapView` numa cena de teste, as 3 Arenas aparecem como na prévia, a partir da folha de quadros.
- [x] `GET /v1/catalog` traz os tipos 190 e 191, os bloqueios e as 4 luzes.
- [x] `godot --headless -d --path client --quit-after 240` roda sem erro de script novo.

## Tarefas

- [x] As prévias (fortaleza, coliseu aberto e fechado) aprovadas pelo dono.
- [x] O `make_arena.py`, a arte com os `.import` e o `PROP_FRAMES`.
- [x] A migração, aplicada no banco.
- [x] Os créditos (`assets/props/CREDITOS.md`) e as luzes à mão (`assets/props/LUZES.md`).
