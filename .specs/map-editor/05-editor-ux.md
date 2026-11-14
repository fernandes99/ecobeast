# 05. Editor mais fácil de usar

- **Status:** concluída
- **Depende de:** [04-buildings-and-areas](04-buildings-and-areas.md), [island-villages/03](../island-villages/03-map-objects.md), [terrain-height](../terrain-height/)

## Contexto

Com as vilas, o editor ganhou objetos com até 9 variantes, ações e áreas, e o painel da esquerda ficou apertado. O dono reclamou de cinco coisas:

- trocar a variante de um objeto já posto é difícil, e o Delete não apaga;
- é difícil ver onde fica uma área no meio das outras;
- só dá para ver as variantes de um objeto pondo ele no mapa;
- a distribuição do menu de ferramentas é ruim, e as chaves de camada ocupam o topo;
- Bioma e Altura mostram as mesmas opções, e tocar numa altura com o Bioma escolhido troca de ferramenta.

O desenho foi combinado com o dono a partir de rascunhos da tela.

## Escopo

- Topo: um botão Camadas, com ícone de olho, que abre as chaves de Áreas, Ações e Bloqueio; um menu Ilhas com a lista de ilhas; desfazer e refazer.
- Uma coluna de ferramentas com ícone e tecla, e um painel com largura fixa, só com as opções da ferramenta escolhida.
- Bioma e Altura separados.
- Objeto: a lista de tipos com nome inteiro e tamanho, a prévia grande com as variantes, a barra ao lado do objeto escolhido no mapa e as teclas.
- Área: o foco, que apaga o resto do mapa.

## Fora do escopo

- Mudar o servidor, o rascunho (`IslandDraft`) ou o formato salvo.
- Uma camada de grade: o editor não tem grade que se desliga, e o rascunho a mostrava só como exemplo.
- Arrastar um objeto para outro lugar.
- Atalhos configuráveis.

## Requisitos

**Topo**

- **RF-01:** O topo tem, nesta ordem: o nome da ilha, o estado, a mensagem, o menu Ilhas, desfazer, refazer, Camadas, Salvar e Publicar.
- **RF-02:** Ilhas abre um painel por cima com a lista de ilhas, Nova ilha e Apagar, como era no painel da esquerda. Abrir uma ilha ou começar uma nova fecha o painel.
- **RF-03:** Camadas abre um painel por cima com as chaves Áreas, Ações e Bloqueio, que funcionam como antes, inclusive ligando sozinhas ao escolher a ferramenta Ação, Área ou o editar bloqueio.
- **RF-04:** Desfazer e refazer fazem o mesmo que Ctrl+Z e Ctrl+Y, e ficam desligados quando não há o que desfazer ou refazer.

**Ferramentas**

- **RF-05:** As 9 ferramentas ficam numa coluna de botões com ícone e o número da tecla. A dica de cada uma mostra o nome e o que ela faz.
- **RF-06:** Ao lado da coluna, o painel tem largura fixa e mostra o nome da ferramenta, a dica e só as opções dela. Trocar de ferramenta não muda a largura do painel nem o tamanho do mapa.
- **RF-07:** O pincel (tamanho) aparece no fim do painel, nas ferramentas que o usam.

**Bioma e Altura**

- **RF-08:** O Bioma mostra os biomas e uma linha "Também pôr altura" com Manter, 0, 1, 2, 3 e 4. Com Manter (o padrão), pintar muda só o bioma; com um número, muda o bioma e a altura. Escolher um número não troca de ferramenta.
- **RF-09:** A Altura mostra só os números de 0 a 4 (de 0 a 10 desde a [terrain-height/02](../terrain-height/02-eleven-heights.md)), sem os biomas, e pintar muda só a altura.
- **RF-10:** Pôr hexágono continua mostrando os biomas e as alturas, porque o hexágono novo precisa dos dois.
- **RF-11:** Com o Bioma ou a Altura escolhidos, as teclas Shift+0 a Shift+4 escolhem a altura (Shift+0 a Shift+9 desde a [terrain-height/02](../terrain-height/02-eleven-heights.md)).

**Objeto** (desde a [free-props/03](../free-props/03-pieces-tool.md), a ferramenta se chama Peças e põe também as peças soltas)

- **RF-12:** Os tipos aparecem numa lista, um por linha, com o ícone, o nome inteiro e o tamanho em hexágonos.
- **RF-13:** Em cima da lista, a prévia grande mostra a arte do objeto, com o espelho. Sem objeto escolhido no mapa, é o objeto novo: as setas e os números das variantes trocam a variante que será posta. Com um objeto escolhido, é ele, e as setas trocam a variante dele na hora.
- **RF-14:** O clique esquerdo num objeto já posto escolhe esse objeto, em vez de tentar pôr outro em cima. O botão direito continua escolhendo.
- **RF-15:** Com um objeto escolhido, aparece no mapa, logo abaixo dele, uma barra com a variante (setas e número), Espelhar, Editar bloqueio e Apagar. Ela acompanha o zoom e o arrasto e some quando nada está escolhido ou quando o objeto sai do mapa visível.
- **RF-16:** Com um objeto escolhido, ← e → trocam a variante, M espelha, Delete apaga e Esc tira a escolha. Cada mudança entra no desfazer, como pelos botões.

