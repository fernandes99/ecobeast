# 02. As pedras grandes de gelo

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [01](01-glacier-art.md) (o chão da prévia e o grupo do pincel) e [giant-rocks/01](../giant-rocks/01-rock-props.md) (o caminho das pedras)

## Contexto

As pedras gigantes da Montanha são desenhadas pelo `client/assets/props/make_giant_rocks.py`, que grava um PNG por variante em `client/assets/props/<slug>/<n>.png`, com o pé no meio da borda de baixo. Cada uma bloqueia o Domador por uma linha fechada no pé (`prop_type_blocks`).

## Escopo

- Os desenhos das pedras de gelo, mostrados ao dono antes de entrar.
- Os tipos de peça, com o bloqueio no pé, na categoria Pedras e no grupo Pedras de gelo do pincel.

## Fora do escopo

- As pedras no mapa sorteado ([04](04-generated-glacier.md)).

## As pedras

O dono aprovou as 6 em 2026-11-21 ("Todas as 6"). O Bloco de gelo tem 2 variantes, uma limpa e outra com neve no alto:

| Slug | Nome | Como é |
| --- | --- | --- |
| `ice_block` (171) | Bloco de gelo | Um bloco grande de facetas lisas, azul por dentro |
| `ice_spires` (172) | Pináculos de gelo | Espetos que saem do chão em grupo, de alturas diferentes |
| `ice_arch` (173) | Arco de gelo | Um arco baixo. Ele bloqueia pelas duas bases, e o meio é só arte por cima, sem passagem |
| `trapped_rock` (174) | Rocha presa no gelo | Uma rocha escura vista por dentro de um bloco de gelo |
| `icicle_block` (175) | Bloco com sincelos | Uma laje larga por cima do bloco, com pingentes de gelo pendurados na borda dela |
| `ice_shelf` (176) | Laje de gelo | Uma laje inclinada, com a neve soprada no pé |

## Requisitos

- **RF-01:** A arte entra no `make_giant_rocks.py`, com o material gelo:
  - até 7 tons de azul e branco, com a luz de cima à esquerda;
  - um brilho de 1 px nas arestas;
  - o contorno azul-escuro de 1 px;
  - as facetas lisas, sem o grão da pedra, com as emendas claras (`Rock(smooth=True)` e `Rock.ice`).

  Rodar duas vezes dá os mesmos PNGs. A prévia mostra cada pedra sobre o chão da Geleira, ampliada 3 vezes, ao lado do Domador para a escala. Os PNGs do jogo só são gravados depois que o dono aprova.
- **RF-02:** A migration `ice_rocks`:
  - insere os tipos aprovados em `prop_types`, nos ids 171 a 176, na categoria Pedras (6), a mesma das pedras gigantes: não existe uma categoria Pedras gigantes;
  - insere a linha fechada de cada tipo no pé em `prop_type_blocks`, como as da `giant-rocks`. O Arco de gelo tem uma linha em cada perna (`position` 0 e 1), impressas pelo `make_giant_rocks.py` (`Rock.image(bases=...)`).
- **RF-03:** As pedras de gelo ficam num grupo próprio do pincel, "Pedras de gelo", logo depois do grupo Geleira, com o `per_tile` 0,25 das Pedras gigantes. Elas não entram no grupo Geleira porque um grupo tem um `per_tile` só, e o dele (1) poria uma pedra grande por hexágono.
- **RF-04:** Uma lista `ICE_ROCKS` com os slugs aprovados, usada pelo pincel. A [04](04-generated-glacier.md) usa os mesmos slugs no servidor.

## Critérios de aceite

- [x] A prévia aprovada pelo dono.
- [ ] No F2, cada pedra de gelo aparece na ferramenta Peças e bloqueia o Domador pelo pé. O catálogo já serve os tipos 171 a 176 e as 7 linhas de bloqueio; falta o dono abrir o F2.
- [x] `godot --headless --path client --quit-after 60` sem erro de script.
- [x] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Tarefas

- [x] O material gelo no `make_giant_rocks.py` e a prévia.
- [x] Depois da aprovação: os PNGs com os `.import`, a migration (`20270201000001_ice_rocks`) aplicada no banco e o pincel.
