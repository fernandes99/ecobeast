# 33. A área Triângulo, de 3 hexágonos

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-skill-areas.md) e [02](02-board-engine.md) (as áreas e a luta no tabuleiro)

## Contexto

Em 2026-11-20, o dono pediu: "Na chama espiral eu gostaria de escolher uma área de 3 hexagonos. Hoje o dano por área é só uma área." Das três formas mostradas (triângulo, onda atravessada e livre), ele escolheu o **triângulo**: o hexágono tocado e os 2 vizinhos dele do lado de lá, longe de quem usa.

No mesmo pedido, ele quer, para uma Técnica do futuro, "o chão em chamas por onde o projétil passar". Isso já existe: uma Técnica de Linha reta com marca no chão marca todos os hexágonos do caminho, até o primeiro inimigo, ou até o fim do alcance se atravessa (`lineArea` e `placeMarks`). Basta criá-la no Editar do F1, sem código novo.

## Escopo

- A forma nova `triangle` ("Triângulo") em `area_shapes`, na luta, na IA, no jogo e no Editar do F1.
- A Chama Espiral passa a usar o Triângulo.

## Fora do escopo

- Escolher a inclinação do triângulo à mão.
- A IA mirar para pegar mais de um inimigo: ela continua mirando no hexágono do inimigo, que sempre fica dentro do triângulo.
- Uma Técnica nova com o rastro de fogo da Linha reta.
- Dano menor por dividir a área: cada inimigo no triângulo leva o dano inteiro, como na linha que atravessa.

## Requisitos

- **RF-01:** `area_shapes` ganha o id 3, `triangle`, "Triângulo".
- **RF-02:** O alvo de uma Técnica de Triângulo é um hexágono do tabuleiro a até `range` de quem usa, sem contar o próprio hexágono, de onde ele está depois de andar. A área é esse hexágono (o **vértice**) e os 2 vizinhos dele mais longe de quem usa, que são vizinhos entre si. Os hexágonos fora do tabuleiro ficam de fora, e a área pode ter só 1 ou 2.
- **RF-03:** Quando o vértice está numa das 6 retas de quem usa, há dois triângulos possíveis. O escolhido é o que tem mais inimigos de pé. Se der empate, ganha o que tem mais hexágonos no tabuleiro, e depois o que gira no sentido horário a partir da reta. O jogo e o servidor usam a mesma regra (_a revisar_).
- **RF-04:** Sem marca no chão, o alvo precisa de pelo menos um inimigo de pé no triângulo. Sem ele, a Técnica é recusada com "Não há inimigo nesse hexágono.". Com marca no chão, como a Chama Espiral, qualquer vértice ao alcance vale.
- **RF-05:** Cada inimigo de pé no triângulo recebe a Técnica inteira: o acerto, o dano e os efeitos são sorteados para cada um, como na linha que atravessa. Os aliados no triângulo não são atingidos. A marca no chão vai para todos os hexágonos da área.
- **RF-06:** No `skill_used`, `cells` traz a área com o vértice por último, porque o projétil voa até o último hexágono.
- **RF-07:** No jogo, depois de tocar na Técnica, os vértices ao alcance acendem, como hoje. O 1º toque num vértice acende o triângulo dele, na cor da área. O 2º toque, em qualquer hexágono desse triângulo, usa a Técnica, e um toque em outro vértice troca o triângulo (_a revisar_). As formas Um alvo e Linha reta continuam com um toque só.
- **RF-08:** O `CatalogValidator` do jogo e as regras do Editar do F1 aceitam o `triangle`. Uma Técnica para o time continua só com Um alvo.
- **RF-09:** A Chama Espiral (`chama_espiral`) passa para o Triângulo, com o mesmo alcance 3, a marca de fogo por 6 vezes e o resto igual. A descrição vira "Envolve 3 hexágonos numa espiral de fogo, com 10% de chance de deixar cada alvo Queimado." (_a revisar_).

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| No empate, o triângulo que pega mais inimigos | Sem escolha à mão, o jogo faz o que o jogador ia querer |
| Dois toques só no Triângulo | Com 3 hexágonos e a inclinação automática, o jogador precisa ver a área antes de gastar a vez |
| A IA mira no inimigo, como hoje | O inimigo sempre fica dentro do triângulo, e mirar em dois é outra entrega |

## Critérios de aceite

- [x] Unidade (`areas.spec.ts`): o vértice fora da reta dá um triângulo só, o vértice na reta escolhe o lado com mais inimigos, e no empate o horário; os hexágonos fora do tabuleiro saem, e sem marca e sem inimigo a Técnica é recusada.
- [x] Unidade (`board-engine.spec.ts`): dois inimigos no triângulo levam dano os dois, o aliado no triângulo não, e a marca fica nos 3 hexágonos.
- [x] A migração aplica sobre o banco de hoje, e o `GET /v1/catalog` traz o `triangle` e a Chama Espiral com ele.
- [x] O jogo abre sem erro do `CatalogValidator`, e o `BoardGeometry` dá a mesma área do servidor nos casos da unidade.
- [x] Testes de unidade, lint, typecheck e os e2e da luta passam.
- [x] Numa cena temporária com a conta do dono, o Testar técnica 2×2 da Chama Espiral acendeu o triângulo no 1º toque, usou no 2º, e o servidor pôs o fogo nos mesmos 3 hexágonos.
- [ ] No jogo, pelo Testar técnica em 2×2 ou 3×3, a Chama Espiral acende o triângulo no 1º toque, usa no 2º e põe fogo nos 3 hexágonos.

## Desenho técnico

**Banco:** uma migração nova insere a linha 3 em `area_shapes` e faz o `UPDATE` da Chama Espiral pelo `slug`. O `server/prisma/seed-data/area_shapes.json` e o `skills.json` ganham o mesmo.

**Servidor:** `AreaShape` em `server/src/domain/battle/types.ts` ganha `'triangle'`, e `areaOf` em `server/src/domain/board/areas.ts` ganha `triangleArea`. As regras do Editar (`skill-draft.ts`) já leem as áreas do banco.

**Jogo:**

- `AREA_SHAPES` em `res://core/data/catalog_schema.gd` com o `triangle`.
- `BoardGeometry.targets` e `BoardGeometry.area` em `res://domain/rules/board_geometry.gd`, com a mesma regra do servidor.
- O 1º e o 2º toque no `_on_cell_tapped` da `board_battle_screen.gd`.

**Specs:** a tabela `area_shapes` em `.specs/game-data/architecture.md`, e a linha desta fase no `README.md` da iniciativa.
