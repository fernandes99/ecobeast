# 05. Mochila, Esfera, troca e fuga no tabuleiro

- **Status:** rascunho
- **Depende de:** [04](04-board-screen.md)

## Contexto

A tela do tabuleiro joga Técnicas, anda e repõe quem cai, mas Mochila, Trocar e Fugir estão desabilitados, e Explorar zona ainda abre a luta antiga. Esta fase completa as ações e troca a luta de Explorar zona pela do tabuleiro. A luta antiga deixa de ser aberta por qualquer tela, mas o código dela, no jogo e no servidor, fica no repositório, como legado, até o dono pedir para apagar.

## Escopo

- Mochila: itens e Esferas, com o alvo da Esfera no tabuleiro.
- Trocar e Fugir.
- Explorar zona abrindo sempre a luta no tabuleiro.

## Fora do escopo

- Apagar a luta antiga, as rotas `/v1/me/battle` ou as telas de `res://screens/battle/` que não forem reaproveitadas.
- Visual novo dos painéis de Mochila e de troca. Eles são os de hoje.

## Requisitos

- **RF-01:** Mochila abre o `BattleItemsPanel` de hoje. Um item de cura manda `{type: 'item', item_id, team_index}`, para qualquer Ecobeast da equipe.
- **RF-02:** Uma Esfera acende os hexágonos de todos os selvagens do tabuleiro. Tocar num deles manda `{type: 'capture', item_id, target}`. O `CaptureOverlay` de hoje mostra o `capture_attempted`, e o capturado sai do tabuleiro.
- **RF-03:** Trocar abre o `NextCreaturePanel` com a reserva de pé e manda `{type: 'switch', team_index}`. Quem entra aparece no hexágono de quem saiu.
- **RF-04:** Fugir manda `{type: 'flee'}`. Com o Ecobeast já tendo andado, o jogo pergunta antes se desfaz o passo, porque o servidor recusa andar e fugir juntos.
- **RF-05:** As ações da Mochila, de troca e de fuga mandam o `move`, quando ele andou, menos a fuga.
- **RF-06:** Explorar zona abre sempre a luta no tabuleiro. "Tabuleiro: ligado/desligado" sai do menu de depuração, e o "Teste 2×2" e o "Teste 3×3" ficam.
- **RF-07:** A luta antiga não abre por nenhuma tela. A rota `&"battle"` do `Router` e as rotas `/v1/me/battle` continuam existindo. Em `/docs`, as rotas antigas ficam marcadas como legado.
- **RF-08:** Os e2e da luta antiga (`battle`, `battle-items`, `capture` e `progression` em `server/test/`) saem do `npm run test:e2e` e passam para `npm run test:e2e:legacy`, para quem mexer no código antigo. Antes disso, os e2e da luta no tabuleiro cobrem o que eles cobriam depois da luta: HP, PP, status, captura, XP, subida de nível e Evolução. Decisão do dono, em 2026-11-04, para a suíte ficar mais rápida.

## Critérios de aceite

- [ ] Curar um Ecobeast da reserva pela Mochila gasta a vez e sobe o HP dele.
- [ ] Uma Esfera num selvagem a 4 hexágonos tenta a captura, e o capturado vai para a equipe ou para o Santuário, como hoje.
- [ ] Trocar põe quem entra no hexágono de quem saiu, e ele só joga na rodada seguinte.
- [ ] Fugir com sucesso volta para o mapa, e a falha gasta a vez.
- [ ] Um encontro de Explorar zona abre o tabuleiro sem nada no menu de depuração.
- [ ] Nenhuma tela abre `res://screens/battle/battle_screen.tscn`, conferido por busca no código.
- [ ] `npm run test:e2e` não roda os e2e da luta antiga, e `npm run test:e2e:legacy` roda e passa.
- [ ] Os testes do servidor passam, e o projeto abre sem erros nem avisos de script.

## Desenho técnico

**Alterar:**

- `res://screens/board_battle/board_battle_screen.gd`, `board_action_panel.gd` e `board_view.gd`, com as ações e o alvo da Esfera.
- `res://screens/exploration/exploration_screen.gd` e `.tscn`, com a luta no tabuleiro sempre e o menu de depuração sem o liga e desliga.
- `server/src/battle/battle.controller.ts`, só com o texto de legado no `/docs`.
- `server/vitest.config.e2e.ts` e `server/package.json`, com o `test:e2e:legacy`.

**Specs:** `CLAUDE.md` (o escopo atual), `.specs/roadmap.md` e `.specs/battle-screen/README.md`, dizendo que a luta de Explorar zona é a do tabuleiro.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test && npm run test:e2e
godot --headless --path client --quit-after 60
```

F5, Explorar zona e encontros jogados até o fim: um vencendo, um capturando, um fugindo e um trocando de Ecobeast no meio. Quem implementa diz o que conferiu e o que ficou para o dono.

## Tarefas

- [ ] Mochila e Esfera (RF-01 e RF-02).
- [ ] Trocar e Fugir (RF-03 a RF-05).
- [ ] Explorar zona no tabuleiro e a luta antiga como legado (RF-06 a RF-08).
- [ ] Atualizar `CLAUDE.md`, o roadmap e a battle-screen.
- [ ] Rodar a verificação, marcar a spec e o README como `concluída` e fazer o commit `feat: Mochila, Esfera, troca e fuga no tabuleiro`.
