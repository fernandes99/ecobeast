# 04. A Home com cara de jogo

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [03-tab-bar](03-tab-bar.md)

## Contexto

Em 2026-11-21, depois da fase 3, o dono pediu: "melhore essa tela do hub, deixe mais na cara de um jogo. Não fique preso pelo background de traz, se for preciso pode remover ele". A ilustração pintada do Hub não combina com o Domador e o Ecobeast em pixel art em cima dela, e os painéis lisos parecem de aplicativo.

## Escopo

- `client/screens/hub/` (`hub_screen.gd`, `hub_screen.tscn` e um `hub_island.gd` novo).
- `client/ui/components/hex_map_view.gd` (o `map_bounds`, público, para a ilhota caber).
- `client/ui/theme/palette.gd` (as cores do céu de cada parte do dia).

## Requisitos

**O palco**

- **RF-01:** A ilustração sai da Home. No lugar dela, o céu num degradê com as cores da parte do dia (Manhã, Tarde, Final de tarde e Noite, do `WorldClock`), que troca quando a parte do dia muda.
- **RF-02:** No meio do céu, uma ilhota flutuante de 7 hexágonos de Planície em degraus, desenhada pelo mesmo `HexMapView` do mapa de Explorar (o chão, os paredões, as plantas e o vento), no maior zoom inteiro, até 4, em que ela cabe inteira no palco (`HexMapView.map_bounds`), e com uma seed fixa, montada só no cliente: ela é enfeite, e o servidor não sabe dela. O hexágono do meio fica sem plantas (`bare`).
- **RF-03:** O Domador e o Ecobeast em destaque ficam de pé no hexágono do meio, na escala da ilhota, virados um para o outro, entrando entre as plantas pela altura do pé (`set_actor_depth`). Sem as folhas do mapa, o Ecobeast aparece pelo `front.png`, pequeno.
- **RF-04:** A etiqueta acima do Ecobeast continua (o nome, o nível e o HP) e abre o detalhe, como tocar nele.

**A interface**

- **RF-05:** Os textos grandes (o nome do Domador, o da etiqueta, o Explorar e o nome da aba escolhida) ganham o contorno escuro dos jogos.
- **RF-06:** O nível do Domador vira um selo redondo com o número, no canto de baixo do avatar, e a barra de XP fica mais grossa, embaixo do nome.
- **RF-07:** Tocar nas moedas abre a aba Loja.
- **RF-08:** O Explorar vira um botão de jogo: a borda de baixo grossa e mais escura, que encolhe ao apertar, e um pulo leve a cada poucos segundos, que para enquanto o dedo está nele. Desligado (sem equipe), fica cinza e parado.
- **RF-09:** Cada bolinha da equipe ganha embaixo o nível, em texto com contorno.

## Fora do escopo

- Nuvens, estrelas ou outra arte no céu.
- A luz da noite (`DayLightLayer`) na ilhota.
- Mudar as outras abas.

## Critérios de aceite

- [x] A Home não mostra mais a ilustração; o céu tem a cor da parte do dia.
- [x] A ilhota aparece inteira, com o Domador e o Ecobeast em cima, e as plantas não os cobrem pela frente de um jeito errado.
- [x] O Explorar pula de leve e afunda ao apertar.
- [x] As moedas abrem a Loja; o selo do nível e os selos das bolinhas aparecem.
- [x] O jogo sem janela abre sem erro de script.

## Verificação

```bash
godot --headless -d --path client --quit-after 240
```

Depois, no jogo, a Home de manhã e à noite (pela aba Hora do Debug do mapa).

## Tarefas

- [x] O céu e a ilhota.
- [x] O Domador e o Ecobeast na ilhota.
- [x] Os contornos, o selo do nível, as moedas, o Explorar e os selos das bolinhas.
- [x] Atualizar o `CLAUDE.md`, o `TELAS.md` e o README da iniciativa.
- [x] A verificação.
