# 03. O teleporte do mapa grande, só para depurar

- **Status:** concluída (falta o dono conferir no F5)
- **Depende de:** [02](02-island-map.md)

## Contexto

Em 2026-11-17, o dono pediu: "quero poder me teleportar no mapa clicando em algum lugar no mapa que abre do minimapa, mas isso só para admins (no caso eu para debugar)".

Hoje:

- **O mapa grande** (`IslandMapPanel`, [02](02-island-map.md)) mostra a `MinimapImage` inteira, com zoom e arrasto. Um toque nele não faz nada. O `MinimapImage.owner_at(pixel)` já diz de qual hexágono é um pixel da imagem.
- **O servidor confere a caminhada** só quando o Domador enfrenta alguém: Procurar e o Domador NPC chamam o `BattleRecordsService.confirmPosition`, que recusa ("longe demais") quando a distância em hexágonos, desde a última posição conferida, vezes 300 ms passa do tempo que se passou. Sem uma rota nova, um teleporte de 100 hexágonos deixaria o Procurar recusado por 30 s.
- **Quem é admin:** o servidor já tem a lista `MAP_EDITOR_USER_IDS`, a do F2, e o `EditorGuard`, que dá 404 com a lista vazia e 403 a quem não está nela. No jogo, o menu Debug de Explorar só aparece com `OS.is_debug_build()`.

## Escopo

- Tocar num hexágono do mapa grande teleporta o Domador para ele, só no jogo de depuração.
- A rota do servidor que muda a posição conferida, só para quem está em `MAP_EDITOR_USER_IDS`.

## Fora do escopo

- O teleporte para o jogador comum, ou como item ou ação do jogo.
- Teleportar para outra ilha.
- Um botão de teleporte no minimapa pequeno.

## Requisitos

### O servidor

- **RF-01:** `PUT /v1/me/exploration/position`, com `{ "q": <int>, "r": <int> }`, troca a posição conferida da exploração do usuário pelo hexágono dado e a marca como conferida agora. Assim, o Procurar e o Domador NPC valem nele na hora. A resposta é `{ "q", "r" }`.
- **RF-02:** A rota usa o `AuthGuard` e o `EditorGuard`: com `MAP_EDITOR_USER_IDS` vazia dá 404 "Rota não encontrada.", e quem não está nela recebe 403. Sem exploração aberta, dá 404 com a mensagem de hoje (`NO_EXPLORATION`, "Essa exploração acabou. Saia e entre de novo."). `q` e `r` fora de −1.000 a 1.000, ou que não são inteiros, dão 400.
- **RF-03:** O servidor não guarda o mapa e não confere se o hexágono é andável: isso fica com o jogo, como no andar normal.

### O jogo

- **RF-04:** Com `OS.is_debug_build()`, um toque no mapa grande, sem arrastar nem pinçar, escolhe o hexágono do pixel tocado (`MinimapImage.owner_at`). No jogo exportado sem depuração, o toque continua sem fazer nada.
- **RF-05:** O hexágono precisa estar no mapa e não pode bloquear o andar (`ExplorationMap.is_blocked_hex`). Senão, nada muda, e a barra de mensagem diz "Debug: não dá para ir para esse hexágono.". O hexágono não precisa ter sido descoberto.
- **RF-06:** Com um hexágono válido, o jogo chama a rota do RF-01 pelo `Session`. Se ela falhar, a mensagem de erro aparece na barra, e o Domador fica onde está; com 403 ou 404 da lista vazia, a mensagem é "Debug: o teleporte é só para quem está em MAP_EDITOR_USER_IDS.".
- **RF-07:** Se der certo:
  - o mapa grande fecha;
  - a caminhada para, e o Domador aparece no centro do hexágono, parado, com a altura dele na hora (sem a subida aos poucos);
  - a câmera e o minimapa vão para ele;
  - a névoa se abre em volta, e os hexágonos novos vão para a fila de descobertas da ilha, como numa caminhada;
  - os Ecobeasts e os Domadores NPC perto dele aparecem, e os longe somem, como depois de um passo;
  - quem segue o Domador (`_followers`) aparece num hexágono andável vizinho, ou no mesmo, se não houver.
