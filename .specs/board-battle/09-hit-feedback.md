# 09. Golpes com efeito, tempos e o log de uma linha

- **Status:** concluída (falta o dono testar no editor)
- **Depende de:** [08](08-board-ground.md)

## Contexto

Na [08](08-board-ground.md), o golpe no tabuleiro é só um número que sobe reto sobre o alvo, e as frases vão direto para o histórico, sem aparecer na tela. Em 2026-11-05, o dono instalou um kit de efeitos em pixel art ("Effect and FX Pixel All Free") e pediu para melhorar os golpes e os tempos da luta, começando pela Arranhão, com a folha `Free/Part 9/447.png` do kit.

A sequência que ele pediu: o Ecobeast anda; na hora de atacar, ele treme um pouco ("como se fosse de ataque, no futuro vamos colocar animação de ataque"); o arranhão aparece no alvo; o alvo treme e pisca; e o dano aparece e some aos poucos, subindo "zanzando". Ele também pediu de volta uma linha de texto com o log, escrita letra por letra, rápido. Depois, pediu que o selvagem derrotado, ao sumir, deixasse uma moeda girando que sobe e vai sumindo, como nos jogos de plataforma clássicos. Por fim, pediu um som para a Arranhão ("consegue gerar ou buscar algum som para ele?"): o som foi gerado por síntese, sem arquivo de terceiros, e por isso sem licença para conferir. Depois, pediu um som de dano junto com a piscada, em todo dano, com três versões: normal, super efetivo e pouco efetivo. Ele mandou o som de super efetivo de outro jogo como referência; o arquivo não entra no projeto, e dele só se tirou o jeito: um impacto largo de 1,7 s, que começa forte e fica assim por uns 0,3 s, com um grave entre 130 e 300 Hz, um ruído médio entre 1 e 2 kHz, uma leve trepidação no volume e um ronco que some até 1,2 s.

