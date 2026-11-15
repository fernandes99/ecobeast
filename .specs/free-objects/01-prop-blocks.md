# 01. O bloqueio das peças

- **Status:** concluída
- **Depende de:** [free-props](../free-props/) e [free-fences](../free-fences/)

## Contexto

As peças soltas nunca bloqueiam. Esta fase dá a elas as linhas de bloqueio da [arquitetura](architecture.md#a-linha-de-bloqueio): no catálogo (do tipo) e na ilha (o ajuste da peça). O servidor passa a contar os hexágonos bloqueados pelas linhas e pelas paredes, e o Domador esbarra nas linhas como esbarra numa cerca.

## Escopo

- A tabela `prop_type_blocks` no catálogo, e a `island_props.custom_block` com a `island_prop_blocks` na ilha.
- O campo `block` da peça no rascunho do editor e no mapa de Explorar numa ilha.
- O `blockedKeys` novo, nas regras da chegada e do nascimento.
- No cliente:
  - o catálogo novo;
  - o `block` da peça no rascunho do editor, guardado e devolvido sem mudar;
  - as linhas no índice de bloqueio do `ExplorationMap`.

## Fora do escopo

- Ver e editar as linhas no editor ([02](02-block-editing.md)).
- A ação da peça ([03](03-prop-actions.md)).
- O toque na arte da peça ([03](03-prop-actions.md)).

## Requisitos

- **RF-01:** A migration `prop_blocks` cria as duas tabelas e a coluna da arquitetura, com os `CHECK` de tamanho dos pontos (pares, de 4 a 128). O `seed-data` ganha `prop_type_blocks.json`, vazio.
- **RF-02:** O `GET /v1/catalog` manda `prop_type_blocks`, e o cliente a espelha no `catalog_schema.gd`. O `GameData.get_prop_blocks(prop_type_id)` devolve as linhas do tipo.
- **RF-03:** O rascunho aceita e devolve o `block` das peças ajustadas, e o mapa de uma ilha o devolve.
  - Uma peça sem o campo usa as linhas do tipo.
  - Com `block: []`, a peça não bloqueia.
- **RF-04:** O servidor recusa o rascunho, com a mensagem da peça, quando uma linha passa dos limites:
  - de 2 a 64 pontos inteiros, e pelo menos 3 numa linha fechada;
  - cada coordenada entre −512 e 512;
  - no máximo 8 linhas por peça.
- **RF-05:** O servidor recusa mais de 2.000 peças que bloqueiam por ilha, contando as linhas do tipo das peças sem ajuste.
- **RF-06:** O `content_hash` leva o `block` só das peças ajustadas. Uma ilha sem ajuste tem o hash de antes.
- **RF-07:** O `blockedKeys` segue a [arquitetura](architecture.md#os-hexágonos-bloqueados-no-servidor-fase-1): as linhas das peças (do tipo ou ajustadas, com o espelho) e as paredes. Ele vale na chegada (`publishError`) e no nascimento (`spawnAreas`), que passam a receber as linhas dos tipos.
- **RF-08:** No jogo, o índice do `ExplorationMap` recebe as linhas das peças no chão plano, e o Domador, os NPCs e quem vaga respeitam as linhas como respeitam as paredes.

## Critérios de aceite

- [x] Uma peça com linha fechada no rascunho volta igual na leitura, e uma sem `block` volta sem o campo.
- [x] A chegada num hexágono tocado por uma linha, ou por uma parede, não deixa publicar.
- [x] As áreas não fazem nascer Ecobeasts num hexágono tocado por uma linha.
- [x] O hash de uma ilha sem peças ajustadas não muda.
- [x] No jogo, o Domador não atravessa a linha de uma peça.
- [x] Os testes do servidor passam, e o jogo abre sem erros de script.

## Verificação

- **Testes de unidade:** o `blocked-hexes` (linha aberta, linha fechada com o centro dentro, espelho), os limites e o hash.
- **Testes e2e:** o rascunho com `block` e a recusa da chegada.
- **Desempenho:** o `blockedKeys` numa ilha com 2.000 peças e 2.000 paredes, com o tempo anotado.
- **No banco:** as ilhas cuja chegada passaria a ficar num hexágono bloqueado pelas paredes, listadas ao dono.
- **Cena temporária sem janela:** o `crosses_wall` com a linha de uma peça.

## Tarefas

- [x] A migration, o schema e o catálogo.
- [x] O rascunho, a leitura, a gravação e o mapa de Explorar com o `block`.
- [x] O `blockedKeys` novo e os testes.
- [x] O cliente: o catálogo, o `MapProp`, o `IslandDraft` do editor e o índice do `ExplorationMap`.
- [x] A conferência no banco e a documentação.

## Resultado da verificação

Em 2026-11-15:

- **Testes de unidade** (`npm test`, 898): o `blocked-hexes.spec.ts` confere:
  - a linha curta e a que cruza dois hexágonos;
  - a fechada com os centros dentro;
  - as linhas do tipo e o `[]` que não bloqueia;
  - o espelho e as paredes.
  O `island-draft.spec.ts` confere os limites das linhas, as 2.000 peças que bloqueiam, a chegada tocada por uma linha ou por uma parede e o hash. O `area-spawns.spec.ts` confere o nascimento fora dos hexágonos tocados.
- **Testes e2e** (`islands-editor.e2e-spec.ts`, 59, e `catalog.e2e-spec.ts`, 48): o bloqueio ajustado vai e volta, a linha fora dos limites é recusada, e a chegada tocada por uma linha ou por uma parede não deixa publicar.
- **Desempenho:** o `blockedKeys` de uma ilha com 2.000 peças com linha fechada e 2.000 paredes levou 45 ms.
- **No banco:** nas 15 versões de ilha (2 com paredes), nenhuma chegada passa a ficar num hexágono bloqueado.
- **Cena temporária sem janela** (apagada):
  - a linha fechada ajustada barra quem entra;
  - a linha do tipo, espelhada, barra só do lado certo;
  - o caminho dá a volta pela peça.
- **O jogo sem janela** abre contra o servidor local, com a `prop_type_blocks` no catálogo, sem erros de script nem avisos. O servidor da porta 3100 precisou ser reiniciado pelo dono: o watch não recompilou o cliente novo do Prisma.
- **Não conferido:** uma peça com bloqueio numa ilha de verdade, que só existe depois da [02](02-block-editing.md).
