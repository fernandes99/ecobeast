# free-objects

Os objetos de grade (as casas da cidade, os prédios do Refúgio e da Loja e o Observatório) viram peças soltas, postas em qualquer ponto. O bloqueio deixa de ser do hexágono inteiro e vira uma forma de linhas, como a da cerca. O editor mostra essas formas, que se editam ponto a ponto.

A ideia é do dono, em 2026-11-15: os objetos de grade são limitados demais.

## Contexto

- **Objetos de grade** (`island_objects`, [island-villages](../island-villages/architecture.md)): ficam presos a um hexágono de apoio, com o formato do tipo (`map_object_type_tiles`). Cada hexágono do formato bloqueia inteiro. O Domador não entra nele, e tocar num hexágono bloqueado com ação, ao lado dele, abre a ação (o Refúgio e a Loja).
- **Peças soltas** (`island_props`, [free-props](../free-props/architecture.md)): o pé fica num ponto em pixels, desenhado na faixa de profundidade do pé. Elas nunca bloqueiam.
- **Paredes** (`island_walls`, [free-fences](../free-fences/architecture.md)): linhas de pontos. O Domador não chega a menos de `WALL_REACH` delas, e a busca de caminho já as respeita (`ExplorationMap.crosses_wall`).
- **O servidor** usa o bloqueio por hexágono em duas regras: a chegada da ilha não fica num hexágono bloqueado, e os Ecobeasts das áreas não nascem nele (`blockedKeys`). Hoje, as paredes não entram nessa conta.

## Objetivos

1. Toda peça solta pode bloquear com linhas, abertas ou fechadas, como as paredes.
2. O bloqueio é do tipo, e cada peça posta pode ter o seu.
3. O editor mostra todos os bloqueios e os edita ponto a ponto.
4. Uma peça pode ter uma ação, que acontece quando o Domador encosta no bloqueio dela.
5. Os objetos de grade viram peças soltas, e a camada de objetos sai.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| Os objetos ficam soltos, como as peças, e bloqueiam pela linha, como a cerca | A grade limita onde e como se põe um prédio |
| O bloqueio é do tipo, e cada peça posta pode ser ajustada | Desenhar uma vez e acertar só onde precisar |
| Todo hexágono que um bloqueio toca conta como bloqueado no servidor: nele não nasce Ecobeast nem fica a chegada. Vale também para as paredes. **Trocado na [prop-depth-blocks](../prop-depth-blocks/README.md#decisões):** só conta o hexágono cujo centro a linha pega | Nada nasce embaixo de um prédio ou em cima de uma cerca |
| A ação é do prédio: tocar na arte leva o Domador até o bloqueio, e a ação acontece ao encostar | Sem uma camada de hexágonos à parte para acertar |
| Os objetos de grade e as peças soltas viram uma coisa só, a peça solta | Um sistema só; uma pedra ou um poste também podem bloquear |
| A conversão não mantém compatibilidade com um APK de antes dela | Ninguém depende do APK de 14/11 |

Do planejamento, a revisar pelo dono:

| Decisão | Motivo |
| --- | --- |
| Mudar o bloqueio do tipo muda as peças sem ajuste, em todas as ilhas, e não mexe nas ajustadas | O ajuste é a escolha de quem editou aquela peça |
| O ajuste se faz no mapa, com a peça escolhida. "Salvar como do tipo" passa o bloqueio dela para o tipo | Não é preciso uma tela à parte para editar o tipo |
| A ação é de cada peça posta, e o tipo não tem ação padrão | Um mesmo prédio pode ser só enfeite numa ilha |
| As ações pintadas em hexágonos continuam, para o chão aberto. A conversão passa para a peça só as que ficavam embaixo de um objeto | Uma ação de entrar numa área continua possível |
| A ação só acontece quando a caminhada começou pelo toque na peça. Esbarrar andando para outro lugar não a abre | Não abrir o Refúgio sem querer |

## Fora do escopo

- Bloqueio por altura (passar por baixo de um arco ou de uma ponte).
- Peças animadas: hoje nenhum objeto é animado (`MapObjectSprite.FRAME_RATES` está vazio), e o suporte sai na conversão.
- O mapa sorteado: ele não tem peças.
- Mudar o desenho das paredes ou a ferramenta Cerca.

## Pré-requisitos

- [free-props](../free-props/): as peças soltas e a ferramenta Peças.
- [free-fences](../free-fences/): o índice das paredes e o `crosses_wall`.
- [island-villages](../island-villages/): os objetos e as ações.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-prop-blocks](01-prop-blocks.md) | O bloqueio das peças: o catálogo e a ilha guardam as linhas, o servidor conta os hexágonos bloqueados por elas e pelas paredes, e o Domador esbarra nelas | concluída |
| 2 | [02-block-editing](02-block-editing.md) | No editor: a camada Bloqueios e a edição dos pontos de cada peça, além do "Usar o do tipo" e do "Salvar como do tipo" | concluída (falta o dono conferir no editor) |
| 3 | [03-prop-actions](03-prop-actions.md) | A ação da peça: escolhida no editor; no jogo, tocar na arte leva o Domador até o bloqueio, e a ação acontece ao encostar | concluída (falta o dono conferir no jogo) |
| 4 | [04-objects-to-props](04-objects-to-props.md) | Os objetos de grade viram peças soltas, com o bloqueio e a ação, e as tabelas, o código e a arte deles saem | concluída (falta o dono conferir no jogo e no editor) |

O desenho comum está na [arquitetura](architecture.md).
