# 04. O toque passa pela peça sem ação

- **Status:** concluída (falta o dono jogar)
- **Depende de:** [02](02-variant-blocks.md) e [free-objects/03](../free-objects/03-prop-actions.md)

## Contexto

Em 2026-11-15, na ilha "Teste dos pacotes", o dono tocou na copa de uma árvore, e o Domador foi para a base dela. Ele pediu: "quando eu vou tocar em uma árvore, ele deve ir para a direção do toque em baixo da árvore".

A causa: desde a [free-objects/03](../free-objects/03-prop-actions.md), a arte de uma peça com bloqueio ou ação pega o toque e leva o Domador até o ponto da linha mais perto. Era para os prédios, que têm ação. Com a [02](02-variant-blocks.md), as árvores grandes passaram a ter bloqueio, e a copa passou a pegar o toque também.

## Requisitos

- **RF-01:** Só a arte de uma peça com ação pega o toque. A de uma peça só com bloqueio deixa o toque passar para o chão, como uma peça sem bloqueio: o Domador anda até o ponto tocado no chão plano e para rente ao bloqueio, se o ponto ficar atrás dele.

## Critérios de aceite

- [x] O jogo compila sem erros de script.
- [ ] Na ilha "Teste dos pacotes" (F5), tocar na copa de uma árvore anda até o chão atrás dela, e tocar num prédio com ação continua levando até ele.

## Desenho técnico

**Alterar:** `res://screens/exploration/exploration_screen.gd` (`_prop_hit`).

## Resultado da verificação

Em 2026-11-15, o jogo compila sem erros de script. Falta o dono jogar.
