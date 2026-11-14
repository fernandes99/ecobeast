# 02. As peças soltas no jogo

- **Status:** concluída (o dono vê depois da fase 3)
- **Depende de:** [01](01-prop-records.md) e [wild-battle/15](../wild-battle/15-free-walk.md)

## Contexto

Desde a [01](01-prop-records.md), Explorar numa ilha devolve as peças soltas (`map.props`), mas o jogo não as desenha. Hoje cada linha de hexágonos tem duas camadas de decoração, a de trás e a da frente, e o Domador fica sempre entre elas ([wild-battle/11](../wild-battle/11-depth-planes.md)). Desde a [wild-battle/15](../wild-battle/15-free-walk.md), ele fica em qualquer ponto do hexágono, e uma flor 10 pixels à frente dele pode aparecer atrás.

## Escopo

- Ler e desenhar as peças soltas, com o vento nas plantas.
- O plano das decorações e das peças em faixas, com o Domador entre elas pela altura do pé.
- As ilhas sem decorações sorteadas, no jogo e no editor.
- A arte das 4 decorações de rua como peça.

## Fora do escopo

- Pôr, mover e apagar peças no editor (fase 3).
- O mapa sorteado: continua com as decorações sorteadas, sem peças.

## Requisitos

- **RF-01:** O `ExplorationMap` lê `props` (`MapProp`: `prop_type_id`, `coord`, `offset`, `variant`, `mirrored`).
- **RF-02:** O pé de uma peça é `HexMapView.flat_center(coord) + offset`, levantado pela altura do hexágono dela. A arte:
  - os 17 tipos das plantas e pedras do terreno são a célula `variant` (de 1 a 4) da linha do tipo na folha `decorations.png`, com o pé no `HexDecorations.CELL_BASE` e o vento do `KIND_SWAY`, como as decorações sorteadas;
  - os outros são `assets/props/<slug>/<variant>.png`, com o pé no meio da borda de baixo da imagem, sem vento.

  Espelhada, a arte vira na horizontal. Um tipo sem arte não aparece, e o jogo segue.
- **RF-03:** Cada linha de hexágonos tem 4 faixas de decoração (`HexMapView.DEPTH_BANDS`), em vez de 2, pela distância do pé ao centro do hexágono, de cima para baixo (`dy` de −29 a 29, cada faixa com 14,5 pixels da arte). As decorações sorteadas, as da Vegetação e as peças entram na faixa do pé delas.
- **RF-04:** O Domador entra entre as faixas pela altura do pé dele (`HexMapView.set_actor_depth`): na linha dos pés ([wild-battle/15](../wild-battle/15-free-walk.md), RF-07), na divisa de faixas mais perto do pé. Os Ecobeasts e os Domadores NPC continuam no meio da linha (entre a faixa 2 e a 3), como antes.
- **RF-05:** Numa ilha, as decorações sorteadas não aparecem (`HexMapView.random_decorations`), no jogo e no editor. As da Vegetação continuam. O mapa sorteado continua igual.
- **RF-06:** A arte do Poste de luz, da Placa, do Canteiro e do Banco passa para `assets/props/<slug>/<variante>.png`, sem a borda vazia de baixo; o `make_town.gd` a gera lá. A arte deles em `assets/map_objects/` sai.

## Critérios de aceite

- [x] Uma peça aparece no ponto dela, na altura do hexágono, com a variante e o espelho certos.
- [x] Uma planta solta balança com o vento; o banco fica parado.
- [x] O Domador passa atrás de uma peça cujo pé está à frente do dele, e na frente de uma cujo pé está atrás, no mesmo hexágono.
- [x] Numa ilha não há decorações sorteadas; no mapa sorteado continuam.
- [ ] O dono vê as peças numa ilha (depois da fase 3, quando puder pô-las).

## Desenho técnico

**Criar:** `client/domain/models/map_prop.gd` (`class_name MapProp`); `client/assets/props/<slug>/<variante>.png` das 4 decorações de rua.

**Alterar:**

- `exploration_map.gd`: `props` e a leitura.
- `hex_map_view.gd`: as 4 faixas por linha no lugar de `_back_rows` e `_front_rows`; `set_props`; `random_decorations`; `set_actor_depth`; o desenho das peças.
- `exploration_screen.gd`: `random_decorations` numa ilha, `set_props` e o Domador por `set_actor_depth`.
- `tools/map_editor/`: `random_decorations` desligado.
- `assets/map_objects/make_town.gd`: as 4 decorações de rua para `assets/props/`.
- `client/CLAUDE.md` e o `architecture.md` da free-props.

## Verificação

- Um teste sem janela: o `ExplorationMap` lê as peças; a faixa de cada `dy`; o `HexMapView` monta as peças na faixa e na textura certas; numa ilha, nenhuma decoração sorteada; e a divisa do Domador pela altura do pé.
- Um print com janela de um mapa montado à mão, com peças dos dois tipos, espelhadas, em alturas diferentes, e o Domador entre elas.
- O jogo sem janela abre sem erros de script.

## Tarefas

- [x] Spec.
- [x] O `MapProp` e a leitura.
- [x] As faixas e o desenho das peças.
- [x] As ilhas sem decorações sorteadas e o Domador por faixa.
- [x] A arte das decorações de rua.
- [x] Testes, print e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste sem janela** (uma cena temporária, já apagada, contra o servidor novo numa porta à parte): falhou antes (sem o `MapProp` nem as faixas) e passou depois, com 0 falhas. O mapa leu as 2 peças com todos os campos; a faixa de cada `dy` de −29 a 29 deu `[0, 0, 1, 2, 2, 3, 3]`; numa ilha, as flores entraram na faixa 0 da folha das decorações e o banco na faixa 3 com a arte dele, sem nenhuma decoração sorteada, que continuaram com `random_decorations` ligado; e o Domador entrou entre a faixa 1 e a 2 com o pé 2 pixels acima do centro, e depois da 3 com o pé 26 abaixo.
- **Print com janela:** um mapa montado à mão, com um degrau de altura 3. Árvore, pinheiro, arbusto, pedra, flores e tufos da folha, e banco, poste, placa e canteiro com arte própria, alguns espelhados: cada um no ponto dele, o pinheiro e a pedra no alto do degrau, o Domador na frente do banco (pé atrás do dele) e atrás das flores amarelas (pé à frente).
- **Mapa sorteado:** a tela de exploração de verdade, contra o servidor local, com o Domador andando duas linhas para cima: as decorações sorteadas continuam, e os pinheiros da frente cobrem o Domador.
- **Projeto:** o jogo sem janela, com o depurador, abre sem erros de script e com os mesmos 9 avisos de antes. Na primeira tentativa, `DEPTH_BANDS / 2` dava 2 avisos novos de divisão inteira, trocados pela constante `MIDDLE_BAND`.
- **Falta o dono:** ver as peças numa ilha, quando a fase 3 deixar pô-las.