A folha 447 tem 576 × 576 pixels, em células de 64: 9 linhas de cor, com os mesmos 9 quadros do arranhão em cada uma. A Arranhão é do Elemento Fera, marrom (#B08B6E). A primeira versão usou a 5ª linha, a marrom, mas num print ela quase sumia sobre um Ecobeast laranja, cor de boa parte dos Ecobeasts de Fogo. Por isso ela usa a 6ª linha, a cinza-clara, que aparece sobre qualquer cor. _A revisar._

## Escopo

- A sequência do golpe no tabuleiro: o atacante treme, o efeito da Técnica no alvo, o alvo treme e pisca, e o número do dano sobe zanzando.
- O efeito da Arranhão, recortado do kit.
- Uma caixa de uma linha, acima do cartão do jogador, com as frases da luta letra por letra.

## Fora do escopo

- A animação de ataque de cada Ecobeast: por enquanto, ele só treme.
- O efeito das outras Técnicas: cada uma chega quando o dono escolher a folha, sem mudar código.
- Tocar para completar a frase ou pular a sequência.
- Som nas outras Técnicas e na luta em geral (passos, queda, moeda).

## Requisitos

- **RF-01:** Quando um Ecobeast usa uma Técnica, ele treme um pouco no lugar, de um lado para o outro, por 0,25 s, enquanto a área da Técnica acende. Depois a frase "X usou Y." aparece no log.
- **RF-02:** Uma Técnica com efeito mostra a animação dele sobre o corpo do alvo, 1,5× maior que a arte, para cobrir o Ecobeast, um quadro a cada 0,05 s. Com o atacante à direita do alvo, o efeito aparece espelhado. Hoje só a Arranhão tem efeito.
- **RF-03:** Depois do efeito, o alvo treme e pisca por 0,35 s, e a barra de HP dele cai nesse momento.
- **RF-04:** Depois disso, o número do dano aparece logo acima da barra de HP do alvo, em letra maior que antes (34), sobe uns 50 pixels em 2 s ondulando de um lado para o outro e, da metade do caminho em diante, some aos poucos. Começou com 1,2 s, e o dono achou rápido demais. A sequência não espera o número sumir: a frase do dano já começa a aparecer no log.
- **RF-05:** O dano que não vem de uma Técnica (recuo, estado, chão e confusão) tem só o RF-03 e o RF-04. A cura tem só o número, em verde, sem tremer.
- **RF-06:** Uma caixa de uma linha fica logo acima do cartão do jogador. Cada frase da luta aparece nela letra por letra, a 60 letras por segundo (_a revisar_), e fica 0,35 s depois de completa. A frase mais longa que a linha termina em reticências, e o histórico guarda todas inteiras. Os avisos da vez do jogador (como "Toque no hexágono verde onde ele entra.") aparecem inteiros na mesma caixa. O log nunca fica vazio depois que a luta começa: ele guarda a última frase ("Um Ruvo selvagem apareceu!", "Ruvo usou Arranhão."), e ela volta quando um aviso sai. Pedido do dono: "deve sempre mostrar a última ação". Por isso a frase da rodada ("Rodada 2.") vai só para o histórico: ela não é uma ação, e o dono já tinha tirado o contador de rodadas da tela.
- **RF-07:** O tabuleiro continua parado ([08](08-board-ground.md)): a caixa tem sempre a altura de uma linha.
- **RF-08:** Quando um selvagem derrotado sai do tabuleiro, ele some de vez em 0,3 s, e no lugar dele uma moeda (o ícone de moeda do jogo, `res://ui/icons/coin.svg`) sobe girando por 1,1 s, desacelerando, e some aos poucos da metade do caminho em diante. A moeda é só um sinal: o servidor só conta as moedas no fim da luta, e o valor aparece na frase do fim. O capturado e os Ecobeasts do jogador saem sem moeda. A luta não espera a moeda sumir.
- **RF-09:** A Arranhão toca o som dela no mesmo instante em que o efeito começa: três rasgos rápidos, um por garra, em 0,42 s. Uma Técnica sem arquivo de som não toca nada. É o primeiro som do jogo. _A revisar._
- **RF-10:** Todo dano toca um som junto com a piscada do alvo (RF-03): o super efetivo, se o multiplicador do Elemento passar de 1; o pouco efetivo, se ficar abaixo de 1; e o normal no resto, inclusive no dano que não vem de uma Técnica. O som da Técnica (RF-09) vem antes, com o efeito. Os três são gerados por síntese: normal, um golpe seco de 0,25 s; super efetivo, um impacto largo de 0,62 s que treme e deixa um ronco, mais forte que os outros; pouco efetivo, uma batida abafada e baixa de 0,18 s. _A revisar._

## Critérios de aceite

- [ ] Com F5, uma luta em que o Ecobeast do jogador anda e usa a Arranhão: ele anda, treme, a frase aparece letra por letra, o arranhão marrom aparece no selvagem, o selvagem treme e pisca, a barra cai, e o número sobe zanzando e some.
- [ ] Uma Técnica sem efeito pula o arranhão e faz o resto.
- [ ] O log de uma linha mostra as frases da luta, e o histórico ("?") continua com todas.

## Desenho técnico

- **Efeitos das Técnicas:** `res://assets/effects/skills/<slug da Técnica>.png`, uma tira de quadros quadrados da esquerda para a direita. O número de quadros é a largura dividida pela altura. Sem o arquivo, a Técnica não tem efeito. `arranhao.png` é a 6ª linha (a cinza-clara) da `Part 9/447.png` do kit: 576 × 64, com 9 quadros de 64, sem mudança nos pixels. O kit não traz arquivo de licença na pasta.
- **`BoardView`** ganha:
  - `attack_shake(key)`: o corpo treme de lado e volta ao lugar. Pode ser esperado com `await`.
  - `play_effect(key, texture, mirrored)`: um `Sprite2D` sobre o meio do corpo do alvo, que troca de quadro e some no fim.
  - `hit(key)`: o corpo treme e o sprite pisca.
  - `float_number`: o número sobe e ondula, e some aos poucos.
  - O som de cada Técnica fica em `res://assets/sounds/skills/<slug da Técnica>.wav`, tocado por um `AudioStreamPlayer` da tela, no bus Master. `arranhao.wav` (44,1 kHz, mono, 16 bits) é gerado por `art-source/sounds/arranhao.py`: ruído branco num filtro passa-banda que desce de 6200 para 1900 Hz, com ataque de 4 ms e queda rápida, três vezes, com uma seed fixa. Para mudar o som, muda-se o script e gera-se de novo.
  - Os sons de dano ficam em `res://assets/sounds/hits/` (`normal.wav`, `super.wav` e `weak.wav`), gerados por `art-source/sounds/hits.py`, e tocam num segundo `AudioStreamPlayer`, para não cortar o som da Técnica. O tipo sai do `multiplier` do evento `damage`, lido com o novo `DictFields.get_float`.
  - `vanish(key, coin)`: o Ecobeast some e sai; com `coin`, a moeda sobe girando no lugar dele. O giro é a largura da moeda indo e voltando (um cosseno), sem folha de quadros.
- **Tela da luta:** o `skill_used` guarda quem usou e qual Técnica até a próxima vez. Cada `damage` desse golpe toca o efeito da Técnica, se ela tiver um, depois o `hit` e o número. A `Message` passa a morar numa caixa (`LogBox`, painel do tema) de uma linha. As frases saem com `visible_characters`, num `Tween`. Os avisos põem o texto inteiro.

## Verificação

- O projeto abre sem erros, e o teste do tabuleiro (`sheets_test.gd`) e o do tabuleiro parado seguem passando.
- Um teste sem janela toca um golpe da Arranhão e confere a ordem: o atacante treme, o efeito aparece e some, o alvo pisca, e o número nasce depois do efeito.
- O dono vê os tempos com F5.

## Tarefas

- [x] Spec.
- [x] O efeito da Arranhão recortado do kit.
- [x] A sequência do golpe no `BoardView` e na tela.
- [x] O log de uma linha.
- [x] A moeda do selvagem derrotado.
- [x] O som da Arranhão.
- [x] Os sons de dano, por efetividade.
- [ ] O dono ver com F5 e acertar os tempos.

## Resultado da verificação

Em 2026-11-05, sem janela:

- O projeto importa sem erros; a checagem de carga, o teste do tabuleiro e o do tabuleiro parado dão 0 falhas. O log de uma linha não muda a altura do bloco de baixo.
- Um teste montou uma luta em que o Ecobeast do jogador usa a Arranhão e anotou quando cada parte começa: o atacante treme (2,94 s), a frase "Ruvo usou Arranhão." aparece letra por letra (3,22 s), o arranhão aparece no alvo (3,88 s), o alvo pisca (4,38 s), o número nasce (4,75 s) e a frase do dano começa logo depois. A ordem é a do pedido.

Com janela, prints no meio do golpe mostraram o arranhão cinza-claro sobre o alvo e o "-12" acima da barra de HP. Outro teste, com janela, derrubou o selvagem com a Arranhão: a moeda apareceu depois de "Ruvak desmaiou." e de ele sumir, e um print a mostrou de frente, girando, no lugar dele. O teste do golpe também conferiu que o som começa no mesmo quadro que o efeito, e um desenho da onda mostra os três rasgos. O som não foi ouvido aqui. Falta o dono ouvir o som e ver os tempos com F5.
