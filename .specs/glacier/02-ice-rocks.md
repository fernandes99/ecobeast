# 02. As pedras grandes de gelo

- **Status:** proposta
- **Depende de:** [01](01-glacier-art.md) (o chão da prévia e o grupo do pincel) e [giant-rocks/01](../giant-rocks/01-rock-props.md) (o caminho das pedras)

## Contexto

As pedras gigantes da Montanha são desenhadas pelo `client/assets/props/make_giant_rocks.py`, que grava um PNG por variante em `client/assets/props/<slug>/<n>.png`, com o pé no meio da borda de baixo. Cada uma bloqueia o Domador por uma linha fechada no pé (`prop_type_blocks`).

## Escopo

- Os desenhos das pedras de gelo, mostrados ao dono antes de entrar.
- Os tipos de peça, com o bloqueio no pé, na categoria Pedras gigantes e no grupo Geleira do pincel.

## Fora do escopo

- As pedras no mapa sorteado ([04](04-generated-glacier.md)).

## As pedras

A proposta é de 6 a 8 desenhos, e a prévia decide quais ficam:

| Slug | Nome | Como é |
| --- | --- | --- |
| `ice_block` | Bloco de gelo | Um bloco grande de facetas lisas, azul por dentro |
| `ice_spires` | Pináculos de gelo | Espetos que saem do chão em grupo, de alturas diferentes |
| `ice_arch` | Arco de gelo | Um arco baixo. Ele bloqueia pelas duas bases, e o meio é só arte por cima, sem passagem |
| `trapped_rock` | Rocha presa no gelo | Uma rocha escura vista por dentro de um bloco de gelo |
| `icicle_block` | Bloco com sincelos | Um bloco com pingentes de gelo pendurados na borda de cima |
| `ice_shelf` | Laje de gelo | Uma laje inclinada, com a neve soprada no pé |

## Requisitos

- **RF-01:** A arte entra no `make_giant_rocks.py`, com o material gelo:
  - até 7 tons de azul e branco, com a luz de cima à esquerda;
  - um brilho de 1 px nas arestas;
  - o contorno azul-escuro de 1 px.

  Rodar duas vezes dá os mesmos PNGs. A prévia mostra cada pedra sobre o chão da Geleira, ampliada 3 vezes, ao lado do Domador para a escala. Os PNGs do jogo só são gravados depois que o dono aprova.
- **RF-02:** A migration `ice_rocks`:
  - insere os tipos aprovados em `prop_types`, na categoria Pedras gigantes, nos ids seguintes aos da [01](01-glacier-art.md);
  - insere a linha fechada de cada tipo no pé em `prop_type_blocks`, como as da `giant-rocks`.
- **RF-03:** O grupo Geleira do pincel ganha as pedras de gelo, com o `per_tile` 0,25 das Pedras gigantes.
- **RF-04:** Uma lista `ICE_ROCKS` com os slugs aprovados, usada pelo pincel. A [04](04-generated-glacier.md) usa os mesmos slugs no servidor.

## Critérios de aceite

- [ ] A prévia aprovada pelo dono.
- [ ] No F2, cada pedra de gelo aparece na ferramenta Peças e bloqueia o Domador pelo pé.
- [ ] `godot --headless --path client --quit-after 60` sem erro de script.
- [ ] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Tarefas

- [ ] O material gelo no `make_giant_rocks.py` e a prévia.
- [ ] Depois da aprovação: os PNGs com os `.import`, a migration aplicada no banco e o pincel.
