# 03. A ação da peça

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-prop-blocks.md) e [02](02-block-editing.md)

## Contexto

O Refúgio e a Loja abrem hoje pelo hexágono de ação embaixo do objeto de grade. Com o prédio solto e bloqueando por linhas, a ação passa a ser da peça: tocar na arte leva o Domador até o bloqueio, e a ação acontece ao encostar, como na [arquitetura](architecture.md#no-jogo-fases-1-e-3).

## Escopo

- A coluna `island_props.action_type_id` e o campo `action_type_id` da peça no contrato.
- A ação escolhida no editor, na peça escolhida.
- No jogo, o toque na arte das peças com bloqueio ou ação, a caminhada até o bloqueio e a ação.

## Fora do escopo

- Passar as ações dos objetos de grade para as peças ([04](04-objects-to-props.md)).
- Ação padrão do tipo.

## Requisitos

- **RF-01:** A migration `prop_actions` cria a coluna, com FK para `action_types`, que não deixa apagar o tipo em uso.
  - O rascunho e o mapa de uma ilha levam `action_type_id` só nas peças com ação.
  - O hash leva o campo só quando ele aparece.
- **RF-02:** O servidor recusa uma ação que não existe ("A peça N tem uma ação que não existe.") e mais de 500 peças com ação por ilha (`MAX_PROP_ACTIONS`).
- **RF-03:** No editor, a peça escolhida tem a lista Ação ("Nenhuma" e os `action_types`). Trocar a ação é um passo do desfazer.
  - Na camada Ações, o nome da ação aparece acima do pé da peça, na cor do tipo.
  - O Carimbo leva a ação.
- **RF-04:** No jogo, a arte das peças com bloqueio ou ação pega o toque, pelo retângulo e pelo alfa do pixel. Ganha a peça da frente, a do pé mais embaixo. As outras peças deixam o toque passar para o chão.
- **RF-05:** O toque numa dessas peças funciona assim:
  - **O caminho:** o Domador anda pelo caminho mais curto até o ponto das linhas mais perto dele e para rente ao bloqueio, a `WALL_REACH`.
  - **Sem linhas:** o caminho vai até o pé.
  - **A ação:** acontece se ele termina encostado, a até `TOUCH_REACH` (8 px) de uma linha, ou a até 16 px do pé numa peça sem linhas. Já encostado, ela acontece sem andar.
  - **Outro toque:** um toque em outro lugar no meio do caminho troca o destino, e um Domador NPC no caminho para a caminhada. Nos dois casos, a ação não acontece.

## Critérios de aceite

- [x] A ação da peça vai e volta no rascunho, e uma ação que não existe é recusada.
- [x] O hash de uma ilha sem peças com ação não muda.
- [x] A rota até o ponto mais perto termina encostada no bloqueio, sem atravessá-lo.
- [ ] No jogo, tocar num prédio com ação leva o Domador até ele e abre a tela (falta o dono conferir).

## Tarefas

- [x] A migration, o contrato, a validação e os testes.
- [x] A lista Ação no editor, o nome na camada Ações e o Carimbo.
- [x] O toque na arte e a caminhada até o bloqueio em Explorar.

## Resultado da verificação

Em 2026-11-15:

- **Testes de unidade:** a ação que existe e a que não existe, as 500 peças com ação e o hash só com a ação.
- **e2e** (`islands-editor.e2e-spec.ts`): a ação vai e volta com o bloqueio ajustado, e a ação 999999 é recusada com 400.
- **Cena temporária sem janela** (apagada):
  - a `MapProp` lê a ação;
  - o ponto mais perto de quem vem da esquerda fica na borda esquerda da linha fechada;
  - a rota termina a 3 px da linha, encostada, sem atravessá-la.
- **O jogo e o editor** compilam sem erros de script e sem avisos.
- **Não conferido:** o toque na arte com o jogo aberto, porque nenhuma ilha tem prédio solto com ação antes da [04](04-objects-to-props.md).
