# 02. Os patamares e as escadarias

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-cliff-rule](01-cliff-rule.md), [map-realism](../map-realism/), [coast-rivers](../coast-rivers/)

## Contexto

Veja o [README](README.md#contexto). Depois da [fase 1](01-cliff-rule.md), o paredão bloqueia, e o gerador abre encostas onde falta caminho. Esta fase troca as 5 alturas fixas do mapa sorteado (`terrainOf`) por alturas que saem do relevo:

- patamares na terra;
- a Montanha no alto;
- escadarias de vários degraus, além das encostas que a garantia abre.

A água nas alturas, com as cachoeiras, chegou a ser feita e foi desfeita. Na primeira prévia, o dono viu a água isolada no alto e a terra no nível da água, pediu os ajustes e depois decidiu: "Vamos deixar as cachoeiras para depois, desfaça o que fez nelas, todas as aguas vão nascer no plano 0. Depois pensamos a melhor maneira de criar essas cachoeiras." A água fica toda no 0, e as cachoeiras ficam para uma fase futura.

## Escopo

- `server/src/domain/exploration/`: o gerador, as encostas, a configuração e os testes deles.
- Os nomes dos parâmetros novos no `client/tools/map_editor/new_island_panel.gd` (`PARAM_LABELS`).

O gerador de ilha nova do F2 usa o mesmo gerador e ganha tudo isso sem outra mudança.

## Fora do escopo

- A água acima do 0 e as cachoeiras, que ficam para depois.
- O bioma: continua saindo do clima e da forma, como na [map-realism](../map-realism/). Um patamar alto pode ser Planície, Boreal, Deserto ou Neve.
- O formato dos lagos e o caminho dos rios.
- As ilhas salvas.

## Requisitos

**A terra**

- **RF-01:** A terra fora da Montanha e da Praia fica num de 3 patamares pela altitude do relevo (`elevation`, de 0 a 1, do `shapeRelief`), com os limites na configuração (_a revisar_):

  | Altitude | Altura |
  | --- | --- |
  | abaixo de `terraceLow` (0,45) | 1 |
  | de `terraceLow` a `terraceHigh` (0,75) | 4 |
  | de `terraceHigh` para cima | 7 |

- **RF-02:** A Montanha fica de 8 a 10, pela distância até o hexágono mais perto que não é Montanha (a água conta): 8 a 1 hexágono, 9 a 2 e 10 a 3 ou mais (_a revisar_).
- **RF-03:** A Praia fica no 1.

**A água**

- **RF-04:** Toda água fica no 0: o mar, os lagos e os rios. Como a terra começa no 1, nenhuma terra fica no nível da água. Um rio ou um lago no patamar 4 ou 7 fica num cânion, com paredão em volta.

**As pontes e as escadarias**

- **RF-05:** A ponte automática liga margens da mesma altura (`cell.height`). Quando ela não cabe, as duas margens ficam planas na altura da mais alta (`levelBanks`); uma margem de Montanha antes cai para o patamar dela. Uma margem que é de duas pontes leva as outras junto (`levelLinks`).
- **RF-06:** Além das encostas da garantia (fase 1, RF-05), o gerador abre escadarias. Do dono: "devem existir mais degrais juntos, podem sim existir apenas um [...] Mas o ideal é ter mais".
  - Sorteia as bordas de paredão da terra, uma escadaria a cada `rampEvery` delas (25, _a revisar_), a pelo menos 8 hexágonos uma da outra (`RAMP_GAP`, _a revisar_). Na prática, quem limita é essa distância.
  - A escadaria fica no lado baixo do paredão. Os hexágonos do chão de baixo em volta do pé, até uma largura sorteada de 2 a 5 (_a revisar_) mais a fundura, sobem em anéis pela distância até o alto, um degrau por anel.
  - Cada degrau desce 1 nível (70%, _a revisar_) ou 2, até o último ficar a até 2 do chão (`stepLevels`).
  - A escadaria não sobe água, Montanha nem margem de ponte. Ela usa o sorteio das encostas da fase 1.
- **RF-07:** A ordem no `generateShapedMap`:
  1. as alturas da terra (RF-01 a 03) e a água no 0;
  2. as pontes (RF-05);
  3. os pedaços de terra soltos que viram rio ficam no 0;
  4. a montanha solta que vira Colina cai para o patamar dela, e a Montanha refaz as alturas 8 a 10;
  5. as escadarias (RF-06);
  6. a garantia de alcance;
  7. as pedras gigantes.

**A configuração**

- **RF-08:** Entram no `MapConfig`, com os limites dele e os nomes no `PARAM_LABELS`:
  - `terraceLow` e `terraceHigh` (frações; `terraceLow` menor que `terraceHigh`);
  - `rampEvery` (inteiro; 0 não abre nenhuma escadaria).

  O `MOUNTAIN_HEIGHT` passa a ser 8, a borda da Montanha, e o `terrainOf` passa a dar só o bioma.

## Critérios de aceite

Em 60 seeds:

- [x] Toda água fica no 0.
- [x] Toda Montanha fica de 8 a 10, e nenhuma outra terra passa de 7.
- [x] As duas margens de cada ponte têm a mesma altura.
- [x] Toda a terra fora das pedras gigantes se alcança a partir da chegada (o teste da fase 1 continua passando).
- [x] Há os patamares 1, 4 e 7, paredões e degraus nas alturas 2, 3, 5 ou 6.
- [x] Em pelo menos metade dos mapas, há uma escada de 3 degraus seguidos de 1 nível.

E também:

- [x] Os testes do servidor passam, e o jogo abre sem janela, sem erro novo.
- [x] A prévia foi desenhada pelo jogo.
- [ ] O dono conferiu no jogo, em Explorar zona.

## Desenho técnico

- `map-generator.ts`: `terraceOf`, `placeLandHeights` (que põe a água no 0), `placeMountainHeights` e `groundFloor` (a altura de quem deixa de ser Montanha).
  - As alturas ficam em `cell.height`, e o `generateMap` e o `tiles` as usam.
  - O `levelBanks` sobe a margem mais baixa, e o predicado das pontes compara `cell.height`.
- `map-slopes.ts`: `openRamps` (RF-06, com `stepLevels` e `stairsFrom`) e `levelLinks`, ao lado do `openSlopes` da fase 1.
- `map-config.ts`, `map-config.spec.ts` e o `new_island_panel.gd`: os parâmetros novos.
- O `map-generator.spec.ts` troca os testes que olhavam as 5 alturas fixas pelos critérios desta fase.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```

Depois, no jogo, em Explorar zona e no gerador de ilha nova do F2: os patamares, as escadarias e a Montanha no alto.

## Tarefas

- [x] As alturas da terra, com testes.
- [x] A água no 0 (a água nas alturas foi feita e desfeita a pedido do dono).
- [x] As pontes pela altura e o `levelBanks` que sobe.
- [x] As escadarias, com testes.
- [x] Os parâmetros novos no servidor e no F2.
- [x] Os testes das 60 seeds.
- [x] A prévia para o dono.
- [x] A verificação e os documentos (`CLAUDE.md` da raiz e esta spec).

## Resultado da verificação

Em 2026-11-21:

- Primeira prévia (8 mapas, 2 de cada clima, desenhados pelo próprio jogo, o `HexMapView` numa cena temporária):
  - a terra ficou com cerca de 43% no patamar 1, 29% no 4 e 22% no 7, e de 4% a 5% de Montanha;
  - cada mapa teve de 1.560 a 1.970 bordas de paredão.
- O dono pediu dois ajustes na água (a água isolada no alto e a terra no nível da água) e depois decidiu deixar a água toda no 0. Também pediu escadarias de vários degraus no lugar das encostas de 1 hexágono.
- Com as escadarias, cada mapa do tamanho padrão tem de 750 a 920 hexágonos de degrau (antes, de 70 a 100) e leva de 320 a 460 ms para gerar.
- Uma prévia nova mostrou as escadarias de degraus de 1 nível na Planície e no Deserto.
- O lint, o typecheck e os 1103 testes de unidade do servidor passaram, e nos e2e passaram 696 de 698. As 2 falhas (`species_day_phases` e `species_skills`, do `seed.e2e-spec.ts`) já existiam antes.
- O jogo abriu sem janela só com os avisos que já existiam.
