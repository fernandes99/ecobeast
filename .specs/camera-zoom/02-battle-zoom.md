# 02. A pinça na luta

- **Status:** concluída (falta o dono conferir a pinça no celular)
- **Depende de:** [01](01-explore-zoom.md) e [board-battle](../board-battle/)

## Contexto

O tabuleiro da luta é escalado pelo `_fit_board` para caber inteiro na `BoardArea`. Esta fase deixa o jogador aproximá-lo com a pinça e arrastar a vista, com o `PinchZoom` da [01](01-explore-zoom.md).

## Escopo

- A pinça, a roda do mouse e o arrasto no tabuleiro da luta.

## Fora do escopo

- Guardar o zoom da luta: cada luta começa com o tabuleiro inteiro.
- A câmera seguindo o Ecobeast da vez.

## Requisitos

- **RF-01:** o zoom da luta multiplica o ajuste de hoje (o do `_fit_board`), de 1 (o tabuleiro inteiro) a 2,5, contínuo.
- **RF-02:** a pinça aproxima e afasta em volta do ponto entre os dedos: o ponto do tabuleiro embaixo dele continua embaixo dele. A pinça começa com os dois dedos na `BoardArea`.
- **RF-03:** a roda do mouse multiplica o zoom por 1,25 a cada clique para cima e divide por 1,25 para baixo, em volta do cursor.
- **RF-04:** com o zoom acima de 1, arrastar um dedo, ou o botão esquerdo do mouse, por mais de 24 px move a vista junto com o dedo. Um movimento menor continua sendo um toque no hexágono.
- **RF-05:** a vista nunca sai das bordas do tabuleiro. Em cada eixo em que o tabuleiro é maior que a `BoardArea`, ele cobre a área inteira. No eixo em que é menor, fica centralizado, como hoje.
- **RF-06:** depois de uma pinça ou de um arrasto, o toque não vale até todos os dedos saírem, e nenhum hexágono é escolhido.
- **RF-07:** o chão em volta do tabuleiro (`cover_screen`) continua cobrindo a tela inteira em qualquer zoom e posição.
- **RF-08:** a luta começa com o zoom 1. Quando a `BoardArea` muda de tamanho, o zoom e o ponto do tabuleiro no centro da área se mantêm, presos pelo RF-05.
- **RF-09:** a pinça e o arrasto só valem com o tabuleiro na frente: com uma janela por cima (Mochila, troca, Técnica nova, Evolução, Bestiário, histórico ou nível novo), eles não fazem nada.

## Critérios de aceite

- [ ] Abrindo os dedos, o tabuleiro cresce em volta deles até 2,5 vezes. Fechando, ele volta até caber inteiro e para.
- [ ] Aproximado, um dedo arrasta a vista sem passar das bordas, e o toque curto ainda escolhe o hexágono.
- [ ] Tirar os dedos depois de uma pinça ou de um arrasto não escolhe hexágono.
- [ ] O chão cobre a tela em qualquer zoom, sem buraco nas bordas.
- [ ] As barras de vida, os números de dano, os efeitos e as marcas no chão acompanham o tabuleiro em qualquer zoom.
- [ ] A próxima luta começa com o tabuleiro inteiro.
- [ ] O jogo abre sem erros de script e sem avisos novos.

## Desenho técnico

- **`board_battle_screen.gd`:**
  - a variável `_zoom := 1.0` e o deslocamento da vista;
  - o `_fit_board` passa a usar o ajuste de hoje vezes `_zoom` e aplica o deslocamento preso pelo RF-05, antes do `cover_screen()`;
  - um `PinchZoom`, alimentado pelo `_input` com a área da `BoardArea`, e o arrasto de um dedo.
- **`board_view.gd`:** o `_on_gui_input` não emite `cell_tapped` quando a tela diz que o toque foi bloqueado. Por exemplo, uma propriedade `taps_blocked: Callable` que a tela preenche com o `blocks_tap()` do `PinchZoom` e com o arrasto.
- **`pinch_zoom.gd`:** o que faltar para o arrasto de um dedo. Se for preciso, o `blocks_tap()` passa a valer também depois de um arrasto maior que 24 px.

## Verificação

- Uma cena temporária sem janela em `client/zz_tmp_check` (apagada depois), que abre a luta com um tabuleiro de teste e confere:
  - os limites do zoom;
  - o ponto fixo da pinça;
  - a vista presa nas bordas;
  - o toque bloqueado depois do arrasto.
- O jogo sem janela, sem erros de script.
- **Com o dono:** a pinça e o arrasto no celular, numa luta de selvagem e numa de Domador.

## Tarefas

- [x] O zoom e o deslocamento no `_fit_board`.
- [x] A pinça, a roda e o arrasto.
- [x] O toque bloqueado no `BoardView`.
- [x] A conferência e a documentação.

## Resultado da verificação

Em 2026-11-14:

- **Cena temporária sem janela** (apagada): ela abre a tela da luta com um tabuleiro de teste de 7 × 5 e confere:
  - no zoom 1, o tabuleiro fica centralizado na área;
  - o zoom fica preso entre 1 e 2,5, e a escala é a do ajuste vezes o zoom;
  - o ponto embaixo dos dedos continua embaixo deles;
  - a vista cobre a área no eixo maior e centraliza no outro, mesmo aproximando num canto ou arrastando para longe;
  - um movimento de 10 px não arrasta, e um de 60 px arrasta;
  - o toque fica bloqueado depois do arrasto e durante a pinça, e volta no toque seguinte;
  - a pinça com os dedos a duas vezes a distância do começo dobra o zoom;
  - a roda multiplica o zoom por 1,25;
  - com a Mochila aberta, a pinça e o arrasto não fazem nada.
- **O jogo sem janela** abre sem erros de script e sem avisos.
- **Não conferido:** a pinça e o arrasto no celular, numa luta de verdade.
