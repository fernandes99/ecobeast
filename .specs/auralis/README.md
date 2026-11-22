# auralis

O jogo troca a história por uma progressão de ilhas: o **Arquipélago Auralis**. O Explorar do Hub passa a ter duas opções, o mapa aleatório de hoje e o Arquipélago, onde as ilhas abrem uma de cada vez. Para abrir a próxima, o jogador vence os Domadores da ilha, ganha as Arenas dela e cumpre as missões dos NPCs. Cada ilha aberta destrava biomas e Ecobeasts, e o mapa aleatório só sorteia o que o jogador já destravou.

- **Status:** em andamento
- **Depende de:** [hub-start](../hub-start/), [islands](../islands/), [island-npcs](../island-npcs/), [interiors](../interiors/), [npc-tamers](../npc-tamers/), [player-stats](../player-stats/), [fog-of-war](../fog-of-war/)

## Contexto

Em 2026-11-22, o dono pediu: "A ideia é não ter uma história singleplayer, não por agora." E descreveu:

- ao tocar em Explorar, abrem duas opções: "Explorar randomicamente" e "Arquipélago Auralis";
- o Arquipélago mostra várias ilhas e lugares, e cada ilha se destrava conforme o jogador cumpre missões na ilha anterior: vencer X NPCs, ganhar as Arenas da ilha e fazer X missões dos NPCs (missões gerais, como "Pegue um Puffcoo", "Vire a noite" e "Encontre X item");
- só depois disso a próxima ilha abre, e cada ilha destrava biomas, zonas, Ecobeasts e itens novos;
- "Quero que seja algo em que prenda o jogador e que vá evoluindo aos poucos."

Nas respostas seguintes, ele decidiu:

- o Explorar randomicamente só sorteia os biomas e os Ecobeasts destravados, por uma configuração que ele mesmo insere: "a primeira ilha será a Liora, e lá vamos encontrar até X ecobeasts, e X biomas. Então inicialmente no explorar randomico vai aparecer apenas esse range";
- "quero que exista ecobeasts que serão gerados apenas no randomico mas que o jogador precise pelo menos estar na ilha Y";
- as missões são uma mistura: as que contam para abrir a ilha são escritas por ele, presas a um NPC da ilha, e as extras são sorteadas de modelos;
- "vão ter mais ilhas e mais arenas, as vezes pode ser 1 arena as vezes 2 por ilha. Não deixe nada fixo disso";
- a Liga fica para depois: "ainda to até cogitando se vale a pena ter ela ou não".

O que o jogo já tem e esta iniciativa usa:

- **Ilhas fixas** montadas no F2 e publicadas ([islands](../islands/)), com os NPCs, as falas e as ações ([island-npcs](../island-npcs/)), as salas por dentro ([interiors](../interiors/)) e a névoa guardada por ilha ([fog-of-war](../fog-of-war/)). O nome da ilha mora no `island_maps`, não no `islands`. Desde a [hub-start](../hub-start/), nenhuma ilha é aberta pelo Hub: Liora (ilha 1199) deixou de ser a casa, e a tela Viagem e o `GET /v1/islands` (que lista toda ilha publicada) ficaram sem entrada.
- **As cenas da história** são ligadas à ilha (`island_id`), não à casa. Hoje nenhuma toca porque o `StoryValidator.home_errors` barra as que têm `create_tamer` ou `choose_starter` fora da casa (a `liora_abertura` tem), e as outras 5 de Liora pedem o Marco dela. Uma cena nova de Liora, sem esses passos, tocaria assim que Liora abrisse.
- **Os contadores do Domador** ([player-stats](../player-stats/)): `counters` e `player_counters`, contados pelo servidor, com o recorte por Elemento, parte do dia ou bioma. Hoje são 18, entre eles `wins_tamer`, `captures`, `captures_by_element`, `captures_by_day_phase`, `biome_hexes`, `maps_explored` e `play_seconds`.
- **Os Domadores NPC** ([npc-tamers](../npc-tamers/)), sorteados no mapa aleatório e na luta de 1×1, 2×2 ou 3×3, sem fuga nem Esfera.
- **O mapa aleatório** do servidor, que sorteia os biomas pelo clima e pelo relevo e os Ecobeasts pela taxa de cada bioma (`species_biomes.rate`), pela zona e pela parte do dia.

