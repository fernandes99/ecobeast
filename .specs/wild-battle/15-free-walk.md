# 15. Andar livre por cima da grade

- **Status:** concluída (falta o dono andar com F5)
- **Depende de:** [14-tap-to-walk](14-tap-to-walk.md)

## Contexto

Em 2026-11-13, o dono disse que o mapa em hexágonos estava limitando: "não tem uma reta para cima e nem para baixo". Com os hexágonos de ponta para cima, o Domador só anda para os lados e nas diagonais, e uma trilha para cima vira zigue-zague, parando no centro de cada hexágono.

Claude mostrou que a imagem de referência do dono também é feita de hexágonos, e propôs manter a grade como regra do jogo e soltar o que se vê. Para o andar, deu duas opções: livre só na tela, com o hexágono por baixo, ou livre de verdade, com a posição em pixels no servidor. O dono escolheu "Livre por fora", e depois: "Pode ficar parado no ponto em que toquei".

## Escopo

- O Domador anda em linha reta até o ponto tocado, desviando dos bloqueados, sem parar no centro dos hexágonos.
- Ele para no ponto tocado, não no centro do hexágono.
- O caminho no chão vira uma linha pontilhada contínua.

## Fora do escopo

- O servidor: a posição dele continua sendo um hexágono.
- Encontros, construções e Domadores NPC: continuam por hexágono.
- A camada de arte livre (decoração solta, casas com quintal, trilhas contínuas), que fica para outra fase.
- Regras de altura e custo por terreno.

## Requisitos

- **RF-01:** A posição do Domador é um ponto da arte, sem a altura (o "chão plano" do `HexMapView.flat_center`). O hexágono dele é o hexágono desse ponto (`HexMapView.grid_coord`), e é ele que Procurar, o servidor, as ações e os Domadores NPC usam, como antes.
- **RF-02:** Tocar num hexágono livre leva o Domador até o ponto tocado, incluindo o próprio hexágono dele. Tocar no paredão de um hexágono leva ao centro dele. Tocar num bloqueado continua levando ao hexágono livre mais perto ao lado dele ([14](14-tap-to-walk.md), RF-02 e RF-03), agora até o centro desse hexágono.
- **RF-03:** O caminho sai do caminho de hexágonos da [14](14-tap-to-walk.md) (`path_to_any`), passando pelo centro de cada um, e depois é esticado: de cada ponto, ele pula para o ponto mais adiante que dá para alcançar em linha reta sem passar por um hexágono bloqueado nem fora do mapa (`WalkRoute.points`). Em campo aberto, é uma reta só.
- **RF-04:** O Domador anda com velocidade constante, de `WALK_SPEED` (160) pixels da arte por segundo, medida com a altura da grade esticada para a de um hexágono regular (`WalkRoute.Y_STRETCH`, 55,4 / 42), para andar para cima não parecer mais lento que para o lado. Assim, ele leva pelo menos 0,34 s por hexágono em qualquer direção, acima dos 0,3 s que o servidor exige.
- **RF-05:** Ele olha para a direção em que anda, nas 5 vistas e no espelho (`WanderingSprite.face_toward`), com a mesma altura esticada. Parado, fica olhando para o último lado.
- **RF-06:** Ao cruzar a borda de um hexágono de outra altura, ele sobe ou desce até a altura nova em pouco tempo (`RISE_SPEED`, 160 pixels da arte por segundo), sem pular.
- **RF-07:** O plano do Domador ([11](11-depth-planes.md)) é o da linha do ponto um pouco abaixo dos pés dele (`FEET_DEPTH`, 6 pixels da arte), para a linha da frente não cobrir os pés.
- **RF-08:** Os Domadores NPC, a troca de destino e as ações continuam como na [14](14-tap-to-walk.md) (RF-03, RF-05 a RF-08 e RF-10): pisar no hexágono de um Domador NPC para ali, na borda; um toque durante a caminhada troca o destino na hora, a partir de onde ele está; a ação de chegada abre se o caminho termina nela, vindo de fora.
- **RF-09:** O caminho que falta aparece como pontos a cada `ROUTE_DOT_SPACING` (16) pixels da arte, cada um na altura do hexágono embaixo dele, com o anel no destino ([14](14-tap-to-walk.md), RF-11 e RF-12). Os pontos somem conforme ele passa.

## Critérios de aceite

- [x] Em campo aberto, o caminho para um ponto duas linhas acima é uma reta só.
- [x] O caminho contorna uma parede de objetos sem passar por nenhum hexágono bloqueado.
- [x] O Domador para no ponto tocado.
- [x] Uma caminhada leva pelo menos 0,3 s por hexágono de distância.
- [ ] O dono anda na Vila de Ventoverde com F5.

## Desenho técnico

**Criar**

- `client/screens/exploration/walk_route.gd` (`class_name WalkRoute`, só funções estáticas): `points(map, from, hexes, to)`, o caminho esticado; `length(points)`, `point_at(points, distance)` e `world(vector)`, que estica a altura.

**Alterar**

- `client/screens/exploration/exploration_screen.gd`: `_player_point` e `_shown_rise` ao lado do `_player_coord`; `_tap` guarda o ponto tocado; `_walk` anda pelo caminho quadro a quadro, mudando o hexágono quando o ponto cruza a borda; a câmera segue o ponto; `_show_route` e `_trim_route` pela distância.
- `client/screens/exploration/route_mark.gd`: o `order` passa a ser o número do ponto.
- `README.md` e `architecture.md` desta iniciativa e o `client/CLAUDE.md`.

## Verificação

- Um teste sem janela do `WalkRoute`: a reta em campo aberto, o desvio da parede sem tocar em bloqueado, o `point_at` e o tempo mínimo por hexágono numa reta para cima.
- O jogo de verdade, numa cena temporária contra o servidor local, com toques simulados e prints.
- O jogo sem janela abre sem erros de script.

O servidor confere a distância em hexágonos desde a última posição conferida, não cada borda: duas bordas cruzadas perto de um canto podem ficar a menos de 0,3 s uma da outra, e isso não importa. Só um passo curtíssimo por cima de uma borda, seguido de Procurar na mesma hora, chegaria perto do limite, e o toque em Procurar já leva mais que isso. Decisão de Claude.

## Tarefas

- [x] Spec.
- [x] O `WalkRoute` com o teste.
- [x] O andar na tela, a rota pontilhada e a direção.
- [x] Conferir no jogo, com prints.
- [ ] O dono andar com F5.

## Resultado da verificação

Em 2026-11-13:

- **Teste sem janela do `WalkRoute`:** falhou antes (a classe não existia) e passou depois, com 0 falhas: o centro volta ao hexágono, a reta para cima em campo aberto tem 2 pontos, o desvio de uma parede de 17 hexágonos tem 4 pontos e não passa por nenhum bloqueado (conferido a cada pixel), o `point_at` acerta o começo, o meio e o fim, e uma reta de 4 hexágonos para baixo leva 0,346 s por hexágono.
- **No jogo, contra o servidor local** (uma cena temporária, já apagada, com o toque chamado direto): numa ilha aberta, o Domador andou em reta duas linhas para cima, com a linha pontilhada reta até o anel, e parou no ponto exato. Na Vila de Ventoverde, ele contornou uma barraca até um hexágono a 3 de distância e parou no ponto exato; as caminhadas levaram 0,47 s e 0,53 s por hexágono.
- **Projeto:** o jogo sem janela, com o depurador, abre sem erros de script, com os mesmos 9 avisos de antes.
- **Falta o dono:** andar com F5, numa ilha e no mapa sorteado.
