# 02. Hub no layout do protótipo

- **Status:** rascunho
- **Depende de:** [01-dark-theme](01-dark-theme.md)

## Contexto

Depois da [01](01-dark-theme.md), o Hub já está na paleta escura, mas ainda no layout do MVP ([hub/01](../hub/01-hub-screen.md)): equipe em grade 3 × 2, ações em botões só com texto, abas sem ícones. Esta fase refaz o Hub no layout do protótipo do dono (`hub-prototype.png`, nesta pasta): cenário no topo, Domador e moedas por cima dele, equipe numa linha de 6 cards, ações em 8 cards coloridos com espaço para ilustração e barra inferior com ícones. O comportamento (navegação, placeholders, Perfil de debug, atualização pelo `Session`) não muda.

## Escopo

- Ícones SVG da interface.
- Layout novo do `hub_screen`.
- `CreatureSlot` no formato de card vertical.
- Card de ação (`ActionTile`) com espaço de ilustração.
- Barra inferior com ícones e a aba atual destacada.
- Espaço do cenário do topo.

## Fora do escopo

- Ilustrações (cenário e imagens das ações são do dono; entram pelos arquivos do [README](README.md#arquivos-de-ilustração)).
- Gemas, configurações, "+" das moedas, "Equipe ativa" (o jogo não tem).
- Ícones dos Elementos (o card usa um círculo na cor do Elemento).
- Animações além do retorno de toque.

## Requisitos

**Ícones** — `res://ui/icons/*.svg`, 48 × 48, traço ou preenchimento branco, sem texto.

- **RF-01:** `home`, `team`, `book`, `cart`, `person` (abas), `pencil`, `coin` (a moeda é a única colorida: dourado `WARNING` com borda mais escura) e os 8 das ações: `explore` (marcador de mapa), `challenge` (espadas cruzadas), `arenas` (coroa), `shop` (loja com toldo), `heal` (casa com cruz), `storage` (templo), `codex` (livro), `bag` (mochila). Formas simples, legíveis a 24 px.

**Estrutura** — dentro do `SafeArea`, de cima para baixo:

- **RF-02:** Cenário: um `TextureRect` atrás de tudo, colado no topo, com 38% da altura da tela. Mostra `res://assets/backgrounds/hub.png` se existir (cortado para cobrir, `STRETCH_KEEP_ASPECT_COVERED`); senão, um gradiente vertical de `#52C4F5` a `BACKGROUND`. Um gradiente de `BACKGROUND` transparente a opaco cobre a parte de baixo dele, para o conteúdo não ficar sobre uma borda dura.
- **RF-03:** Topo fixo, por cima do cenário: o painel do Domador à esquerda e o chip de moedas à direita.
- **RF-04:** Conteúdo rolável (`ScrollContainer` vertical): um espaço vazio que deixa o cenário aparecer (até o fim dos 38%), o painel da equipe e a grade de ações.
- **RF-05:** Barra inferior fixa.

**Topo**

- **RF-06:** Painel do Domador: pílula com cantos 24, gradiente horizontal de `#10304C` a `#134162`, borda de 2 px `BORDER`. À esquerda, o avatar: círculo de 88 px em `PRIMARY` com anel de 3 px `ACCENT` e a inicial do nome em branco (Black, 40), sobressaindo do painel. Ao lado, o nome (Black, 28, cortado com "…") e, embaixo, "Nv. <nível>" (Bold, 20, `TEXT_SECONDARY`) seguido de uma barra de XP de 140 × 12 (trilho `TRACK`, preenchimento `ACCENT`, cantos 6) com valor 0.
- **RF-07:** Chip de moedas: cantos 24, fundo `SURFACE`, borda `BORDER`, ícone `coin` de 36 px e o número (Bold, 24, `TEXT`) com separador de milhar em ponto.

**Equipe**

- **RF-08:** Painel com cantos 20, fundo `SURFACE` e borda `BORDER`. Cabeçalho: ícone `team` (28 px, `TEXT`), "Minha equipe" (Black, 24) e, à direita, um botão redondo de 48 px (`SURFACE_RAISED`, ícone `pencil`) que abre o destino "Equipe".
- **RF-09:** Uma linha com os 6 `CreatureSlot`, mesma largura, espaço de 8 px entre eles, altura de 1,5 × a largura.
- **RF-10:** `CreatureSlot` com criatura: cantos 12, borda de 2 px na cor do primeiro Elemento, fundo em gradiente vertical da cor do Elemento escurecida 45% (em cima) a `SURFACE` (embaixo). De cima para baixo: o `CreaturePortrait` ocupando a largura; o nome de exibição (Bold, 16, branco, cortado com "…"); uma linha com um círculo de 14 px na cor do Elemento e "Nv. <nível>" (Bold, 14, `TEXT_SECONDARY`); "HP <atual>/<máximo>" (Bold, 13) e a `HpBar` com 8 px de altura, sem os números.
- **RF-11:** `CreatureSlot` vazio: cantos 12, fundo `SURFACE_RAISED` a 50%, sem borda, "Vazio" (14, `TEXT_MUTED`) no centro; não reage a toque.

**Ações**

- **RF-12:** Grade de 4 colunas e 2 linhas de `ActionTile` (`res://ui/components/action_tile.tscn`/`.gd`), espaço de 12 px, nesta ordem e com estes dados:

| id          | Título             | Subtítulo                                   | Cor da arte | Cor do corpo |
| ----------- | ------------------ | ------------------------------------------- | ----------- | ------------ |
| `explore`   | Explorar zona      | Conheça novas áreas e capture criaturas.    | `#3E9B4F`   | `#0B4436`    |
| `challenge` | Desafiar Domador   | Enfrente outros Domadores.                  | `#B9473F`   | `#3A2433`    |
| `arenas`    | Arenas             | Derrote os 8 Mestres e conquiste a Liga.    | `#4A52C8`   | `#1D335F`    |
| `shop`      | Loja               | Compre itens, Esferas de Vínculo e mais.    | `#D08A22`   | `#4D3C28`    |
| `heal`      | Refúgio            | Cure sua equipe.                            | `#159080`   | `#044247`    |
| `storage`   | Santuário          | Guarde suas criaturas.                      | `#6A44C2`   | `#2A2360`    |
| `codex`     | Bestiário          | Veja todas as espécies.                     | `#1E7FD0`   | `#0E3C61`    |
| `bag`       | Mochila            | Organize seus itens.                        | `#9C6E43`   | `#3E362F`    |

- **RF-13:** `ActionTile`: cantos 16, borda de 2 px na cor do corpo clareada 25%. Em cima, a área da arte (altura 96 px): `res://assets/ui/actions/<id>.png` se existir (`STRETCH_KEEP_ASPECT_COVERED`); senão, um gradiente vertical da cor da arte a ela escurecida 30%, com o ícone da ação (48 px, branco) no centro. Embaixo, no fundo da cor do corpo: o título (Black, 20, branco, centralizado, até 2 linhas) e o subtítulo (14, branco a 75%, centralizado, até 3 linhas). Os cards de uma linha têm a mesma altura.
- **RF-14:** `ActionTile` estende `TapPanel`: retorno de toque, arraste de rolagem passando para o `ScrollContainer`, e o toque emite `pressed`. O Hub liga cada card ao destino com o mesmo rótulo de hoje (`DESTINATIONS`).

**Barra inferior**

- **RF-15:** Painel com cantos 20, fundo `SURFACE`, borda `BORDER`, 5 abas de largura igual: Home (`home`), Equipe (`team`), Bestiário (`book`), Loja (`cart`), Perfil (`person`). Cada aba: ícone de 36 px em cima e o rótulo (Bold, 16) embaixo.
- **RF-16:** A aba atual (Home) tem fundo `PRIMARY` com cantos 16, ícone e rótulo em `TEXT`. As outras: sem fundo, ícone `TEXT_SECONDARY`, rótulo `TEXT_SECONDARY`.

**Sem mudança**

- **RF-17:** Navegação (RF-08 a RF-10 de [hub/01](../hub/01-hub-screen.md)), Perfil de debug (RF-11 e RF-12) e atualização pelo `Session.player_changed` continuam como estão.

## Critérios de aceite

- [ ] A captura do Hub (Movie Maker, 405 × 720) lado a lado com o protótipo mostra a mesma organização: cenário no topo, Domador e moedas por cima, painel "Minha equipe" com 6 cards em linha, 8 cards de ação em 4 colunas e barra com ícones e Home destacada.
- [ ] O inicial aparece no primeiro card com a arte, o nome, o nível, o círculo do Elemento e o HP; os outros 5 dizem "Vazio".
- [ ] Sem `hub.png` nem imagens de ações, o cenário é o gradiente de céu e cada card mostra o seu ícone. Colocando um PNG qualquer em `res://assets/ui/actions/shop.png`, a Loja passa a mostrá-lo sem mudar código. (Conferir e remover o arquivo de teste.)
- [ ] Cada card de ação, o lápis da equipe e as 4 abas (fora Home) abrem o placeholder certo; o voltar retorna ao Hub com a rolagem onde estava.
- [ ] Um nome de 16 caracteres largos ("MMMMMMMMMMMMMMMM") e "Marisgarra" num card não saem dos seus espaços.
- [ ] Numa tela mais baixa (janela 405 × 640), o conteúdo rola e a barra inferior continua visível.
- [ ] O jogo roda sem erros de script e o editor não mostra avisos.

## Desenho técnico

**Criar**

- `res://ui/icons/*.svg` (RF-01), importados com `svg/scale` 2,0 para ficarem nítidos.
- `res://ui/components/action_tile.tscn`/`.gd` (`class_name ActionTile`, estende `TapPanel`, com `setup(id, title, subtitle, art_color, body_color)`).

**Alterar**

- `res://screens/hub/hub_screen.tscn`/`.gd`: estrutura nova; `ACTIONS` passa a ter id, título, subtítulo e cores; `DESTINATIONS` continua igual.
- `res://ui/components/creature_slot.tscn`/`.gd`: card vertical (RF-10, RF-11).
- `res://ui/components/hp_bar.tscn`/`.gd`: opção de esconder os números e altura configurável.
- `res://ui/theme/main_theme.tres`: variações que o Hub usar (aba atual, chip).
- `.specs/hub/README.md`: as decisões "grade de 3 × 2" e "botões só com texto" passam a apontar para esta fase.
- `client/CLAUDE.md`: ícones em `res://ui/icons/` e os arquivos de ilustração.

**Reaproveitar**

- `TapPanel`, `CreaturePortrait`, `HpBar`, `SafeArea`, a tabela `DESTINATIONS` e o `profile_debug_panel`.

## Verificação

Com o servidor rodando:

```bash
godot --headless --path client --quit-after 30
godot --path client --write-movie <pasta>/hub.png --fixed-fps 30 --quit-after 300
```

Comparar a última captura com `hub-prototype.png`. Passo do dono: F5 no editor e no celular (rolagem por toque, toque nos cards).

## Tarefas

- [ ] Ícones SVG (RF-01).
- [ ] Estrutura do Hub, cenário e topo (RF-02 a RF-07).
- [ ] Painel da equipe e `CreatureSlot` novo (RF-08 a RF-11).
- [ ] `ActionTile` e a grade (RF-12 a RF-14).
- [ ] Barra inferior (RF-15, RF-16).
- [ ] Capturas e conferência dos critérios.
- [ ] Documentos; marcar esta spec e a tabela do README como `concluída`; commit `feat: hub no layout do protótipo`.
