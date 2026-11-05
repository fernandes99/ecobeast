# 04. Tela do tabuleiro

- **Status:** concluída (o dono jogou no editor em 2026-11-05 e pediu o andar de 1 hexágono, feito na [05](05-board-actions.md))
- **Depende de:** [03](03-board-api.md), [architecture.md](architecture.md#jogo)

## Contexto

As rotas da luta no tabuleiro existem, mas o jogo só conhece a luta antiga (`res://screens/battle/`). Esta fase cria a tela do tabuleiro, com a vez do jogador (andar e usar uma Técnica), a vez dos selvagens, a entrada depois de uma queda, o fim da luta e o histórico. Explorar zona continua abrindo a luta antiga. A nova abre pelo menu de depuração, até a [05](05-board-actions.md) completar Mochila, Esfera, troca e fuga.

## Escopo

- Modelos, geometria, `Session` e serviço da luta no tabuleiro.
- A tela: topo, fila, tabuleiro, Ecobeasts, painel de ações e histórico.
- A vez do jogador com andar, Técnica, alvo e "Passar a vez".
- A reprodução dos eventos, com o andar animado.
- A escolha de quem entra depois de uma queda e do hexágono de entrada.
- O fim da luta, com as telas de hoje de subir de nível, Técnica nova e Evolução.
- O menu de depuração de Explorar zona: ligar o tabuleiro e as lutas de teste 2×2 e 3×3.

## Fora do escopo

- Mochila, Esfera, troca e fuga (vêm na [05](05-board-actions.md)). Nesta fase, os botões Mochila, Trocar e Fugir aparecem desabilitados.
- Animações de Técnica, sons e o fundo de floresta em volta do tabuleiro, que fica numa cor chapada.

## Requisitos

**Dados**

- **RF-01:** `BoardBattleView.from_dict` lê o `battle` da [03](03-board-api.md), e `BoardTurn` lê `{battle, events}`. Um campo que falta não derruba o jogo e vira um erro na tela.
- **RF-02:** `BoardGeometry` calcula a distância, os vizinhos, os hexágonos alcançáveis em até 3 passos por hexágonos livres e a área de uma Técnica, com as regras do [architecture.md](architecture.md#técnicas-no-tabuleiro).
- **RF-03:** A `Session` ganha `start_board_wild_battle(coord)`, `start_board_test_battle(enemies, slots)` e `board_vez(vez)`, pelo `ApiGameService`, com o `debug_god` de hoje no encontro.

**Tela**

- **RF-04:** O topo mostra o Domador, com a inicial, o nome e o nível, e o botão de informação, que abre o histórico.
- **RF-05:** A fila mostra os Ecobeasts que ainda jogam na rodada, na ordem, com o retrato e a cor do lado. Quem joga agora fica em destaque.
- **RF-06:** O tabuleiro desenha os hexágonos do `board`, com as cores das áreas, e as marcas, na cor do `ground_effect`.
- **RF-07:** Cada Ecobeast aparece no hexágono dele, com o `CreatureSprite` do [architecture.md](architecture.md#jogo), e com o nome, o nível e a barra de HP por cima.
- **RF-08:** O painel de baixo mostra as 4 Técnicas de quem joga, com o nome, a forma e o PP, e os botões Mochila, Trocar, Fugir e "Passar a vez". Sem PP em todas, aparece a Técnica de emergência.

**A vez do jogador**

- **RF-09:** Na vez de um Ecobeast do jogador, os hexágonos aonde ele chega andando ficam acesos. Tocar num deles faz o Ecobeast andar até lá, com a folha `walk`, sem pedir nada ao servidor. Tocar no hexágono de onde ele saiu, ou noutro aceso, desfaz ou refaz o passo.
- **RF-10:** Tocar numa Técnica acende, a partir de onde o Ecobeast está, os hexágonos que servem de alvo. Tocar num deles manda a vez, com `move` e `action`. Tocar de novo na Técnica a desliga. Uma Técnica em si mesmo vai direto, sem alvo.
- **RF-11:** "Passar a vez" manda `{type: 'wait'}`, com o `move` se ele andou.
- **RF-12:** Enquanto a vez vai e volta, o painel fica desabilitado. Uma recusa mostra a mensagem do servidor, devolve o Ecobeast para onde estava e reabre a vez.

**A resposta**

- **RF-13:** Os eventos são mostrados em ordem, um depois do outro: `moved` anda pelo caminho, um hexágono por ciclo da folha `walk`; `skill_used` acende a área por um instante; dano, cura e `ground_damage` mostram o número sobre o Ecobeast e movem a barra de HP; `fainted` tira o Ecobeast; `mark_placed` e `mark_ended` põem e tiram a marca; `creature_entered` põe o Ecobeast no hexágono dele.
- **RF-14:** O `moved` do próprio jogador não anda de novo, porque o Ecobeast já está lá.
- **RF-15:** Cada evento vira uma linha do histórico, com os textos do `BattleNarrator` e textos novos para `round_started`, `moved`, `waited`, `mark_placed`, `mark_ended` e `ground_damage` (_a revisar_).
- **RF-16:** No `choose_next`, o `NextCreaturePanel` de hoje escolhe quem entra, uma vez por vaga pendente. Depois, os `entry_cells` acendem, e tocar num deles escolhe o hexágono. Com todas as vagas escolhidas, o jogo manda `{entries}`.
- **RF-17:** No fim da luta, o resultado, o XP, as moedas e as telas de subir de nível, Técnica nova e Evolução aparecem como na luta de hoje, e depois o jogo volta para Explorar zona.

**Depuração**

- **RF-18:** O menu de depuração de Explorar zona ganha "Tabuleiro: ligado/desligado". Ligado, o encontro do hexágono abre a luta no tabuleiro.
- **RF-19:** O menu ganha "Teste 2×2" e "Teste 3×3", que abrem a luta de teste contra 2 ou 3 Ecobeasts sorteados do catálogo, no nível do primeiro da equipe.

## Critérios de aceite

- [ ] Com o tabuleiro ligado, um encontro abre a tela com os dois Ecobeasts nas linhas 1 e 5 e a fila certa.
- [ ] Na vez do jogador, os hexágonos a até 3 passos acendem, e os ocupados não.
- [ ] Andar, desfazer e andar para outro hexágono funciona sem pedido ao servidor.
- [ ] Arranhão acende só os inimigos ao lado. Faísca Rápida acende as 6 linhas retas. Chama Espiral acende os hexágonos a até 3.
- [ ] Depois de atacar, a vez do selvagem aparece andando e atacando, e a barra de HP do jogador cai.
- [ ] Uma marca de fogo aparece no hexágono, e quem fica nela toma dano a cada vez.
- [ ] Com o Ecobeast do jogador caído e reserva, escolher quem entra e o hexágono da área verde põe o novo lá, e a luta continua.
- [ ] O botão de informação mostra todo o histórico da luta.
- [ ] Vencer mostra o XP, as moedas e, quando houver, subir de nível, e volta para o mapa.
- [ ] "Teste 2×2" abre um 2 contra 2 jogável, com a fila alternando os dois lados.
- [ ] Com o tabuleiro desligado, a luta antiga funciona como antes.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar:**

- `res://domain/models/board_battle_view.gd`, `board_turn.gd`, `board_creature.gd` e `ground_mark.gd`.
- `res://domain/rules/board_geometry.gd`.
- `res://screens/board_battle/`:
  - `board_battle_screen.gd` e `.tscn`, a tela;
  - `board_view.gd`, que desenha os hexágonos com `_draw()` e converte toque em hexágono;
  - `board_token.gd` e `.tscn`, o Ecobeast com o sprite, o nome e a barra;
  - `turn_queue_bar.gd` e `.tscn`;
  - `board_action_panel.gd` e `.tscn`;
  - `board_event_player.gd`, que mostra os eventos em ordem;
  - `battle_history_panel.gd` e `.tscn`.

**Alterar:**

- `res://core/autoload/router.gd`, com `&"board_battle"`.
- `res://core/autoload/session.gd` e `res://core/services/api_game_service.gd`.
- `res://screens/exploration/exploration_screen.gd` e `.tscn`, com o menu de depuração.
- `res://screens/battle/battle_narrator.gd`, com os textos novos, se ficar mais simples do que um narrador próprio.

**Reutilizar:** as peças da lista do [architecture.md](architecture.md#jogo), o `CreatureSprite` e o `HpBar`.

## Verificação

```bash
godot --headless --path client --quit-after 60
```

Com o servidor no ar e `ENABLE_TEST_BATTLE` ligada: F5, Explorar zona, menu de depuração, "Tabuleiro: ligado", e um encontro jogado até o fim, vencendo e perdendo. Depois, "Teste 2×2" e "Teste 3×3" jogados por algumas rodadas. Quem implementa diz o que conferiu e o que ficou para o dono.

**Conferido por quem implementou**, sem janela:

- o projeto abre e todos os scripts e cenas novos carregam, sem erros nem avisos novos;
- com respostas reais do servidor (um 2×2 de teste e uma vez), gravadas por um usuário de teste apagado depois, o jogo monta o `BoardBattleView`, o tabuleiro de 624 × 465 com 42 hexágonos e as áreas, acha o hexágono tocado, põe os Ecobeasts, anda pelo caminho do evento `moved` e tira quem sai;
- o alcance de 3 passos tem só caminhos mais curtos e inclui o hexágono que o servidor aceitou; Arranhão sem ninguém ao lado não acende nada, e Faísca Rápida acende as linhas retas.

**Fica para o dono, no editor (F5):** todos os critérios de aceite acima. A tela inteira (a vez, a reprodução dos eventos, o histórico, a entrada depois de uma queda e o fim da luta) não foi vista rodando.

## Tarefas

- [x] Modelos, `BoardGeometry`, `Session` e serviço (RF-01 a RF-03).
- [x] Tabuleiro, Ecobeasts, fila e painel (RF-04 a RF-08).
- [x] A vez do jogador (RF-09 a RF-12).
- [x] A reprodução dos eventos e o histórico (RF-13 a RF-15).
- [x] A entrada depois de uma queda e o fim da luta (RF-16 e RF-17).
- [x] Menu de depuração (RF-18 e RF-19).
- [x] Rodar a verificação, marcar a spec e o README como `concluída` e fazer o commit `feat: tela da luta no tabuleiro`.

## Divergências

O que a implementação fez diferente desta spec, e por quê:

- **Sem `board_token`, `board_action_panel` e `board_event_player` em arquivos próprios.** O Ecobeast no tabuleiro é uma classe interna do `BoardView` (`Token`, com o sprite, o nome e a barra), o painel de ações está na cena da tela, e a reprodução dos eventos fica no script da tela, que já tem tudo o que ela usa.
- **O `BattleNarrator` não mudou.** As linhas novas (`round_started`, `moved`, `waited`, `mark_placed` e `ground_damage`) ficam em `BOARD_LINES`, na tela. `mark_ended` e `vez_started` não têm linha.
- **Sem a barra de XP subindo no fim:** a tela não tem o cartão da luta de hoje. O XP aparece no histórico, e subir de nível, Técnica nova e Evolução usam as telas de hoje.
- **`BattleHud`, `IconCircle` e `BattleStyles` não foram usados.** A fila usa o `CreaturePortrait`, e o Ecobeast usa o `HpBar`.
- **`BoardBattleView.round_number`**, e não `round`: o nome `round` esconderia a função `round()` do GDScript.
- **A luta de teste sorteia entre todas as espécies do catálogo.** Quem não tem folha animada aparece com o `front.png`, parado.
