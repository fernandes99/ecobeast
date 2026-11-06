# 08. O chão do mapa na tela inteira, com o tabuleiro parado

- **Status:** concluída (falta o dono testar no editor)
- **Depende de:** [06](06-board-look.md) e [07](07-battle-sprites.md)

## Contexto

Na [06](06-board-look.md), os hexágonos do tabuleiro são translúcidos e todos iguais, sobre o fundo de floresta. Em 2026-11-05, o dono mandou um print da luta ao lado de um print do mapa de Explorar e pediu que o campo da luta ficasse parecido com o do mapa: "pode usar os mesmos assets e tudo mais".

No mesmo pedido, ele apontou que o tabuleiro "samba conforme a altura da interface". O tabuleiro fica centrado no espaço entre o cartão de cima e a parte de baixo, e essa parte muda de altura: as Técnicas têm 292 pixels, e os botões, 128. Os cartões, que nascem escondidos, e a mensagem, quando quebra em 2 linhas, também o empurram.

Ele também pediu para tirar a equipe e o botão Trocar do pé da tela: "Depois decido onde vai ter esse botão."

Depois de ver a primeira versão, com o tabuleiro como uma ilha sobre a floresta, o dono pediu o chão na tela inteira: "vamos colocar na tela inteira todos os campos, mas vamos ter um limite dos fields. pensa que nem vai dar para ver o background atrás". No mesmo dia, pediu para abaixar a interface, "alinhando certinho", dar margem ao cartão do selvagem e tirar o contador de rodadas. E pediu para tirar por completo o visual da [06](06-board-look.md) (o painel azul, os botões coloridos e o "?" de imagem): "ficou muito feio, depois penso em algum outro, talvez passar um pacote de asset GUI".

## Escopo

- O chão do mapa, desenhado pelo `HexMapView`, na tela inteira, com o limite do tabuleiro à vista.
- O bioma do hexágono do Domador onde a luta começou.
- O tabuleiro parado: o lugar e o tamanho dele não mudam durante a luta.
- Sair da tela a equipe, o botão Trocar e a rodada.
- A interface encostada no pé e com margem em cima.
- Sair o visual da folha de assets da [06](06-board-look.md): a tela usa o tema do jogo.

## Fora do escopo

- Onde a troca vai ficar. Até o dono decidir, a luta não tem troca pelo jogador; a escolha de quem entra depois de uma queda continua.
- Um visual novo para a interface: o dono vai trazer um pacote de GUI.
- O que aparece enquanto a luta carrega: o fundo do tema do jogo, como nas outras telas.
- Obstáculos ou altura no tabuleiro: todos os hexágonos ficam na mesma altura.

## Requisitos

- **RF-01:** O chão do mapa de Explorar cobre a tela inteira, atrás da interface: a superfície do bioma e o contorno fino entre os hexágonos, como no mapa. O fundo de floresta sai da tela e do projeto: ele só aparecia enquanto a luta carregava, e o dono pediu para tirar ("remove por completo aqueles background, ele aparece no loading da luta"). O tabuleiro são os mesmos 18 hexágonos, e o limite dele fica à vista: o chão de fora fica escurecido, e uma borda clara contorna o tabuleiro. As marcas no chão, o que está aceso e o hexágono de quem joga continuam como na [06](06-board-look.md), por cima do chão. Decisão do dono.
- **RF-02:** O bioma e a forma vêm do hexágono do Domador no mapa: luta na colina tem o chão da colina. A luta de teste do menu de depuração também usa o hexágono do Domador. Sem mapa, o chão é o temperado plano.
- **RF-03:** As plantas e pedras vêm das mesmas receitas do mapa. No tabuleiro e nos hexágonos colados nele, só as baixas (tufo, flores, pedrinhas, samambaia, musgo e tufo seco), porque árvores, arbustos e rochas cobririam os Ecobeasts e o que está aceso. Mais longe, todas as do bioma, como no mapa. Elas mudam de uma luta para outra e balançam com o vento. Ficam longe do centro do hexágono, onde fica o Ecobeast. _A revisar._
- **RF-04:** Os hexágonos continuam do tamanho da [06](06-board-look.md): o hexágono do mapa ampliado 1,5× dentro do tabuleiro. A pixel art do chão pode não cair em pixels inteiros da tela, como os sprites da luta. _A revisar._
- **RF-05:** O tabuleiro fica parado durante a luta: abrir e fechar as Técnicas, mostrar o resultado, uma mensagem de 2 linhas e a chegada dos cartões não mudam o lugar nem o tamanho dele. Só uma mudança no tamanho da janela o move. O bloco de baixo (a mensagem, o cartão do jogador e os controles) reserva a altura da mais alta das formas dos controles (botões, Técnicas ou resultado) e fica encostado no pé, com o cartão logo acima dos botões. A mensagem reserva 2 linhas. Os cartões guardam o lugar mesmo antes de aparecer.
- **RF-06:** A equipe, o botão Trocar e o contador de rodadas saem da tela. A rodada continua no histórico. Decisão do dono.
- **RF-07:** A interface tem 16 de margem em cima e embaixo, além da área segura do aparelho: o cartão do selvagem não encosta no topo, e os botões não encostam no pé.
- **RF-08:** Sem o visual da folha de assets: os botões Atacar, Passar, Mochila e Fugir, os cartões e o "?" usam o tema do jogo, e os Elementos do cartão usam o selo de Elemento do jogo. Decisão do dono, até ele trazer outro pacote de GUI.

## Critérios de aceite

