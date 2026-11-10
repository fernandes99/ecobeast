# codex

O Bestiário (TELAS.md #11). É uma grade numerada com todas as espécies do catálogo. Quem o jogador já capturou aparece colorido, quem ele só viu aparece como sombra, e quem ele nunca viu aparece como "???". Tocar num Ecobeast abre o detalhe dele. Na primeira vez que o jogador captura uma espécie, ou que um Ecobeast dele evolui para uma espécie nova, aparece o aviso "Novo registro no Bestiário!".

A ideia é do dono, em 2026-11-09. O nome da pasta é o do roadmap (`codex`, o nome em código do Bestiário no [glossário](../glossary.md)).

## Contexto

O que já existe e esta iniciativa reaproveita:

- **O botão Bestiário** do Hub, no card e na aba da barra inferior, que hoje abre a tela placeholder.
- **O catálogo** no jogo (`GameData`): espécies com descrição, altura e peso, elementos, biomas (`species_biomes`) e evoluções (`evolutions`). A espécie não tem coluna de número: o número no Bestiário é o `id`, como o `GDD.md` já diz ("25 (número no Bestiário)").
- **As lutas no tabuleiro** ([board-battle](../board-battle/), [npc-tamers](../npc-tamers/)): todo Ecobeast inimigo que entra em campo gera um evento `creature_entered` com o `species_id`, contra selvagem ou contra Domador.
- **A captura** ([capture](../capture/)): o capturado é gravado no fim da luta, pelo `BattleRecordsService`, e a tela da luta já mostra o carregamento da Esfera e a linha de para onde ele foi.
- **A Evolução** ([progression](../progression/)): o `EvolutionOverlay` da luta chama `POST /v1/me/creatures/:uid/evolution`, e o servidor troca a espécie.
- **A arte:** o `CreaturePortrait` mostra o `front.png` da espécie, ou uma forma na cor do Elemento quando falta a arte.

Hoje o servidor não guarda o que o jogador viu nem as espécies que ele já capturou. Só sabe quem está com ele agora (`creature_instances`).

## Objetivos

1. O servidor guarda, por jogador, as espécies que ele viu numa luta e as que ele capturou, mesmo que o Ecobeast evolua depois.
2. O Bestiário lista todas as espécies, na ordem do número, com a contagem de vistos e de capturados.
3. O detalhe de um capturado mostra tudo, e o de um visto só a sombra, o número e o nome.
4. A primeira captura de uma espécie, e a Evolução para uma espécie nova, mostram o aviso de registro.

## Decisões

Do dono, em 2026-11-09:

| Decisão | Motivo |
| --- | --- |
| Uma espécie conta como **vista** quando aparece numa luta contra o jogador, seja selvagem ou de Domador. Passear no mapa não conta | Pedido do dono |
| Uma espécie conta como **capturada** quando o jogador captura um Ecobeast dela | Pedido do dono |
| Na grade, um capturado aparece colorido, um visto como sombra, com o nome, e um nunca visto como o número e "???" | Pedido do dono ("aqueles que não foram pegos, vão ter apenas a sombra deles"; "pode ser com o ???") |
| O detalhe de um capturado mostra a arte, o nome, os elementos, a descrição, a altura e o peso, o habitat e a linha evolutiva. O de um visto mostra a sombra, o número e o nome. Um "???" não abre nada | Proposta aceita pelo dono |
| A primeira captura de uma espécie mostra uma tela de "registrado no Bestiário" com a criatura nova | Pedido do dono |
| Evoluir para uma espécie nova também conta como capturar, e mostra o mesmo aviso | Pedido do dono |
| Ao escolher o inicial, só ele fica capturado. Os outros dois da escolha ficam vistos | Pedido do dono |
| As telas seguem os rascunhos mostrados ao dono: a grade de 3 colunas com a contagem no topo, o detalhe em blocos e o aviso por cima da luta com Continuar | Aprovado pelo dono ("pode seguir assim") |

Escolhas do planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| O registro mora numa tabela do jogador, `codex_entries` (`player_id`, `species_id`, `seen_at`, `caught_at?`), e capturado implica visto | Uma linha por espécie que o jogador conhece. Sem linha, a espécie nunca foi vista |
| A migração registra como capturadas as espécies que cada jogador já tem hoje, na equipe ou no Santuário, e como vistos os iniciais (`starter_options`) que ele não tem. As espécies anteriores dos Ecobeasts que já evoluíram não são recuperadas | É a regra da escolha do inicial aplicada a quem já jogava. O banco não guarda a espécie de antes da Evolução |
| O visto é gravado na hora em que o Ecobeast inimigo entra em campo, na resposta que traz o `creature_entered`, e não no fim da luta | Fechar o app no meio da luta não apaga o que o jogador viu. Um inimigo da reserva que nunca entrou não conta |
| A luta de teste do menu Debug também registra | É como o dono testa o Bestiário sem procurar pelo mapa. Só existe com `ENABLE_TEST_BATTLE` |
| A luta antiga (legado da `battle-core`) não registra o visto. Uma captura nela registra, porque o fim da luta é o mesmo, mas a resposta dela não avisa | Nenhuma tela a abre |
| As respostas da luta e da Evolução dizem quais espécies foram registradas como capturadas pela primeira vez (`registered_species_ids`), e o jogo mostra o aviso só com elas | O servidor é a autoridade; o jogo não compara listas |
| O número é o `id` da espécie, com 3 dígitos (`#004`) | O `GDD.md` já usa o id como número. Ids nunca mudam |
| O detalhe abre por cima da grade e fecha no voltar | O Bestiário é lido uma vez ao abrir, e a linha evolutiva troca o detalhe sem sair da tela |
| Na linha evolutiva, cada espécie segue a regra da grade (colorida, sombra ou "???"), e tocar numa que não seja "???" mostra o detalhe dela | O jogador não descobre uma Evolução que ainda não viu |
| O habitat lista os biomas de `species_biomes` com taxa acima de 0, do mais comum para o mais raro, sem a taxa | É o que o jogador precisa para procurar o Ecobeast |
| Só em build de debug, o Bestiário ganha o botão "Limpar Bestiário", que apaga os registros do jogador (`DELETE /v1/me/codex`, só com `ENABLE_TEST_BATTLE`) | O dono testa o aviso de registro de novo sem apagar o progresso |

## Fora do escopo

- Ecobeast inimigo visto no mapa, sem luta.
- Formas diferentes de uma espécie, Prismáticos e gênero no Bestiário.
- Busca, filtros e ordenações na grade.
- Som do Ecobeast no detalhe (o `call.wav` da [creature-sounds](../creature-sounds/) ainda não toca no jogo).
- Recompensas por completar o Bestiário, porcentagem e conquistas.
- Molduras e skins das cartas do Bestiário (pós-lançamento, `GDD.md`).
- A luta antiga da `battle-core`.

## Pré-requisitos

- [capture](../capture/), [progression](../progression/), [board-battle](../board-battle/) e [npc-tamers](../npc-tamers/) concluídas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-codex-records](01-codex-records.md) | Servidor: a tabela `codex_entries` com a carga de quem já joga, o registro do visto e do capturado nas lutas, na Evolução e no inicial, e as rotas do Bestiário | concluída |
| 2 | [02-codex-screen](02-codex-screen.md) | Jogo: a tela do Bestiário, com a grade, a contagem e o detalhe, aberta pelo Hub | rascunho |
| 3 | [03-codex-registered](03-codex-registered.md) | Jogo: o aviso "Novo registro no Bestiário!" depois da captura e da Evolução | rascunho |

O desenho compartilhado está no [architecture.md](architecture.md).
