# 03. Objetos do mapa

- **Status:** concluída
- **Depende de:** [01-village-records](01-village-records.md), [02-grounds](02-grounds.md)

## Contexto

Com a [01](01-village-records.md), uma ilha guarda objetos com bloqueio por hexágono, mas nada os desenha, o editor não os põe e o Domador ainda atravessa tudo. Esta fase traz a arte provisória dos 17 tipos, o desenho no `HexMapView`, a ferramenta Objeto no editor e o bloqueio no jogo, com as ações em hexágono bloqueado. O desenho e o formato da arte estão no [architecture.md](architecture.md#o-desenho-no-jogo).

## Escopo

- O script da arte provisória e a tabela do tamanho de cada tipo.
- Os objetos no `HexMapView`, com a ordem certa de desenho e a altura.
- A ferramenta Objeto: pôr, escolher, mudar a variante, espelhar, trocar o bloqueio de cada hexágono e apagar.
- No jogo: o Domador não entra em hexágono bloqueado, e tocar num bloqueado com ação executa a ação.

## Fora do escopo

- Arte final, animação e sombra dos objetos.
- Mover um objeto já posto (apague e ponha de novo).
- Objetos no mapa sorteado.

## Requisitos

### Arte

- **RF-01:** `res://assets/map_objects/make_placeholders.gd` gera `res://assets/map_objects/<slug>/<variante>.png` para os 17 tipos, um arquivo por variante, no formato do [architecture.md](architecture.md#o-desenho-no-jogo).
  - As formas são simples, com contorno escuro, no estilo dos hexágonos do mapa: paredes claras e telhado da cor da variante nas casas, copa redonda na árvore, torres no castelo, e assim por diante.
  - As cores das variantes são as da tabela de tipos.
- **RF-02:** a tabela do tamanho da célula de cada tipo fica no [architecture.md](architecture.md#o-desenho-no-jogo).

### Desenho

- **RF-03:** cada objeto aparece com a célula da variante dele (a última que existe, se a variante passar de `variants`), invertida na horizontal se `mirrored`, com o ponto de apoio no lugar do [architecture.md](architecture.md#o-desenho-no-jogo), subindo a altura do hexágono de apoio.
- **RF-04:** um objeto cobre o terreno, as decorações e os atores das linhas de trás, e é coberto pelas linhas da frente. Na linha dele, ele fica por cima das decorações de trás e por baixo dos atores e das decorações da frente.
- **RF-05:** nos hexágonos de um objeto, não nasce decoração sorteada.
- **RF-06:** no editor, pôr, apagar, espelhar ou trocar a variante de um objeto mostra a mudança na hora, sem montar a ilha de novo.

### Editor

- **RF-07:** a ferramenta **Objeto** entra antes de Ação, e as teclas passam a ir até 9: Bioma, Altura, Chão, Pôr hexágono, Tirar hexágono, Chegada, Objeto, Ação e Área. A frase da ferramenta é "Põe objetos. Botão direito escolhe um objeto posto.".
- **RF-08:** o bloco Objeto mostra os 17 tipos como amostras com a arte da primeira variante e o nome. Embaixo, a variante (setas, com o número) e um botão **Espelhar**.
- **RF-09:** com a ferramenta Objeto, sob o ponteiro aparece o formato do tipo escolhido, espelhado se Espelhar estiver ligado, em verde se cabe e em vermelho se não cabe. Ele cabe quando todos os hexágonos existem e nenhum é de outro objeto. O clique esquerdo põe o objeto, com o bloqueio padrão do tipo, se ele couber.
- **RF-10:** o botão direito num hexágono de um objeto escolhe esse objeto. O painel mostra o nome, a variante, Espelhar, **Apagar** e **Editar bloqueio**. Mudar a variante ou espelhar vale para o objeto escolhido. Espelhar só vale se o formato espelhado couber.
- **RF-11:** com Editar bloqueio ligado, o clique esquerdo num hexágono do objeto escolhido troca o bloqueio dele.
- **RF-12:** a camada **Bloqueio**, ligada por um botão na barra de cima como Áreas e Construções, marca os hexágonos bloqueados com um X vermelho. Ela fica sempre ligada enquanto Editar bloqueio está ligado.
- **RF-13:** Tirar hexágono num hexágono de objeto apaga o objeto inteiro.
- **RF-14:** pôr, apagar, espelhar, mudar a variante e trocar o bloqueio são passos do desfazer.

### Jogo

- **RF-15a:** um toque na arte de um objeto vale para o hexágono dele vizinho ao Domador, como no [architecture.md](architecture.md#no-jogo-andar-e-agir).
- **RF-15:** tocar num vizinho bloqueado não anda. Se ele é de uma ação, a ação acontece sem o Domador sair do lugar. Se não é, nada acontece.
- **RF-16:** os objetos aparecem em Ilhas como no editor, e o Domador passa por trás e pela frente deles na ordem certa.

## Critérios de aceite

- [x] Os 17 tipos aparecem no editor, com todas as variantes, normais e espelhados.
- [x] Um castelo posto tem o portão livre e o resto bloqueado. Trocar o bloqueio de um hexágono muda o X.
- [x] Um objeto não cabe em cima de outro nem fora da ilha.
- [x] Ctrl+Z desfaz pôr, apagar, espelhar, variante e bloqueio.
- [x] Em Ilhas:
  - o Domador não entra num hexágono bloqueado;
  - ele passa pelo portão do castelo;
  - tocar numa casa bloqueada com a ação Loja, estando ao lado, abre a Loja.
- [x] O Domador atrás de uma casa fica escondido por ela, e na frente fica por cima.
- [x] Um objeto numa colina de altura 2 sobe junto com ela.
- [x] Nenhuma árvore sorteada nasce dentro de um objeto.
- [x] O projeto abre sem erros nem avisos de script novos.

## Desenho técnico

**Criar**

- `res://assets/map_objects/make_placeholders.gd` e os 31 PNG (um por variante), com o `.import`.
- `res://ui/components/map_object_sprite.gd`: `MapObjectSprite`, o nó de um objeto, com a célula, o espelho e o ponto de apoio.
- `res://tools/map_editor/object_panel.gd`: `ObjectPanel`, o bloco Objeto e o painel do objeto escolhido.

**Alterar**

- `res://ui/components/hex_map_view.gd`:
  - o encaixe dos objetos por linha, `set_object_row(node, row)`, depois das decorações de trás e antes dos atores;
  - o filtro das decorações nos hexágonos de objeto;
  - `set_objects(objects)`, que cria, troca e tira os nós sem montar o mapa.
- `res://screens/exploration/exploration_screen.gd`: os objetos, o bloqueio no `_tap` e a ação em hexágono bloqueado.
- `res://tools/map_editor/`:
  - `editor_tools.gd`: `Tool.OBJECT`;
  - `editor_canvas.gd`: o formato sob o ponteiro e a camada Bloqueio;
  - `island_draft.gd`: pôr e apagar objeto, e Tirar hexágono;
  - `editor_history.gd`: os objetos antes e depois de cada passo;
  - `map_editor.gd`: o botão da camada Bloqueio.
- `.specs/island-villages/architecture.md`: a tabela de tamanhos; e `client/CLAUDE.md`.

## Verificação

```bash
godot --headless -d --path client --quit-after 60
```

Uma cena temporária monta um mapa com os 17 tipos, normais e espelhados, um castelo numa colina e um ator atrás e na frente de uma casa. Ela salva capturas, que são abertas e revisadas, e confere o bloqueio do `ExplorationMap` e o formato espelhado. Depois, a pasta é apagada.

Passos no editor (F2):

1. Pôr cada tipo.
2. Espelhar e trocar a variante.
3. Editar o bloqueio do castelo.
4. Apagar.
5. Desfazer.
6. Salvar e publicar.

Em Ilhas:

1. Andar em volta da vila.
2. Entrar pelo portão.
3. Tocar na casa com a Loja.

## Tarefas

- [x] Script, arte provisória e tabela de tamanhos.
- [x] `MapObjectSprite` e os objetos no `HexMapView`.
- [x] Ferramenta Objeto, painel, formato sob o ponteiro, camada Bloqueio e desfazer.
- [x] Bloqueio e ação no jogo.
- [x] Verificação; atualizar os documentos; marcar esta spec, o README da iniciativa, o `.specs/README.md`, o `roadmap.md` e o escopo do `CLAUDE.md` como `concluída`.

## Decisões da implementação

- **Um PNG por variante, e não uma faixa:** `res://assets/map_objects/<slug>/<variante>.png`. Assim, diminuir `variants` no painel não desalinha as células, e a arte final pode chegar uma variante por vez. O [architecture.md](architecture.md#o-desenho-no-jogo) foi atualizado, com a tabela de tamanhos.
- **Arte gerada pelo Godot (`make_placeholders.gd`), e não por Python**, pelo mesmo motivo das texturas de chão.
- **O encaixe na linha:** cada objeto vai logo depois das decorações de trás da linha da frente dele (`_place_object` no `HexMapView`), e os atores, como hoje, logo antes das decorações da frente. Por isso, numa mesma linha, o Domador fica sempre por cima do objeto.
- **O toque na arte** confere o alfa do pixel. Ele vale para o hexágono do objeto vizinho ao Domador, o de ação primeiro.
- **Painel Objeto:** sem objeto escolhido, a variante e Espelhar valem para o próximo objeto; com um escolhido, mudam ele.
  - Espelhar um objeto posto só acontece se o formato espelhado couber.
  - O castelo é simétrico, então espelhado ocupa os mesmos hexágonos.
- **Tirar hexágono** apaga o objeto inteiro que tem aquele hexágono, e o desfazer devolve.
- **Verificação:**
  - Uma cena temporária, já apagada, conferiu:
    - o formato do castelo, com o portão livre;
    - o formato espelhado do moinho;
    - pôr, recusar em cima de outro e a cor do formato sob o ponteiro;
    - trocar o bloqueio e a variante;
    - Tirar hexágono, com o desfazer;
    - o bloqueio no `ExplorationMap`;
    - o toque na arte de uma casa.
  - Uma captura com os 17 tipos, normais e espelhados, e o castelo num planalto de altura 2 foi aberta e revisada.
  - O projeto abre sem avisos novos.

**Falta do dono:**

1. No F2, pôr os objetos, espelhar, trocar a variante e editar o bloqueio do castelo.
2. Em Ilhas, andar em volta da vila, entrar pelo portão e tocar numa casa bloqueada com a Loja.

Nenhum celular foi testado.