- [ ] Com F5, Explorar zona e Procurar em um hexágono temperado, o gramado do mapa cobre a tela, o fundo de floresta não aparece nem no carregamento, e o tabuleiro se destaca do chão escurecido em volta, com a borda clara.
- [ ] Numa colina, o chão é o da colina.
- [ ] Abrir e fechar Atacar não move o tabuleiro, nem a chegada do resultado.
- [ ] A equipe, o botão Trocar e a rodada não aparecem; o cartão do jogador fica logo acima dos botões, encostados no pé; o cartão do selvagem tem margem em cima.
- [ ] Os botões e os cartões têm o visual do tema do jogo.
- [ ] O acender do alcance, dos alvos e de quem joga aparece por cima do chão.

## Desenho técnico

- **`HexMapView`** ganha opções que o mapa de Explorar não usa:
  - `fixed_scale`: com valor, a escala fica fixa, em vez de seguir a janela para a pixel art cair em pixels inteiros. O tabuleiro usa 1,5, porque os hexágonos dele (96 × 87) são os do mapa (64 × 58) ampliados 1,5×, na mesma grade axial.
  - `allows_decoration`: uma função que recebe a coordenada e o tipo e decide se a decoração aparece.
  - `build_all_rows()`: monta todas as linhas de uma vez. O mapa de Explorar monta só as que chegam perto da tela, e a conta dele não vale dentro de outro nó com outra escala.
- **`BoardView`:** o `cover(area)` monta um `ExplorationMap` com todos os hexágonos que encostam na área, mais 2 de folga, para a borda do mapa nunca aparecer. Todos têm o bioma e a forma recebidos, e a seed é sorteada uma vez por luta. O `cover_screen()` passa a tela inteira, nas coordenadas do tabuleiro. Os nós ficam nesta ordem: o chão (`HexMapView`), um `Node2D` que desenha o chão de fora escurecido, a borda do tabuleiro, as marcas e o que está aceso, e os Ecobeasts. O chão desce a altura do nível do bioma (8 pixels da arte no temperado), para a superfície cair na grade do tabuleiro.
- **`set_board(cells, biome, shape)`** recebe o bioma e a forma. A tela da luta os recebe nos `params`, de Explorar zona: `biome` e `shape` do hexágono do Domador.
- **Cena da luta:** o nó `Background` e a imagem `res://assets/backgrounds/board/temperate.jpg` saem. O tabuleiro mora numa camada própria (`BoardLayer`), antes da interface, para o chão ficar atrás de tudo sem mexer no `z_index`. Na coluna, a `BoardArea` é só o espaço que diz onde ele fica, e a tela o põe lá a cada mudança desse espaço. A área segura, a margem (`Edge`, com 16 em cima e embaixo) e a coluna deixam o toque passar para o tabuleiro.
- **O bloco de baixo** (`Bottom`) fica alinhado no pé, com a altura mínima da mensagem (2 linhas), do cartão e da forma mais alta dos controles, calculada no `_ready` depois de as Técnicas serem criadas. O cartão sem Ecobeast fica transparente, em vez de escondido, e a fila de Elementos dele guarda a altura de um selo.
- **Saem:** `TeamRow`, `TeamBar`, `SwitchButton`, `RoundPill` e o `board_team_bar.gd`; o `board_skin.gd` e o uso de `res://assets/ui/board/`. A função que abre a troca fica, sem botão, para quando o dono decidir onde ele vai.

## Verificação

- O teste do tabuleiro, sem janela (`sheets_test.gd`), segue passando, com o chão montado.
- Um teste sem janela mede a área do tabuleiro com os botões, com as Técnicas abertas e com o resultado, e confere que ela não muda.
- Um print da tela, com janela, para ver o chão.
- O projeto abre sem erros.

## Tarefas

- [x] Spec.
- [x] `HexMapView` com `fixed_scale` e `decoration_kinds`.
- [x] O chão no `BoardView` e o bioma vindo de Explorar zona.
- [x] O tabuleiro parado e a equipe e o Trocar fora.
- [x] O chão na tela inteira, com o limite do tabuleiro.
- [x] A interface no pé, a margem em cima, sem a rodada e sem o visual da folha de assets.
- [ ] O dono ver com F5.

## Divergências

- O `board_team_bar.gd` e o `board_skin.gd` foram apagados, e as cores `BOARD_CELL`, `BOARD_CELL_BORDER` e `BOARD_ACTIVE_BORDER` saíram do `UiPalette`: ficaram sem uso. As imagens de `res://assets/ui/board/` e os ícones `run.svg`, `swords.svg` e `wait.svg` ficaram na pasta, sem uso, para o dono decidir se apaga.
- A seed das decorações é sorteada a cada luta: o chão não é o pedaço do mapa de verdade em volta do Domador, e o servidor não manda uma seed para ele.

## Resultado da verificação

Em 2026-11-05, sem janela:

- O projeto importa sem erros, e a checagem de carga dá 0 falhas.
- O teste do tabuleiro (`sheets_test.gd`) dá 0 falhas, com o chão montado.
- Um teste mediu a área e o lugar do tabuleiro antes do primeiro turno, com os botões, com as Técnicas abertas, com uma mensagem de 2 linhas e com o resultado: os cinco são iguais. Antes desta fase, as Técnicas abertas encolhiam a área de 689 para 525 pixels. O mesmo teste conferiu que o chão montou as linhas na escala 1,5 e que a equipe e o Trocar não existem mais na tela.

Com janela, um print da luta de teste 3 × 3, sem o servidor, mostrou o gramado cobrindo a tela, o chão de fora escurecido com árvores, a borda clara do tabuleiro, o acender por cima do chão, os cartões e botões no tema do jogo, o cartão do jogador logo acima dos botões no pé e o cartão do selvagem com margem em cima. Falta o dono ver no editor e numa colina.
