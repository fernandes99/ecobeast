# day-night

O mundo do jogo ganha um relógio único: um dia inteiro passa em 24 minutos reais. A luz do mapa de exploração e do tabuleiro da luta acompanha a hora, e a UI mostra em qual das 4 partes do dia o jogo está. À noite, os postes e as janelas das casas acendem, e o Domador leva uma luz pequena em volta dele.

## Contexto

Em 2026-11-15, o dono pediu: "no meu jogo vai ter dia e noite, vou precisar que crie esse sistema. vamos ter shaders para controlar a iluminação, preciso pensar na melhor maneira de fazer isso. O dia vai passar tudo em 24 minutos (12 minutos para ir das 0h até 12h e +12 para as 12h as 24h). Vamos ter um indicativo na UI mostrando em qual parte do dia está, sendo 4 indicativos, de manhã, de tarde, final de tarde e a noite."

Hoje o jogo não tem hora. O mapa de exploração é um `Node2D` (`HexMapView`) dentro do `MapArea` da tela `exploration`, e o tabuleiro da luta é o `Board` dentro do `BoardLayer` da tela `board_battle`. Nas duas telas, o mapa vem antes da `SafeArea` com a UI, então dá para pôr um filtro entre os dois. O mapa usa vários materiais próprios (terreno, água, vento, revelação em volta do Domador), nenhum `unshaded`. O renderizador é o `mobile`. O catálogo já tem o Poste de luz (tipo de peça 18), os prédios (22 a 27) e as casas do pacote (95 a 97).

A tabela `evolutions` já tem a coluna `time_of_day` (`day` ou `night`), da migração `init`, que nenhuma regra usa.

## Objetivos

1. Um relógio do mundo, o mesmo para todos os jogadores, que o servidor sabe calcular a qualquer momento.
2. As 4 partes do dia (manhã, tarde, final de tarde e noite) no catálogo, com id estável, para regras futuras apontarem para elas.
3. A luz do mapa de exploração (o sorteado e as ilhas) e do tabuleiro da luta muda aos poucos com a hora.
4. O indicador da parte do dia no Hub e na exploração.
5. À noite, os pontos de luz das peças e a luz do Domador acendem no mapa de exploração.

## Anti-objetivos

- A hora mudar qualquer regra de jogo nesta iniciativa (nascimentos, Evolução, luta, loja).
- Uma noite tão escura que o jogador não enxerga o caminho no celular.
- Um salto de cor quando a parte do dia muda.
- A UI (botões, painéis, nomes dos prédios) escurecer junto com o mapa.
- Mexer nos shaders que já existem (terreno, água, vento) para a luz funcionar.
- Cada aparelho com uma hora diferente, ou a hora vinda do relógio do celular.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| Um dia dura 24 minutos reais: 12 da 0h às 12h e 12 das 12h às 24h | Pedido do dono |
| 4 partes do dia no indicador: manhã, tarde, final de tarde e noite | Pedido do dono |
| Por enquanto, a hora muda só o visual; depois, vai decidir quais Ecobeasts nascem | "Só o visual por enquanto, mas depois influencia nas criaturas que serão geradas" |
| A luz muda no mapa de exploração e no tabuleiro da luta; o Hub e os menus só mostram o indicador | Escolheu "Mapa e luta" |
| À noite acendem as peças (postes e janelas) e uma luz em volta do Domador | Escolheu "Peças e Domador" entre só a cor do céu, peças e peças com o Domador |
| A iluminação é um filtro por cima do mapa, num shader só | Claude mostrou três jeitos (luz nativa do Godot, filtro por cima e a cor dentro de cada shader), e o dono escolheu o filtro |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O relógio é calculado pela hora do servidor, sem nada no banco | O servidor é a autoridade, e a regra futura dos nascimentos precisa da mesma hora que o jogador vê |
| 1 segundo real é 1 minuto do jogo; o dia começa à 0h em 2026-01-01T00:00:00Z | É a conta mais simples para 24 minutos por dia, e a data fixa faz todo servidor chegar à mesma hora |
| O cliente pega a hora do servidor e conta sozinho, sem usar o relógio do celular | O relógio do celular pode estar errado ou ser mudado pelo jogador |
| As partes do dia são uma tabela do catálogo, `day_phases` | A regra futura dos nascimentos aponta para elas por FK (`day_phase_id`), como manda o [game-data/architecture.md](../game-data/architecture.md) |
| Horários _a revisar_: manhã 6h, tarde 12h, final de tarde 17h, noite 19h (até as 6h) | A noite fica com 11 minutos reais, quase metade do ciclo, e o final de tarde é curto, como o pôr do sol |
| As cores da hora ficam numa tabela do jogo, por hora, e não no catálogo | É ajuste de visual, sem regra de jogo, como a força do vento (`KIND_SWAY`) |
| A noite é azulada e menos saturada, nunca preta | O jogo é no celular, muitas vezes na rua; a noite tem que ser legível |
| As luzes das peças ficam no catálogo, `prop_type_lights`, por tipo e variante, como os bloqueios | Peça nova acende sem código, e as janelas mudam de lugar em cada variante das casas |
| No tabuleiro da luta, só a cor da hora, sem pontos de luz | O tabuleiro não tem peças nem o Domador |
| No tabuleiro, a barra de HP, os chips e os números de dano não escurecem; os hexágonos, as marcas e os Ecobeasts sim | Os primeiros são UI desenhada dentro do tabuleiro, e a noite não pode atrapalhar a leitura da luta |
| O "Debug: +1 hora" aparece em toda build de debug | Para testar a noite no celular sem esperar até 24 minutos |
| O indicador não aparece na luta | A tela da luta já está cheia, e a hora não muda nada nela além da cor |
| O editor de ilhas (F2) fica sempre de dia | Para editar, o dono precisa ver a arte como ela é |

## Fora do escopo

- A hora decidir quais Ecobeasts nascem (a iniciativa seguinte, que usa `day_phase_id`).
- A Evolução por horário (`evolutions.time_of_day`); quando vier, a coluna pode virar `day_phase_id`.
- Editar os pontos de luz pelo editor de ilhas (por enquanto, pelo painel do Supabase).
- Luz nos Ecobeasts (brilho de Fogo, de Luz), estrelas, lua, nuvens, chuva e sombras que mudam com o sol.
- Música ou sons diferentes à noite.
- Mudar a luz da ilustração do Hub.

## Pré-requisitos

- [free-objects](../free-objects/) e [prop-depth-blocks](../prop-depth-blocks/): as peças soltas e as tabelas por tipo e variante.
- [camera-zoom](../camera-zoom/): o zoom do mapa e do tabuleiro, que o filtro acompanha.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-world-clock](01-world-clock.md) | O relógio do mundo no servidor e no jogo, e as partes do dia no catálogo | concluída (falta o dono conferir) |
| 2 | [02-day-light](02-day-light.md) | O filtro da hora no mapa e na luta, e o indicador no Hub e na exploração | concluída (falta o dono conferir) |
| 3 | [03-night-lights](03-night-lights.md) | Os pontos de luz das peças e a luz do Domador à noite | concluída (falta o dono conferir) |

O desenho que as três fases compartilham está no [architecture.md](architecture.md).
