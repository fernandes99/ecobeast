# island-npcs

NPCs nas ilhas: personagens que o dono cadastra no catálogo e põe no mapa pelo editor, parados ou passeando entre hexágonos, com um diálogo e uma ação opcionais. Hoje uma ilha só tem terreno, objetos, peças soltas, ações e os Ecobeasts selvagens sorteados pelas áreas; nada nela fala com o jogador.

## Objetivos

- Um catálogo de NPCs (`npcs`), editado pelo painel do Supabase, com nome, descrição e sprite. Com a [04](04-npc-catalog-editor.md), também criado, editado e apagado pelo F2.
- No editor, a ferramenta NPC: escolher um NPC, pô-lo num hexágono, deixá-lo parado ou marcar os hexágonos do passeio, e escrever o diálogo e escolher a ação, os dois opcionais.
- No jogo, o NPC parado ou passeando com as animações de parado e de andar. Tocar nele por perto abre a conversa e, depois dela, roda a ação.

## Decisões

| Decisão | Motivo |
| --- | --- |
| O NPC do catálogo tem nome, descrição e sprite; o diálogo e a ação são de cada NPC posto no mapa | Decisão do dono |
| A ação é um tipo de `action_types`, o mesmo catálogo das ações dos hexágonos (hoje, abrir uma tela). Tipos novos de ação ficam para depois | Decisão do dono |
| Com diálogo e ação, a ação roda depois da última fala | Decisão do dono |
| O NPC passeia entre os hexágonos marcados no editor, ou fica parado | Decisão do dono |
| O sprite é o `slug` de um Ecobeast que tem as folhas de explorar (`explore/idle.png` e `explore/walk.png`, as do `CreatureSprite`), na escala do Domador pelo `height_m` | Decisão do dono: as folhas de luta são mais definidas, mas ficavam grandes demais ao lado do Domador, e encolhidas na proporção exata perdiam o motivo de usá-las. O dono vai melhorar a arte das de explorar. Um NPC humano terá outro formato de sprite quando houver arte |
| No passeio, o NPC escolhe um dos hexágonos ao acaso, anda até ele pelo caminho mais curto sem passar por bloqueado e fica parado de 2 a 5 s | Escolha do planejamento, _a revisar_ |
| O NPC não bloqueia o Domador | Escolha do planejamento: um NPC passeando não pode fechar uma rua |
| Tocar no NPC a até 1 hexágono abre a conversa; de longe, o Domador anda até o lado dele e conversa ao chegar | Escolha do planejamento, igual às ações dos hexágonos |
| Cada parágrafo do diálogo é uma fala; um toque passa à próxima. A caixa mostra o nome do NPC | Escolha do planejamento, a caixa de fala dos Domadores NPC |
| A descrição só aparece no editor | Escolha do planejamento |

## Fora do escopo

- Tipos novos de ação (dar item, lutar, mudar de ilha).
- Escolhas no diálogo, falas que mudam com o progresso e NPCs que lembram do jogador.
- Sprite de NPC humano.
- NPCs no mapa sorteado de Explorar zona.

## Pré-requisitos

- [map-editor](../map-editor/), [islands](../islands/) e [island-villages](../island-villages/): o rascunho, a publicação, as ações e a exploração numa ilha.
- [npc-tamers](../npc-tamers/): a caixa de fala que trava o mapa (`TamerGreetingPanel`).
- [wild-battle/14](../wild-battle/14-tap-to-walk.md): andar até um hexágono distante.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-npc-records](01-npc-records.md) | Servidor: o catálogo `npcs` e os NPCs da ilha no rascunho, na publicação e no mapa de Explorar | concluída |
| 2 | [02-npc-tool](02-npc-tool.md) | Editor: a ferramenta NPC | concluída |
| 3 | [03-npc-talk](03-npc-talk.md) | Jogo: os NPCs passeando, a conversa e a ação | concluída |
| 4 | [04-npc-catalog-editor](04-npc-catalog-editor.md) | Servidor e editor: criar, editar e apagar NPCs do catálogo pelo F2, com a recusa de apagar um NPC em uso | concluída |

O desenho compartilhado está no [architecture.md](architecture.md).