- **RF-08:** O teleporte não roda durante uma cena, uma conversa, a fala de um Domador NPC nem a caminhada para uma ação: o mapa grande já não abre nesses casos.

## Critérios de aceite

- [ ] No F5, tocar num ponto descoberto longe no mapa grande leva o Domador para lá, com a câmera e o minimapa nele.
- [ ] Tocar num ponto não descoberto também leva, e a névoa se abre em volta.
- [x] Tocar na água funda ou num hexágono bloqueado não leva, e a mensagem aparece.
- [x] Arrastar o mapa grande não teleporta.
- [x] Logo depois do teleporte, o Procurar funciona, sem o "longe demais".
- [x] `PUT /v1/me/exploration/position` dá 200 a quem está em `MAP_EDITOR_USER_IDS`, 403 a quem não está e 404 sem exploração.
- [ ] A suíte do servidor passa, menos as 2 falhas que já existiam no `seed.e2e`.

## Desenho técnico

- **Servidor:**
  - `server/src/exploration/exploration.controller.ts` e `.dto.ts`: a rota e o corpo, com o `EditorGuard` (importado de `src/editor/`).
  - `server/src/battle/battle-records.service.ts`: um `setPosition(userId, position)` ao lado do `confirmPosition`, sem a conta do tempo.
  - `server/test/exploration-teleport.e2e-spec.ts`: o 200, o 403, o 404 e o Procurar logo depois.
- **Jogo:**
  - `client/screens/exploration/island_map_panel.gd`: `signal hex_tapped(coord: Vector2i)`, emitido num toque sem arrasto, só com `OS.is_debug_build()`.
  - `client/screens/exploration/exploration_screen.gd`: `_teleport(coord)`, com as regras do RF-05 ao RF-07.
  - `Session` e o serviço do jogador: `set_exploration_position(coord) -> Result`.
- **Reutilizar:** o `_discover`, o `_refresh_wild_sprites` e o `_place_player` da tela, e o `HexMapView.flat_center`.

## Notas da implementação

- O `setPosition` ficou no `ExplorationService`, que já guarda a exploração (`ExplorationStore`), e não no `BattleRecordsService`.
- `q` e `r` usam um validador só cada, para a mensagem de erro aparecer uma vez.
- Além da água, o teleporte recusa o hexágono cujo centro fica a até 8 px de uma parede ou de uma linha de peça, ou dentro de uma linha fechada (`ExplorationMap.is_walled_hex`, a conta do servidor), para o Domador não ficar preso dentro de uma casa. Quem segue o Domador também não cai nesses hexágonos.
- Com o hexágono recusado ou a rota com erro, o mapa grande fecha, para a mensagem da barra aparecer.
- O seguidor aparece no vizinho pelo `NpcSprite.jump_to`.
- Conferido sem janela, abrindo o jogo inteiro contra a API local: arrastar não teleporta; um toque num hexágono não descoberto a 15 hexágonos leva o Domador para o centro dele, fecha o mapa e abre a névoa; a água não leva e mostra a mensagem. O e2e confere o Procurar logo depois do teleporte.

## Verificação

- `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` no `server/`.
- `godot --headless --path client --quit-after 30`, e uma cena temporária, fora de `client/zz_tmp_check`, que abre Explorar numa ilha, toca no mapa grande e confere a posição, a névoa e a rota.
- F5: os critérios acima.

## Tarefas

- [x] A rota, o `setPosition` e o e2e.
- [x] O toque no mapa grande e o teleporte na tela.
- [x] O `client/CLAUDE.md`, o `server/CLAUDE.md` e as tabelas das specs.
