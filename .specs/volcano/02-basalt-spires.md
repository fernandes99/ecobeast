# 02. Os picos de basalto

- **Status:** pendente
- **Depende de:** [01](01-volcano-art.md) (o chão da prévia, a categoria e o grupo do pincel) e [glacier/02](../glacier/02-ice-rocks.md) (o caminho das pedras de gelo)

## Contexto

As pedras gigantes e as de gelo são desenhadas pelo `client/assets/props/make_giant_rocks.py`. Ele grava um PNG por variante em `client/assets/props/<slug>/<n>.png`, com o pé no meio da borda de baixo. Cada pedra bloqueia o Domador por uma linha fechada no pé (`prop_type_blocks`).

Na imagem do dono, o que faz o vulcão é a borda de espetos altos e pontudos de rocha escura. A altura do terreno vai só até 10, então esses espetos são peças.

## Escopo

- Os desenhos dos picos de basalto, mostrados ao dono antes de entrar.
- Os tipos de peça, com o bloqueio no pé, na categoria Vulcão e no grupo Picos de basalto do pincel.

## Fora do escopo

- Os picos no mapa sorteado ([04](04-land-volcano.md)).

## Os picos

A proposta. A prévia pode tirar ou trocar picos, e o dono escolhe quais entram.

| Slug | Nome | Como é |
| --- | --- | --- |
| `basalt_spire` | Pico de basalto | Um espeto alto e fino, torto, com a ponta quebrada |
| `basalt_twin` | Picos gêmeos | Dois espetos de alturas diferentes saindo da mesma base |
| `basalt_crown` | Coroa de picos | Um grupo de 4 ou 5 espetos baixos em roda |
| `basalt_columns` | Colunas de basalto | Colunas de seis lados, de alturas diferentes, lado a lado |
| `lava_vein_spire` | Pico com veio de lava | Um espeto largo com uma fresta laranja acesa descendo por ele |
| `ash_boulder` | Rochedo de cinza | Uma rocha grande e arredondada, coberta de cinza no alto |

## Requisitos

- **RF-01:** A arte entra no `make_giant_rocks.py`, com o material basalto:
  - até 7 tons de cinza-chumbo e marrom-escuro, com a luz de cima à esquerda;
  - o contorno quase preto de 1 px;
  - o grão áspero da pedra;
  - o laranja só nos veios de lava, que acendem à noite como as decorações da [01](01-volcano-art.md).

  Rodar duas vezes dá os mesmos PNGs. A prévia mostra cada pico sobre o chão do Vulcão, ampliado 3 vezes, ao lado do Domador para a escala. Os PNGs do jogo só são gravados depois que o dono aprova.
- **RF-02:** Os picos são mais altos que as pedras gigantes da Montanha: o mais alto tem pelo menos 3 vezes a altura do Domador.
- **RF-03:** A migration `basalt_spires`:
  - insere os tipos aprovados em `prop_types`, nos ids seguintes aos da [01](01-volcano-art.md), na categoria Vulcão;
  - insere a linha fechada de cada tipo no pé em `prop_type_blocks`, como as da `giant-rocks`.
- **RF-04:** Os picos ficam num grupo próprio do pincel, "Picos de basalto", logo depois do grupo Vulcão, com o `per_tile` 0,25 das Pedras gigantes.
- **RF-05:** Uma lista `BASALT_SPIRES` com os slugs aprovados, usada pelo pincel. A [04](04-land-volcano.md) usa os mesmos slugs no servidor.

## Critérios de aceite

- [ ] A prévia aprovada pelo dono.
- [ ] No F2, cada pico aparece na ferramenta Peças e bloqueia o Domador pelo pé. Fica para o dono conferir.
- [ ] `godot --headless --path client --quit-after 60` sem erro de script.
- [ ] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Tarefas

- [ ] O material basalto no `make_giant_rocks.py` e a prévia.
- [ ] Depois da aprovação: os PNGs com os `.import`, a migration aplicada no banco e o pincel.
