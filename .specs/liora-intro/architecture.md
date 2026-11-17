# liora-intro: arquitetura

O desenho que as fases da [liora-intro](README.md) compartilham.

## A entrada nova do jogo

| O jogador | O jogo abre |
| --- | --- |
| sem Domador (`player` nulo) | `POST /v1/me` sem corpo, e depois o resto da tabela |
| sem nome, ou com nome e sem inicial | `Home.go()`: as cenas de Liora cuidam do resto |
| com inicial | `Home.go()`, como na [home-island/02](../home-island/02-open-at-home.md) |

Sem ilha casa (`Session.home_island_id == 0`), não há onde tocar a introdução. O jogo abre a tela Aparência no modo de entrada, que ganha o campo de nome quando o Domador não tem, e depois a escolha do inicial, como antes desta iniciativa. Esse caminho existe para o banco de desenvolvimento e não é a introdução.

Quem decide é o `Home.start()` (`client/core/home.gd`), chamado pelo `main.gd` e pelo "Apagar Domador" do Perfil. A tela de nome (`res://screens/title/`) sai do projeto e do `Router`.

## O Domador sem nome

- `players.name` passa a aceitar `""`, que quer dizer "ainda sem nome". Um nome de verdade segue a regra de hoje (`NAME_PATTERN`, de 2 a 16 letras, números ou espaços).
- `POST /v1/me` com `name` cria como hoje. Sem `name` (corpo vazio ou sem o campo), cria com `""`.
- `PUT /v1/me/name` com `{ "name": "..." }` dá o nome. Ele só vale uma vez: com o nome já dado, 409 "Seu Domador já tem nome.". Renomear fica fora.
- `GET /v1/me` devolve `name: ""`. No jogo, `Player.has_name() -> bool`.

## Liora sem equipe

No servidor, `ExplorationService.start` aceita o Domador sem equipe só na ilha casa (`islands.is_home`):

| Sem Domador | Sem equipe, na casa | Sem equipe, em outra ilha ou na zona |
| --- | --- | --- |
| 409 "Crie seu Domador primeiro." (como hoje) | o mapa, como para quem tem equipe | 409 "Escolha seu primeiro Ecobeast antes de viajar." |

As lutas já recusam quem não tem equipe ([board-battle](../board-battle/)). No jogo, sem equipe em Liora:

| O que | Faz |
| --- | --- |
| Procurar e o toque num selvagem | escondido; o toque não abre luta |
| O botão Menu | escondido |
| Encostar na Viagem | "Você precisa de um Ecobeast para viajar." |
| Encostar no Refúgio | "Você ainda não tem Ecobeasts para cuidar." |
| A Loja, a conversa com NPCs e as cenas | como sempre |

## As contas antigas

A migration `intro_skip` liga o Marco `introducao_pulada` para cada jogador que já tem um Ecobeast:

```sql
INSERT INTO "ecobeasts"."player_story_marks" ("player_id", "mark")
SELECT DISTINCT "player_id", 'introducao_pulada' FROM "ecobeasts"."creature_instances"
ON CONFLICT DO NOTHING;
```

A primeira cena da introdução tem `forbids: ["introducao_pulada"]`, e as outras dependem dela pelos Marcos, então nenhuma roda para essas contas. O servidor continua sem saber o que o Marco quer dizer. A Linha da história mostra o `introducao_pulada` sem dono; isso é esperado e fica escrito na descrição da cena.

## O texto das falas

`StoryText` (`client/core/story/story_text.gd`, `class_name StoryText`, só funções estáticas):

- `static func render(text: String, player: Player) -> String`: troca `{nome}` pelo nome do Domador e cada `{forma masculina|forma feminina}` pela forma do corpo dele (`body_types.slug`: `male` pega a primeira, `female` a segunda). Sem Domador, ou com um corpo que não é nenhum dos dois, fica a primeira.
- `static func check(text: String) -> String`: o erro do texto, ou `""`. Um `{` sem `}`, chaves dentro de chaves, um trecho com mais de uma `|` ou com um lado vazio, e um trecho sem `|` que não seja `{nome}` são erros. Cada lado tem até 40 caracteres.

