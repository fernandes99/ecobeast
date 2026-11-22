# 05. Andar na ilhota, mais campo e as nuvens

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [04-game-look](04-game-look.md)

## Contexto

Em 2026-11-21, depois da fase 4, o dono pediu: "eu vou poder se mexer dentro desse campo, e pode deixar mais fields, e em volta coloca algumas nuvens ou uma vinheta ou gradiente não sei...". A ilhota da Home tinha 7 hexágonos parados, só de enfeite.

## Escopo

- `client/screens/hub/` (`hub_island.gd`, `hub_screen.gd`, `hub_screen.tscn` e um `hub_clouds.gd` novo).
- `client/ui/theme/palette.gd` (a cor das nuvens em cada parte do dia e a vinheta).
- `client/assets/ui/hub/` (as nuvens em pixel art e o `make_clouds.py` que as gera).

## Requisitos

**A ilha**

- **RF-01:** A ilhota cresce para 37 hexágonos de Planície e de Boreal, em 7 linhas, em patamares de altura 1 a 4, com um laguinho de água rasa que cai em cachoeira pela borda. Ela continua montada só no cliente, com seed fixa, e o servidor não sabe dela.
- **RF-02:** A ilha passa a ficar atrás da Home inteira, com a interface por cima, e o toque no palco é passado a ela (`HubIsland.handle_touch`). O zoom fica fixo no 3. A câmera põe o Domador no meio do palco, suave, sem mostrar além da borda da ilha onde ela é maior que a tela; onde é menor, a ilha fica centrada no meio do palco, com o céu em volta.

**Andar**

- **RF-03:** Tocar num hexágono da ilha anda o Domador pelo caminho mais curto até o centro dele (`ExplorationMap.path_to_any`, sem passar pela água nem por paredões de 3 níveis), na velocidade de Explorar, virado para onde anda e com a animação de correr. Tocar no meio da caminhada troca o destino. Tocar na água, fora da ilha ou num hexágono sem caminho não faz nada.
- **RF-04:** O Ecobeast em destaque segue o Domador, um hexágono atrás: vai para o hexágono que o Domador deixou, andando, e para virado para ele. Sem as folhas do mapa, ele aparece pelo `front.png` pequeno, que desliza sem animação.
- **RF-05:** Os dois entram entre as plantas pela altura do pé a cada passo (`follow_depth`). A etiqueta do Ecobeast vai junto com ele. Tocar no Ecobeast ou na etiqueta continua abrindo o detalhe.
- **RF-06:** O lugar dos dois não é gravado: ao voltar ao Hub, eles começam no meio da ilha.

**Em volta**

- **RF-07:** Nuvens em pixel art passam devagar pelo céu, atrás da ilha, em velocidades diferentes, e algumas na frente, embaixo do palco, cobrindo a ponta dos paredões. À noite, elas ficam escuras e azuladas. A arte sai do `assets/ui/hub/make_clouds.py`.
- **RF-08:** Uma vinheta escurece de leve as bordas da Home, por baixo da interface.

## Fora do escopo

- Ecobeasts selvagens, NPCs, construções ou ações na ilhota.
- A pinça para mudar o zoom na Home.
- A luz da noite (`DayLightLayer`) na ilhota.

## Critérios de aceite

- [x] Tocar num hexágono anda o Domador até ele, e o Ecobeast segue um hexágono atrás.
- [x] A câmera acompanha sem mostrar o vazio além da ilha.
- [x] As nuvens passam atrás e na frente, e a vinheta escurece as bordas.
- [ ] Tocar no Ecobeast abre o detalhe.
- [x] O jogo sem janela abre sem erro de script.

## Verificação

```bash
python client/assets/ui/hub/make_clouds.py
godot --headless -d --path client --quit-after 240
```

Depois, no jogo, andar pela ilha e trocar o Ecobeast em destaque.

## Tarefas

- [x] A ilha maior e a câmera que segue o Domador.
- [x] Andar por toque, com o Ecobeast seguindo.
- [x] As nuvens e a vinheta.
- [x] Atualizar o `CLAUDE.md`, o `TELAS.md` e o README da iniciativa.
- [x] A verificação.
