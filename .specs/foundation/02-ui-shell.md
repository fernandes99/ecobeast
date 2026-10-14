# 02. Casca da interface

- **Status:** rascunho
- **Depende de:** [01-project-setup](01-project-setup.md), [game-data/03-starter-content](../game-data/03-starter-content.md) (componentes leem nomes e cores do catálogo)

## Contexto

Depois da fase 01 o jogo abre uma cena vazia, e depois de [game-data](../game-data/) o catálogo está carregado no `GameData`. Esta fase cria tudo que as telas do MVP vão compartilhar: o tema visual, a navegação em pilha, a área segura do celular, os componentes que mostram uma criatura e a tela placeholder que o Hub usa para as features que ainda não existem.

## Escopo

- Tema global, paleta da interface e fonte.
- `Router` (autoload) e `ScreenHost` na cena raiz, com voltar do Android.
- Boot provisório: carrega o catálogo e abre a tela placeholder com o título "Ecobeast".
- Componentes: `SafeArea`, `ElementBadge`, `CreaturePortrait`, `HpBar`.
- Tela `PlaceholderScreen`.

## Fora do escopo

- O boot que decide entre entrada, escolha e Hub ([onboarding/01](../onboarding/01-title-and-tamer-name.md)).
- `CreatureSlot` ([hub/01](../hub/01-hub-screen.md)).
- Animações de transição entre telas.
- Ícones desenhados (os botões são só texto no MVP).

## Requisitos

**Tema**

- **RF-01:** `res://ui/theme/main_theme.tres` é o tema do projeto (`gui/theme/custom`). Fonte padrão Nunito (Regular para texto, Bold para títulos e botões), tamanho base 26 px.
- **RF-02:** Cores da interface em `res://ui/theme/palette.gd` (`class_name UiPalette`, só constantes `Color`), _a revisar_: fundo `#FFF8EC`, superfície `#FFFFFF`, texto `#2D2A32`, texto secundário `#6E6873`, primária `#2BAE8E`, primária pressionada `#1F8A70`, perigo `#E5534B`, aviso `#F2B33D`, borda `#E9E1D3`.
- **RF-03:** `Button`: fundo na cor primária, texto branco em Bold, cantos de 16 px, altura mínima 64 px; pressionado escurece; desabilitado com 40% de opacidade. `PanelContainer`: superfície branca, cantos de 20 px, borda de 2 px na cor de borda, sem sombra. `LineEdit`: superfície branca, borda de 2 px, cantos de 14 px, altura mínima 64 px; borda na cor primária quando em foco.
- **RF-04:** O fundo de toda tela é a cor de fundo do RF-02 (um `ColorRect` ou `Panel` de fundo na cena raiz).

**Navegação**

