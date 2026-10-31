# 01. Tela do Hub

- **Status:** concluída
- **Depende de:** [onboarding/02-starter-selection](../onboarding/02-starter-selection.md)

## Contexto

O jogador termina o onboarding num placeholder "Hub", e o boot também abre esse placeholder quando já existe equipe. Esta fase entrega o Hub de verdade (TELAS.md #3) e liga cada feature a uma tela placeholder.

## Escopo

- Tela `hub`: topo com o Domador, equipe, grade de ações e barra inferior.
- Componente `CreatureSlot`.
- Navegação de cada ação, aba e slot para o placeholder.
- Painel extra do Perfil com "Apagar progresso" (só debug).
- Boot e escolha do inicial apontando para `hub`.

## Fora do escopo

- As features por trás dos botões.
- Reorganizar a equipe; arrastar slots.
- Animações e sons.

## Requisitos

**Layout** — `res://screens/hub/hub_screen.tscn`, registrada como `&"hub"`. Tudo dentro do `SafeArea`, em três faixas: topo fixo, conteúdo rolável (`ScrollContainer` vertical) e barra inferior fixa.

- **RF-01:** Topo (`PanelContainer`): à esquerda, um círculo de 72 px na cor primária com a inicial do nome do Domador em branco; ao lado, o nome (Bold, 28, cortado com "…" se não couber) e, embaixo, "Domador · Nível <nível>" (texto secundário, 20). À direita, um círculo de 24 px na cor de aviso (a moeda) e o número de moedas com separador de milhar em ponto ("1.000").
- **RF-02:** Seção "Sua equipe" (título Bold, 28) com uma grade de 3 colunas e 2 linhas de `CreatureSlot`, na ordem da equipe; posições sem criatura mostram o slot vazio.
- **RF-03:** Seção "Ações" (título Bold, 28) com uma grade de 2 colunas destes botões, nesta ordem: Explorar zona, Desafiar Domador, Arenas, Loja, Refúgio, Santuário, Bestiário, Mochila. Variação de tema `ActionButton`: fundo na cor de superfície, borda de 2 px na cor de borda, texto na cor de texto em Bold, altura de 88 px.
- **RF-04:** Barra inferior com 5 abas de largura igual: Home, Equipe, Bestiário, Loja, Perfil. Variação de tema `TabButton`: sem fundo, texto 18; a aba atual (Home) fica com o texto na cor primária e uma linha de 4 px na cor primária em cima.
- **RF-05:** A tela é atualizada quando `Session.player_changed` é emitido.

**`CreatureSlot`** — `res://ui/components/creature_slot.tscn/.gd`, com `set_creature(creature: CreatureInstance)` e `set_empty()`.

- **RF-06:** Com criatura: `PanelContainer` com borda na cor do primeiro elemento, `CreaturePortrait` de 96 px, o nome de exibição (`display_name`, Bold, 20, cortado com "…"), "Nv. <nível>" (texto secundário, 18) e a `HpBar` com `current_hp`/`stats.hp` e os números.
- **RF-07:** Vazio: mesmo tamanho, borda na cor de borda, sem fundo, com "Vazio" (texto secundário) no centro; não reage a toque.

**Navegação** — tabela no `hub_screen.gd` de rótulo para `{id, params}`; nesta fase todos apontam para `&"placeholder"` com o título igual ao rótulo, abertos com `Router.push`.

- **RF-08:** Cada ação do RF-03 e as abas Equipe, Bestiário, Loja e Perfil abrem o placeholder com o próprio nome como título ("Bestiário" pela ação ou pela aba abre a mesma tela). A aba Home não faz nada.
- **RF-09:** Tocar num slot com criatura abre o placeholder com o título "Detalhes de <nome de exibição>". (Desde a [creature-details/02](../creature-details/02-details-screen.md), abre a tela de detalhes.)
- **RF-10:** O voltar do Android (Esc no editor) no Hub não faz nada; num placeholder aberto pelo Hub, volta ao Hub com a rolagem onde estava.

**Perfil (debug)**

- **RF-11:** O placeholder do Perfil recebe como `extra` o painel `res://screens/hub/profile_debug_panel.tscn`, que mostra "Domador: <nome>" e, só quando `OS.is_debug_build()`, o botão "Apagar progresso" na cor de perigo.
- **RF-12:** O primeiro toque em "Apagar progresso" troca o texto para "Toque de novo para apagar" por 3 segundos; um segundo toque nesse intervalo chama `Session.reset_progress()` e, com sucesso, `Router.go_to(&"title")`. Depois dos 3 segundos sem segundo toque, o botão volta ao normal. Falha: a mensagem do `Result` aparece abaixo do botão.

**Ligações**

- **RF-13:** O boot (`main.gd`) abre `&"hub"` quando o jogador tem equipe, e a escolha do inicial ([onboarding/02](../onboarding/02-starter-selection.md)) termina em `Router.go_to(&"hub")`, sem placeholder.

## Critérios de aceite

- [x] Depois de escolher o inicial, o Hub mostra o nome digitado, "Domador · Nível 1", "1.000" e o inicial no primeiro slot com nível 5 e HP cheio; os outros 5 slots dizem "Vazio".
- [x] Cada um dos 8 botões de ação e das 4 abas (fora Home) abre um placeholder com o título certo, e "Voltar" e Esc retornam ao Hub.
- [x] Tocar no slot do inicial abre "Detalhes de <nome>"; tocar num slot vazio não faz nada.
- [x] Com a janela de 405×720, tudo cabe ou rola sem cortar botões; a barra inferior fica sempre visível.
- [x] Um nome de 16 caracteres largos ("MMMMMMMMMMMMMMMM") não empurra as moedas para fora da tela.
- [x] Perfil > "Apagar progresso" com dois toques volta à tela de entrada, e o `save.json` não existe mais; com um toque só, depois de 3 s o botão volta ao normal.
- [x] Fechar e reabrir com equipe abre direto no Hub.

Conferidos por uma cena temporária (já apagada). Ela abriu o jogo numa janela de 405×720 e fez o caminho completo com o save apagado: entrada, escolha com toque de verdade no cartão, Hub, cada ação e aba, Perfil, apagar e entrada. Depois simulou a reabertura com equipe. Também conferiu:

- a rolagem do Hub igual depois de voltar de um placeholder;
- o Esc no Hub sem efeito;
- o clique de verdade num botão de ação e nos slots;
- os slots vazios com o mesmo tamanho do ocupado (a terceira coluna fica 1 px mais estreita, arredondamento da grade);
- um toque só em "Apagar progresso" sem apagar o save.

Ficam para conferir no aparelho a rolagem com o dedo por cima dos botões e dos slots e o voltar do Android, que usa o mesmo caminho do Esc.

**Decisões da implementação**

- **`TapPanel`** (`res://ui/components/tap_panel.gd`): o toque com folga de 24 px que o `StarterCard` tinha virou um componente, estendido pelo cartão e pelo `CreatureSlot`. Ele não consome o evento (`mouse_filter` = Passar), para o arraste chegar ao `ScrollContainer` e a tela rolar por cima do painel. Os botões de ação também usam Passar, pelo mesmo motivo.
- **Variações de tema a mais:** `CurrentTabButton` (a aba atual, com base em `TabButton`) e `DangerButton` (o "Apagar progresso"), além das `ActionButton` e `TabButton` da spec. A cor do botão de perigo pressionado entrou na `UiPalette` como `DANGER_PRESSED`. As abas que não são a atual usam o texto secundário.
- **Slot vazio do mesmo tamanho:** o conteúdo continua no layout, transparente, e o "Vazio" fica por cima. A borda do slot ocupado tem 3 px, como a do cartão da escolha.
- **`HpBar`** passou a ignorar o mouse, para não roubar o toque do slot.
- **Barra inferior:** um painel com a borda do tema, dentro da margem do `SafeArea`.
- **Confirmação de "Apagar progresso":** um nó `Timer` de 3 s, que roda uma vez só. O segundo toque só apaga com o timer ainda correndo.

## Desenho técnico

**Criar**

- `res://screens/hub/hub_screen.tscn` e `.gd`.
- `res://screens/hub/profile_debug_panel.tscn` e `.gd`.
- `res://ui/components/creature_slot.tscn` e `.gd`.
- `res://ui/components/tap_panel.gd` (toque em painel, ver as decisões).

**Alterar**

- `res://core/autoload/router.gd`: registrar `&"hub"`.
- `res://screens/main/main.gd`: a linha "com equipe" do boot passa a abrir `hub`.
- `res://screens/starter_select/starter_select_screen.gd`: terminar em `&"hub"`.
- `res://ui/theme/main_theme.tres`: variações `ActionButton`, `TabButton`, `CurrentTabButton` e `DangerButton`; `palette.gd`: `DANGER_PRESSED`.
- `res://screens/starter_select/starter_card.gd`: estender `TapPanel`.
- `res://ui/components/hp_bar.tscn`: ignorar o mouse.
- `.specs/README.md`: MVP de estrutura concluído (todas as fases da tabela).

**Reaproveitar**

- `PlaceholderScreen` com `title` e `extra`, `CreaturePortrait`, `HpBar`, `SafeArea` ([foundation/02](../foundation/02-ui-shell.md)); `Session.player`, `Session.reset_progress()` ([onboarding](../onboarding/architecture.md)); `CreatureInstance.display_name()`; `GameData.get_species()`.

## Verificação

```bash
godot --headless --path client --script res://tools/validate_data.gd
```

No editor: percorrer os critérios de aceite e, no fim, o caminho completo com o save apagado: entrada → nome → escolha → Hub → Perfil → apagar → entrada.

## Tarefas

- [x] `CreatureSlot`.
- [x] Variações de tema `ActionButton` e `TabButton`.
- [x] Layout do Hub (topo, equipe, ações, barra inferior).
- [x] Tabela de navegação e placeholders.
- [x] Painel de debug do Perfil.
- [x] Ligar boot e escolha do inicial ao `hub`.
- [x] Marcar esta spec e as tabelas como `concluída`; commit `feat: tela do Hub`.
