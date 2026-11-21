# Arquitetura

O desenho que as fases compartilham. O que não aparece aqui segue o [battle-core/architecture.md](../battle-core/architecture.md) e a [battle-slots/architecture.md](../battle-slots/architecture.md): dano, precisão, status, Traços, itens, captura, XP e moedas não mudam.

A luta contra um Domador NPC é a mesma, com `opponent: 'tamer'`: sem Esfera, sem fuga, e XP e moedas maiores ([npc-tamers/architecture.md](../npc-tamers/architecture.md#luta-contra-domador)). As moedas do fim contam quem estava em campo na última vez, inclusive quem acabou de cair: até a [npc-tamers/02](../npc-tamers/02-tamer-rules.md), a derrota no tabuleiro contava a vaga já vazia como nível 1 e tirava moedas demais.

## Tabuleiro

O tabuleiro é uma lista de hexágonos, com a ponta para cima, em **coordenadas axiais** `{q, r}`, as mesmas do mapa de Explorar zona (`server/src/domain/exploration/hex.ts`). A distância é `hexDistance`, e os vizinhos são `hexNeighbors`.

O tamanho é sorteado a cada luta pelo servidor ([board-size/01](../board-size/01-board-size-rules.md)): o `BoardBattleService.begin` chama o `rollBoardSize(slots, random)`, que sorteia as colunas e depois as linhas, cada uma uniforme na faixa do formato pedido (_a revisar_), e o tamanho fica no `Board.size`. A vista manda `cells`, `zones`, `columns` e `rows`.

| Formato | Colunas e linhas |
| --- | --- |
| 1×1 | de 4 a 10 |
| 2×2 | de 6 a 12 |
| 3×3 | de 8 a 16 |

Depois, o `biteBoard` tira de 1 a 5 mordidas da borda ([board-size/03](../board-size/03-board-bites.md)): cada uma, de 1 a 3 casas juntas, começa numa casa da borda e fica a até 1 hexágono dela, sem tirar as casas de começo de 1, 2 e 3 vagas nem os vizinhos delas, sem partir o tabuleiro e deixando pelo menos 80% das casas (`rollBoard` faz as duas coisas, e o serviço entrega o tabuleiro pronto ao motor, pela opção `board`). As zonas perdem as casas que saíram, e o `Board.size` continua o retângulo sorteado.

Sem tabuleiro, o motor usa o `makeBoard()` padrão, de `DEFAULT_BOARD_SIZE`, 3 × 6, o tabuleiro que valeu até a board-size (os testes do motor continuam nele). O 3 × 6 veio de 6 × 7 na [06](06-board-look.md), decisão do dono em 2026-11-05: os hexágonos ficavam pequenos na tela; hoje a pinça resolve isso num campo grande. A linha 0 fica em cima, e as linhas ímpares ficam deslocadas meio hexágono para a direita. A casa da coluna `c` na linha `r` é `{q: c - floor(r / 2), r}`.

**Largada:** com `rows` linhas, a linha da frente do inimigo é `floor((rows - 4) / 2)`, e a do jogador fica 3 linhas abaixo dela: os dois lados começam perto do meio, a 3 hexágonos, como no 3 × 6 (linhas 1 e 4). A área de cada lado é a linha da frente e a de trás dela (acima do inimigo, abaixo do jogador), se houver, de ponta a ponta. As colunas ficam em volta do centro `c = floor((columns - 1) / 2)`:

| Vagas | Colunas |
| --- | --- |
| 1 | `c` |
| 2 | `c - 1` e `c + 1` |
| 3 | `c - 2`, `c` e `c + 2`, ou `c - 1`, `c` e `c + 1` quando não cabem |

**Constantes** (_a revisar_), em `server/src/domain/board/board.ts`: `BOARD_SIZE_RANGES`, `DEFAULT_BOARD_SIZE` e `MOVE_RANGE = 1`. O andar começou em 3 e passou para 1 na [05](05-board-actions.md), decisão do dono em 2026-11-05, depois de jogar a tela: 3 hexágonos cobriam quase o tabuleiro todo. O jogo usa o mesmo número, em `BoardGeometry.MOVE_RANGE`.

## Estado

O motor do tabuleiro usa o `BattleState` da battle-slots, com as vagas e o `Spot {side, position}`. A posição é a vaga, de 0 a 2, e continua a mesma enquanto o Ecobeast fica no tabuleiro. O que o tabuleiro acrescenta:

```ts
interface BoardState extends BattleState {
  board: Board; // os hexágonos e as duas áreas
  /** Por lado e por vaga: onde está quem ocupa a vaga, ou null com a vaga vazia. */
  cells: Record<SideSlug, (HexCoord | null)[]>;
  marks: GroundMark[];
  round: number;
  /** O que falta da rodada, na ordem. O primeiro é quem joga agora. */
  queue: QueueEntry[]; // Spot e o teamIndex de quem ocupava a vaga
  /** No `choose_next`: onde quem entra pode ficar. */
  entryCells: HexCoord[];
}

interface Board {
  cells: HexCoord[];
  zones: Record<SideSlug, HexCoord[]>;
}

interface GroundMark {
  cell: HexCoord;
  groundEffectId: number;
  /** Quantas vezes da fila ainda faltam. */
  remaining: number;
}
```

Um hexágono tem no máximo um Ecobeast e uma marca. As fases são as de hoje: `choose_action`, quando o primeiro da fila é do jogador; `choose_next`, quando o jogador precisa escolher quem entra; e `ended`.

## Rodada e vez

1. **Começo da rodada:** a fila recebe todos os Ecobeasts de pé no tabuleiro, dos dois lados, pela Velocidade efetiva, com estágios e paralisia, como no cálculo de hoje. O empate é sorteado, e a prioridade das Técnicas não conta. Evento `round_started`.
2. **A vez:** o primeiro da fila joga. Evento `vez_started`. Quem dorme, está congelado ou perde a vez pela paralisia ou pelo medo não anda nem age, com o `cannot_act` de hoje. Quem está atordoado não anda, mas age ([puffcoo-line/01](../puffcoo-line/01-field-rules.md)).
3. **Andar (opcional):** até `MOVE_RANGE` passos, por hexágonos do tabuleiro sem nenhum Ecobeast. Marcas não bloqueiam. Evento `moved`, com o caminho que o servidor escolheu, um dos mais curtos.
4. **Agir (opcional):** uma Técnica, um item, uma troca, uma Esfera ou fugir. Sem ação, é `wait`, e o evento é `waited`.
5. **Fim da vez**, nesta ordem:
   1. o dano de status de quem jogou (queimadura, veneno), como no fim do turno de hoje;
   2. as marcas agem sobre cada Ecobeast de pé num hexágono marcado, em ordem de lado (jogador, depois inimigo) e de vaga;
   3. cada marca perde 1 de `remaining`, e a que chega a 0 some, com `mark_ended`;
   4. quem desmaiou deixa o tabuleiro, com `creature_left`, e as vagas são repostas como em [Entrada](#entrada);
   5. o fim da luta é conferido.
6. O primeiro da fila sai. Com a fila vazia, começa a próxima rodada.

**Contadores:** sono e confusão contam as vezes do próprio Ecobeast, como hoje contam os turnos. A proteção dura até a próxima vez de quem a usou. O medo faz perder a próxima vez de quem o sofreu. O que hoje se limpa no fim do turno (`status.ts`) passa a se limpar no fim da vez do próprio Ecobeast.

**Uma resposta, várias vezes:** depois da vez do jogador, o servidor joga as vezes dos selvagens até chegar a uma vez do jogador, um `choose_next` ou o fim. A resposta traz os eventos de tudo isso, na ordem.

## Técnicas no tabuleiro

Cada Técnica tem, no catálogo ([01](01-skill-areas.md)):

| Campo | O que é |
| --- | --- |
| `area_shape` | `single`: um hexágono a até `range` de distância. `line`: uma linha reta, numa das 6 direções, com `range` hexágonos. `triangle`: o hexágono a até `range` e os 2 vizinhos dele mais longe de quem usa ([33](33-triangle-area.md)) |
| `range` | De 1 a 6. Com `single` e 1, é o corpo a corpo |
| `pierces` | Só na `line`: atravessa os inimigos em vez de parar no primeiro |
| `ground_effect_id` e `ground_turns` | A marca que fica no chão e por quantas vezes da fila. Os dois nulos: sem marca |

Uma Técnica em si mesmo (`skill_target` `self`) ignora a forma e não pede alvo. O padrão de toda Técnica é `single` com alcance 1.

**Alvo:** a ação manda `target: {q, r}`, um hexágono.

- **`single` sem marca:** o alvo precisa ter um inimigo a até `range`.
- **`single` com marca:** o alvo pode ser qualquer hexágono a até `range`, até vazio, porque a marca fica mesmo sem ninguém.
- **`line`:** o alvo precisa estar numa das 6 linhas retas que saem de quem usa, a até `range`, e escolhe a direção. A linha anda `range` hexágonos ou até a borda. Aliados não param a linha nem são atingidos. Sem `pierces`, ela para no primeiro inimigo; com, atinge todos os inimigos no caminho. Uma linha que não atinge ninguém gasta o PP e a vez.
- **`triangle`:** o alvo é um hexágono a até `range`, o vértice, e a área junta os 2 vizinhos dele mais longe de quem usa. Numa das 6 retas há dois triângulos: fica o com mais inimigos, depois o com mais hexágonos no tabuleiro, depois o que gira no sentido horário. Cada inimigo no triângulo recebe a Técnica inteira, os aliados não, e a marca no chão vai para os 3 hexágonos. Sem marca, o triângulo precisa de um inimigo. No jogo, o 1º toque acende o triângulo e o 2º usa ([33](33-triangle-area.md)).

**Atingidos:** cada inimigo atingido sofre a Técnica inteira, com o próprio sorteio de precisão, de crítico e de efeito, na ordem do caminho. O evento `skill_used` leva `cells`, os hexágonos da área, para o jogo desenhar.

**Marca:** fica em cada hexágono da área. Na linha, até onde ela parou, inclusive. Uma marca nova num hexágono substitui a antiga. Evento `mark_placed`.

**Recusas novas** (pt-BR): "Esse hexágono está fora do alcance.", "Não há inimigo nesse hexágono.", "A linha só anda em linha reta.", "Não dá para chegar lá.", "Não é a vez desse Ecobeast.", "Fugir não combina com andar.", "Esse hexágono não está livre para entrar.".

## Marcas no chão

A tabela `ground_effects` diz o que cada marca faz, depois de cada vez da fila, a quem estiver no hexágono:

| Coluna | O que faz |
| --- | --- |
| `damage_percent` | Dano de uma porcentagem do HP máximo, no mínimo 1. Evento `ground_damage` |
| `heal_percent` | Cura de uma porcentagem do HP máximo, no mínimo 1, sem passar do máximo, depois do dano e só em quem ainda está de pé. Evento `ground_heal`; com o HP cheio, nada. Desde a [field-effects/01](../field-effects/01-field-rules.md) |
| `status_condition_id` | Tenta aplicar o status, com as imunidades e as regras de hoje. Quem já tem esse status ou é imune a ele é pulado, sem evento. Evento `status_applied` |
| `ground_effect_stats` (tabela filha) | Muda os estágios de quem **acabou de jogar** e terminou a vez na marca, uma linha por atributo, com o limite de ±6. Evento `stat_changed`. Desde a [puffcoo-line/01](../puffcoo-line/01-field-rules.md) |

A marca age em qualquer Ecobeast, dos dois lados, inclusive em quem a criou. Andar por cima não aplica nada. O dano e o status agem em todos que estão na marca depois de cada vez; os atributos, só em quem acabou de jogar. O Atordoado de quem jogou acaba no fim da vez dele, antes de as marcas agirem, e o Preso, o Encharcado e o Brotando contam uma vez dele no mesmo ponto, depois da cura do Brotando ([field-effects/01](../field-effects/01-field-rules.md)). A primeira marca é `fire`, "Chão em chamas", com `damage_percent` 6 (_a revisar_, cerca de 1/16, como a queimadura).

## Entrada

- **Começo:** cada vaga recebe o próximo de pé da equipe, como na battle-slots, no hexágono de largada dela.
- **Queda, lado do jogador:** com reserva de pé, a fase vira `choose_next`, com `pendingPositions` e `entryCells`: os hexágonos livres da área do jogador, ou, com ela cheia, os livres mais perto dela. O jogador manda um `switch` por vaga pendente, com `team_index` e `cell`. Sem reserva, a vaga fica vazia.
- **Queda, lado do inimigo:** com reserva, quem entra vai para o primeiro hexágono livre da área do inimigo, linha da frente primeiro, colunas em ordem.
- **Troca do jogador:** gasta a vez. Quem entra fica no hexágono de quem saiu.
- Quem entra recebe o Traço de entrada e só joga na rodada seguinte, porque a fila da rodada já foi montada. Evento `creature_entered`, com `cell`.

## A vez dos selvagens

A IA joga cada vez de selvagem no servidor, em `server/src/domain/board/board-ai.ts`:

1. **Alvo:** o Ecobeast do jogador de pé mais perto, com empate sorteado.
2. **Andar:** se alguma Técnica com PP e dano já atinge um Ecobeast do jogador de onde ele está, ele fica. Senão, anda até o hexágono alcançável mais perto do alvo. Entre hexágonos igualmente bons, prefere os sem marca e depois sorteia.
3. **Agir:** entre as Técnicas que atingem algum Ecobeast do jogador do hexágono final, e as em si mesmo, ele escolhe pelo peso de hoje (`skillWeight`, contra o alvo). Sem nenhuma, espera. Sem PP em todas, usa a Técnica de emergência, corpo a corpo, se tiver alguém ao lado.

## Eventos

Os eventos de hoje continuam, com `side` e `position`. Os novos e os que mudam:

| Evento | Campos |
| --- | --- |
| `round_started` | `round`, `queue: {side, position}[]` |
| `vez_started` | `side`, `position` |
| `moved` | `side`, `position`, `path: {q, r}[]` (sem a origem, até o destino) |
| `waited` | `side`, `position` |
| `skill_used` | os de hoje e `cells: {q, r}[]` |
| `mark_placed` | `cell`, `ground_effect_id`, `remaining` |
| `mark_ended` | `cell` |
| `ground_damage` | `side`, `position`, `amount`, `hp`, `ground_effect_id` |
| `ground_heal` | `side`, `position`, `amount`, `hp`, `ground_effect_id`: a cura de uma marca ([field-effects/01](../field-effects/01-field-rules.md)) |
| `status_heal` | `side`, `position`, `status`, `amount`, `hp`: a cura do Brotando no fim da vez ([field-effects/01](../field-effects/01-field-rules.md)) |
| `multi_hit` | `side`, `position` (do alvo), `hits`: depois dos `damage` de uma Técnica de vários golpes ([puffcoo-line/01](../puffcoo-line/01-field-rules.md)) |
| `creature_entered` | os de hoje e `cell` |
| `capture_attempted` | os de hoje, com `target` sendo a posição do selvagem |

## API

Rotas novas, ao lado das antigas, num `BoardBattleController` em `server/src/board-battle/`. O Domador tem no máximo uma luta, de qualquer tipo, e começar uma descarta a outra, como hoje.

| Rota | Corpo | O que faz |
| --- | --- | --- |
| `POST /v1/me/board-battle` | `enemies` e `slots`, como a batalha de teste de hoje | A luta de teste, com `ENABLE_TEST_BATTLE` |
| `POST /v1/me/board-battle/wild` | `q`, `r` e `god`, como `/battle/wild` | O encontro de Explorar zona, com 1 vaga |
| `POST /v1/me/board-battle/action` | `{position, move?, action}` ou, no `choose_next`, `{entries: [{position, team_index, cell}]}` | A vez do jogador |

`action` é `{type: 'skill', slot, target?}`, `{type: 'emergency', target?}`, `{type: 'item', item_id, team_index}`, `{type: 'switch', team_index}`, `{type: 'capture', item_id, target}`, `{type: 'flee'}` ou `{type: 'wait'}`. `move` e `target` são `{q, r}`.

A resposta é `{battle, events}`, como hoje, e `battle` acrescenta ao DTO de hoje `round`, `board`, `marks`, `queue`, a `cell` de cada Ecobeast em campo e, no `choose_next`, `entry_cells`. Os nomes exatos ficam na [03](03-board-api.md).

## Jogo

Em `client/`:

- **Modelos:** `BoardBattleView`, `BoardTurn` e `GroundMark` em `res://domain/models/`. A `Skill` ganha `area_shape`, `area_range` (a coluna `range`, com outro nome para não esconder o `range()` do GDScript), `pierces`, `ground_effect_id` e `ground_turns`, e o catálogo ganha `GroundEffect`.
- **Geometria:** `res://domain/rules/board_geometry.gd`, com a distância, os vizinhos, os hexágonos alcançáveis e a área de uma Técnica, iguais aos do servidor. Ela só serve para prever o que acender. Quem decide é o servidor.
- **Tela:** `res://screens/board_battle/`, rota `&"board_battle"` no `Router`. A luta antiga (`res://screens/battle/`) fica como está, e as peças reaproveitáveis vêm de lá: `BattleSkillButton`, `BattleItemsPanel`, `NextCreaturePanel`, `CaptureOverlay`, as telas de subir de nível, Técnica nova e Evolução, `BattleNarrator` (os textos do histórico) e `BattleStyles`. Desde a [06](06-board-look.md), a tela segue o print do dono: o cartão do selvagem e a rodada em cima, o tabuleiro, o cartão de quem joga, os botões Atacar, Passar, Mochila e Fugir. A equipe e o botão Trocar ficaram no pé até a [08](08-board-ground.md), quando o dono os tirou; a troca fica sem botão até ele decidir onde. A fila de vezes não aparece. O tabuleiro fica parado: a parte de baixo guarda a altura da maior das suas formas (botões, Técnicas ou resultado), a mensagem guarda 2 linhas e os cartões sem Ecobeast ficam transparentes, guardando o lugar ([08](08-board-ground.md)).
- **Hexágonos na tela:** as proporções do hexágono do mapa ([wild-battle/architecture.md](../wild-battle/architecture.md#superfícies)), em 1,5×: 96 × 87 px, com passo de 96 e 63 e linha deslocada em 48. O tabuleiro tem 336 × 402 px e é ampliado como era o de 6 colunas: na escala em que 624 px ocupam a largura da área, ou menos, se não couber. Desde a [08](08-board-ground.md), o chão do mapa de Explorar cobre a tela inteira, desenhado pelo próprio `HexMapView` com escala fixa de 1,5, numa camada atrás da interface: a superfície e a forma do hexágono do Domador, o contorno, só as decorações baixas no tabuleiro e em volta dele, e o chão de fora escurecido, com uma borda clara no limite do tabuleiro. O fundo de floresta saiu na 08; antes, o tabuleiro ficava sobre ele (`res://assets/backgrounds/board/temperate.jpg`, a imagem do dono, cobrindo a tela). O hexágono de quem joga agora fica em azul escuro, se for do jogador, ou vermelho escuro, se for selvagem, com borda branca. Decisão do dono em 2026-11-05, depois de jogar a [04](04-board-screen.md): antes, eram cores chapadas, com as áreas em verde e vermelho, num fundo de cor chapada, e quem jogava tinha só um anel amarelo nos pés. As áreas continuam no contrato: o servidor as usa na largada e na entrada, e a entrada acende os hexágonos livres.
- **Ecobeasts na tela:** as folhas da luta de cada espécie, em `res://assets/creatures/<slug>/battle/` ([07](07-battle-sprites.md)). O `idle.png` tem 2 vistas, de frente e de costas, ou 5, com os 3 lados na ordem do walk ([17](17-idle-facing.md)), e o `walk.png` tem 3, a diagonal descendo, o lado e a diagonal subindo, ou 5, com a frente e as costas, que o tabuleiro não usa. A esquerda é espelhada. Quem tem o idle de lado fica parado olhando para o último passo. As folhas aparecem sem ampliar, sem filtro e com uma sombra.
  - **Parado:** o Ecobeast toca o idle olhando para o adversário: os do jogador de costas, os selvagens de frente.
  - **Andando:** toca o walk na vista do passo.
  - **Quem não tem as folhas:** usa o `board.png`, a pixel art gerada do `front.png` por `res://tools/board_sprites.gd` e mostrada 2× maior. Parado, ele respira; andando, dá um pulinho por hexágono. Sem o `board.png`, usa o `front.png` reduzido.

  As folhas do mapa ficam em `explore/`. Os tamanhos são _a revisar_.