- **RF-05:** `Router` (autoload `res://core/autoload/router.gd`) tem `go_to(id: StringName, params: Dictionary = {})`, `push(id, params = {})` e `back()`, com o comportamento descrito em [architecture.md](architecture.md#navegação). Também expõe `can_go_back() -> bool`.
- **RF-06:** O registro de telas desta fase tem só `&"placeholder"`; cada fase seguinte acrescenta a sua. Id desconhecido gera `push_error` com o id e não muda a tela.
- **RF-07:** O voltar do Android (e a tecla Esc no editor, para testar) chama `Router.back()`.

**Boot provisório**

- **RF-08:** `main.gd` chama `GameData.load_catalog()`. Se falhar, mostra no centro da tela "Erro nos dados do jogo" e, abaixo, cada erro em uma linha (texto secundário, tamanho 18); nenhuma tela é aberta. Se der certo, `Router.go_to(&"placeholder", {"title": "Ecobeast"})`.
- **RF-09:** O `Label` "Ecobeast" da fase 01 sai de `main.tscn`.

**Componentes** (em `res://ui/components/`, cada um com `.tscn` + `.gd` e `class_name`)

- **RF-10:** `SafeArea` (`MarginContainer`): aplica como margem a diferença entre a janela e `DisplayServer.get_display_safe_area()`, convertida para a escala do viewport, e recalcula quando o tamanho da janela muda. Margem mínima de 24 px nas laterais.
- **RF-11:** `ElementBadge`: `set_element(element_id: int)`; pílula com fundo na cor do elemento (`Element.color`) e o nome do elemento em branco, Bold, tamanho 18. Para elementos claros (luminância > 0,6), texto na cor de texto em vez de branco.
- **RF-12:** `CreaturePortrait`: `set_species(species_id: int)` e `@export var portrait_size: int = 160`. Se existir `res://assets/creatures/<slug>/front.png`, mostra a imagem. Se não, mostra o placeholder: círculo na cor do primeiro elemento, borda de 6 px na cor do segundo elemento (ou um tom mais escuro do primeiro, se tiver um só), e a inicial do nome da espécie em branco, Bold, no centro, com tamanho de 45% do retrato.
- **RF-13:** `HpBar`: `set_hp(current: int, maximum: int)`; barra arredondada com preenchimento proporcional, verde (`#4CB050`) acima de 50%, amarelo (`#F2B33D`) acima de 20% e vermelho (`#E5534B`) até 20%. Opção `@export var show_numbers: bool` mostra "21/21" ao lado.

**Tela placeholder**

- **RF-14:** `res://screens/placeholder/placeholder_screen.tscn`, registrada como `&"placeholder"`. Recebe `{"title": String}` em `setup`. Mostra o título (tamanho 40, Bold), o texto "Em construção" (texto secundário) e o botão "Voltar", visível só quando `Router.can_go_back()`.
- **RF-15:** O placeholder aceita também `{"extra": PackedScene}` para que uma tela que o use acrescente conteúdo abaixo do texto (usado pelo Perfil em [hub/01](../hub/01-hub-screen.md)).

## Critérios de aceite

- [ ] F5 abre a tela "Ecobeast / Em construção", sem botão Voltar, no fundo creme e com a fonte Nunito.
- [ ] Quebrar uma FK em qualquer `res://data/*.json` e dar F5 mostra "Erro nos dados do jogo" com o erro listado. Desfazer.
- [ ] Uma cena de teste temporária mostra os três portraits iniciais (Fagulho, Gotículo, Brotelho) como círculos nas cores de Fogo, Água e Flora, e os 14 `ElementBadge` legíveis. (Apagar a cena depois.)
- [ ] Na mesma cena, `HpBar` com 30/30, 12/30 e 5/30 aparece verde, amarela e vermelha.
- [ ] Um `push` seguido de Esc volta para a tela anterior com o estado que ela tinha.
- [ ] Com a janela no formato de um celular com notch (Projeto > Configurações > `display/window/size` ou o emulador de dispositivo do editor), o conteúdo não fica embaixo do recorte.

## Desenho técnico

**Criar**

- `res://ui/theme/main_theme.tres`, `res://ui/theme/palette.gd`.
- `res://ui/theme/fonts/Nunito-Regular.ttf`, `Nunito-Bold.ttf` e `OFL.txt` (baixar de fonts.google.com/specimen/Nunito; guardar a licença junto).
- `res://core/autoload/router.gd` e registro do autoload `Router` (depois de `GameData`).
- `res://ui/components/safe_area.tscn/.gd`, `element_badge.tscn/.gd`, `creature_portrait.tscn/.gd`, `hp_bar.tscn/.gd`.
- `res://screens/placeholder/placeholder_screen.tscn/.gd`.

**Alterar**

- `res://screens/main/main.tscn` e `main.gd`: fundo, área de erro, boot provisório e tratamento do voltar.
- `project.godot`: `gui/theme/custom` e o autoload.

**Reaproveitar**

- `GameData.get_element(id)` e `GameData.get_species(id)` ([game-data/01](../game-data/01-data-layer.md)).

## Verificação

```bash
godot --headless --path . --script res://tools/validate_data.gd
```

No editor: percorrer os critérios de aceite.

## Tarefas

- [ ] Fonte, paleta e tema; definir como tema do projeto.
- [ ] `Router` e `ScreenHost`; voltar do Android e Esc.
- [ ] Boot provisório com a tela de erro de dados.
- [ ] `PlaceholderScreen`.
- [ ] `SafeArea`, `ElementBadge`, `CreaturePortrait`, `HpBar`.
- [ ] Atualizar o `CLAUDE.md` se alguma regra nova surgir.
- [ ] Marcar esta spec e as tabelas como `concluída`; commit `feat: tema, navegação e componentes base`.
