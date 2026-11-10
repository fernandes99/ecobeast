# 04. Domadores no mapa

- **Status:** concluída (falta o teste do dono no editor)
- **Depende de:** [03-tamer-api](03-tamer-api.md), [architecture.md](architecture.md)

## Contexto

O servidor já manda os Domadores no `map` e abre a luta contra eles. Falta o jogo:

- A tela de exploração (`res://screens/exploration/exploration_screen.gd`) desenha o Domador do jogador com o `TamerSprite` e os selvagens perto dele com o `CreatureSprite`, que passeia dentro do hexágono. Procurar abre a tela `board_battle` com `coord`, e a volta tira o selvagem enfrentado (`Session.take_fought_spawn`).
- A tela da luta (`res://screens/board_battle/board_battle_screen.gd`) escreve o log letra por letra (`_type_line`), num painel com o estilo `BattleTheme.LOG`, e mostra Fugir e as Esferas da Mochila. No fim, `_leave` volta com `Router.back()`.

Godot, para quem está começando: uma **cena** (`.tscn`) é uma árvore de **nós** salva em arquivo, e o script `.gd` dá comportamento ao nó raiz dela. Um `class_name` registra o script como um tipo, que outras partes usam pelo nome (como `TamerSprite.new()`). O `Session` é um **autoload**: um nó que o Godot cria uma vez e deixa acessível de qualquer script.

## Escopo

- Os Domadores passeando no mapa, com as folhas do template.
- A fala no log, o mapa travado e a luta ao tocar no log.
- A luta contra Domador: sem Fugir, sem Esferas, com o nome dele no log.
- A volta: vitória ao mapa sem o Domador, derrota ao Hub.
- Os botões de Domador no menu Debug do mapa.

## Fora do escopo

- O Desafiar do Hub: vem na [05](05-hub-challenge.md).
- Sprite próprio, retrato ou cartão do Domador na luta.
- O Domador virar para o jogador ou andar até ele.

## Requisitos

### Mapa

- **RF-01:** `ExplorationMap` lê `tamers` do `map` em `MapTamer` (`id`, `coord`, `name_id`, `greeting_id`), com `tamer_at(coord) -> MapTamer` (nulo sem Domador).
- **RF-02:** cada Domador a até `CREATURE_RADIUS` hexágonos do jogador é um nó `TamerSprite`, com as folhas do template, na mesma escala do jogador, passeando dentro do hexágono dele como um `CreatureSprite`: para um pouco, anda até um ponto sorteado do hexágono com a folha `run`, olhando para onde anda, e para de novo com a `idle`.
- **RF-03:** o passeio sai do `CreatureSprite` para o `WanderingSprite`, que ele e o `TamerSprite` estendem. Os Ecobeasts do mapa passeiam como hoje, e o Domador do jogador, que nunca chama `wander_in`, não passeia.
- **RF-04:** quando o jogador termina um passo num hexágono com Domador, o mapa trava: tocar no mapa, Procurar, Mochila, Voltar, Debug e o voltar do aparelho não fazem nada (`handle_back` devolve `true`).
- **RF-05:** com o mapa travado, um painel no estilo `BattleTheme.LOG` aparece sobre o mapa, acima dos botões, e escreve `"{nome}: {fala}"` letra por letra, na velocidade do log da luta, com o triângulo de "continua" no fim. Nome e fala vêm do `GameData` pelos ids do Domador.
- **RF-06:** tocar no painel enquanto a fala é escrita mostra a frase inteira. Tocar com a frase inteira abre a tela `board_battle` com `tamer_coord` e o terreno do hexágono, como o Procurar faz.
- **RF-07:** ao voltar da luta, o Domador enfrentado sai do mapa (`Session.take_fought_tamer`, com o `tamer_id` da resposta), e o mapa destrava. Se a luta não chegou a começar, o Domador continua lá, e o mapa fica destravado até o jogador sair do hexágono e entrar de novo.
- **RF-08:** com Domador e selvagem no mesmo hexágono, a fala aparece ao chegar, e depois da luta Procurar enfrenta o selvagem como hoje.

### Luta

- **RF-09:** `Session.start_board_tamer_battle(coord)` chama `POST /v1/me/board-battle/tamer`, e a tela, com `tamer_coord`, a usa no lugar do encontro selvagem.
- **RF-10:** o `BoardBattleView` ganha `tamer_name_id` e `tamer_source` (vazio sem Domador), lidos do `battle.tamer`.
- **RF-11:** contra Domador, o botão Fugir não aparece, e a Mochila não lista Esferas.
- **RF-12:** contra Domador, a entrada de um Ecobeast do NPC no log é "{nome} enviou {Ecobeast}!", no lugar de "Um {Ecobeast} selvagem apareceu!". O fim da vitória é "Você venceu {nome}!" e o da derrota "{nome} venceu a luta.". As linhas de XP e de moedas ficam como hoje.
- **RF-13:** na derrota contra um Domador do mapa, o botão de saída diz "Voltar ao Hub", e tocar nele relê o jogador, como hoje, e abre o Hub com `Router.go_to(&"hub")`, fechando o mapa. Nos outros fins, a saída é a de hoje.

### Depuração

- **RF-14:** só em build de debug, o menu Debug do mapa ganha "Domador 1×1", "Domador 2×2" e "Domador 3×3". Cada um chama `POST /v1/me/exploration/tamers` no hexágono do jogador, põe o Domador no mapa e trava o mapa com a fala, como se o jogador tivesse acabado de chegar.
- **RF-15:** o botão de limpar o spawn, que passa a se chamar "Remover spawns", também tira do mapa os Domadores da depuração (`removed_tamer_ids`).

