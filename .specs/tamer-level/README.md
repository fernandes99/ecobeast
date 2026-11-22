# tamer-level

O Domador passa a ter XP e nível, de 1 a 99, separados dos Ecobeasts. O XP vem um pouco das lutas e principalmente dos marcos (a primeira captura de cada espécie, os Domadores vencidos e, quando a [auralis](../auralis/) existir, as missões, as Arenas e as ilhas). Cada nível paga uma recompensa pequena. O 99 é difícil de alcançar. Mais tarde, o nível dá os pontos de uma árvore de melhorias.

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [progression](../progression/) (o XP dos Ecobeasts no fim da luta), [codex](../codex/) (a primeira captura de cada espécie), [npc-tamers](../npc-tamers/), [player-stats](../player-stats/) (a luta de teste e o modo deus não contam) e [hub-start](../hub-start/) (o selo e a barra de XP da Home, o Perfil)

## Contexto

Em 2026-11-22, o dono escreveu: "Vamos criar a iniciativa de nivel e progressão da conta do jogador, hoje temos apenas os niveis dos ecobeasts." E também: "talvez o level até 99 e que seja dificil de alcançar. Futuramente eu gostaria de ter algum sistema de skills e melhorias. Tipo um arvore de skill que vai liberando pontos conforme upa o nivel, tipo como funciona no Arc raiders", com árvores de velocidade do Domador, limite de inventário, velocidade na montaria e fôlego na água, "mas não vamos aprofundar nisso ainda".

O que o jogo já tem:

- A coluna `players.level` (`model Player`, em `server/prisma/schema.prisma`), com o CHECK de 1 a 100 da migration `init`, sempre 1. O `PlayerDto` (`server/src/player/player.dto.ts`) já manda o `level`, e o `res://domain/models/player.gd` já lê.
- A Home (`res://screens/hub/hub_screen.gd`) mostra o selo do nível (`%LevelBadge`, `%LevelLabel`) e uma barra de XP (`%XpBar`) parada em 0, com o comentário "O Domador ainda não sobe de nível (o GDD não define como)". O Perfil (`res://screens/profile/profile_screen.gd`) mostra o nível.
- O [roadmap](../roadmap.md) lista em "Dúvidas globais em aberto": "Nível do Domador: o Hub mostra o nível, mas o GDD não diz como ele sobe. No MVP fica fixo em 1."
- O fim de cada luta é uma transação só (`BattleRecordsService.finish`, em `server/src/battle/battle-records.service.ts`). Ele já sabe o XP que cada Ecobeast ganhou (`creature.xpEarned`), as espécies capturadas pela primeira vez (`registeredSpeciesIds`, do `CodexService.newlyCaught`) e se o oponente era selvagem ou Domador. A luta de teste (`noRewards`) e o modo deus (`godMode`) já não dão recompensa.
- A [auralis](../auralis/), em rascunho, deixou o XP do Domador de fora. Ela cria os Domadores fixos das ilhas, as missões, as Arenas e a abertura das ilhas, que são os marcos maiores desta iniciativa.

## Objetivos

1. O jogador tem uma meta longa que não depende de um Ecobeast só: o nível do Domador sobe devagar, do 1 ao 99.
2. Avançar no jogo vale mais que repetir lutas: os marcos dão a maior parte do XP, e as lutas dão um pouco para a barra nunca ficar parada.
3. Subir de nível já vale alguma coisa hoje: cada nível paga uma recompensa.
4. O dono ajusta a curva, as recompensas e quanto cada fonte vale pelo painel do Supabase, sem código.
5. O servidor decide e grava tudo, e o jogo só mostra.

## Não objetivos

