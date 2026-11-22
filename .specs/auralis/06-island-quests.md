# 06. As missões das ilhas

- **Status:** concluída (falta o dono conferir no jogo e criar as missões das ilhas)
- **Depende de:** [04-island-tamers](04-island-tamers.md), [05-arenas](05-arenas.md), [player-stats](../player-stats/), [fog-of-war](../fog-of-war/)

## Contexto

O [README](README.md) decidiu que a ilha só abre a seguinte quando os Domadores estão vencidos, as Arenas ganhas e as missões dos NPCs cumpridas. As missões que contam são escritas pelo dono e presas a um NPC da ilha.

Em 2026-11-22, o dono pediu **tipos de missão base**, que ele repete e usa fácil, escolhendo o parâmetro de cada missão na hora de criar ("vou pedindo individualmente para a criação das missões, mas crie missões base para eu conseguir replicar e usar fácil"). Os 9 tipos dele:

1. Capture X Ecobeasts (ele define a quantidade).
2. Derrote X Ecobeasts.
3. Explore X% do mapa (ele escolhe a porcentagem).
4. Vá até o X (ele escolhe o nome do lugar e os hexágonos do mapa).
5. Fale com o NPC X (ele escolhe o NPC).
6. Fique no mapa por pelo menos X minutos.
7. Encontre o Ecobeast X (ele escolhe a espécie).
8. Derrote o Ecobeast X.
9. Derrote o NPC X.

O "Vire a noite" do README era só um exemplo, e saiu.

## Decisões desta fase

| Decisão | Motivo |
| --- | --- |
| O catálogo `quest_types` tem os 9 tipos (ids 1 a 9), e cada missão (`quests`) é uma linha com o tipo e os parâmetros dele: a quantidade, a espécie, o NPC alvo, ou o nome do lugar e os hexágonos | Uma missão nova é uma linha, sem código; a mesma regra serve para todas as do mesmo tipo |
| Cada missão tem a ilha, o NPC que dá (`npc_id`) e a ordem nele (`position`): o NPC dá a 1ª, e a seguinte só depois de entregar a anterior | O NPC pode ter uma fila de missões, sem várias de uma vez |
| O progresso fica em `player_quests.progress`, somado pelos acontecimentos depois de aceitar | Só conta o que o jogador fez com a missão aceita; sem guardar o valor dos contadores do Perfil |
| Capturar, derrotar e encontrar contam em qualquer mapa (ilha ou sorteado) | O jogador treina no mapa sorteado, e a missão não fica presa a um canto |
| "Explore X%" é o descoberto da ilha da missão (`island_discoveries`) sobre os hexágonos do mapa publicado, contando o que ele já tinha descoberto antes | A névoa já guarda o descoberto da ilha; explorar antes de pegar a missão não deveria se perder |
| "Fique no mapa" conta o tempo do sinal de cada minuto enquanto a exploração está na ilha da missão | O sinal já tem o teto contra trapaça (no máximo o tempo real, até 90 s por sinal) |
| "Vá até o X" se cumpre quando o jogo avisa que o Domador pisou num hexágono do lugar, e o servidor confere a ilha, o hexágono e a velocidade do passo | O servidor só sabe a posição quando o jogo conta; a conferência do passo é a do Procurar |
| "Fale com o NPC X" se cumpre na conversa com ele, num mapa onde ele está posto | O mesmo aviso do fim da conversa que dá e entrega as missões |
| "Derrote o NPC X" é a vitória contra o Domador da ilha daquele NPC (`tamers`), a primeira ou uma revanche | O NPC precisa ser um Domador para lutar |
| A missão se aceita sozinha depois da última fala do NPC, e se entrega voltando a ele: ele mostra o progresso enquanto não acabou | O pedido "o NPC dando, mostrando o progresso e entregando", sem uma tela nova |
| A recompensa é o `quest` (100 XP de Domador), as moedas da missão e um item opcional | A regra da [tamer-level](../tamer-level/README.md); o item cobre o "novos itens" do README |
| A ilha completa também pede as missões que contam (`counts_for_unlock`), pelo número opcional `islands.required_quests` (nulo pede todas) | O README; a mesma regra dos Domadores |
| O título sai do tipo e dos parâmetros ("Capture 3 Ecobeasts", "Vá até o Farol"), e a missão pode ter um título próprio (`title`) | O dono não precisa escrever o texto de cada uma |

