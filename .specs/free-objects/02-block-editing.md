# 02. A edição dos bloqueios no editor

- **Status:** concluída (falta o dono conferir no editor)
- **Depende de:** [01](01-prop-blocks.md)

## Contexto

A [01](01-prop-blocks.md) guarda as linhas de bloqueio, mas nada as mostra nem as edita. Esta fase dá ao editor (F2) a camada Bloqueios e o modo de editar o bloqueio da peça escolhida, além da rota que salva as linhas de um tipo.

## Escopo

- A rota `PUT /v1/editor/prop-types/:id/blocks`.
- A camada Bloqueios do editor, com as linhas e os hexágonos bloqueados.
- O modo de edição do bloqueio de uma peça solta, com o "Usar o do tipo" e o "Salvar como do tipo".
- O Carimbo levando o bloqueio ajustado.

## Fora do escopo

- A ação da peça ([03](03-prop-actions.md)).
- O bloqueio por hexágono dos objetos de grade, que continua no mesmo botão de cadeado até a [04](04-objects-to-props.md).

## Requisitos

- **RF-01:** A rota troca as linhas do tipo numa transação, libera o catálogo novo e devolve as linhas e as versões de ilha com a chegada bloqueada, como na [arquitetura](architecture.md#o-catálogo-prop_type_blocks-fase-1).
  - Ela recusa uma linha fora dos limites com 400 e um tipo que não existe com 404.
  - Só quem está em `MAP_EDITOR_USER_IDS` pode chamá-la.
- **RF-02:** A camada Bloqueios (painel Camadas, ligada ao abrir) mostra:
  - um X em cada hexágono que o servidor conta como bloqueado (`IslandBlocks`, a mesma conta do `blocked-hexes.ts`, mais os hexágonos que bloqueiam dos objetos de grade);
  - as linhas das peças, tracejadas: as do tipo em `WARNING` e as ajustadas em `ACCENT`.
- **RF-03:** Com uma peça solta escolhida, o cadeado da barra da peça (ou do painel) liga a edição do bloqueio:
  - os pontos aparecem;
  - arrastar um ponto o move;
  - clicar num trecho põe um ponto ali, já arrastável;
  - o botão direito num ponto o apaga, e uma linha com menos pontos do que precisa abre ou some;
  - "Nova linha" desenha a cliques. Enter ou o botão direito terminam, clicar no primeiro ponto (com 3 ou mais) termina e fecha, e Esc desiste;
  - "Fechar linha" e "Abrir linha" trocam a linha mexida por último;
  - Esc fora do desenho sai do modo.
  
  Os pontos ficam a até 6 px do ponteiro (`EditorTools.BLOCK_PICK`) e são guardados a partir do pé, sem o espelho.
- **RF-04:** A primeira mudança copia as linhas do tipo para a peça, que fica ajustada.
  - "Usar o do tipo" apaga o ajuste.
  - Cada mudança é um passo do desfazer.
- **RF-05:** "Salvar como do tipo":
  - pergunta antes, porque vale para todas as ilhas;
  - chama a rota e troca as linhas do tipo no catálogo local;
  - volta a peça para as do tipo;
  - avisa as ilhas com a chegada bloqueada.
- **RF-06:** O Carimbo guarda e põe o `block` das peças, sem mexer nos pontos ao espelhar, porque o espelho é da peça.

## Critérios de aceite

- [x] A rota troca as linhas, e o `GET /v1/catalog` seguinte as traz.
- [x] A rota recusa uma linha fora dos limites e um tipo que não existe.
- [x] Pôr, arrastar e apagar pontos e desenhar uma linha fechada deixam a peça ajustada, com os pontos certos na peça espelhada.
- [x] "Usar o do tipo" volta a peça para as linhas do tipo.
- [ ] No editor aberto, as linhas e os X aparecem e acompanham a peça arrastada (falta o dono conferir).
- [ ] "Salvar como do tipo" no editor aberto (falta o dono conferir).

## Tarefas

- [x] A rota e o e2e dela.
- [x] O `IslandBlocks`, as funções do `IslandDraft` e o catálogo local.
- [x] O modo de edição no `ObjectPanel` e no `EditorTools`.
- [x] O desenho no `EditorCanvas` e os atalhos e o aviso no `MapEditor`.
- [x] O Carimbo.

## Resultado da verificação

Em 2026-11-15:

- **e2e** (`prop-types-editor.e2e-spec.ts`, no grupo que grava no catálogo):
  - a rota troca as linhas, e o catálogo novo as traz;
  - ela volta a `[]`;
  - ela recusa a linha fechada de 2 pontos (400) e o tipo 999999 (404);
  - ela lista a ilha cuja chegada ficou bloqueada.
- **Cena temporária sem janela** (apagada), com o `EditorTools` e o `ObjectPanel` de verdade numa peça espelhada. Ela confere:
  - as contas do pé e do espelho;
  - a linha fechada desenhada a cliques;
  - o ponto arrastado, que vira um passo do desfazer;
  - o ponto posto num trecho e o apagado pelo botão direito;
  - a linha fechada no chão plano e os hexágonos que ela toca;
  - o "Usar o do tipo".
- **O jogo e o editor** compilam sem erros de script e sem avisos.
- **Não conferido:** o desenho no editor aberto e o "Salvar como do tipo" com a janela, porque precisam da sessão do dono.
