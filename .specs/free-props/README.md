# free-props

As ilhas ganham uma camada de arte livre por cima da grade. Além dos objetos presos aos hexágonos, o dono põe **peças soltas** (uma flor, um barril, um pedaço de cerca, uma árvore) em qualquer ponto da ilha, em pixels, várias no mesmo hexágono, e **carimbos**: conjuntos prontos (uma casa com quintal, uma praça) que, ao serem postos, se desmancham em objetos, peças soltas e chão comuns. A grade continua sendo a regra do jogo; a peça solta é só enfeite.

## Contexto

Em 2026-11-13, o dono mostrou uma ilha feita no editor e uma imagem de referência, e disse que o hexágono estava limitando: "cada decoração ocupa um e também não tem uma reta para cima e nem para baixo", "esta ficando ruim". Claude mostrou que a referência também é feita de hexágonos: o que muda é que as coisas em cima do chão não obedecem à grade (cercas, flores e árvores em grupos soltos, casas com quintal ocupando vários hexágonos, a praça como um desenho só, trilhas contínuas).

O dono escolheu manter a grade e soltar o que se vê. A primeira parte, o Domador andando em reta até o ponto tocado, é a [wild-battle/15](../wild-battle/15-free-walk.md). Esta é a segunda.

Perguntado sobre como quer montar uma vila no editor, o dono quis as três formas: **peça por peça**, **conjuntos prontos** e **pincel**. Claude dividiu em projetos, nesta ordem: (1) peças soltas e conjuntos, esta iniciativa; (2) o pincel, que espalha peças soltas numa área; (3) trilhas contínuas; (4) a arte final, gerada pelo dono com outra IA, entrando conforme fica pronta.

O que existe hoje ([island-villages](../island-villages/architecture.md)):

- **Objetos** (`island_objects`, `island_object_tiles`): um tipo do catálogo (`map_object_types`), um hexágono de apoio, os hexágonos do formato (`map_object_type_tiles`, com `dq`, `dr` e o bloqueio padrão), variante e espelho. O formato já pode ter qualquer quantidade de hexágonos no banco; os de hoje vão de 1 a 5.
- **Decorações sorteadas**: árvores, pedras e plantas escolhidas pelo `HexDecorations` a partir do bioma e da seed, sem guardar nada. Numa ilha, não nascem em hexágono com objeto ou piso.
- **A Vegetação** (`plants`, id 20): um objeto de 1 hexágono que não bloqueia, com uma combinação das plantas do terreno.
- **O desenho** é feito linha por linha de hexágonos, com as decorações de trás e as da frente de cada linha, e os atores entre elas ([wild-battle/11](../wild-battle/11-depth-planes.md)).

## Objetivos

1. O dono põe, move, troca a variante, espelha e apaga peças soltas em qualquer ponto da ilha, várias no mesmo hexágono.
2. O dono põe objetos de grade e peças soltas na mesma ferramenta do editor.
3. O dono guarda uma parte da ilha como carimbo e a põe de novo em outro lugar, inteira, e depois ajusta cada peça dela.
4. No jogo, as peças soltas aparecem na altura do chão embaixo delas, na frente ou atrás do Domador conforme a posição, com o vento nas plantas, sem pesar com milhares delas.
5. As ilhas não têm mais decorações sorteadas: tudo que aparece foi posto pelo dono.

## Anti-objetivos

- A peça solta nunca muda regra: não bloqueia, não tem ação, não muda encontro nem a posição conferida pelo servidor.
- Nada muda no mapa sorteado de Explorar zona: ele continua com as decorações sorteadas e sem peças.

## Decisões

Do dono, em 2026-11-13:

| Decisão | Motivo |
| --- | --- |
| Manter a grade de hexágonos como regra e soltar a arte por cima | A referência do dono também é de hexágonos; trocar a grade refaria servidor, editor e tabuleiro sem deixar o mapa mais bonito |
| As três formas de montar: peça por peça, conjuntos prontos e pincel | Pedido do dono. O pincel fica para a iniciativa seguinte |
| A peça solta é só enfeite: nunca bloqueia | "Peça solta só enfeite está bom". Para fechar uma passagem, usa-se um conjunto ou um objeto que bloqueia |
| Duas camadas nos dados (opção A): os objetos de grade viram os conjuntos, e as peças soltas são uma tabela nova, com o ponto em pixels | Escolhida pelo dono. O que bloqueia precisa encaixar nos hexágonos, e o servidor só conhece hexágonos |
| Todas as ilhas do banco foram apagadas | Pedido do dono, sem cópia, em 2026-11-13 (5 ilhas: 85, 331, 634, 791 e 844). Nada precisa ser convertido |
| O conjunto pronto é um **carimbo**: um modelo que, ao ser posto, vira objetos, peças soltas e chão comuns | Escolhido pelo dono. Num quintal ou praça em que se anda, uma imagem só cobriria o Domador; em peças, cada parte fica na frente ou atrás dele, e o dono ajusta depois. A arte da outra IA vem em peças separadas |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e no `architecture.md`):