O `StoryPlayer` usa o `render` em toda fala (`say`) e em toda opção de escolha (`choice`); o `StoryValidator` usa o `check` nos mesmos lugares, com a mensagem "Cena X: passo N: <erro>".

Exemplo: `Você chegou {cansado|cansada}, {nome}?`

## Os passos novos

| `type` | Campos | Faz |
| --- | --- | --- |
| `create_tamer` | — | abre a criação por cima do mapa ([fase 03](03-intro-steps.md)) e espera o "Pronto". O Domador sem nome escolhe nome e aparência; com nome, só a aparência |
| `choose_starter` | — | abre a escolha do inicial (`Router.push(&"starter_select", {"story": true})`) e espera a escolha. Quem já tem inicial pula o passo |

Os dois só valem em cenas da ilha casa. O `StoryValidator.home_errors(scene, home_island_id)` devolve "Cena X: passo N: só vale em cenas da ilha casa." para cada um fora dela. Como a casa é dado do servidor, essa conferência roda ao tocar a cena (uma cena recusada não toca, e o console avisa) e ao salvar no F2 (o "Casa do jogador" da ilha aberta), e não no `load_scenes()` do começo do jogo.

## A criação por cima do mapa

A Aparência de hoje (`appearance_screen.gd`) monta as abas dos lugares e as opções de peça e cor. Essa parte sai dela para o componente `TamerEditor` (`client/ui/components/tamer_editor.gd`), que tem:

- o campo de nome, só quando o Domador não tem nome, com a regra e a mensagem de hoje;
- o corpo, as abas e as opções da Aparência;
- o sinal `changed(appearance: TamerAppearance)` a cada mudança.

A tela Aparência passa a usar o `TamerEditor`, com a prévia dela. A criação em Explorar usa o mesmo componente, num painel na metade de baixo da tela. Em cima, o mapa, com a câmera no Domador e o Domador vestindo cada mudança na hora. O "Pronto" fica desabilitado enquanto o nome é inválido. Ao tocar nele, o jogo grava o nome (`PUT /v1/me/name`, se o Domador não tinha) e depois a aparência (`PUT /v1/me/appearance`). Um erro aparece no painel, que continua aberto.

## Os NPCs pessoas

- `npcs.sprite` passa a aceitar nulo. `npcs` ganha `body_type_id` e `skin_palette_id`, nulos, com FK para `body_types` e `palettes`.
- O CHECK `npcs_look_check` exige exatamente um dos dois: `(sprite IS NULL) <> (body_type_id IS NULL)`, e `skin_palette_id` só junto com `body_type_id`.
- A tabela nova `npc_appearance_parts` (`npc_id`, `appearance_slot_id`, `appearance_part_id`, `palette_id`) é igual a `player_appearance_parts`, com a chave `(npc_id, appearance_slot_id)` e as mesmas regras de peça, de corpo e de paleta. Ela entra no catálogo (`GET /v1/catalog`) e no `CatalogValidator`.
- `TamerAppearance.for_npc(npc_id: int) -> TamerAppearance` monta a aparência do NPC pelo catálogo (null para um NPC de Ecobeast). O `NpcSprite` do NPC pessoa fica sem folhas próprias e desenha um `TamerSprite` filho, que segue a linha, o espelho e a animação dele (parado ou correndo). `NpcSprite.make(map_npc)` cria o certo, ou null sem desenho. Vale no mapa, nos atores das cenas e no mapa do F2.
- A rota `PUT /v1/editor/npcs/:id/appearance`, com o mesmo corpo e as mesmas regras do `PUT /v1/me/appearance`, troca as peças de um NPC pessoa numa transação e libera o catálogo novo (`BundleService.invalidate()`), como o editor de Técnicas. Um NPC de Ecobeast responde 400 "Esse NPC é um Ecobeast.".