## Critérios de aceite

- [ ] Ao andar pelo mapa, aparecem Domadores com o sprite do template, passeando dentro do hexágono deles, e nunca na água.
- [ ] Entrar no hexágono de um Domador escreve "{nome}: {fala}" no painel, e nada mais responde até tocar no painel.
- [ ] Tocar no painel abre a luta, com 1, 2 ou 3 Ecobeasts do NPC, sem Fugir e sem Esferas na Mochila.
- [ ] O log mostra "{nome} enviou {Ecobeast}!" para cada Ecobeast do NPC.
- [ ] Vencer volta ao mapa, sem o Domador, e com as moedas e o XP do Domador no log.
- [ ] Perder mostra "Voltar ao Hub", e o Hub abre com as moedas atualizadas. Entrar em Explorar zona de novo gera outro mapa.
- [ ] Com a equipe toda sem HP, a luta mostra "Cure sua equipe no Refúgio.", e de volta ao mapa o jogador consegue sair do hexágono.
- [ ] Os três botões de Domador no Debug abrem lutas de 1×1, 2×2 e 3×3.
- [ ] Os selvagens continuam passeando e sendo enfrentados como antes.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos:

- `res://domain/models/map_tamer.gd`: `MapTamer`, com `from_dict`, como o `MapCreature`. O modelo guarda só os ids, porque `domain/` não usa o `GameData`: quem mostra a fala monta `"{nome}: {fala}"`.
- `res://ui/components/wandering_sprite.gd`: `WanderingSprite`, que estende `SheetSprite` e tem o passeio que morava no `CreatureSprite` (`wander_in`, `random_spot`, `face_toward`). Quem estende diz que animação toca parado e andando, em `_play_still` e `_play_moving`.
- `res://screens/exploration/tamer_greeting_panel.gd`: `TamerGreetingPanel`, o painel da fala, montado em código no estilo `BattleTheme.LOG`, com o sinal `tapped` quando a frase inteira é tocada. Ele é um nó `TamerGreeting` na cena do mapa, acima dos botões.

Arquivos alterados:

- `res://ui/components/creature_sprite.gd`: estende `WanderingSprite` e só escolhe as folhas.
- `res://ui/components/tamer_sprite.gd`: estende `WanderingSprite`, monta as folhas uma vez para todos os Domadores e toca `run` andando. O desenho pedia um `NpcTamerSprite` à parte, mas ele não teria nada além do `TamerSprite`: o Domador NPC é um `TamerSprite` com `wander_in`.
- `res://domain/models/exploration_map.gd`: `tamers` e `tamer_at`.
- `res://domain/models/board_battle_view.gd` e `board_turn.gd`: `tamer_name_id`, `tamer_source` e `tamer_id`.
- `res://core/services/game_service.gd` e `api_game_service.gd`: `start_board_tamer_battle` e `debug_tamer`. O `debug_clear_spawns` passa a devolver `{"creature_ids", "tamer_ids"}`.
- `res://core/autoload/session.gd`: `start_board_tamer_battle`, `take_fought_tamer` e `debug_tamer`.
- `res://screens/exploration/exploration_screen.gd` e `.tscn`: os sprites dos Domadores (`_place_wanderer` serve aos dois tipos de sprite), o desafio ao terminar um passo, o travamento (`_challenger`), o painel e a linha "Domador 1×1 / 2×2 / 3×3" no menu Debug.
- `res://screens/board_battle/board_battle_screen.gd`: `tamer_coord` no `setup`, o nome do Domador (`_meet_tamer`), Fugir escondido, as frases do fim e a saída para o Hub (`_exits_to_hub`).
- `res://screens/battle/battle_items_panel.gd`: o `open` recebe `allow_capture`, e com ele falso as Esferas não aparecem.
- `res://screens/battle/battle_narrator.gd`: `set_tamer_name` e a linha "{nome} enviou {Ecobeast}!".
- `client/CLAUDE.md`: uma linha sobre os Domadores do mapa.

## Verificação

```bash
cd server && npm run start:dev
godot --headless -d --path client --quit-after 60
```

No editor (F5), em 360×640, com `ENABLE_TEST_BATTLE` ligada no servidor:

- Andar até um Domador do mapa e conferir a fala, o travamento e a luta.
- Usar os três botões de Domador do Debug e vencer pelo menos um.
- Perder uma luta contra Domador (God desligado, equipe fraca) e conferir a volta ao Hub.
- Conferir que o Domador some depois da vitória e que os selvagens continuam iguais.

O que foi conferido em 2026-11-09: o projeto abre sem erro de script, e os avisos com `-d` são todos de arquivos que esta fase não tocou. Uma cena temporária, que roda com os autoloads e já foi apagada, carregou as cenas do mapa e da luta, compilou os scripts delas e conferiu: o mapa lê os Domadores e ignora um incompleto; o `tamer_at`; o `tamer_id` e o Domador na luta, e a falta deles contra selvagem; "Um Ruvo selvagem apareceu!" e "Lia enviou Ruvo!"; o Domador NPC passeia e o do jogador não; e o painel, em que o primeiro toque completa a frase e o segundo abre a luta. Os passos no editor, com o jogo de verdade, ficam para o dono.

## Tarefas

- [x] Modelos e serviços.
- [x] O passeio compartilhado (`WanderingSprite`).
- [x] Os Domadores no mapa, o travamento e o painel da fala.
- [x] A luta contra Domador na tela e no narrador.
- [x] A volta ao Hub na derrota.
- [x] Os botões de Debug.
- [x] Atualizar o `client/CLAUDE.md`, rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.