**Área**

- **RF-17:** O painel da Área tem a chave "Focar na escolhida" (tecla F). Ligada, todo hexágono fora da área escolhida fica escurecido, e só a cor da área escolhida aparece. Trocar de área move o foco; sair da ferramenta Área desliga o foco.

## Critérios de aceite

- [x] O topo tem Ilhas, desfazer, refazer e Camadas, e as chaves de camada saíram da barra.
- [x] Trocar entre as 9 ferramentas não muda a largura do painel.
- [x] Bioma com Manter não muda a altura; com 3, pinta o bioma e a altura 3. Altura não mostra biomas.
- [x] A prévia mostra cada variante de um tipo antes de pôr no mapa.
- [x] Clicar num objeto posto o escolhe, a barra aparece embaixo dele, e as setas, M e Delete funcionam e se desfazem com Ctrl+Z.
- [x] O foco numa área escurece o resto do mapa.
- [x] O projeto abre sem erros nem avisos de script novos.

## Desenho técnico

**Criar**

- `client/tools/map_editor/icons/*.svg`: 19 ícones brancos de 48×48, desenhados à mão (preenchidos ou de traço), só do editor. A lixeira, o olho e os outros não existiam em `ui/icons`, que é da interface do jogo.
- `client/tools/map_editor/object_bar.gd`: `class_name ObjectBar`, a barra ao lado do objeto escolhido, que chama o `ObjectPanel`.

**Alterar**

- `map_editor.gd`: o topo novo, os painéis por cima (`PopupPanel`) de Ilhas e Camadas, a coluna de ferramentas, a barra do objeto e as teclas.
- `editor_tools.gd`: a coluna de ferramentas sai para o `MapEditor`; o painel com largura fixa; Bioma e Altura separados (`biome_height`, -1 é Manter).
- `object_panel.gd`: a lista de tipos, a prévia e as variantes; métodos públicos para a barra e as teclas (`change_variant`, `toggle_mirror`, `toggle_blocks`, `delete_selected`).
- `area_panel.gd`: a chave Focar.
- `editor_canvas.gd`: o foco (uma `HexTintLayer` escura sobre os hexágonos de fora) e o sinal `view_changed`, para a barra acompanhar o mapa; `object_rect(index)`, o retângulo do objeto na tela.

**Conceito do Godot**

`PopupPanel` é uma janelinha sem borda que abre por cima do resto (`popup()`) e fecha sozinha ao clicar fora dela. Serve para o menu Ilhas e para Camadas sem tirar espaço da tela.

## Verificação

Uma cena temporária abre o editor na Vila de Ventoverde e salva imagens de cada ferramenta, do objeto escolhido com a barra, da prévia e do foco numa área. Passos do dono no editor (F2): pôr objetos trocando a variante pela prévia, escolher um objeto posto e trocar a variante com as setas, apagar com Delete e desfazer, focar numa área.

```bash
godot --headless -d --path client --quit-after 60
```

Feito: duas cenas temporárias, já apagadas, abriram o editor na Vila de Ventoverde.

- Imagens de Bioma, Altura, Pôr hexágono, Área com foco, Objeto sem e com escolha (com a barra no mapa), Camadas e Ilhas abertos. O painel ficou com 430 px em todas as 9 ferramentas (o da Área pedia mais que os 400 do começo).
- Comportamento: o clique esquerdo num objeto posto o escolhe, sem pôr outro; → troca a variante; M espelha; Delete apaga e Ctrl+Z traz de volta; Esc tira a escolha; o Bioma com Manter não mudou a altura, e com Shift+3 pintou o bioma e a altura 3 sem trocar de ferramenta; F liga o foco, e sair da Área o desliga.

## Decisões da implementação

- Os painéis de Ilhas e Camadas são `PopupPanel`s com fundo próprio, e a janela do editor passou a ter `gui_embed_subwindows`: sem isso, eles abririam como janelas do sistema, fora do lugar. Os diálogos de salvar, apagar e publicar também passam a abrir dentro da janela.
- A coluna de ferramentas é montada pelo `EditorTools` (`tool_column`), que continua sendo quem marca a ferramenta escolhida, e o `MapEditor` só a põe ao lado do painel.
- O foco escurece com uma `HexTintLayer` (`_dim_layer`) por cima do mapa, na altura de cada hexágono. Paredões e objetos altos fora da área ficam só em parte escurecidos, o que basta para achar a área.
- O erro "Invalid access to property or key 'size'" no `HexMapView._update_scale`, ao fechar o jogo, já existia antes desta fase.

## Tarefas

- [x] Topo: Camadas, Ilhas, desfazer e refazer (RF-01 a RF-04).
- [x] Coluna de ferramentas e painel fixo (RF-05 a RF-07).
- [x] Bioma e Altura (RF-08 a RF-11).
- [x] Objeto: lista, prévia, barra e teclas (RF-12 a RF-16).
- [x] Foco na área (RF-17).
- [x] Conferir no editor; remover os temporários; atualizar o README, `architecture.md` e o `client/CLAUDE.md`.
