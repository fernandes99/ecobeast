# 02. A parede bloqueia

- **Status:** concluída (falta o dono jogar numa ilha com cercas)
- **Depende de:** [01](01-wall-records.md)

## Contexto

Com a [01](01-wall-records.md), as paredes estão no mapa e desenhadas, mas o Domador as atravessa. Esta fase faz a parede bloquear, como no [architecture.md](architecture.md#o-bloqueio-fase-2). Tudo é no cliente: o servidor continua conferindo só o tempo do andar.

## Escopo

- O índice das paredes no `ExplorationMap` e a pergunta `crosses_wall`.
- A rota em reta, a busca de caminho (do Domador e dos NPC que passeiam) e o toque num hexágono com uma parede passando pelo centro.
- Os Ecobeasts e os Domadores NPC que vagam dentro do hexágono.

## Fora do escopo

- O servidor, o nascimento dos Ecobeasts, Procurar e o desafio do Domador NPC.
- A ferramenta Cerca ([03](03-fence-tool.md)).

## Requisitos

- **RF-01:** `ExplorationMap.walls` é uma propriedade: trocar a lista refaz o índice (os trechos de parede por hexágono, com uma folga de `WALL_REACH` + 1 px em volta de cada trecho).
- **RF-02:** `ExplorationMap.crosses_wall(from: Vector2, to: Vector2) -> bool` diz se o segmento passa a menos de `WALL_REACH` (3 px da arte, no chão plano) de algum trecho de parede. Sem paredes, devolve `false` sem procurar.
- **RF-03:** `ExplorationMap.clip_to_walls(from: Vector2, to: Vector2) -> Vector2` devolve o ponto mais longe de `from`, na reta até `to`, que se alcança sem cruzar parede (`to` quando a reta é livre).
- **RF-04:** `path_to_any(from, goals, from_point := Vector2.INF)`:
  - não passa de um hexágono a um vizinho quando a reta entre os centros cruza uma parede;
  - com `from_point`, se a reta dele até o centro do próprio hexágono cruzar uma parede, a busca começa pelos vizinhos cujo centro ele alcança em reta.
- **RF-05:** `WalkRoute.points` monta a rota só com trechos livres:
  - o ponto do Domador;
  - o centro do próprio hexágono, quando alcançável;
  - os centros dos hexágonos do caminho, incluindo o último;
  - o ponto final, cortado pelo `clip_to_walls` a partir do último ponto da rota.
  - O esticar só pula para um ponto à frente quando a reta até ele é livre, sem parede (`is_clear` também pergunta `crosses_wall`).
- **RF-06:** tocar num hexágono livre cujo centro fica a menos de `WALL_REACH` de uma parede (`ExplorationMap.is_center_walled`) busca o caminho até os vizinhos livres dele que alcançam o ponto tocado em reta (`approach_goals`; sem nenhum, todos), e o Domador vai até o ponto tocado, parando rente à parede.
- **RF-07:** o toque, a ida até um NPC e a ida até um Domador NPC passam o ponto do Domador ao `path_to_any`.
- **RF-08:** um `WanderingSprite` com o mapa (`wander_in(coord, center, map)`) só escolhe pontos de onde está até lá sem cruzar parede, e começa num ponto longe de parede. Sem nenhum, fica parado. É só desenho.

## Critérios de aceite

- [x] Uma parede entre dois hexágonos fecha a passagem: a busca contorna, e um cercado fechado dá "sem caminho" para dentro.
- [x] Tocar do outro lado de uma cerca, sem volta por fora, leva o Domador até a cerca, rente a ela.
- [x] O Domador dentro de um hexágono cortado por uma cerca, do lado sem o centro, sai pelo vizinho alcançável.
- [x] Um Ecobeast que vaga num hexágono cortado por uma cerca não a atravessa.
- [x] Sem paredes, a rota e a busca dão o mesmo resultado de antes.

## Desenho técnico

- `domain/models/exploration_map.gd`: `walls` com setter, `_wall_cells`, `crosses_wall`, `clip_to_walls`, `is_center_walled` e o `path_to_any` novo. `WALL_REACH := 3.0`. O centro plano vem do `HexMapView.flat_center`, como o `IslandDraft` já usa o `HexMapView.grid_coord`.
- `screens/exploration/walk_route.gd`: a rota e o `is_clear`.
- `screens/exploration/exploration_screen.gd`: o toque, a ida até o NPC e até o Domador NPC, e o `_place_wanderer`.
- `ui/components/wandering_sprite.gd`: o mapa e o desvio do centro plano.

## Verificação

- Uma cena temporária sem janela, que falha antes e passa depois, com um mapa de 5×5 hexágonos e paredes:
  - `crosses_wall` (cruzando, rente, a 4 px, sem paredes);
  - `clip_to_walls`;
  - a busca contornando uma parede, o cercado fechado e a saída do lado sem centro;
  - a rota sem trecho que cruze parede;
  - o mesmo resultado de antes sem paredes;
  - o `WanderingSprite` sem cruzar.
- O jogo sem janela abre sem erros de script e sem avisos.

## Tarefas

- [x] O índice e as perguntas no `ExplorationMap`.
- [x] A busca e a rota.
- [x] O toque, o NPC e o Domador NPC na tela.
- [x] Quem vaga.
- [x] Testes e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste sem janela** (`zz_tmp_check/block_check`, apagado): 20 de 20. Ele falhou antes, sem o `crosses_wall`, o `clip_to_walls` e o `path_to_any` com o ponto. Confere:
  - o cruzamento (cruzando, rente, a 4 px, sem paredes) e o corte rente à parede;
  - a busca contornando, o cercado fechado e a saída do lado sem centro;
  - as rotas sem trecho que cruze parede, e a mesma reta de antes sem paredes;
  - quem vaga sem cruzar;
  - os casos da revisão (abaixo).
- **Revisão final** (um revisor novo, sobre as fases 2 e 3). Corrigido, com teste que falhou antes:
  - **Afastar-se de uma cerca:** quem estava a menos de 3 px de uma cerca não saía mais. Agora pode se afastar, e só aproximar-se ou cruzar conta.
  - **O lado certo ao tocar:** tocar num hexágono com a cerca pelo centro escolhia qualquer vizinho. Agora escolhe os que alcançam o ponto em reta (`approach_goals`).
  - **Busca sem saída:** com objetivos vazios, a busca ainda rodava a ilha inteira. A busca sem saída numa ilha de 5.400 hexágonos leva 19 ms, porque só pergunta pela parede quando um dos dois hexágonos tem trecho no índice. O tempo de antes não foi medido: o teste não compilava sem a função nova.
  - **Quem vaga sem ter para onde ir** agora descansa, sem virar à toa.
- **Ficou anotado, sem mudar:**
  - **Voltar pelo próprio hexágono:** a busca que começa do lado de uma cerca sem o centro não volta pelo centro do próprio hexágono, e um caminho que precisaria disso dá "sem caminho".
  - **Ações e conversa através da cerca:** a ação de um hexágono bloqueado e a conversa com um NPC a 1 hexágono ainda passam através de uma cerca.
  - **A chegada da ilha:** o editor não avisa quando uma cerca passa rente a ela.
- **Projeto:** o jogo sem janela abre sem erros de script e sem avisos.
- **Não conferido:** jogar numa ilha publicada com cercas.