## Os tipos

| id | slug | Título | Parâmetros | Cumpre quando |
| --- | --- | --- | --- | --- |
| 1 | `capture_any` | Capture N Ecobeasts | `amount` | N capturas |
| 2 | `defeat_any` | Derrote N Ecobeasts | `amount` | N inimigos derrubados (selvagens ou de Domadores) |
| 3 | `explore_percent` | Explore N% de <ilha> | `amount` (1 a 100) | o descoberto da ilha chega a N% |
| 4 | `reach_place` | Vá até <lugar> | `place_name` e os hexágonos em `quest_tiles` | o Domador pisa num dos hexágonos |
| 5 | `talk_npc` | Fale com <NPC> | `target_npc_id` | a conversa com o NPC |
| 6 | `stay_minutes` | Fique em <ilha> por N minutos | `amount` (minutos) | N minutos somados na ilha |
| 7 | `find_species` | Encontre <espécie> (ou "Encontre N <espécie>") | `species_id`, `amount` (1 se nulo) | N lutas com a espécie do lado inimigo |
| 8 | `defeat_species` | Derrote <espécie> (ou "Derrote N <espécie>") | `species_id`, `amount` (1 se nulo) | N da espécie derrubados |
| 9 | `defeat_tamer` | Derrote <NPC> | `target_npc_id` (um Domador da ilha) | a vitória contra ele |

Derrubar é terminar a luta com o HP em 0, sem ter sido capturado. A luta de teste e o modo deus não contam.

## Escopo

- O catálogo `quest_types`, as tabelas `quests`, `quest_tiles` e `player_quests` e a coluna `islands.required_quests`.
- As regras puras: o título, o alvo de cada tipo, o progresso dos acontecimentos da luta e a ilha completa com as missões.
- A conversa com o NPC (`POST /v1/me/quests/talk`), o lugar alcançado (`POST /v1/me/quests/reach`) e o progresso pela luta e pelo sinal de cada minuto.
- Na exploração de uma ilha, os lugares das missões aceitas (`quest_places`).
- No jogo: as falas da missão depois da última fala do NPC, fora e dentro das salas, o aviso do lugar alcançado e a recompensa.

## Fora do escopo