- A árvore de melhorias e os pontos: vêm numa iniciativa depois, lendo o `players.level` (ver [O futuro](#o-futuro-a-árvore-de-melhorias)).
- O inventário com limite, a montaria e o fôlego na água: são ramos da árvore futura.
- Travar conteúdo pelo nível do Domador (itens da Loja, ilhas, Ecobeasts). O que destrava conteúdo é a [auralis](../auralis/), pelas ilhas.
- O XP das missões, das Arenas, dos Domadores das ilhas e das ilhas abertas: essas fontes ficam no catálogo desde já, mas só passam a pagar quando a [auralis](../auralis/) criar esses eventos.
- Mostrar o nível de outros jogadores, ranking.

## Antiobjetivos

- Dar para subir rápido repetindo a mesma luta: a parte da luta é pequena, e cada marco paga uma vez só.
- A luta de teste da Técnica ou o modo deus darem XP de Domador.
- Uma recompensa de nível paga duas vezes, ou perdida, quando o jogador sobe vários níveis de uma vez.
- Um número fixo no código: a curva, o nível máximo, as recompensas e o valor de cada fonte vêm do catálogo.

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| O nível vai do 1 ao 99 e é difícil chegar ao topo | "talvez o level até 99 e que seja dificil de alcançar" |
| O XP vem das lutas e dos marcos juntos | Ele escolheu "Lutas e marcos" entre só a parte da luta, só os marcos e os dois juntos |
| Cada nível paga uma recompensa pequena, até a árvore existir | Ele escolheu "Recompensa por nível" entre só a festa, a recompensa e destravar coisas pelo nível |
| A curva, as recompensas e o valor de cada fonte ficam em tabelas do catálogo | Ele escolheu "Tudo no catálogo" entre isso, a curva por fórmula no código e o XP como um contador da [player-stats](../player-stats/) |
| A árvore de melhorias fica para depois | "mas não vamos aprofundar nisso ainda" |
| Revencer um Domador fixo da ilha rende XP, mas menos que a primeira vitória | "pode até render, mas não tanto quanto a primeira vez. Será uma quantia menor" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A parte da luta é uma porcentagem (10%) do XP bruto que os inimigos derrubados valem (a soma do `xpYield` de cada um, com o `TAMER_XP_MULTIPLIER` na luta contra Domador, antes de dividir e sem tirar quem está no nível 100), arredondada para baixo | O XP dos Ecobeasts já cresce com o nível do inimigo, então a parte da luta acompanha o jogo; o bruto não zera quando a equipe toda já está no 100, justo no fim do jogo, quando o jogador sobe para o 99; 10% deixa os marcos com o peso maior |
| A parte da luta só paga quando a equipe recebe XP, ou seja, na vitória (`state.result === 'victory'`, como o `progressTeam`) | Segue a regra do XP dos Ecobeasts: a derrota, a fuga e a captura não dão XP à equipe, então também não dão ao Domador. O `new_species` paga na captura, que é um marco |
| Os marcos de hoje: a primeira captura de cada espécie (100 XP) e a vitória contra um Domador NPC (50 XP, a cada vitória) | São os marcos que o fim da luta já conhece; hoje toda luta contra Domador é contra um sorteado, que é sempre novo, então não tem o "uma vez só" |
| A luta contra os Domadores fixos da [auralis](../auralis/) não paga o `tamer_win`: a primeira vitória paga o `island_tamer_win` (ou o `arena`), e cada revanche vencida paga o `island_tamer_rematch` (15 XP). Marcar a luta como "Domador fixo" é trabalho da auralis | A revanche menor segue a decisão do dono acima; a fase 01 não precisa saber de Domador fixo, porque ainda não existe |
| A Evolução que registra uma espécie no Bestiário não conta como marco | O marco é capturar; a Evolução já é a recompensa do Ecobeast |
| A recompensa entra direto na conta, sem botão de resgatar | Menos um passo, e o aviso de nível novo já mostra o que veio |
| As recompensas são moedas em todo nível e um item, às vezes, nos níveis múltiplos de 5 (ver [A curva](#a-curva-e-as-recompensas)) | Pequena e constante, com um presente maior de tempos em tempos |
| No 99, o XP continua somando, mas o nível não sobe mais, e a barra aparece cheia | Não se perde o que foi ganho, se o máximo subir um dia |
| Os jogadores de antes começam no nível 1 com 0 XP | Os contadores só existem desde a [player-stats](../player-stats/) (2026-11-21), e recalcular o passado daria números errados |
| O CHECK de `players.level` continua de 1 a 100; o nível máximo é o da maior linha de `tamer_levels` | Não precisa de migration no CHECK, e o dono muda o máximo pelo catálogo |
| O aviso de nível novo aparece depois da tela de fim da luta, antes de voltar ao mapa | É onde o XP foi ganho e onde o jogador já está esperando recompensa |

## O desenho

### O catálogo (schema `ecobeasts`, editado pelo painel)

- **`tamer_levels`**: uma linha por nível. `level` (PK, de 1 em diante, sem buraco), `xp_total` (o XP somado para chegar nele, 0 no nível 1, crescente), `reward_coins` (≥ 0), `reward_item_id` (FK para `items`, nulo sem item) e `reward_item_quantity` (≥ 1 quando há item, nulo sem item). O nível 1 não tem recompensa. O nível máximo é a maior linha.
- **`tamer_xp_sources`**: quanto vale cada fonte. `id`, `slug` único (`^[a-z0-9_]+$`), `name` e `amount` (≥ 0). As linhas iniciais:

| slug | name | amount | Quando paga |
| --- | --- | --- | --- |
| `battle_xp_percent` | Parte do XP da luta (%) | 10 | Na vitória: `floor(XP bruto dos inimigos derrubados × amount / 100)` |
| `new_species` | Primeira captura de uma espécie | 100 | Por espécie em `registeredSpeciesIds` |
| `tamer_win` | Vitória contra um Domador NPC | 50 | Vitória numa luta contra Domador sorteado (hoje, toda luta contra Domador) |
| `island_tamer_win` | Primeira vitória contra um Domador da ilha | 150 | Na [auralis](../auralis/) |
| `island_tamer_rematch` | Revanche vencida contra um Domador da ilha | 15 | Na [auralis](../auralis/) |
| `quest` | Missão entregue | 100 | Na [auralis](../auralis/) |
| `arena` | Arena ganha | 500 | Na [auralis](../auralis/) |
| `island_unlocked` | Ilha aberta | 1000 | Na [auralis](../auralis/) |

As duas tabelas entram no catálogo (`GET /v1/catalog`, pela lista de `server/src/catalog/catalog-tables.ts`) e o `CatalogValidator` do jogo as confere: `tamer_levels` começa no 1 com `xp_total` 0, sem buraco e crescente; a recompensa de item tem a quantidade. As linhas `island_tamer_win`, `island_tamer_rematch`, `quest`, `arena` e `island_unlocked` existem desde já, para a auralis só ler o valor delas.

### O jogador

- `players.xp` (inteiro ≥ 0, padrão 0): o XP total do Domador. O nível continua em `players.level` e é sempre o da maior linha de `tamer_levels` com `xp_total ≤ xp`.
- O `PlayerDto` ganha `xp`, `level_xp` (o `xp_total` do nível atual) e `next_level_xp` (o do próximo, nulo no máximo), como o `CreatureDto` já faz para os Ecobeasts.

### As regras (pacote puro do servidor)

`server/src/domain/progression/tamer-level.ts`, sem Nest nem banco, com testes:

- `tamerXpFromBattle(rawEnemyXp, victory, newSpeciesCount, tamerWin, sources)`: o XP da luta pelas fontes. O `rawEnemyXp` é o XP bruto dos inimigos derrubados, que o motor da luta passa a guardar ao lado do `xpEarned`.
- `addTamerXp(xp, level, gained, levels)`: devolve o XP novo, o nível novo e a lista dos níveis subidos, cada um com a recompensa. Sobe vários níveis de uma vez quando o XP dá, e para no máximo.

### Onde o XP é dado

- No `BattleRecordsService.finish`, dentro da mesma transação (as espécies novas saem hoje do resultado da transação, pelo `CodexService.newlyCaught`; a fase 01 lê o Bestiário antes ou passa para uma transação interativa): soma o XP, sobe o nível, paga as moedas e os itens de cada nível subido (o item vai para a Mochila como a Loja faz) e devolve o resultado. Fica de fora quando o `godMode` ou o `noRewards` está ligado, como a recompensa de hoje.
- A resposta do fim da luta ganha `tamer_progress`: `xp_gained`, `level_before`, `level_after`, `current_xp`, `level_xp`, `next_level_xp` e `levels` (cada nível subido, com `level`, `reward_coins`, `reward_item_id` e `reward_item_quantity`).
- As fontes da [auralis](../auralis/) chamam o mesmo `addTamerXp` na transação de cada evento; esta iniciativa só deixa a função e as linhas prontas.

### O jogo

- A Home: o selo mostra o nível e a barra de XP enche de `level_xp` até `next_level_xp`, pelo `/v1/me`; no máximo, a barra fica cheia. O comentário "O Domador ainda não sobe de nível" sai.
- O Perfil: o nível e o XP que falta para o próximo ("1.240 / 2.000 XP").
- O fim da luta: o histórico da luta ganha a linha "+N XP de Domador". Quando `levels` não está vazio, um aviso "Domador nível N!" mostra as recompensas (as moedas e o ícone do item), um por nível subido, ou um só com a soma quando subiu mais de um.

### A curva e as recompensas

Proposta de Claude, _a revisar_, gerada por fórmula na migration e retocada à mão depois pelo dono:

- `xp_total(n) = round(40 × (n − 1) + 0,8 × (n − 1)³)`. Isso dá 41 XP no nível 2, 943 no 10, 20.671 no 30, 96.079 no 50 e 756.874 no 99.
- A ideia do ritmo: os primeiros níveis em minutos, o 30 em algumas semanas de jogo normal e o 99 em centenas de horas. A conta é aproximada, porque o XP por hora depende do nível dos selvagens. O dono ajusta depois de jogar.
- `reward_coins(n) = 50 + 10 × n`.
- Item nos múltiplos de 5: Esferas de Vínculo da mais simples nos níveis 5, 15, 25…, e da melhor nos 10, 20, 30…, com 3 de cada (os ids saem do catálogo `items`). Os ids de verdade e as quantidades são da fase 01.

### O futuro: a árvore de melhorias

Fica para uma iniciativa própria. O que esta deixa pronto: o nível guardado no servidor. A ideia de hoje é que os pontos saiam do nível (por exemplo, 1 ponto por nível subido), sem uma coluna de pontos agora. Assim, quando a árvore chegar, quem já estiver no 40 recebe os 39 pontos de uma vez. Os ramos que o dono citou: velocidade do Domador, limite de inventário, velocidade na montaria e fôlego na água.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-tamer-xp-server](01-tamer-xp-server.md) | As tabelas `tamer_levels` e `tamer_xp_sources` com a curva e as fontes, a coluna `players.xp`, as regras puras com testes, o XP no fim da luta com as recompensas, o `tamer_progress` na resposta e o `xp` no `PlayerDto`; o `CatalogValidator` confere as tabelas novas | concluída |
| 2 | [02-tamer-level-client](02-tamer-level-client.md) | A barra da Home e o selo, o XP no Perfil, o "+N XP de Domador" no fim da luta e o aviso de nível novo com as recompensas | concluída (falta o dono conferir no jogo) |