| Decisão | Motivo |
| --- | --- |
| No editor, uma ferramenta só, **Peças**, com uma paleta única: o objeto encaixa no hexágono, a peça solta fica no ponto exato | A separação é só nos dados; para o dono, é tudo "pôr uma peça" |
| O carimbo é um arquivo do editor (`client/tools/map_editor/stamps/<slug>.json`, versionado), criado por "Guardar seleção como carimbo": os objetos, as peças soltas e o chão de uma área, relativos a um hexágono de apoio. Ele pode ser espelhado ao pôr | O jogo e o servidor nunca veem um carimbo: ele vira peças comuns ao ser posto. Não precisa de tabela nem de rota |
| Pôr um carimbo por cima de algo troca o que estiver nos hexágonos dele (objetos e chão), e as peças soltas dele se somam às que já estão lá; tudo num passo só de desfazer | É o que o dono espera de um carimbo; o desfazer conserta um erro |
| O plano entre a peça solta e o Domador é pela altura do pé, em faixas de cerca de 10 pixels da arte (4 por linha de hexágonos), e não pixel a pixel | A comparação exata, com milhares de peças, pesaria; 10 pixels é menos que o pé do Domador. Um objeto conta como uma peça na borda da frente dele |
| O Poste de luz, a Placa, o Canteiro e o Banco (objetos 36 a 39) saem de `map_object_types` e voltam como peças soltas, com ids novos; os ids velhos não são reaproveitados. O Poste, a Placa e o Banco deixam de bloquear | A regra da peça solta. Nenhuma ilha usa esses objetos, porque todas foram apagadas |
| A praça usa o piso de pedra de hoje (chão) e uma Fonte nova, objeto de grade que bloqueia, com arte provisória no `make_town.gd` | Não existe arte de fonte, e a praça da referência tem uma |
| As ilhas param de ter decorações sorteadas; o mapa sorteado continua com elas | Sem ilhas antigas, não precisa de chave por ilha. Até o pincel chegar, a Vegetação e as peças soltas cobrem a vegetação |
| Os tipos de peça solta são uma tabela do catálogo (`prop_types`), como os de objeto | Regra dos dados de design: um tipo novo é uma linha no painel mais a arte |
| A posição da peça é o ponto do pé dela no chão plano, em pixels inteiros da arte, sem a altura (como o `_player_point` da [wild-battle/15](../wild-battle/15-free-walk.md)); a altura vem do hexágono embaixo do pé. É guardado como o hexágono do pé mais o deslocamento a partir do centro dele | Mudar a altura de um hexágono leva as peças dele junto, sem regravar; o hexágono explícito deixa o servidor conferir e o editor achar as peças de um hexágono apagado |
| A peça só pode ficar com o pé num hexágono que existe na ilha | Uma peça na água do fundo, fora do mapa, ninguém veria nem conseguiria apagar |
| As primeiras peças soltas são as plantas e as pedras do terreno (`HexDecorations`, 17 tipos, 4 variantes cada) e as decorações de rua da cidade (poste, placa, canteiro e banco), que saem dos objetos | São a arte que já existe, no estilo do jogo. O dono troca depois pela arte da outra IA |
| Os primeiros carimbos, montados por Claude no editor com a arte que já existe: uma casa da cidade com quintal (horta, cerca e flores) e a praça com a Fonte | Mostram o carimbo funcionando antes da arte final |
| Um limite de peças por ilha (`MAX_PROPS`, 6000), conferido ao salvar | A ilha inteira vai para o jogo numa resposta só |

## Fora do escopo

- O pincel e as trilhas contínuas (as próximas iniciativas).
- A arte final.
- Peças soltas no mapa sorteado de Explorar zona.
- Girar uma peça além de espelhar, escalar, ou peças animadas além do vento das plantas.
- Bloqueio ou ação numa peça solta.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-prop-records](01-prop-records.md) | Servidor e contrato: o catálogo `prop_types`, a tabela `island_props`, as rotas do editor (salvar, publicar) e as peças na resposta de Explorar numa ilha. As decorações de rua passam de objeto a peça | concluída |
| 2 | [02-props-in-game](02-props-in-game.md) | Jogo: as peças soltas desenhadas em lote por linha, na altura do hexágono, com o vento nas plantas e o plano certo com o Domador; as ilhas sem decorações sorteadas | concluída |
| 3 | [03-pieces-tool](03-pieces-tool.md) | Editor: a ferramenta Peças, com a paleta única, pôr, mover, variante, espelho, apagar e desfazer, para conjuntos e peças soltas | concluída |
| 4 | [04-stamps](04-stamps.md) | Editor: guardar uma seleção como carimbo e pôr um carimbo (espelhado ou não); a Fonte; os dois primeiros carimbos | concluída |

O desenho compartilhado está no [architecture.md](architecture.md).
