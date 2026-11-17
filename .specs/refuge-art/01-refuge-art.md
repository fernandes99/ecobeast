# 01. O Refúgio da imagem do dono

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [free-objects](../free-objects/) (os prédios como peças soltas), [day-night](../day-night/) (as luzes das peças) e [chimney-smoke](../chimney-smoke/) (o botão da fumaça)

## Contexto

O dono quer o Refúgio com a arte da imagem dele, no padrão das casas ([README](README.md#contexto)).

## Escopo

- O script `client/assets/props/make_refuge_building.py`, a imagem `art-source/refuge_building/reference.png` e a arte `assets/props/refuge_building/` (`1.png` a `8.png` e `smoke.png`).
- O `HexMapView.PROP_SMOKE`, com a fumaça do Refúgio.
- O tipo de peça 22 (variantes, bloqueio padrão e luzes), na migração `20270102000000_refuge_art` e na carga inicial.
- A saída do Refúgio do `make_town.gd` e do `find_lights.py`.

## Requisitos

- **RF-01:** `python -I make_refuge_building.py`, de dentro de `client/assets/props`, lê a cor de cada pixel da arte pela mediana dos 3×3 pixels do meio dele na imagem (a grade começa em (5,05; 3,6) e anda 5,12 pixels), apaga a fumaça desenhada acima da chaminé (colunas 50 a 76 e linhas 0 a 15 da grade), junta as cores a menos de 14 em cada canal, apaga o fundo branco, recorta pelos pixels (178×132) e grava `refuge_building/1.png` a `8.png` (180×134) e a `smoke.png`, copiada da Casa grande.
- **RF-02:** Cada cor ganha um material como na [Casinha enxaimel](../timber-cottage/01-timber-cottage.md#requisitos) (contorno, vidro, pedra, reboco, telha e madeira), mais o que fica com a cor da imagem: o verde e o rosa saturados, o amarelo claro e, por retângulos da grade, as floreiras, as lanternas e as plantas da estufa (todas as cores menos o contorno) e as duas placas da cruz (o vermelho). O vermelho solto fora do telhado e os escuros seguem as regras da Casinha enxaimel, e a madeira com 5 ou mais vizinhos de telha vira telha, para não ficar com a cor da madeira num telhado de outra cor.
- **RF-03:** Os tons de cada material viram os da Casa grande na proporção dela (`RAMPS`), e o contorno, o escuro do material da maioria em volta, como na Casinha enxaimel. A sombra translúcida da Casa grande (`(53, 53, 43, 89)`) fica 1 px do lado das paredes, nas linhas em que a borda não é telhado, e 2 px abaixo do pé de cada coluna.
- **RF-04:** As variantes são as 8 cores da Casa grande, pelos mesmos grupos (telhado, pedra e creme, que aqui é o reboco) e as mesmas regras do `make_houses.py`. A madeira, o vidro e o que fica com a cor da imagem não mudam.
- **RF-05:** O tipo de peça 22 tem 8 variantes. O bloqueio padrão (id 1, variante 0) é a linha fechada pelo pé do prédio em T: (−88, −50), (−58, −50), (−58, −13), (−34, −13), (−34, −3), (34, −3), (34, −44), (88, −44), (88, −86) e (−88, −86).
- **RF-06:** As luzes do tipo 22 (variante 0, todas as cores) são as 4 janelas das alas, em (−71, −63), (−47, −63), (47, −63) e (69, −63), com raio 9 e a cor `ffcf70` (ids 3 a 6), e as 2 lanternas da porta, em (−15, −27) e (14, −27), com raio 18 e a cor `ffd890` das lanternas do Observatório (ids 7 e 149).
- **RF-07:** A fumaça do Refúgio (`PROP_SMOKE["refuge_building"]`) tem o canto do quadro em (−57, −156) do pé, com a boca da chaminé no lugar da boca da Casa grande, e some com o `no_smoke` da peça, pelo botão da fumaça do F2.
- **RF-08:** O `make_town.gd` não desenha mais o Refúgio, e o `find_lights.py` não tem mais o tipo 22 (as luzes dele ficam à mão, como as da Casinha enxaimel, `LUZES.md`).

## Critérios de aceite

- [ ] A ferramenta Peças do editor mostra o Prédio do Refúgio com a arte nova, com as 8 cores pelas teclas ← →, espelhado ou não.
- [ ] A chaminé solta fumaça, e o botão da fumaça da barra da peça a tira.
- [ ] O Domador para no pé do prédio, na frente e nas alas, e passa atrás dele, coberto pelo telhado.
- [ ] À noite, as 4 janelas e as 2 lanternas acendem.
- [ ] Numa ilha com o Refúgio de antes, ele aparece com a arte nova, e a ação Refúgio continua abrindo a tela.
- [x] O teste das tabelas do catálogo passa, com o tipo 22 em 8 cores, 4 janelas e 2 lanternas.
- [x] `godot --headless -d --path client --quit-after 240` roda sem erro de script.
