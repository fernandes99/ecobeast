# 01. Tema escuro

- **Status:** concluída
- **Depende de:** [hub/01-hub-screen](../hub/01-hub-screen.md)

## Contexto

O tema atual (`res://ui/theme/main_theme.tres` e `UiPalette`) é claro: fundo creme, painéis brancos, botões verdes. Algumas cenas também têm cores fixas no próprio arquivo, fora do tema. Esta fase troca tudo pela paleta escura do [README](README.md#paleta), sem mudar o layout de nenhuma tela. O Hub novo vem na [02](02-hub-layout.md); aqui o Hub atual só muda de cores.

Godot: um **tema** (`Theme`) é um recurso com os estilos de cada tipo de controle (Button, Label, Panel…). O projeto aponta para ele em `gui/theme/custom`, e todo controle sem estilo próprio usa o tema. Uma **variação de tema** (`theme_type_variation`, como `TitleLabel`) é um estilo alternativo de um tipo, escolhido por nó. Um `StyleBoxFlat` desenha um retângulo com cor, borda, cantos arredondados e sombra, sem precisar de imagem.

## Escopo

- `UiPalette` com a paleta nova.
- `main_theme.tres` com os estilos novos e a fonte de título em peso 900.
- Fundo das telas em gradiente.
- Cores fixas das cenas e componentes passando a vir da paleta ou do tema.

## Fora do escopo

- Layout novo do Hub, ícones e espaços de ilustração ([02](02-hub-layout.md)).
- Mudar textos, tamanhos de tela ou navegação.

## Requisitos

**Paleta e fonte**

- **RF-01:** `UiPalette` tem exatamente as constantes da [paleta](README.md#paleta), com os nomes e valores de lá. As constantes antigas que saem (`SURFACE` branco, `BORDER` creme etc.) não ficam no arquivo; quem usava passa a usar a nova equivalente.
- **RF-02:** `res://ui/theme/fonts/nunito_black.tres`: `FontVariation` da `Nunito-Variable.ttf` com peso 900. As variações `TitleLabel` e `BoldLabel` continuam existindo; `TitleLabel` passa a usar a Black.

**Tema** (`main_theme.tres`; cantos em px)

- **RF-03:** `Label`: cor `TEXT`. `SecondaryLabel`: `TEXT_SECONDARY`. `TitleLabel`: `TEXT`, Black.
- **RF-04:** `PanelContainer` e `Panel`: fundo `SURFACE`, borda de 2 px `BORDER`, cantos 20, sombra `#000000` a 35% com tamanho 8 e deslocamento (0, 4).
- **RF-05:** `Button`: fundo `PRIMARY`, borda de 2 px `ACCENT` a 50%, cantos 16, texto `TEXT` em Bold; pressionado `PRIMARY_PRESSED`; desabilitado com 40% de opacidade.
- **RF-06:** `OutlineButton`: sem fundo, borda de 2 px `ACCENT`, texto `ACCENT`; pressionado com fundo `SURFACE_RAISED`. `DangerButton`: fundo `DANGER`, pressionado `DANGER_PRESSED`, texto `TEXT`.
- **RF-07:** `ActionButton`, `TabButton` e `CurrentTabButton` (do Hub atual): `ActionButton` com fundo `SURFACE`, borda `BORDER`, texto `TEXT`; `TabButton` com texto `TEXT_SECONDARY`; `CurrentTabButton` com texto `TEXT` e a linha de cima em `ACCENT`.
- **RF-08:** `LineEdit`: fundo `SURFACE_RAISED`, borda de 2 px `BORDER`, cantos 14, texto `TEXT`, placeholder `TEXT_SECONDARY`, cursor `ACCENT`; com foco, borda `ACCENT`.
- **RF-09:** Barras de rolagem: trilho transparente, alça de 6 px em `TEXT_MUTED`, `TEXT_SECONDARY` ao arrastar.

**Telas e componentes**

- **RF-10:** O fundo da cena raiz (`res://screens/main/main.tscn`, nó `Background`) é um gradiente vertical de `BACKGROUND` (em cima) a `BACKGROUND_DEEP` (embaixo), num `TextureRect` com `GradientTexture2D`.
- **RF-11:** Nenhuma cena ou script do jogo tem cor fixa (`Color(...)` ou `#…`) fora de `palette.gd` e `main_theme.tres`, com três exceções: as cores dos Elementos (do catálogo), o branco do texto sobre cor de Elemento e transparências do próprio Godot (`Color.TRANSPARENT`). As cores que estavam fixas viram constantes da paleta, aplicadas por código, ou estilos do tema.
- **RF-12:** Título "Ecobeast" da entrada em `ACCENT`; dica de erro do nome em `DANGER`, como hoje.
- **RF-13:** `HpBar`: trilho `TRACK`; preenchimento `HP_HIGH`, `WARNING` e `DANGER` nas mesmas faixas de hoje.
- **RF-14:** `CreatureSlot` vazio: borda `BORDER`; com criatura, borda na cor do primeiro Elemento, como hoje, e fundo `SURFACE`.
- **RF-15:** `ElementBadge`: continua na cor do Elemento, com texto escuro (`BACKGROUND`) quando a cor é clara e branco quando é escura.
- **RF-16:** O painel de confirmação da escolha do inicial escurece a tela com `OVERLAY`. O texto de perigo do painel e do Perfil (debug) usa `DANGER`.
- **RF-17:** `TapPanel` dá retorno de toque visível no fundo escuro: pressionado, o painel clareia (`UiPalette.PRESSED_TINT`, `modulate` de 1,25) em vez de escurecer.

## Critérios de aceite

- [x] Capturas de tela (Movie Maker, janela 405 × 720) da entrada, da escolha do inicial, do painel de confirmação, do Hub, de um placeholder, da tela "sem conexão" e da tela "Erro nos dados do jogo" mostram fundo escuro, painéis `SURFACE` com borda e texto branco ou `TEXT_SECONDARY`, sem nenhuma cor creme, branca de fundo ou verde do tema antigo.
- [x] As artes de Fogo e Água aparecem na escolha do inicial e no Hub sem halo claro em volta.
- [x] `grep` por `Color(` e `#` de cor em `client/**/*.tscn` e `client/**/*.gd` só encontra `palette.gd`, `main_theme.tres` e as exceções do RF-11.
- [ ] Os fluxos continuam iguais: nome, escolha, confirmação, Hub, placeholders, voltar, "Tentar de novo". (O layout e os scripts das telas não mudaram; o F5 é passo do dono.)
- [x] O jogo roda sem erros de script e o editor não mostra avisos.

## Desenho técnico

**Criar**

- `res://ui/theme/fonts/nunito_black.tres`.

**Alterar**

- `res://ui/theme/palette.gd`, `res://ui/theme/main_theme.tres`.
- `res://screens/main/main.tscn` (fundo), `res://screens/title/title_screen.tscn`, `res://screens/starter_select/confirm_panel.tscn`, `res://screens/hub/hub_screen.tscn`, `res://screens/hub/profile_debug_panel.tscn`.
- `res://ui/components/hp_bar.tscn`/`.gd`, `creature_slot.gd`, `element_badge.tscn`/`.gd`, `tap_panel.gd`.
- `client/CLAUDE.md` (regra visual: paleta escura e variações de tema).

**Reaproveitar**

- As variações de tema existentes; a estrutura das cenas não muda.

## Verificação

Com o servidor rodando (`cd server && npm run start:dev`):

```bash
godot --headless --path client --quit-after 30
godot --path client --write-movie <pasta>/tela.png --fixed-fps 30 --quit-after 300
```

As telas sem jogador salvo (entrada, escolha, confirmação) e as de erro são capturadas por uma cena temporária que abre cada tela direto pelo `Router`, apagada no fim da fase. Passo do dono: F5 no editor e no celular, conferindo legibilidade.

## Tarefas

- [x] `UiPalette` e `nunito_black.tres` (RF-01, RF-02).
- [x] `main_theme.tres` (RF-03 a RF-09).
- [x] Fundo em gradiente (RF-10).
- [x] Cores fixas das cenas e componentes (RF-11 a RF-17).
- [x] Capturas de todas as telas e conferência dos critérios.
- [x] `client/CLAUDE.md`.
- [x] Marcar esta spec e a tabela do README como `concluída`; commit `feat: tema escuro`.

## Decisões da implementação

- **Cores fixas das cenas viraram variações de tema**: `LogoLabel` (título da entrada), `DangerLabel` (mensagens de erro), `AvatarPanel`, `CoinDot` e `TabBarPanel` (Hub atual), `HpBar` (barra de HP) e `ElementPill` (selo de Elemento). A `HpBar` e o `ElementBadge` copiam o estilo do tema ao abrir (`duplicate`) e pintam só a própria cópia, para uma barra não mudar a cor das outras.
- **Fundo e escurecimento pelo código:** o gradiente do fundo é montado no `main.gd` e o `OVERLAY` da confirmação no `confirm_panel.gd`, com as cores da `UiPalette`. Assim nenhuma cena guarda cor.
- **`PRESSED_TINT` entrou na paleta**, porque o RF-11 não deixa cor fixa em script.
- **Barra de rolagem** em `TEXT_MUTED`: `SURFACE_RAISED`, previsto antes, quase não aparecia sobre o fundo.
- **O texto branco sobre a cor do Elemento** (inicial do retrato, selo) vem da cor padrão do `Label`, que agora é `TEXT` (branco). Não sobrou nenhuma cor fixa nas cenas, nem as exceções do RF-11.
- **O tema foi gerado por um script** a partir da tabela da paleta, para os valores saírem exatos. Daqui em diante ele se edita normalmente pelo editor do Godot.
- **Conferência:** capturas do Movie Maker das sete telas (entrada, escolha, confirmação, Hub, placeholder, sem conexão, erro nos dados), por uma cena temporária apagada no fim; boot headless sem erros e 0 avisos do editor em 46 scripts.