Um cuidado do modelo de hoje: as linhas das ilhas (`island_npcs`, `island_props` e as outras) são de um `island_maps`, que é refeito a cada publicação, então os ids delas mudam. Tudo o que o progresso do jogador guarda aponta para ids que não mudam: a ilha (`islands`), o NPC do catálogo (`npcs`) e as tabelas novas desta iniciativa.

## Objetivos

1. O jogador vê a próxima meta e sente que avança: a tela do Arquipélago mostra o que falta na ilha da vez ("3/5 Domadores, 1/2 Arenas, 4/6 missões").
2. Cada ilha aberta muda o que o jogo oferece: o mapa aleatório passa a sortear os biomas e os Ecobeasts dela.
3. O dono configura tudo pelo banco, sem código: a ordem das ilhas, o que cada uma destrava, os Domadores, as Arenas e as missões, com números diferentes em cada ilha.
4. O servidor decide tudo: o que está aberto, o que foi cumprido e o que o mapa aleatório sorteia. O cliente só mostra.

## Não objetivos

- A Liga e o número total de Arenas. A Liga volta à conversa quando o dono decidir se ela vale a pena.
- A história: as cenas e os Marcos continuam guardados, sem tocar.
- "Encontre X item": pede um item no chão do mapa para pegar, que o jogo ainda não tem. Entra numa fase depois (ver [Fases](#fases)).
- Mudar a luta, a captura, a Loja, o Refúgio ou a Mochila.
- O PVP, o PVE e ver os outros jogadores nas ilhas.
- O XP do Domador e a subida de nível dele.
- O nível dos selvagens do mapa aleatório pela ilha da vez (ver [Dúvidas](#dúvidas-em-aberto)).

## Antiobjetivos

- O jogador ficar preso: uma ilha aberta sem como cumprir o que falta (um Domador que não está no mapa publicado, uma missão de um Ecobeast que não nasce em nenhum lugar aberto).
- O mapa aleatório quebrar por um bioma travado: um mapa sem terra, sem chegada ou sem nenhum Ecobeast para encontrar.
- Mostrar um Ecobeast ou um bioma travado antes da hora, no mapa aleatório ou nas missões extras.
- Contar para uma missão o que o jogador fez antes de aceitá-la.
- Um número fixo no código: o total de ilhas, de Arenas por ilha, de Domadores ou de missões.

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| O jogo fica sem história por agora | "A ideia é não ter uma história singleplayer, não por agora" |
| O Explorar abre duas opções: Explorar randomicamente e Arquipélago Auralis | O pedido dele |
| As ilhas abrem uma de cada vez, na ordem dele, e Liora é a primeira | "a primeira ilha será a Liora" |
| A próxima ilha abre quando a da vez tem os Domadores vencidos, as Arenas ganhas e as missões cumpridas | O pedido dele |
| Cada ilha destrava biomas e Ecobeasts, numa configuração que ele insere | "eu insiro uma configuração para isso" |
| O mapa aleatório só sorteia os biomas e os Ecobeasts das ilhas abertas, somados | "inicialmente no explorar randomico vai aparecer apenas esse range" |
| Um Ecobeast pode nascer só no mapa aleatório, a partir de uma ilha Y aberta | "ecobeasts que serão gerados apenas no randomico mas que o jogador precise pelo menos estar na ilha Y" |
| As missões que contam para abrir a ilha são escritas por ele e presas a um NPC dela; as extras são sorteadas de modelos | "Vou nessa mistura" |
| Cada ilha tem os próprios números: 1, 2 ou mais Arenas, e quantos Domadores e missões ele quiser | "Não deixe nada fixo disso" |
| Os Domadores que contam são os que ele põe na ilha, com a equipe fixa, e cada um conta uma vez | Ele confirmou a proposta: "Bate sim" |
| A Arena é um prédio com sala, com Domadores de treino e o Mestre de Arena; vencer o Mestre dá o emblema, e a Arena seguinte da ilha só abre depois | Ele confirmou a proposta: "Bate sim" |
| A Liga fica de fora | "Vamos pensar na liga só mais tarde" |
| Uma iniciativa só, com as fases em ordem | Ele escolheu o caminho 1: "pode" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O que cada ilha destrava é uma lista explícita (`island_unlock_biomes` e `island_unlock_species`), e não tirada sozinha das áreas e do terreno da ilha | O dono pediu uma configuração que ele insere, e os Ecobeasts "só do randômico" não estão em nenhuma área |
| Um Ecobeast "só do randômico" é uma linha de `island_unlock_species` com `random_only = true`: ele entra no sorteio do mapa aleatório quando aquela ilha está aberta | É a mesma tabela, e "a partir da ilha Y" é a ilha da linha |
| A Planície, a Água rasa e a Água profunda valem sempre, e a Lava vem junto com o Vulcão | A Planície é o fim de toda troca, então o mapa nunca fica com buraco; sem água, o gerador não faz mar, rio nem lago; a Lava não existe sem o cone |
| No mapa aleatório, um bioma de terra travado vira o vizinho mais parecido (`biomes.locked_fallback_biome_id`), seguindo a corrente até um aberto: a Neve vira Boreal, a Montanha vira Colina, o Boreal, a Colina, a Pedra, o Deserto e a Praia viram Planície. A troca mantém a altura do hexágono | O mapa continua inteiro e jogável sem mostrar o conteúdo travado, e uma seed gera o mesmo terreno com o bioma trocado |
| O Vulcão e a Geleira travados não são postos (`locked_fallback_biome_id` nulo só vale para eles), e as pedras gigantes e as de gelo só são postas quando a Montanha e a Geleira estão abertas | São manchas e peças que o gerador põe depois do terreno; sem elas o mapa de baixo já está pronto |
| As cenas da história só tocam na ilha casa, e Liora continua sem a marca de casa | A história está pausada, não apagada ("não por agora"); a regra impede que uma cena toque no Arquipélago |
| A tela Viagem continua sem entrada, e o Arquipélago tem a própria rota, que só dá o nome das ilhas abertas e da próxima | O `GET /v1/islands` de hoje mostraria o nome de toda ilha publicada |
| O clima do mapa continua sorteado como hoje, e o bioma trocado cobre a diferença | Não muda o gerador, e o clima Frio sem Neve vira um mapa de Boreal, que faz sentido |
| A próxima ilha abre sozinha quando a da vez fica completa, com um aviso na tela; o jogador não precisa ir até ela | É o momento de recompensa, e não há o que o jogador ganhe com um passo a mais |
| Uma ilha completa continua aberta para jogar; o que ela destravou não some | Ela vira lugar de treino e de captura |
| Os jogadores de antes começam como um jogador novo: só Liora aberta, com os Ecobeasts que já têm | Ninguém perde nada, e todos entram no Arquipélago pelo começo |
| As condições de cada ilha: todas as Arenas da ilha, e os Domadores e as missões marcados como "contam". Cada ilha tem dois números opcionais (`islands.required_tamer_wins` e `islands.required_quests`): nulo pede todos; um número pede só aquela quantidade entre os marcados ("3 de 5") | O dono falou em "X NPCs" e "X missões"; o número opcional cobre os dois jeitos sem fixar nada |
| O Domador da ilha e o Mestre de Arena são um catálogo novo (`tamers`, com a equipe em `tamer_creatures`), ligado ao NPC posto no F2 ou na sala (`island_npcs.tamer_id` e o mesmo na sala) | O id do `tamers` não muda ao publicar a ilha; o progresso guarda esse id |
| A luta contra um Domador da ilha usa a luta de Domador de hoje, com a equipe fixa do catálogo, e paga como hoje | Não muda a luta, e o dono ajusta a dificuldade pela equipe |
| Revencer um Domador da ilha é possível, mas só a primeira vitória conta | Dá para treinar sem inflar a contagem |
| As missões guardam o valor do contador quando o jogador aceita (`player_quests.baseline`), e contam a diferença | Só conta o que o jogador fez depois de aceitar, sem um sistema novo de contagem |
| Faltam contadores para as missões do dono: capturas por espécie (`captures_by_species`, recorte novo `species`) e tempo jogado por parte do dia (`play_seconds_by_day_phase`, para "Vire a noite") | Os 18 de hoje não dizem qual espécie foi pega nem quando o jogador jogou |
| O jogador entrega a missão da ilha ao NPC que a deu, que paga a recompensa (moedas ou itens, por missão) | Faz o jogador circular pela ilha; o NPC já tem a conversa |
| As missões extras ficam num quadro da tela do Arquipélago, 3 de cada vez, e uma nova é sorteada quando o jogador entrega outra; elas só sorteiam espécies, Elementos e biomas já destravados | Não dependem de uma ilha, e o quadro mostra a todo momento o que fazer |
| A tela do Arquipélago mostra as ilhas abertas, a próxima trancada com o nome e a lista do que falta, e as seguintes como silhuetas sem nome | Dá a meta seguinte sem estragar a surpresa das outras |
| Entrar numa ilha trancada é recusado pelo servidor, não só escondido pelo cliente | O servidor é a autoridade |

## Desenho

### Configuração (catálogo, editado pelo painel do Supabase)

- `islands.archipelago_order` (inteiro, nulo fica fora do Arquipélago): a ordem das ilhas. A de menor ordem começa aberta.
- `island_unlock_biomes` (`island_id`, `biome_id`): os biomas que a ilha destrava no mapa aleatório.
- `island_unlock_species` (`island_id`, `species_id`, `random_only`): os Ecobeasts que a ilha destrava no mapa aleatório; `random_only` marca os que nascem só lá.
- `biomes.locked_fallback_biome_id`: o bioma posto no lugar quando este está travado; nulo é "não pôr".
- `tamers` (nome, aparência ou sprite do NPC, fala antes e depois da luta, formato 1×1, 2×2 ou 3×3, `counts_for_unlock`) e `tamer_creatures` (espécie, nível, Técnicas): os Domadores das ilhas e os Mestres de Arena.
- `arenas` (`island_id`, ordem na ilha, nome, `interior_id`, `boss_tamer_id`): as Arenas de cada ilha. A de ordem 1 começa aberta; cada uma abre a seguinte.
- `quests` (`island_id`, `npc_id` do catálogo `npcs`, título, texto, `counter_id`, `subject_id`, alvo, recompensa, `counts_for_unlock`): as missões escritas pelo dono.
- `quest_templates` (contador, de onde vem o recorte, faixa do alvo, recompensa): os modelos das missões extras.

Os nomes das tabelas e das colunas são propostas; a fase de cada uma decide o nome final.

### Progresso do jogador (servidor)

- `player_islands` (`player_id`, `island_id`, `unlocked_at`): as ilhas abertas.
- `player_tamer_wins` (`player_id`, `tamer_id`, `won_at`): a primeira vitória sobre cada Domador.
- `player_arenas` (`player_id`, `arena_id`, `won_at`): os emblemas.
- `player_quests` (`player_id`, a missão ou o modelo sorteado, `baseline`, alvo, situação aceita, cumprida ou entregue).

O servidor confere se a ilha da vez ficou completa a cada vitória de Domador, emblema e missão entregue, e abre a próxima na mesma transação.

### O mapa aleatório

Antes de gerar, o servidor junta os biomas e as espécies das ilhas abertas do jogador. O gerador faz o terreno como hoje e, no fim, troca cada bioma travado pelo `locked_fallback_biome_id` dele (ou não põe o Vulcão e a Geleira). O sorteio dos selvagens só considera as espécies destravadas e, dentro delas, as taxas de sempre. Os Domadores NPC sorteados só levam espécies destravadas.

### As telas

- **Explorar** (o botão do Hub): abre a escolha entre Explorar randomicamente e Arquipélago Auralis.
- **Arquipélago:** as ilhas na ordem, cada uma aberta, completa, a próxima trancada ou em silhueta; tocar numa aberta mostra o que falta nela e o botão Entrar. Embaixo, o quadro das missões extras.
- **Na ilha:** os NPCs com missão mostram um sinal em cima da cabeça (missão nova, em andamento ou pronta para entregar). Ao entregar, aparece a recompensa.
- **Ao completar uma ilha:** um aviso de "Ilha nova aberta", com o que ela destrava.

## Fora do escopo

- A Liga e as recompensas finais do Arquipélago.
- O item no chão para pegar e as missões "Encontre X item" (vêm na fase 8).
- Destravar itens da Loja por ilha (o dono citou; entra depois da fase 3, quando a Loja ganhar uma lista por ilha).
- As missões diárias e as conquistas (podem usar os mesmos contadores depois).
- O teleporte entre as ilhas pelo altar do Veilmoth.

## Fases

Cada fase é jogável sozinha. Uma ilha só abre a próxima quando tem pelo menos uma condição e cumpre todas. Sem condição configurada, a próxima só abre pela rota de depuração da 01.

A fase 2 está adiada. Em 2026-11-22, o dono pediu: "vamos pular a parte do Explorar Randomico, ainda quero manter do jeito que está para eu testar o algoritmo procedural, até eu decidir que não vai ter novos biomas ou zonas." Até lá, o mapa aleatório sorteia todos os biomas e Ecobeasts, como hoje. As listas de `island_unlock_biomes` e `island_unlock_species` continuam no banco, sem ninguém ler, e as outras fases não dependem da 2.

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-unlock-config](01-unlock-config.md) | A ordem das ilhas, o que cada uma destrava, as ilhas abertas do jogador (Liora para todos) e a entrada numa ilha trancada recusada | concluída |
| 2 | 02-random-filter | O mapa aleatório com os biomas travados trocados e só os Ecobeasts destravados, os "só do randômico" incluídos | adiada |
| 3 | [03-archipelago-screen](03-archipelago-screen.md) | A escolha do Explorar e a tela do Arquipélago | concluída (falta o dono conferir no jogo) |
| 4 | 04-island-tamers | O catálogo `tamers`, o Domador posto no F2 com a equipe fixa, a primeira vitória contando, a ilha seguinte abrindo e o aviso da ilha nova | rascunho |
| 5 | 05-arenas | As Arenas de cada ilha, com a sala, os Domadores de treino, o Mestre e o emblema, uma abrindo a seguinte | rascunho |
| 6 | 06-island-quests | As missões escritas pelo dono, os contadores novos, o sinal no NPC, a entrega e a recompensa | rascunho |
| 7 | 07-extra-quests | Os modelos de missão e o quadro de missões extras do Arquipélago | rascunho |
| 8 | 08-ground-items | O item no chão da ilha para pegar e as missões "Encontre X item" | rascunho |

As specs das fases são escritas quando cada uma for planejada.

## Dúvidas em aberto

- **O nível dos selvagens no mapa aleatório:** hoje não depende da ilha da vez. Uma ilha mais adiante pode pedir selvagens mais fortes no aleatório também.
- **Os itens destravados por ilha:** o dono citou "novos itens". Falta dizer se é a Loja que vende mais, se é a recompensa das missões, ou as duas.
- **A Liga:** se vale a pena e o que ela pede.
- **A luta contra um Domador da ilha:** começa quando o Domador chega perto, com o mapa travando como no mapa aleatório, ou só quando o jogador toca no NPC? E, dentro de uma Arena, perder volta ao Hub, como a derrota para um Domador de hoje, ou volta para a porta da Arena? Sugestão de Claude: ao tocar no NPC e, na Arena, voltar para a porta. Decide as fases 4 e 5.
- **"Vire a noite":** o tempo jogado durante a Noite somado em vários dias (o `play_seconds_by_day_phase` das escolhas acima), ou jogar uma Noite inteira sem sair? Sugestão de Claude: o tempo somado, mais simples e mais justo no celular. Decide o contador novo da fase 6.
