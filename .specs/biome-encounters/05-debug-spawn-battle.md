# 05. Spawn de depuração que dá para enfrentar

- **Status:** concluída (falta o dono testar no editor)
- **Depende de:** [04-map-creatures](04-map-creatures.md) e [wild-battle/13](../wild-battle/13-debug-menu.md)

## Contexto

Hoje, o spawn do menu de depuração ([wild-battle/13](../wild-battle/13-debug-menu.md)) só desenha o Ecobeast no jogo. O servidor não sabe que ele existe, então Procurar no hexágono dele responde "Nada por aqui". Em 2026-11-05, o dono pediu: "no spawn eu quero spawnar um ecobeast que dê para enfrentar; se eu colocar procurar, deve poder enfrentar ele". Serve para testar a luta contra uma espécie à escolha, como o Ruvak com as folhas novas da [board-battle/07](../board-battle/07-battle-sprites.md), sem esperar o sorteio do mapa.

## Escopo

- Servidor: uma rota de depuração que põe um Ecobeast na exploração guardada, e outra que tira os que ela pôs.
- Jogo: o spawn do menu passa a usar essas rotas, e Procurar enfrenta o Ecobeast do spawn como enfrenta um do mapa.

## Fora do escopo

- Escolher o nível no menu. A rota aceita um nível, mas o menu usa o padrão.
- Spawn de espécies sem as folhas do mapa: elas continuam desativadas no menu, porque não apareceriam no mapa.
- Guardar os Ecobeasts do spawn depois de sair do mapa: como os do sorteio, eles somem com a exploração.

## Requisitos

**Servidor**

- **RF-01:** `POST /v1/me/exploration/spawns`, com sessão, recebe `{"species_id", "q", "r", "level"?}` e põe um Ecobeast dessa espécie no hexágono `(q, r)` da exploração guardada. Responde `201 {"creature": {"id", "species_id", "q", "r"}}`, no formato dos Ecobeasts do mapa.
- **RF-02:** Sem `level`, o nível é a média de nível da equipe, arredondada. Com `level`, ele vale de 1 a 100.
- **RF-03:** O `id` é novo na exploração. Procurar no hexágono enfrenta esse Ecobeast como um do sorteio. Se o hexágono tiver mais de um, o servidor sorteia entre eles, como já faz.
- **RF-04:** `DELETE /v1/me/exploration/spawns` tira da exploração todos os Ecobeasts postos pela rota do RF-01, e só eles, e responde `200 {"removed_ids": [...]}`.
- **RF-05:** As duas rotas só existem com `ENABLE_TEST_BATTLE` ligada; sem ela, dão `404`, como as outras rotas de teste. Sem exploração, dão `404` "Essa exploração acabou. Saia e entre de novo.". Uma espécie que não existe, ou um nível fora de 1 a 100, dão `400` "Esse inimigo não existe.".
- **RF-06:** A rota não confere se o hexágono existe no mapa nem se o Domador está nele. O servidor não guarda os hexágonos, e Procurar já confere a posição do Domador ([03](03-exploration-session.md)).

**Jogo**

- **RF-07:** Tocar num Ecobeast do menu de spawn pede a rota do RF-01 no hexágono do Domador. Com a resposta, ele entra nos Ecobeasts do mapa, aparece passeando ali, e a linha de aviso diz "<Nome> apareceu aqui. Toque em Procurar.". O menu continua aberto, para colocar outros.
- **RF-08:** Procurar no hexágono abre a luta no tabuleiro contra ele, e depois da luta ele some do mapa, como os outros ([04](04-map-creatures.md)).
- **RF-09:** "Remover todos" pede a rota do RF-04 e tira do mapa os ids que voltaram. Ele fica desativado quando não há nenhum Ecobeast do spawn no mapa.
- **RF-10:** Uma recusa do servidor, como a rota desligada, aparece na linha de aviso em vermelho.

## Critérios de aceite

- [ ] Com a rota ligada, o spawn põe um Ecobeast no hexágono do Domador, e Procurar abre a luta contra ele.
- [ ] Depois da luta, ele não está mais no mapa.
- [ ] "Remover todos" tira só os do spawn, e Procurar no hexágono volta a dizer "Nada por aqui".
- [ ] Sem `ENABLE_TEST_BATTLE`, as rotas dão 404 e o jogo mostra a recusa.
- [x] Os testes do servidor passam, e o projeto abre sem erros nem avisos de script.

## Desenho técnico

**Servidor:**

- `server/src/domain/exploration/spawns.ts`: o `MapSpawn` ganha `debug?: boolean`.
- `server/src/exploration/exploration.dto.ts`: `DebugSpawnBodyDto`, `DebugSpawnResponseDto` e `DebugClearResponseDto`.
- `server/src/exploration/exploration.service.ts`: `debugSpawn(userId, body)` e `debugClear(userId)`, com o `ConfigService`.
- `server/src/exploration/exploration.controller.ts`: `POST spawns` e `DELETE spawns`.
- `server/test/exploration.e2e-spec.ts`: os casos dos RF-01 a RF-05, e a luta no tabuleiro contra o Ecobeast do spawn.

**Jogo:**

- `GameService.debug_spawn(species_id, coord) -> Result` (com um `MapCreature`) e `debug_clear_spawns() -> Result` (com os ids), no `ApiGameService` e no `Session`.
- `res://screens/exploration/exploration_screen.gd`: o spawn e o "Remover todos" passam a usar o servidor. A lista local de sprites do spawn sai.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test && npm run test:e2e -- exploration board-battle
godot --headless --path client --quit-after 60
```

No jogo: F5, Explorar zona, Debug, Spawn, Ruvak, Procurar.

## Tarefas

- [x] As rotas no servidor, com os e2e.
- [x] O spawn e o "Remover todos" no jogo.
- [ ] Atualizar o README da iniciativa, rodar a verificação e fazer o commit.

## Resultado da verificação

**Conferido por quem implementou, sem janela:**

- **Servidor:** typecheck e lint sem erros. Os testes de unidade passam (690). Os e2e da exploração (19, 7 deles novos) e da luta no tabuleiro (22) também passam.
- **Testes novos:** cobrem o formato da resposta, o nível da equipe, o nível escolhido e a luta no tabuleiro contra o Ecobeast do spawn, que sai do mapa depois. Também cobrem os 400, o 404 sem exploração, o "remover" tirando só os do spawn e a rota desligada.
- **Jogo:** o projeto abre sem erros nem avisos, e todos os scripts e cenas compilam, inclusive a tela do mapa.

**Fica para o dono, com F5:** o fluxo no jogo. Explorar zona → Debug → Spawn → um Ecobeast → Procurar → a luta → voltar ao mapa sem ele. Depois, "Remover Ecobeasts". O servidor de desenvolvimento precisa estar com o código novo e com `ENABLE_TEST_BATTLE=true`.
