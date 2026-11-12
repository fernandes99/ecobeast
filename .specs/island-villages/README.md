# island-villages

As ilhas ganham vilas: trilhas e pisos sobre o terreno, objetos com arte que ocupam um ou vários hexágonos (casas, moinho, castelo, árvore grande, cerca, poço) e uma camada de ações que substitui as construções de hoje. O estilo é de vila de fantasia rural medieval: arquitetura campestre, natureza, e um mundo em que humanos e Ecobeasts convivem há gerações.

A ideia é do dono, em 2026-11-11, com duas imagens de referência: uma vila com trilhas de terra e de pedra, casas de telhados coloridos, moinhos, hortas cercadas e um castelo.

## Contexto

O que existe hoje:

- **O hexágono da ilha** tem bioma, altura (0 a 4), variante e área de Ecobeasts ([terrain-height](../terrain-height/README.md), [map-editor](../map-editor/architecture.md)).
- **Decorações:** as árvores, as pedras e as plantas são sorteadas pelo `HexDecorations`, a partir do bioma e da posição, e não são guardadas ([wild-battle](../wild-battle/architecture.md#decorações)).
- **Construções:** o dono pinta hexágonos com um tipo de `building_types` (Refúgio, Loja, Arena, Casa). No jogo, eles são pintados com a cor do tipo e o nome por cima, e entrar num grupo deles vindo de fora abre a tela do tipo: o Refúgio e a Loja abrem, a Arena e a Casa não abrem nada ([islands](../islands/architecture.md)).
- **Andar:** cada toque num vizinho anda um hexágono, e nenhum hexágono é bloqueado. O servidor não guarda os hexágonos do mapa e confere a posição só pela distância (`confirmPosition`, em `server/src/battle/battle-records.service.ts`).

Referências pesquisadas:

- Battle for Wesnoth: terreno de base mais uma camada por cima (estrada, vila) no mesmo hexágono ([TerrainCodeWML](https://wiki.wesnoth.org/TerrainCodeWML)).
- Heroes of Might and Magic 3: a estrada é uma ferramenta à parte do terreno, de terra, cascalho ou pedra, e os objetos ocupam várias casas, com as que bloqueiam e a de entrada ([Map Editor - Objects](https://heroes.thelazy.net/index.php/Map_Editor_-_Objects)).
- Catlike Coding, Hex Map: a estrada guardada como os lados do hexágono que ela atravessa, desenhada do centro até cada lado ligado ([parte 7](https://catlikecoding.com/unity/tutorials/hex-map/part-7/)).

## Objetivos

1. O dono pinta trilhas (faixas que se ligam sozinhas às vizinhas) e pisos (que cobrem o hexágono inteiro) de terra e de pedra.
2. O dono põe objetos de 1 a 4 hexágonos, com variante de cor e espelhados, e escolhe quais hexágonos de cada objeto bloqueiam a passagem.
3. As construções viram ações: o dono pinta uma ação nos hexágonos, e entrar neles (ou tocar neles, se forem bloqueados) executa a ação.
4. No jogo, a ilha aparece com trilhas, pisos e objetos, e o Domador não atravessa um hexágono bloqueado.

## Decisões

Do dono, em 2026-11-11:

| Decisão | Motivo |
| --- | --- |
| As decorações sorteadas continuam como estão | O controle delas fica para depois |
| Dois tipos de chão: a trilha, uma faixa que se liga às vizinhas, e o piso, que cobre o hexágono inteiro, como uma praça. Os dois se ligam entre si | Pedido do dono, a partir das imagens de referência |
| A arte de agora é provisória, gerada por código. O dono troca depois pela arte gerada com outra IA | Pedido do dono |
| Os objetos bloqueiam a passagem por padrão, e o bloqueio se ajusta por hexágono no editor (um castelo com o portão livre) | Pedido do dono |
| Ação e objeto são camadas separadas. Uma casa pode só bloquear, como decoração, ou ter uma ação por cima | Pedido do dono |
| A construção de hoje é uma ação de abrir uma tela. Depois virão outras ações (diálogo, ir para outra ilha ou mapa, começar uma luta) | Pedido do dono |
| Tocar num hexágono bloqueado com ação, estando ao lado dele, executa a ação sem entrar | Pedido do dono: é como bater na porta |
| A primeira leva de objetos é a lista do [architecture.md](architecture.md#os-tipos-de-objeto), com variantes de cor nas casas | Aprovada pelo dono |
| A água continua livre para andar; a ponte é só visual | Pedido do dono |

Escolhas do planejamento (corrigíveis; ao mudar uma, atualize aqui e no [architecture.md](architecture.md)):

| Decisão | Motivo |
| --- | --- |
| Os tipos de chão, de objeto e de ação são tabelas do catálogo (`ground_types`, `map_object_types` com `map_object_type_tiles`, e `action_types`) | É a regra dos dados de design: um tipo novo é uma linha no painel mais um arquivo de arte |
| `building_types` vira `action_types`, e as construções das ilhas viram ações, com os mesmos ids e hexágonos | As ilhas que existem continuam iguais, sem retrabalho do dono |
| A Arena e a Casa continuam como tipos de ação, sem tela | A Arena ganha tela na `arenas-league`. A Casa o dono pode apagar quando trocar pelos objetos |
| O bloqueio é regra do servidor: Ecobeasts não nascem em hexágono bloqueado, e a chegada não fica nele | Regra de jogo mora no servidor |
| A conferência da posição continua pela distância em linha reta | Ela nunca recusa um caminho de verdade, só fica mais folgada em volta de um bloqueio. Caminho mínimo fica para quando o bloqueio for usado em mais lugares |
| O objeto fica na altura do hexágono de apoio (o `(0, 0)` do formato) | Um objeto em hexágonos de alturas diferentes precisa de uma altura só para a arte |
| Num hexágono com objeto ou piso, não nascem decorações sorteadas. Numa trilha, só as pequenas | Uma árvore no meio da casa ou da praça quebra o desenho |
| Trilhas, pisos e objetos são só das ilhas | O mapa sorteado de Explorar zona continua igual |

## Fora do escopo

- Controlar as decorações sorteadas (pôr, tirar, mudar).
- Outras ações além de abrir uma tela: diálogo, viajar, lutar.
- Arte final; esta iniciativa entrega a provisória e o formato dos arquivos.
- Objetos e trilhas no mapa sorteado de Explorar zona.
- Caminho mínimo na conferência da posição, e o toque longe andar sozinho até o destino.
- Objetos animados, sombras projetadas e girar um objeto além de espelhar.

## Pré-requisitos

- [map-editor](../map-editor/), [islands](../islands/) e [terrain-height](../terrain-height/) concluídas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-village-records](01-village-records.md) | Servidor e contrato: os tipos no catálogo, o chão, os objetos e as ações nas ilhas, as construções convertidas em ações e as regras do bloqueio. O jogo e o editor passam a falar de ações | concluída |
| 2 | [02-grounds](02-grounds.md) | Jogo e editor: trilhas e pisos desenhados, com a arte provisória, e a ferramenta Chão | concluída |
| 3 | [03-map-objects](03-map-objects.md) | Jogo e editor: os objetos desenhados, com a arte provisória, a ferramenta Objeto com variante, espelho e bloqueio, e o Domador respeitando o bloqueio e as ações em hexágono bloqueado | concluída |
| 4 | [04-plants-and-animations](04-plants-and-animations.md) | A Vegetação (as plantas do terreno como objeto), moinho, árvore e santuário animados, mais casas e santuários, e sai a casa na árvore | concluída |
| 5 | [05-connected-fences](05-connected-fences.md) | A Cerca se liga sozinha às vizinhas na mesma altura, como a trilha, de madeira e de pedra | concluída |

O desenho compartilhado está no [architecture.md](architecture.md).
