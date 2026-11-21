# 02. A arte nova e a animação do altar

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-portal-altar](01-portal-altar.md) e a fumaça da [home-pack](../home-pack/01-big-house.md) (os quadros trocados no shader)

## Contexto

Em 2026-11-21, o dono pediu: "quero que melhore a pixel art dele, quero que tenha o mesmo padrão que a casa grande", e que a animação só viesse depois de aprovar a arte parada. Claude redesenhou o altar com a pedra da Casa grande, e o dono aprovou com "Aprovado, anima".

## Escopo

- O `client/assets/props/make_portal_altar.py`, que grava `portal_altar/1.png` e `2.png` (o quadro 0) e `1_frames.png` e `2_frames.png` (os 16 quadros lado a lado).
- O `HexMapView.PROP_FRAMES`, que troca a arte de uma peça pelos quadros dela no mapa.

## Requisitos

- **RF-01:** O tamanho continua 62×74, com o pé no meio da borda de baixo, e o bloqueio e as luzes da [fase 1](01-portal-altar.md) não mudam.
- **RF-02:** A pedra é a da Casa grande (`big_house/1.png`, do `#768996` ao `#464752`, mais o claro `#a2b0ba`), com a junta `#393a42` e o contorno `#28282e`. Cada bloco tem o seu tom, a borda de cima e a da esquerda um tom mais claras, a de baixo e a da direita um tom mais escuras, e o terço da direita mais escuro, pela luz de cima à esquerda:
  - a base redonda, com a lateral em duas fiadas de blocos desencontrados, a face de cima em lajes, o anel arcano gravado e o degrau da frente;
  - os pilares de blocos empilhados, com o capitel e o plinto, a runa de olho de mariposa e o musgo;
  - o arco de 9 aduelas, com a pedra-chave alta e o cristal lapidado cravado nela;
  - o pedestal com a bacia vista de cima e os tufos de musgo em volta da base.
- **RF-03:** A variante 1 tem o Veilmoth novo (21×16, as asas com os olhos-de-portal ciano, o corpo de pelo creme e as antenas), o portal em anéis (o aro e os arcos de dentro) e os brilhos em cruz. A variante 2 tem o aro tracejado e apagado, dois pares de arcos fracos e a bacia escura.
- **RF-04:** A animação tem 16 quadros a 10 por segundo (1,6 s):
  - **variante 1:** os arcos do portal giram (o aro e os de fora uma volta, os de dentro duas), as asas sobem e se fecham uma vez por ciclo, a mariposa flutua 1 px, os 7 brilhos piscam cada um no seu tempo, um brilho desce pelo cristal, e o anel da base e a bacia cintilam;
  - **variante 2:** o aro tracejado gira devagar, os arcos de dentro giram em sentidos contrários, e o cristal acende um pouco no meio do ciclo.
- **RF-05:** No mapa, `HexMapView.PROP_FRAMES` (`"portal_altar": 16 quadros, 10 por segundo`) troca a arte `<variante>.png` pela `<variante>_frames.png`, e o `plant_wind.gdshader` escolhe o quadro como faz com a fumaça (`CUSTOM1.x` 2), com cada peça num ponto do ciclo pelo ponto do pé. A espelhada anima espelhada. A miniatura do editor, o toque e a visão de cima continuam usando o quadro 0.

## Critérios de aceite

- [x] `python -I make_portal_altar.py` grava as 4 imagens, só com o alfa 0 e 255, além da sombra.
- [x] Uma cena temporária com janela mostra três altares (com a mariposa, vazio e espelhado) animando, cada um num ponto do ciclo.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script novo.
- [ ] No jogo, o dono vê o altar animado numa ilha, de dia e à noite.

## Verificação

```bash
cd client/assets/props && python -I make_portal_altar.py
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```
