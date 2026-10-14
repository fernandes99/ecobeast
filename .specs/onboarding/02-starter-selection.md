# 02. Escolha do inicial

- **Status:** rascunho
- **Depende de:** [01-title-and-tamer-name](01-title-and-tamer-name.md)

## Contexto

Depois da fase 01, o jogador cria o Domador e cai no placeholder "Escolha do inicial". Esta fase entrega as regras que criam uma criatura (stats, XP e geração, em `res://domain/rules/`), implementa `choose_starter` e a tela em que o jogador escolhe entre Fagulho, Gotículo e Brotelho (TELAS.md #2). O Hub vem em [hub/01](../hub/01-hub-screen.md); até lá, depois da escolha o jogo abre o placeholder "Hub".

## Escopo

- `XpCurve`, `StatCalculator`, `CreatureFactory`.
- `LocalGameService.choose_starter` e o preenchimento de `stats` em toda criatura devolvida.
- Tela `starter_select` com a confirmação.

## Fora do escopo

- Apelido e detalhes completos da criatura (stats, técnicas) na escolha.
- Animação de entrada das criaturas, sons.

## Requisitos

**Regras**

- **RF-01:** `XpCurve`, `StatCalculator` e `CreatureFactory` seguem a seção "Regras" de [architecture.md](architecture.md), sem usar `GameData`, `Session`, `Node` ou arquivo.
- **RF-02:** `LocalGameService.choose_starter(species_id)` recusa (mensagens do contrato em [architecture.md](architecture.md#contrato-do-gameservice)) quando não há jogador, quando a equipe não está vazia e quando a espécie não está em `starter_options`. Senão monta os parâmetros a partir do catálogo (espécie, learnset, PP máximo das técnicas do learnset, traços dos slots 1 e 2, os 25 temperamentos, multiplicador da curva), cria a criatura no nível 5 com um `RandomNumberGenerator` com `randomize()`, coloca no slot 1, grava e devolve o `Player`.
- **RF-03:** Todo `Player` devolvido pelo `LocalGameService` (inclusive em `get_player`) tem `stats` preenchido em cada criatura, calculado pelo `StatCalculator`.

**Tela** — `res://screens/starter_select/starter_select_screen.tscn`, registrada como `&"starter_select"`.

- **RF-04:** Título "Escolha seu primeiro Ecobeast" (Bold, tamanho 40) e o texto "Ele vai te acompanhar desde o começo, <nome do Domador>." (texto secundário).
- **RF-05:** Abaixo, um cartão (`PanelContainer`) por espécie de `GameData.get_starters()`, na ordem: `CreaturePortrait` de 140 px à esquerda; à direita o nome (Bold, tamanho 32), o `ElementBadge` do elemento e a descrição do Bestiário (tamanho 20, texto secundário, quebrando linha). O cartão inteiro é tocável, e sua borda fica na cor do elemento.
- **RF-06:** Tocar num cartão abre, por cima da tela, um painel de confirmação: fundo escurecido (preto, 50%), `CreaturePortrait` de 200 px, "Escolher <nome>?", o `ElementBadge`, o texto "Essa escolha não pode ser desfeita." e os botões "Escolher" (primário) e "Voltar" (contorno, sem fundo). Tocar no fundo escurecido, em "Voltar" ou o voltar do Android fecha o painel sem escolher.
- **RF-07:** "Escolher" desabilita os dois botões, troca o texto para "Escolhendo…" e chama `Session.choose_starter(id)`. Sucesso: abre o Hub (nesta fase, `Router.go_to(&"placeholder", {"title": "Hub"})`; [hub/01](../hub/01-hub-screen.md) troca por `&"hub"`). Falha: a mensagem do `Result` aparece no painel, na cor de perigo, e os botões voltam a funcionar.
- **RF-08:** A tela não tem botão de voltar: o Domador já foi criado.

## Critérios de aceite

- [ ] Com um Domador sem equipe, F5 abre a escolha com Fagulho, Gotículo e Brotelho, nessa ordem, com cores de Fogo, Água e Flora.
- [ ] Tocar em Gotículo e depois em "Voltar" fecha o painel e nada é gravado.
- [ ] Confirmar Brotelho abre o placeholder "Hub"; `save.json` tem uma criatura `species_id` 7, nível 5, `current_xp` 125, 2 técnicas (Patada com 35 PP e Olhar Manhoso com 30 PP), `trait_id` 5, `bond` 70 e `is_prismatic` false.
- [ ] O `current_hp` gravado é igual ao HP calculado à mão com a fórmula de [architecture.md](architecture.md) para os Genes gravados.
- [ ] Apagar o save e repetir 3 vezes gera Genes e Temperamentos diferentes.
- [ ] Fechar e reabrir abre direto o placeholder "Hub".
- [ ] Um script temporário confirma o exemplo do `StatCalculator` em [architecture.md](architecture.md) (Fagulho, nível 5, Genes 0, neutro: 19/10/9/11/9/11). (Apagar depois.)

## Desenho técnico

**Criar**

- `res://domain/rules/xp_curve.gd`, `stat_calculator.gd`, `creature_factory.gd`.
- `res://screens/starter_select/starter_select_screen.tscn` e `.gd`.
- `res://screens/starter_select/starter_card.tscn` e `.gd` (o cartão de uma espécie).
- `res://screens/starter_select/confirm_panel.tscn` e `.gd` (o painel de confirmação).

**Alterar**

- `res://core/services/local_game_service.gd`: `choose_starter` e o preenchimento de `stats`.
- `res://core/autoload/router.gd`: registrar `&"starter_select"`.
- `res://screens/main/main.gd`: a linha "sem equipe" do boot passa a abrir `starter_select`.
- `res://screens/title/title_screen.gd`: depois de criar o Domador, abrir `&"starter_select"` em vez do placeholder.
- `res://ui/theme/main_theme.tres`: variação de botão "contorno" (`theme_type_variation` `OutlineButton`), usada no "Voltar".

**Reaproveitar**

- `CreaturePortrait`, `ElementBadge`, `SafeArea` ([foundation/02](../foundation/02-ui-shell.md)); `GameData.get_starters()`, `get_learnset()`, `get_species_traits()`, `get_temperaments()`, `get_growth_rate()`, `get_skill()` ([game-data/01](../game-data/01-data-layer.md)).

## Verificação

```bash
godot --headless --path . --script res://tools/validate_data.gd
```

No editor: percorrer os critérios de aceite.

## Tarefas

- [ ] `XpCurve` e `StatCalculator`; conferir o exemplo.
- [ ] `CreatureFactory`.
- [ ] `choose_starter` e `stats` no `LocalGameService`.
- [ ] Cartão, painel de confirmação e tela de escolha.
- [ ] Boot apontando para `starter_select`.
- [ ] Marcar esta spec e as tabelas como `concluída`; commit `feat: escolha do Ecobeast inicial`.
