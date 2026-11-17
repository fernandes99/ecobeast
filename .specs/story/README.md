# story

As cenas da história, com o roteiro morando no cliente e só os Marcos do jogador no servidor. O dono escreve cada cena na ferramenta Cenas do editor de ilhas (F2) como uma lista de passos (falas, escolhas, gente andando, câmera), e o jogo toca as cenas pelos gatilhos da ilha. Ao terminar uma cena, o jogo grava no servidor os Marcos que ela ligou, e é por eles que o jogador volta ao ponto onde parou ao reinstalar o app.

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [island-npcs](../island-npcs/), [islands](../islands/), [map-editor](../map-editor/), [tamer-appearance](../tamer-appearance/)

## Contexto

O dono escreveu a introdução do jogo (a natureza de Liora, a criação do Domador dentro da cena, o avô, o caminho até a Vila Raiz, o reencontro com a Mira e o primeiro vínculo no Refúgio), e a história vai continuar com missões paralelas e escolhas. Hoje só existe o embrião disso: o NPC das ilhas tem um diálogo de parágrafos e uma ação no fim ([island-npcs](../island-npcs/architecture.md)). Falta um jeito de escrever cenas com várias pessoas, câmera e escolhas, de saber quais já aconteceram e de guardar isso na conta.

## Objetivos

1. O dono cria, muda e testa uma cena sozinho, dentro do F2, sem editar arquivo à mão.
2. A história cresce para os lados (missões paralelas, escolhas) sem que uma cena precise saber das outras: uma cena só lê e liga Marcos.
3. Reinstalar o app (ou trocar de aparelho) volta ao mesmo ponto da história.
4. O servidor guarda o mínimo: uma lista de Marcos, sem saber o que eles significam.
5. A Linha da história mostra a ordem das cenas e avisa dos buracos (uma cena que nunca pode rodar).

## Não objetivos

- Construir a introdução de Liora em si (a ilha, o avô, a Mira, o novo começo do jogo). Ela vira a iniciativa seguinte, que usa estas ferramentas.
- Recompensas pela história. Uma cena não dá item, moeda nem Ecobeast; quando a história precisar, a cena abre uma tela que já existe (a escolha do inicial, por exemplo), e a regra continua na rota dela.
- Variáveis com número (contadores, "confiança"). Só Marcos, ligados ou não.
- Cenas fora das ilhas (no Hub, na luta, no mapa sorteado).

## Antiobjetivos

- O servidor passar a conhecer o roteiro ou decidir alguma coisa por ele.
- Um Marco falso dar vantagem a quem trapaceia.
- Uma cena travar o jogador sem saída (sem fala para avançar, ator que não chega ao destino).
- O dono precisar abrir um `.json` para escrever uma cena.

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| O roteiro mora no cliente; o servidor guarda só os Marcos do jogador | Decisão do dono: o mínimo de dados no servidor, só o bastante para voltar ao ponto ao reinstalar |
| O progresso é uma lista de Marcos, não um marcador único | A história vai ter missões paralelas e escolhas, que um marcador único não guarda |
| As cenas são um formato próprio, editado na ferramenta Cenas do F2 | As cenas são mais coreografia no mapa de hexágonos do que conversa; tudo fica no editor que o dono já usa |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| A história é a exceção à regra "dados de design moram no banco"; as cenas são arquivos em `res://story/scenes/` | Decisão do dono acima. Consequência: uma cena nova ou um texto corrigido chegam ao jogador numa versão nova do app |
| O servidor nunca dá nada por um Marco | Assim um Marco falso não vale nada, e o servidor não precisa conferir a história |
| Os Marcos só são gravados quando a cena termina, todos juntos | Fechar o app no meio da cena a recomeça do início, sem meio estado |
| Toda cena que não é repetível liga, ao terminar, o Marco com o próprio slug | "Precisa de `avo_chega`" se lê sozinho, e o dono não precisa lembrar de ligar um Marco no fim de cada cena |
| Marcos só são ligados, nunca desligados | São fatos que aconteceram; uma escolha vira Marcos diferentes (`ajudou_fazendeiro` ou `recusou_fazendeiro`). Apagar o progresso já leva os Marcos junto |
| As cenas só rodam em Explorar numa ilha | Explorar já exige um Domador, então sempre há onde gravar os Marcos |
| Testar daqui usa a versão publicada da ilha | O mapa de Explorar vem do servidor, que hoje só monta a versão publicada; testar o rascunho pediria uma rota nova |
| O gatilho de NPC aponta para o `npc_id` do catálogo | O `id` do NPC na ilha muda quando a ilha ganha ou perde NPCs |
| As escolhas e os "se tiver o Marco" levam os passos dentro deles, em vez de saltos | Uma lista com blocos dentro é mais fácil de ler e de editar que "vá para o passo 12" |
| Testar daqui usa Marcos de teste do editor, sem gravar no servidor | O dono testa a cena 30 sem jogar as 29 de antes e sem sujar a conta |

## Fora do escopo

- A forma de tratamento do Domador e a variável de texto dela (vem com a introdução de Liora).
- Cenas antes do Domador existir, como a abertura de Liora antes do nome. A introdução de Liora decide como o começo do jogo muda para isso.
- Música e som nos passos (a música da luta continua como está).
- Retratos (rosto grande) na caixa de fala.
- Pular cena.

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01](01-story-marks.md) | Marcos no servidor: a tabela, o `story_marks` no `GET /v1/me` e a rota que liga Marcos | concluída |
| [02](02-scene-player.md) | O tocador de cenas: o formato, a leitura e a conferência dos arquivos, os gatilhos e os passos de conversa (fala, escolha, se tiver o Marco, ligar Marco, esperar, escurecer) | concluída |
| [03](03-map-steps.md) | Os passos no mapa: pôr e tirar atores, andar, virar, câmera, seguir o Domador e abrir tela | concluída |
| [04](04-scenes-tool.md) | A ferramenta Cenas do F2: a lista de cenas da ilha, o gatilho, os passos com os blocos, pegar hexágono no mapa, salvar e Testar daqui | concluída |
| [05](05-story-line.md) | A Linha da história: as cenas ligadas pelos Marcos, com os avisos | concluída |
| [06](06-scene-timeline.md) | A linha do tempo das cenas: os passos em cartões embaixo do mapa do F2, os ramos em faixas juntas e o painel lateral reorganizado, com o topo, o passo escolhido e as seções dobráveis | concluída |

O desenho que as fases compartilham está em [architecture.md](architecture.md).
