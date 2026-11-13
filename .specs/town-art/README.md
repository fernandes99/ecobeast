# town-art

A arte das cidades nas ilhas ganha um estilo próprio, mais vivo e fácil de ler: o Refúgio com cara de clínica, a Loja com cara de mercado, a Arena com cara de arena, e as casas e objetos da vila no mesmo traço. O estilo fica escrito no [guia de estilo](style-guide.md), que toda arte nova de cidade segue.

A ideia é do dono, em 2026-11-12, com referências de cidades de RPGs de criaturas em pixel art 2D: construções que dizem o que são só de olhar, caminhos claros, postes, placas e flores. O visual do Pokémon não pode ser copiado (regra do projeto): a referência é o gênero, e a arte é nossa.

## Contexto

O que existe hoje:

- **Objetos das ilhas** ([island-villages](../island-villages/architecture.md#os-tipos-de-objeto)): casas de 1, 2 e 3 hexágonos, moinho, horta, cerca, poço, barraca, carroça, estábulo, bebedouro, santuário, árvore, pedra e vegetação, com variantes. A arte é gerada pelo `res://assets/map_objects/make_objects.gd` a partir do pacote Sunnyside World, de traço terroso e sem contorno.
- **Ações** (Refúgio, Loja, Arena, Casa) são uma camada separada dos objetos: o dono pinta a ação nos hexágonos, e o objeto por baixo é só arte e bloqueio. Hoje o Refúgio e a Loja são uma Casa grande de outra cor, e a Arena é um cercado.
- **A amostra do estilo**, aprovada pelo dono em 2026-11-12: uma cena descartável, desenhada por código, com o Refúgio, a Loja, a Arena, uma casa e decorações de rua. As cores e as formas dela viraram o [guia de estilo](style-guide.md).

## Objetivos

1. O Refúgio, a Loja e a Arena viram objetos próprios, que se reconhecem de longe pela cor e pelo símbolo.
2. As casas e os objetos da vila ganham versões no estilo novo, como tipos novos, ao lado dos de hoje.
3. Decorações novas de rua: poste de luz, placa, canteiro de flores e banco.
4. O estilo fica documentado e é seguido por toda arte nova de cidade.
5. Uma ilha nova, a partir da Vila da Fonte Azul (ilha 634, rascunho), mostra tudo isso como vitrine; a 634 fica como está.

## Decisões

Do dono, em 2026-11-12:

| Decisão | Motivo |
| --- | --- |
| A arte é desenhada por código, sem pacote de fora | Pacotes grátis não têm construções com função clara, e misturar pacotes quebra o estilo |
| O estilo da amostra está aprovado | O dono viu a cena e as três construções ampliadas |
| O terreno, a água, as elevações, as árvores, as pedras e a vegetação continuam como estão | Pedido do dono: o ambiente já está bom |
| Todas as casas e objetos da vila ganham o estilo novo, não só as três construções-chave | Pedido do dono: a cidade fica uniforme |
| O estilo novo é documentado, e o dono passa a segui-lo sempre | Pedido do dono |
| Nada do que existe é apagado nem trocado: o estilo novo entra só como tipos novos, ao lado dos de hoje, e as ilhas de hoje continuam iguais | Pedido do dono, antes da fase 02 |

Escolhas do planejamento, _a revisar_ (ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| As três construções-chave são tipos de objeto novos, e a ação continua uma camada separada, pintada pelo dono | É a regra da island-villages: objeto é arte e bloqueio, ação é o que acontece |
| As construções-chave têm 1 variante cada | A cara única é o que as faz reconhecíveis |
| O vermelho de telhado é só do Refúgio, o azul só da Loja e o cinza-ardósia com laranja só da Arena | Uma casa vermelha confundiria com o Refúgio |
| Os tipos novos de casa e de vila têm o slug do tipo de hoje com `town_` na frente e o nome com "(cidade)" no fim | O dono acha o par de cada um na barra do editor |
| Um gerador novo, `res://assets/map_objects/make_town.gd`, desenha os tipos novos; o `make_objects.gd` continua igual | O gerador novo não depende do pacote Sunnyside, e a arte de hoje não muda |
| O moinho e o santuário novos são animados, como os de hoje | O jogo já anda nos quadros por `FRAME_RATES` |

## Fora do escopo

- O terreno, a água, os paredões, as trilhas e os pisos, e as árvores, pedras e plantas (do bioma e da Vegetação).
- Ponte, cais e barco: a água continua livre para andar, e uma ponte em hexágono pede um desenho próprio. Fica para quando o dono pedir.
- A tela da Arena (ela segue sem tela até a `arenas-league`).
- Interiores das construções.
- Arte do Domador, dos Ecobeasts e das telas.

## Pré-requisitos

- [island-villages](../island-villages/) concluída.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-key-buildings](01-key-buildings.md) | O gerador `make_town.gd` com o traço do guia, e o Refúgio, a Loja e a Arena como objetos novos no catálogo | concluída |
| 2 | [02-houses](02-houses.md) | Casa, Casa média e Casa grande da cidade, tipos novos ao lado dos de hoje | concluída |
| 3 | [03-village-objects](03-village-objects.md) | Moinho, horta, cerca, poço, barraca, carroça, estábulo, bebedouro e santuário da cidade, tipos novos | concluída |
| 4 | [04-street-decorations](04-street-decorations.md) | Poste de luz, placa, canteiro de flores e banco, novos no catálogo | concluída |
| 5 | [05-showcase-village](05-showcase-village.md) | Uma ilha nova, a partir da Vila da Fonte Azul, com a arte nova | rascunho |

O estilo, com as cores, o traço e as regras, está no [style-guide.md](style-guide.md).
