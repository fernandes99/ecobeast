# 04. Os objetos de grade viram peças

- **Status:** concluída (falta o dono conferir no jogo e no editor)
- **Depende de:** [01](01-prop-blocks.md), [02](02-block-editing.md) e [03](03-prop-actions.md)

## Contexto

Com as peças bloqueando por linhas e com ação, os objetos de grade sobram. Esta fase os converte em peças soltas, no mesmo lugar, e apaga a camada de objetos do banco, do servidor e do jogo, como na [arquitetura](architecture.md#a-conversão-fase-4).

## Escopo

- A migration `objects_to_props`, conferida antes no banco real.
- O servidor e o catálogo sem os objetos, com a carga inicial (`seed-data`) acompanhando.
- O jogo e o editor sem os objetos, com a arte dos prédios em `assets/props/`.

## Requisitos

- **RF-01:** Os tipos `map_object_types` 21, 22, 24, 25, 26 e 41 viram os tipos de peça 22 a 27, com o mesmo `slug`, nome e variantes:

  | Tipo antigo | Peça | Slug |
  | --- | --- | --- |
  | 21 | 22 | `refuge_building` |
  | 22 | 23 | `shop_building` |
  | 24 | 24 | `town_house` |
  | 25 | 25 | `town_house_medium` |
  | 26 | 26 | `town_house_large` |
  | 41 | 27 | `observatory` |

- **RF-02:** Cada tipo novo ganha uma linha fechada de bloqueio: o contorno dos hexágonos do formato, 4 px para dentro, a partir do pé.

  | Formato | Tipos | Pontos |
  | --- | --- | --- |
  | 1 hexágono | 24 | `0,-54  28,-40  28,-18  0,-4  -28,-18  -28,-40` |
  | 2 hexágonos | 25 | `-32,-54  0,-38  32,-54  60,-40  60,-18  32,-4  0,-20  -32,-4  -60,-18  -60,-40` |
  | 3 hexágonos | 22, 23, 26 e 27 | `0,-20  -32,-4  -60,-18  -60,-40  -28,-56  -28,-82  0,-96  28,-82  28,-56  60,-40  60,-18  32,-4` |

  Cada uma toca só os hexágonos do formato: a conta foi conferida antes de escrever a migration.
- **RF-03:** Cada objeto vira uma peça sem ajuste, com a variante e o espelho dele:
  - o pé fica no ponto de hoje: o x é a média dos centros planos dos hexágonos do objeto, e o y é o maior y mais 29;
  - o hexágono do pé é o que a conta do `grid_coord` dá. Na prática, ele cai na linha da frente, porque o pé fica na borda de baixo.
- **RF-04:** As ações:
  - uma ação que tinha hexágonos embaixo de um objeto passa para a peça;
  - com mais de uma, a peça fica com a de mais hexágonos ali;
  - esses hexágonos saem da ação, e a ação que fica sem nenhum sai.
- **RF-05:** Os hexágonos dos objetos ficam com a marca `bare`, como se a Borracha tivesse passado neles, porque não tinham decorações sorteadas.
- **RF-06:** Saem:
  - as quatro tabelas dos objetos e os modelos do Prisma;
  - o campo `objects` do rascunho e do mapa;
  - as tabelas do catálogo (de 43 para 41) e a carga inicial delas.

  Depois da migration, o `prisma/recompute-island-hashes.ts` recalcula o hash das ilhas, porque o rascunho canônico perdeu a chave `objects`.
- **RF-07:** No cliente saem:
  - o `MapObject` e o `MapObjectSprite`;
  - os objetos do `HexMapView`, do `ExplorationMap` e da tela de Explorar;
  - a lista de tipos de grade do `ObjectPanel` e a parte de objetos do editor.

  A arte dos prédios vai para `assets/props/<slug>/`, e o `make_town.gd` passa a gravar lá. Um carimbo antigo com `objects` converte cada objeto em peça ao ser posto, pela regra do RF-03.
- **RF-08:** Sem compatibilidade com um APK de antes desta fase (decisão do dono em 2026-11-15).

## Critérios de aceite

- [x] A migration, num teste dentro de uma transação desfeita, converte os 14 objetos do banco em 14 peças, todas com o pé dentro do próprio hexágono.
- [x] Os 6 tipos novos têm uma linha fechada cada um, e os hexágonos dos objetos ficam com a marca `bare`.
- [x] O servidor, os testes de unidade e a suíte e2e passam sem os objetos.
- [x] O jogo e o editor compilam sem erros de script e sem avisos.
- [ ] Numa ilha, os prédios aparecem no mesmo lugar, e o Domador esbarra na linha deles (falta o dono conferir).

## Tarefas

- [x] A migration, conferida no banco antes de aplicar, e os hashes recalculados.
- [x] O servidor, a carga inicial e os testes.
- [x] O cliente, a arte e o `make_town.gd`.
- [x] A documentação.

## Resultado da verificação

Em 2026-11-15:

- **No banco**, antes de aplicar, numa transação desfeita:
  - 14 objetos viraram 14 peças, nenhuma com o pé fora do hexágono;
  - nenhuma tinha ação embaixo;
  - nenhuma ficou com o pé num hexágono de altura diferente do de apoio;
  - nenhum objeto tinha bloqueio diferente do tipo.
- **Depois de aplicar:** os 15 hashes de versão de ilha foram recalculados.
- **Servidor:**
  - `npm run lint`, `npm run typecheck` e `npm test` passam (887 testes);
  - a suíte e2e passou em 568 de 570 testes. Os 2 que falharam eram do próprio trabalho e foram corrigidos e rodados de novo, passando:
    - o número de tabelas (agora 62, mais o histórico);
    - os ids das 6 linhas de `prop_type_blocks`, que o e2e da [02](02-block-editing.md) tinha deixado fora de 1 a 6 e foram renumerados.
- **Cliente:** o editor e o jogo compilam sem erros de script, e o jogo sobe sem avisos. Uma cena temporária (apagada) conferiu:
  - os tipos 22 a 27 no catálogo e a arte deles pelo `PropArt`;
  - pôr, espelhar, editar o bloqueio, apagar e desfazer uma peça no editor;
  - o carimbo antigo com objetos virando peças, com o pé certo, inclusive espelhado.
- **Corrigido de passagem:** o F2 travava ao abrir, porque o `block_preview` da [02](02-block-editing.md) era ligado antes de o canvas existir.
- **Limite:** um objeto de carimbo antigo com bloqueio diferente do tipo vira uma peça com as linhas do tipo.
- **Não conferido:** os prédios numa ilha com o jogo aberto, o Domador esbarrando neles e o editor aberto.
