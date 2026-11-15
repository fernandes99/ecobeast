# 01. A pinça ao explorar

- **Status:** concluída (falta o dono conferir a pinça no celular)
- **Depende de:** [wild-battle](../wild-battle/) e [islands](../islands/)

## Contexto

O mapa de Explorar mostra a arte sempre no mesmo tamanho (`ART_SCALE` = 2 no `HexMapView`). Esta fase deixa o jogador escolher o tamanho com a pinça, como no [README](README.md), e cria o leitor de pinça que a [02](02-battle-zoom.md) reaproveita.

## Escopo

- O `PinchZoom`, que lê dois dedos e a roda do mouse.
- O nível de zoom do `HexMapView` e a pinça na tela de Explorar.
- O zoom de Explorar guardado no aparelho.

## Fora do escopo

- A luta ([02](02-battle-zoom.md)).
- O modo de debug "mapa inteiro", que continua como está e ignora a pinça.

## Requisitos

- **RF-01:** os níveis de zoom são 1, 2, 3 e 4 pixels da tela lógica por pixel da arte; o 2 é o de hoje. Cada nível é arredondado para pixels inteiros da janela, como o `art_scale()` faz hoje com o 2.
- **RF-02:** durante a pinça, o nível acompanha os dedos: o nível mostrado é o do começo da pinça vezes a razão entre a distância atual dos dedos e a do começo, arredondado e preso entre 1 e 4. Ele muda na hora, sem esperar os dedos saírem.
- **RF-03:** a câmera continua com o Domador no centro em qualquer nível, parado ou andando, e os sprites (Domador, Ecobeasts, Domadores NPC e NPCs) e os nomes das construções acompanham o nível.
- **RF-04:** a pinça só começa com os dois dedos na área do mapa e só quando o toque no mapa valeria: sem conversa, desafio, mensagem que trava o mapa ou "mapa inteiro".
- **RF-05:** depois de uma pinça, nenhum toque vale até todos os dedos saírem da tela, e o Domador não anda.
- **RF-06:** no PC, cada clique da roda do mouse sobre o mapa sobe ou desce um nível.
- **RF-07:** o nível fica guardado no aparelho (`user://view.json`, chave `explore_zoom`) ao mudar, e a próxima exploração abre nele. Sem o arquivo, ou com um valor fora de 1 a 4, abre no 2.
- **RF-08:** os Ecobeasts continuam nascendo e sumindo fora da vista: o raio em que existem como nós (`CREATURE_RADIUS`, 16 no nível 2) cresce no nível 1, para 16 × 2 ÷ nível (32). Nos níveis 3 e 4 ele fica em 16, como hoje.

## Critérios de aceite

- [ ] Abrindo e fechando os dedos no mapa, o zoom passa pelos 4 níveis e para nos limites.
- [ ] Em todos os níveis a pixel art fica nítida, com todos os pixels da arte do mesmo tamanho.
- [ ] O Domador fica no centro em todos os níveis, e o toque leva o Domador ao ponto tocado.
- [ ] Tirar os dedos depois de uma pinça não faz o Domador andar.
- [ ] No nível 1, nenhum Ecobeast aparece ou some dentro da tela.
- [ ] Saindo e voltando a Explorar, ou fechando o jogo, o zoom escolhido continua.
- [ ] A roda do mouse muda o nível no PC.
- [ ] O jogo abre sem erros de script e sem avisos novos.

## Desenho técnico

- **Criar `res://ui/components/pinch_zoom.gd`** (`class_name PinchZoom`, `RefCounted`), que a tela alimenta com os eventos e que não sabe de mapa nem de tabuleiro:
  - `feed(event: InputEvent, area: Rect2) -> bool`: guarda os dedos (`InputEventScreenTouch` e `InputEventScreenDrag`, pelo `index`) e devolve `true` quando consumiu o evento numa pinça. A pinça começa quando o segundo dedo toca e os dois estão dentro de `area`.
  - O sinal `pinched(ratio: float, center: Vector2)`: a razão entre a distância atual e a do começo da pinça, e o ponto entre os dedos.
  - `wheel(event: InputEvent, area: Rect2) -> int`: +1 ou −1 para a roda dentro da área, 0 para o resto.
  - `blocks_tap() -> bool`: `true` desde o começo de uma pinça até o último dedo sair.
- **Criar `res://core/settings/view_settings.gd`** (`class_name ViewSettings`, só funções `static`): `explore_zoom() -> int` e `set_explore_zoom(level: int)`, lendo e gravando `user://view.json`.
- **`hex_map_view.gd`:** a propriedade `zoom_level := 2`, usada no `art_scale()` no lugar do `ART_SCALE`; mudar o nível chama o `_update_scale()`.
- **`exploration_screen.gd`:**
  - um `PinchZoom`, alimentado pelo `_input` com a área do `_map_area`. Antes do toque em `_on_map_input`, o `blocks_tap()`;
  - ao mudar o nível: o `zoom_level`, o `_fit_view()` e o `ViewSettings`;
  - o raio dos Ecobeasts do RF-08 no `_is_near_coord`.

## Verificação

- Uma cena temporária sem janela em `client/zz_tmp_check` (apagada depois), que confere o `PinchZoom` com eventos de toque falsos: a razão da pinça, o `blocks_tap()` e o toque fora da área. Ela também confere o `ViewSettings` com um valor fora da faixa.
- O jogo sem janela, sem erros de script.
- **Com o dono:** a pinça no celular, ou a roda do mouse no PC, numa ilha.

## Tarefas

- [x] O `PinchZoom` e o `ViewSettings`.
- [x] O nível de zoom no `HexMapView`.
- [x] A pinça, a roda e o raio dos Ecobeasts na tela de Explorar.
- [x] A conferência e a documentação.

## Resultado da verificação

Em 2026-11-14:

- **Cena temporária sem janela** (apagada): o `PinchZoom` com toques falsos confere:
  - um dedo não é pinça;
  - o segundo dedo começa a pinça, e dobrar a distância dá a razão 2;
  - o bloqueio do toque vale até o último dedo sair;
  - um dedo fora da área não começa a pinça;
  - a roda dá +1 e −1, e 0 fora da área.
- **O `ViewSettings`:** abre no 2 sem arquivo, com 9, com 2,5 e com um arquivo inválido, e grava e lê o 4. O arquivo do aparelho foi guardado antes e devolvido depois.
- **O `HexMapView`:** o nível fica preso em 4. Com a janela em 1,5 vez a tela lógica, os níveis de 1 a 4 dão 2, 3, 5 e 6 pixels inteiros da janela.
- **O jogo sem janela** abre sem erros de script e sem avisos.
- **Não conferido:** a pinça no celular e a roda numa ilha, com o jogo aberto.
