# 03. A ilha lembrando o que foi descoberto

- **Status:** concluída
- **Depende de:** [01](01-discovery-store.md), [02](02-fog-layer.md)

## Contexto

Depois da [02](02-fog-layer.md), a névoa funciona, mas nas ilhas recomeça a cada entrada. Esta fase liga o jogo às rotas da [01](01-discovery-store.md): a ilha abre com o que já foi descoberto, e o que o Domador descobre vai para o servidor ([README](README.md#decisões)).

## Escopo

- Ler `discovered` da entrada e começar a névoa da ilha com esses hexágonos.
- Mandar os hexágonos novos de uma ilha ao servidor em lotes.
- O botão de debug "Esquecer ilha".

## Fora do escopo

- Guardar a descoberta do mapa sorteado.
- Guardar a descoberta no aparelho sem internet: o jogo é só online.

## Requisitos

- **RF-01:** `ExplorationMap` ganha `discovered: Array[Vector2i]`, preenchido por `ApiGameService.start_exploration` a partir do `discovered` da resposta (fora de `map`). Um item malformado é ignorado.
- **RF-02:** Numa ilha, a tela `exploration` cria a `MapDiscovery` com `discovered` (`add`) antes do `reveal_around` da partida, e manda para a névoa tudo junto.
- **RF-03:** Os hexágonos que `reveal_around` devolve numa ilha vão para a fila do `Session` (`queue_island_discoveries(island_id, coords)`). Os que vieram de `discovered` não vão. A fila mora no `Session`, e não na `MapDiscovery` como dizia a spec aprovada, porque o autoload continua vivo depois que a tela some, e o envio que estava no meio termina sem erro.
- **RF-04:** `Session.send_island_discoveries()` manda a fila pelo `GameService.add_island_discoveries(island_id, coords)` novo, que chama `POST /v1/me/islands/{id}/discoveries`, em lotes de até 1000 (`Session.DISCOVERY_BATCH`), um envio por vez. A tela o chama a cada `DISCOVERY_SYNC_INTERVAL = 5.0` s (um `Timer`, só numa ilha), ao ficar escondida (ir para uma luta, para a Loja ou para o Refúgio) e ao sair (`_exit_tree`). Se uma chamada falhar, o lote volta para a fila e vai na próxima, sem mensagem para o jogador; fechar o jogo nesse meio perde só o que estava na fila.
- **RF-05:** No mapa sorteado, nada vai para o servidor.
- **RF-06:** No menu Debug da exploração, numa ilha, o botão "Esquecer ilha" chama `Session.forget_island_discoveries(island_id)` (que tira a ilha da fila e chama `DELETE /v1/me/islands/{id}/discoveries`), limpa a descoberta e a névoa e descobre de novo em volta do Domador, onde ele está. No mapa sorteado, o botão fica desabilitado, como os outros botões que não valem ali.

## Critérios de aceite

- [x] Andar numa ilha, voltar ao Hub e entrar de novo: o que foi descoberto continua aceso, e o resto continua na névoa.
- [ ] O mesmo vale depois de fechar e abrir o jogo, e em outro aparelho com a mesma conta.
- [ ] Andar numa ilha e entrar numa luta logo depois: ao voltar ao Hub e à ilha, o caminho até a luta está aceso.
- [ ] Com o servidor fora do ar por alguns segundos enquanto anda, a descoberta chega ao servidor quando ele volta, sem aviso na tela.
- [x] No mapa sorteado, nenhuma chamada a `/discoveries` aparece no log do servidor.
- [x] "Esquecer ilha" deixa só o raio em volta do Domador, e entrar de novo na ilha começa assim.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script.

## Desenho técnico

- **Alterar:**
  - `client/domain/models/exploration_map.gd` (`discovered`)
  - `client/core/services/game_service.gd` e `client/core/services/api_game_service.gd` (`add_island_discoveries`, `forget_island_discoveries` e a leitura de `discovered`)
  - `client/core/autoload/session.gd` (a fila, `queue_island_discoveries` e `send_island_discoveries`)
  - `client/screens/exploration/exploration_screen.gd` e `.tscn` (o envio, o timer e o botão "Esquecer ilha")
- **Reutilizar:** o `Api.request` e o padrão de `Result` das outras chamadas do `ApiGameService`, e o jeito de desabilitar os botões do menu Debug fora das ilhas.

## Verificação

- F5 no Godot, com o servidor no ar e `ENABLE_TEST_BATTLE` ligada: andar numa ilha, voltar ao Hub, entrar de novo; fechar e abrir o jogo; "Esquecer ilha".
- Conferir as linhas em `ecobeasts.island_discoveries` pelo painel do Supabase.
- Os testes do servidor continuam passando.

## Tarefas

- [x] `discovered` no `ExplorationMap` e as chamadas no `GameService`.
- [x] Os pendentes, o envio em lotes e o envio ao sair.
- [x] "Esquecer ilha".
- [x] Atualizar `CLAUDE.md`, `client/CLAUDE.md`, o README e as tabelas das specs.

Conferido por Claude, pelo jogo aberto numa janela e guiado por uma cena temporária, com o servidor local: esquecer uma ilha, entrar (0 descobertos, 61 acesos), andar 5 hexágonos (106), voltar ao Hub e entrar de novo (106 vindos do servidor), a fila vazia depois do envio de 5 s, "Esquecer ilha" (61) e a entrada seguinte com 61; no mapa sorteado, nada na fila e o botão desabilitado. Fica para o dono: fechar e abrir o jogo, outro aparelho, a volta de uma luta e o servidor fora do ar no meio.