- Uma tela com a lista das missões (o progresso aparece no NPC).
- Criar as missões pelo F2: veio na [07](07-quest-editor.md). Até ela, o dono pedia a Claude ou criava a linha no painel do Supabase, pelas receitas abaixo.
- As missões extras sorteadas (08) e "Encontre X item" (09), na tabela de fases do [README](README.md#fases).

## Como criar uma missão

Toda missão é uma linha em `quests` (e, no "Vá até", os hexágonos em `quest_tiles`). Os campos comuns: `island_id`, `npc_id` (quem dá), `position` (a ordem nele, de 1 em diante), `quest_type_id`, `coins` (as moedas, 0 por padrão), `item_id` e `item_quantity` (opcionais), `counts_for_unlock` (verdadeiro por padrão) e `title` (opcional).

```sql
-- Capture 3 Ecobeasts, dada pelo NPC 6 em Liora, que paga 50 moedas
insert into ecobeasts.quests (island_id, npc_id, position, quest_type_id, amount, coins)
values (1199, 6, 1, 1, 3, 50);

-- Encontre o Puffcoo (espécie 15)
insert into ecobeasts.quests (island_id, npc_id, position, quest_type_id, species_id)
values (1199, 6, 2, 7, 15);

-- Fale com o NPC 7
insert into ecobeasts.quests (island_id, npc_id, position, quest_type_id, target_npc_id)
values (1199, 6, 3, 5, 7);

-- Vá até o Farol, nos hexágonos (4, -2) e (5, -2)
with q as (
  insert into ecobeasts.quests (island_id, npc_id, position, quest_type_id, place_name)
  values (1199, 8, 1, 4, 'o Farol') returning id
)
insert into ecobeasts.quest_tiles (quest_id, q, r)
select id, t.q, t.r from q, (values (4, -2), (5, -2)) as t(q, r);
```

## Onde ficou

- O banco: a migration `20270214000000_island_quests`, com os 9 `quest_types`, as tabelas `quests`, `quest_tiles` e `player_quests`, a coluna `islands.required_quests` e o CHECK `quests_params_check`, que pede os parâmetros de cada tipo (com `COALESCE`, porque um parâmetro nulo daria NULL, e o CHECK aceitaria).
- As regras puras em `server/src/domain/quests/quests.ts`: o título (`questTitle`), o alvo (`questTarget`), as falas (`progressLine`, `acceptedLine` e `claimedLine`), a porcentagem do descoberto (`explorePercent`) e quanto o fim da luta soma em cada missão (`battleQuestDeltas`). O `islandComplete` de `archipelago.ts` ganhou `questIds`, `claimedQuestIds` e `requiredQuests`.
- A ilha completa saiu do `IslandTamersService` para o `IslandCompletionService` (`server/src/islands/island-completion.service.ts`), com o `placedNpcs` e o `unlockedBy`, que a vitória contra um Domador e a entrega da missão usam. Só contam as missões cujo NPC está posto na ilha, como os Domadores.
- O `QuestsService` (`server/src/quests/`): `POST /v1/me/quests/talk` e `POST /v1/me/quests/reach`, os lugares (`places`), o progresso da luta (`battleWrites`, chamado no `saveTeam` do `BattleRecordsService`) e o do sinal de cada minuto (`stayWrite`, no `ping` do `CountersService`). O progresso soma com `LEAST(progress + n, alvo)` no SQL, então não passa do alvo.
- A conferência do passo (`confirmPosition`) foi para o `ExplorationStore`, que o Procurar e o `reach` usam: o módulo das missões não pode depender do da luta, que depende dele.
- Diferenças da spec: o "Fique" guarda o progresso em segundos (o alvo é `amount * 60`), e a fala mostra os minutos; o "Explore" é calculado na conversa, pelo descoberto de agora, e gravado junto. A entrega que abre a ilha seguinte paga também o XP `island_unlocked`, como a vitória contra um Domador.
- No jogo: o modelo `QuestTalk` (`client/domain/models/quest_talk.gd`), as rotas no `GameService` e no `ApiGameService`, o `Session.talk_quest` (que relê o Domador quando há recompensa) e o `Session.reach_quest_place`, e os lugares em `Session.quest_places` (e em `ExplorationMap.quest_places` na entrada). O `_after_talk` da tela de Explorar e da sala chama a conversa, mostra as falas com a voz da narração (com a recompensa, o nível e a ilha aberta) e depois vai para a luta ou a ação (`_finish_talk`); a cada hexágono novo, a tela de Explorar avisa o lugar (`_check_quest_place`) e mostra "Você chegou em <lugar>.".
- Os testes: `server/src/domain/quests/quests.spec.ts`, os casos novos de `archipelago.spec.ts` e o e2e `server/test/island-quests.e2e-spec.ts`.

## Requisitos

- **RF-01:** `quest_types` tem os 9 tipos da tabela acima (`id`, `slug`, `name`, `description`). `quests` tem `id`, `island_id` (apaga junto), `npc_id`, `position` (maior que 0, única por ilha e NPC), `quest_type_id`, `amount`, `species_id`, `target_npc_id`, `place_name` (1 a 40 caracteres), `title` (1 a 60 caracteres), `coins` (0 ou mais), `item_id`, `item_quantity` (1 ou mais, junto com o `item_id`) e `counts_for_unlock`, com um CHECK por tipo: os tipos 1, 2 e 6 pedem `amount` maior que 0, o 3 pede `amount` de 1 a 100, o 4 pede `place_name`, os 5 e 9 pedem `target_npc_id`, e os 7 e 8 pedem `species_id`, com `amount` nulo ou maior que 0. `quest_tiles` tem `quest_id` (apaga junto), `q` e `r`. `player_quests` tem `player_id`, `quest_id`, `progress` (0 ou mais), `accepted_at` e `claimed_at` (nulo até a entrega).
- **RF-02:** `POST /v1/me/quests/talk` com `npc_id`, numa exploração de ilha, com o NPC posto nela (no mapa publicado ou numa sala dele): cumpre as missões aceitas "Fale com" esse NPC. Se ele dá missões nessa ilha, olha a primeira da fila não entregue: aceita se ainda não foi aceita; entrega se está cumprida (e aceita a seguinte); senão, mostra o progresso. Responde `lines` (as falas da missão, vazias se não há o que dizer), `reward` (moedas, item e XP, ou nulo), `tamer_progress`, `island_unlocked` e `quest_places`. Fora de uma ilha, ou com o NPC fora dela, dá 409.
- **RF-03:** as falas: ao aceitar, "Nova missão: <título>."; com a missão em andamento, "<título>: <progresso> de <alvo>." (no "Explore", em %; no "Fique", em minutos); ao entregar, "Missão cumprida: <título>!".
- **RF-04:** a entrega grava `claimed_at`, soma as moedas, o item e o XP `quest` numa transação. Se ela completa a ilha, abre a ilha seguinte, como a vitória da [04](04-island-tamers.md), e a resposta traz `island_unlocked`.
- **RF-05:** o fim de uma luta (sem a luta de teste nem o modo deus) soma nas missões aceitas e não entregues: as capturas no `capture_any`, os inimigos derrubados no `defeat_any`, as espécies inimigas no `find_species` (uma vez por luta), os derrubados da espécie no `defeat_species` e a vitória contra o Domador da ilha do NPC alvo no `defeat_tamer`. O progresso não passa do alvo.
- **RF-06:** o sinal de cada minuto soma os segundos que ele conta nas missões `stay_minutes` aceitas da ilha da exploração.
- **RF-07:** `POST /v1/me/quests/reach` com `q` e `r` confere o passo como o Procurar (a posição e a velocidade) e cumpre as missões `reach_place` aceitas da ilha da exploração com esse hexágono. Responde os nomes dos lugares alcançados e os `quest_places` que faltam.
- **RF-08:** a resposta de `POST /v1/me/exploration` numa ilha traz `quest_places`, os lugares das missões "Vá até" aceitas e não cumpridas dessa ilha (`quest_id`, `name` e os hexágonos). No mapa sorteado, vem vazia.
- **RF-09:** a ilha completa quando tem pelo menos uma condição (um Domador que conta, uma Arena ou uma missão que conta) e cumpre todas. As missões estão cumpridas quando as entregues entre as que contam chegam a `min(required_quests ?? n, n)`.
- **RF-10:** no jogo, numa ilha, depois da última fala de um NPC (fora ou numa sala), o jogo chama a conversa da missão e mostra as falas dela na caixa de fala, com a recompensa e a ilha aberta no fim; depois vem a luta (se é Domador) ou a ação dele. Pisar num hexágono de um lugar avisa o servidor e mostra "Você chegou em <lugar>.".

## Critérios de aceite

- [x] Falar com o NPC aceita a 1ª missão dele, falar de novo mostra o progresso, e, cumprida, a entrega paga as moedas e o XP e aceita a 2ª.
- [x] Cada tipo soma pelo seu acontecimento, e não passa do alvo.
- [x] Uma ilha só com uma missão que conta completa na entrega, e a ilha seguinte abre.
- [x] Uma ilha com Domadores e missões só completa com os dois.
- [ ] No jogo, as falas da missão aparecem depois da fala do NPC, e chegar no lugar avisa (falta o dono conferir).
