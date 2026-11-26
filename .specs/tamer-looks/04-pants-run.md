# 04. As partes de baixo na corrida e a edição à mão

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [03](03-shoes.md)

## Contexto

O dono pediu para corrigir as animações da Calça e perguntou onde elas ficam, porque quer poder editá-las.

O defeito: na corrida, o template desenha a luz da coxa e do joelho com os mesmos pixels claros do pé, e a Calça deixava todo pixel claro da altura das pernas com a cor da pele, abrindo buracos nas pernas. A perna de trás, que a corrida desenha cheia na cor do contorno, ficava preta. E a largura do quadril era medida pela linha inteira: nos quadros em que a mão ou o braço descem até o quadril (a diagonal de cima parada e vários da corrida), a cueca do corpo e todas as partes de baixo pintavam a mão; o dono apontou na folha do corpo sem calça.

## Escopo

- A Calça certa parada e correndo, no adulto e na criança. A Calça capri e a Calça boca de sino, feitas da Calça, também.
- O quadril sem a mão na cueca do corpo e em todas as partes de baixo.
- A lista `HAND_DRAWN` do `make_wardrobe.gd`, com a Calça: as peças que o dono edita à mão.

## Fora do escopo

- As outras peças de roupa na corrida.

## Requisitos

- **RF-01:** A mão (`_hand`) são os pixels claros da altura das pernas ligados ao braço por pixels claros, com no máximo 4 deles na altura das pernas. O pé descalço (`_feet`) é o pixel claro sem nada da perna embaixo (a sola) e o claro logo acima dele.
- **RF-02:** A largura das pernas (`_leg_span`) se mede na linha do quadril: dos trechos de pixels sem contorno dela, só contam os que continuam para baixo, nas pernas, mais o contorno dos lados; a mão e o braço são trechos separados por contorno e ficam de fora. A cueca do corpo, a Calça, a Bermuda e as saias usam essa largura, e a cueca e a Bermuda também deixam a mão de fora. A Calça cobre a linha do quadril, nessa largura, e tudo da altura das pernas para baixo, menos o pé descalço e a mão. A perna de trás desenhada cheia na cor do contorno (`_far_leg`: o contorno de dentro da figura num bloco com 3 pixels seguidos numa linha) fica no tom mais escuro da Calça; o vão de 2 pixels entre as pernas, de frente, continua contorno.
- **RF-03:** O `make_wardrobe.gd` não grava as peças da lista `HAND_DRAWN`, para não apagar a edição à mão; tirar a peça da lista volta a gerá-la por código. (A [fase 05](05-wardrobe-editor.md) trocou a lista pelo `assets/tamer/hand_drawn.json`.) A Calça capri e a Calça boca de sino continuam geradas pelo código da Calça e não seguem a edição à mão.
- **RF-04:** As outras peças saem iguais.

## Critérios de aceite

- [x] Na corrida, as pernas ficam cobertas e a perna de trás sai no tom escuro da Calça.
- [x] Rodar o `make_wardrobe.gd` não muda `parts/pants/`.
- [x] A cueca do corpo e as partes de baixo não pintam a mão, parado e correndo.
- [ ] No jogo, o Domador de Calça corre sem buracos nas pernas.

## Desenho técnico

- `client/assets/tamer/make_wardrobe.gd`: `Frame.cache`, `_hand`, `_feet`, `_leg_span`, `_in_legs`, `_far_leg`, `_pants_keeps`, a cueca em `_body`, `_shorts_keeps`, `_skirt_layer` e `HAND_DRAWN`.

## Verificação

```bash
cd client && godot --headless -s res://assets/tamer/make_wardrobe.gd
```

E a prévia ampliada da Calça parada e correndo.
