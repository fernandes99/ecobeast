# 04. O bioma e a hora no topo

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02-hud-layout](02-hud-layout.md), [03-quest-tracker](03-quest-tracker.md)

## Contexto

Em 2026-11-23, depois das fases 1 a 3, o dono mandou um protótipo da tela e pediu as informações dele que a tela não tinha, menos a altitude e o nome da zona ("floresta costeira"), e, no topo, "o nome do bioma e um ícone representativo desse bioma, se não existe um ícone para ele, crie um". A primeira versão copiou também o visual do protótipo (molduras douradas, fonte de pixel, botões com losangos); o dono não gostou: "remova todas essas bordas douradas. Volte com a fonte normalmente. Mas mantenha a disposição dos elementos." Ficaram só as informações e a disposição; o visual é o da [02](02-hud-layout.md).

## Escopo

- `client/assets/ui/biomes/` (novo): `make_biome_icons.py` e os ícones.
- `client/screens/exploration/` (`explore_plates.gd` novo, a cena e a tela, a `PartyStrip`).

## Requisitos

- **RF-01:** um ícone de 16 × 16 em pixel art para cada bioma do catálogo (`assets/ui/biomes/<slug>.png`, do `make_biome_icons.py`, desenhado por código): Planície, Boreal, Pedra, Colina, Montanha, Água rasa, Água profunda, Deserto, Neve, Praia, Geleira, Vulcão, Lava rasa e Lava funda, mostrado em 32 × 32 com o filtro mais próximo. Um bioma sem ícone mostra só o nome.
- **RF-02:** a placa de cima mostra o ícone e o nome do bioma do hexágono do Domador e troca quando ele anda para outro bioma. O nome da ilha sai da tela (continua no título do mapa grande).
- **RF-03:** embaixo dela, uma placa com o ícone da parte do dia, a hora do mundo ("21:40", do `WorldClock`) e o nome da parte do dia na cor dela (`UiPalette.HUD_PHASE_COLORS`), separados por uma barra.
- **RF-04:** as duas placas são o painel escuro da [02](02-hud-layout.md) (`ExplorePlates.panel_style`, que o quadro de missões e o aviso também usam), com o texto na Nunito contornada.
- **RF-05:** os rostos da equipe ficam do mesmo tamanho (60), com o anel de HP.
- **RF-06:** a altitude e o nome da zona do protótipo não entram.

## Escolhas de Claude (_a revisar_)

| Decisão | Motivo |
| --- | --- |
| O bioma é o do hexágono do Domador, e o nome da ilha sai da placa | O dono pediu o bioma no topo; o nome da ilha continua no mapa grande |
| O brilho do protótipo, ao lado da parte do dia, não entrou | Sem as molduras ele era só enfeite, e o jogo não tem clima para ele mostrar |
