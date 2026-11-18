# minimap

Explorar ganha um minimapa redondo, de moldura dourada em pixel art, no canto de cima à direita. Ele mostra onde o Domador está e o que já foi descoberto em volta, com o resto escuro como a névoa. Tocar nele abre o mapa grande da ilha inteira (ou da zona, no mapa sorteado), que se arrasta e tem zoom, com os ícones do Refúgio, da Loja e dos NPCs já descobertos.

## Contexto

Em 2026-11-16, depois da [fog-of-war](../fog-of-war/README.md), o dono pediu: "vamos criar uma nova iniciativa, que é o minimapa, eu gostaria que ele fosse bonito, e pixelado se possivel. Lembrando que temos aquela visualização do mapa que vai aprendendo aos poucos."

Na conversa, o dono:

- **disse para que serve:** "Onde estou e o que já descobri ao redor, e no futuro indicadores de missões e etc.";
- **mandou como referência** a captura de um jogo de pixel art com um minimapa redondo no canto de cima à direita, numa moldura de metal dourado, com o terreno em cores chapadas e marcadores por cima, e lembrou que "deve ficar bom para mobile";
- **viu os modelos** (no companheiro visual do brainstorming) e escolheu, entre a moldura redonda dourada, a quadrada de madeira e a hexagonal de pedra, "A redonda dourada, como na referência";
- **quer que o toque** no minimapa abra "um mapa grande da ilha inteira", onde ele vai "ver onde estou, arrastar e dar zoom pela ilha", com "O Refúgio, a Loja e os NPCs" marcados;
- **quer o não descoberto** escuro: "fique tudo escuro até ser explorado", sem o contorno da ilha.

O que existe hoje:

- **A tela de Explorar** (`res://screens/exploration/exploration_screen.tscn`) é de retrato, 720×1280. No topo, a `TopRow` (centralizada) tem o nome da ilha (`IslandPlate`) e o `DayPhaseBadge`; embaixo, o `ControlsPanel` com a mensagem, Procurar, Mochila e Voltar. Os dois cantos de cima estão livres.
- **A descoberta** é a `MapDiscovery` (`res://domain/models/map_discovery.gd`): os hexágonos descobertos, a até 4 do Domador. Nas ilhas, ela começa pelo que o servidor guardou (`ExplorationMap.discovered`); no mapa sorteado, recomeça a cada exploração. A `FogLayer` já monta uma imagem com um pixel por hexágono para o shader da névoa.
- **A grade** do mapa: o hexágono `(q, r)` tem o canto em `(64q + 32r, 42r)` pixels da arte (`HexMapView._tile_origin`), e `HexMapView.grid_coord` acha o hexágono de um ponto do chão plano.
- **O Refúgio e a Loja** de uma ilha são ações (`MapAction`, com os hexágonos dela) ou peças soltas com ação (`MapProp.action_type_id`), as duas com o tipo `refuge` ou `shop` em `action_types`. Os **NPCs** são `MapNpc`, desenhados pelos `NpcSprite`s, parados ou passeando.
- **O zoom** de Explorar é a pinça ou a roda do mouse, pelo `PinchZoom` (`res://ui/components/pinch_zoom.gd`), em pixels inteiros ([camera-zoom](../camera-zoom/README.md)).

## Objetivos

1. Ao explorar, o jogador sabe de relance onde está e o que já descobriu em volta, sem abrir nada.
2. Tocando no minimapa, ele vê a ilha inteira descoberta, arrasta e dá zoom, e acha o Refúgio, a Loja e os NPCs.
3. O minimapa e o mapa grande parecem parte do jogo: pixel art nítida, moldura dourada e cores que lembram os biomas.
4. Os ícones de missão de uma iniciativa futura entram sem refazer o minimapa.

## Anti-objetivos

- O minimapa ou o mapa grande mostrando o que ainda está na névoa: terreno, contorno da ilha, construção ou NPC.
- Pixels borrados ou de tamanhos diferentes.
- O minimapa cobrindo o nome da ilha, o selo da parte do dia ou os botões.
- Andar ficando travado por causa do minimapa, numa ilha grande, no celular.

## Decisões

Do dono, em 2026-11-16:

| Decisão | Motivo |
| --- | --- |
| O minimapa é redondo, com moldura dourada em pixel art, no canto de cima à direita | Escolheu "A redonda dourada, como na referência", entre três modelos |
| O minimapa mostra onde o Domador está e o que já foi descoberto em volta, e terá os ícones de missão no futuro | "Onde estou e o que já descobri ao redor, e no futuro indicadores de missões" |
| Tocar no minimapa abre o mapa grande da ilha inteira, que se arrasta e tem zoom | "Abrir um mapa grande da ilha inteira"; "ver onde estou, arrastar e dar zoom pela ilha" |
| O mapa grande marca o Refúgio, a Loja e os NPCs | "O Refúgio, a Loja e os NPCs" |
| O que não foi descoberto fica escuro, sem o contorno da ilha | "fique tudo escuro até ser explorado" |
| Tocar no mapa grande não leva o Domador a lugar nenhum | Ele pediu só "ver onde estou, arrastar e dar zoom" |

Escolhas de Claude, aprovadas pelo dono como "Está certo" nos resumos da conversa (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O Domador é um pino vermelho no centro do minimapa, e o terreno rola por baixo dele | É o que a referência faz; o centro fixo responde "onde estou" sem procurar |
| O terreno é desenhado em cores chapadas por bioma, sem a arte das árvores e das casas, com as trilhas, os pisos e as pontes por cima e uma sombra na beira da terra com a água | Lê bem pequeno e parece um mapa; a arte de verdade não caberia nesse tamanho |
| O minimapa tem perto de um terço da largura da tela. _A revisar_ | Grande o bastante para ler no celular, sem tomar o topo |
| O nome da ilha e o selo da parte do dia saem do centro e vão para a esquerda da `TopRow` | Centralizados, eles bateriam no minimapa |
| O minimapa e o mapa grande valem nas ilhas e no mapa sorteado, só na tela de Explorar | É a mesma tela e a mesma névoa; na luta não há o que mostrar |
| O mapa grande abre com a ilha (ou a zona) inteira na tela, numa moldura dourada retangular do mesmo metal, com a legenda e o botão Fechar | É o "mapa grande da ilha inteira" que o dono pediu |
| No mapa grande, a pinça, a roda do mouse e os botões + e − mudam o zoom em degraus inteiros, de quanto a ilha cabe até 3 vezes isso; um dedo arrasta | Como o zoom da exploração, sempre nítido; os botões servem para o PC |
| Os ícones só aparecem nos hexágonos descobertos e não crescem com o zoom; o NPC que passeia aparece onde está agora; o minimapa também mostra os ícones que caem nele | A névoa não entrega nada, e um ícone de tamanho fixo continua legível |
| Com o mapa grande aberto, o Domador fica parado: abrir no meio de uma caminhada a para onde ele está | O mapa grande é para olhar; andar sem ver a tela confunde |
| A moldura, o pino e os ícones são pixel art desenhada por Claude, com a paleta Ouro e a regra de luz e contorno do [guia de estilo](../town-art/style-guide.md) | Não há arte pronta disso, e o resto do jogo segue esse guia |

O desenho técnico compartilhado está no [architecture.md](architecture.md).

## Fora do escopo

- Os ícones de missão (só o lugar para eles, no `architecture.md`).
- Ecobeasts selvagens, Domadores NPC, peças, casas e o Observatório no minimapa ou no mapa grande.
- Andar, marcar destino ou viajar rápido tocando no mapa grande.
- Uma porcentagem da ilha descoberta.
- O minimapa no tabuleiro da luta, no editor (F2) e no Desafiar do Hub.
- Girar o minimapa com a direção do Domador.
- Mudar a névoa, o raio de descoberta ou o que o servidor guarda.

## Pré-requisitos

- [fog-of-war](../fog-of-war/README.md): a `MapDiscovery` e a descoberta guardada das ilhas.
- [camera-zoom](../camera-zoom/README.md): o `PinchZoom`.
- [islands](../islands/README.md), [island-npcs](../island-npcs/README.md) e [free-objects](../free-objects/README.md): as ações, os NPCs e as peças com ação.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-minimap](01-minimap.md) | A imagem do mapa descoberto, a arte da moldura e dos ícones e o minimapa redondo no canto da tela de Explorar | concluída (falta o dono conferir) |
| 2 | [02-island-map](02-island-map.md) | O mapa grande, aberto pelo minimapa, com o zoom, o arrasto, os ícones, a legenda e o Fechar | concluída (falta o dono conferir) |
| 3 | [03-admin-teleport](03-admin-teleport.md) | O teleporte de depuração: tocar num hexágono do mapa grande leva o Domador para ele, só para quem está em `MAP_EDITOR_USER_IDS` | concluída (falta o dono conferir) |
