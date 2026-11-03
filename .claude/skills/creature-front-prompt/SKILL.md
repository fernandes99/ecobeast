---
name: creature-front-prompt
description: Monta o prompt, em inglês, que o dono manda para outra IA gerar numa imagem só o front.png de todas as formas de uma linha evolutiva de Ecobeast, com fundo transparente. Use sempre que o usuário pedir prompt, input ou descrição para gerar imagem, arte, front ou ilustração de um Ecobeast novo ou das evoluções dele, mesmo que passe só os nomes e uma ideia solta.
---

# Prompt de imagem dos Ecobeasts

O dono passa as informações básicas de uma linha evolutiva, e esta skill devolve um prompt pronto para colar numa IA de imagem. Ela não gera imagem nem cria arquivos. Fale com o dono em pt-BR. O prompt sai em inglês, porque as IAs de imagem seguem melhor.

## O que o dono passa

- Os nomes de cada forma, em ordem.
- O conceito: o animal e a ideia que muda na evolução.
- Os Elementos de cada forma.
- Se quiser: cores, traços marcantes, altura e peso.

Se faltar algo, complete a partir do conceito e dos Elementos, e diga ao dono o que você completou. Só pergunte quando não houver nem os nomes nem o conceito.

## Requisitos da imagem

| Requisito         | Valor                                                                                                                                                                         |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `front.png` final | 512×512, PNG RGBA com fundo transparente, uma forma por arquivo, ocupando quase todo o quadro, como os de `client/assets/creatures/<slug>/front.png`                         |
| Imagem pedida     | Uma só, com 512 px de altura e 512 px de largura por forma (1536×512 para três), com as formas da esquerda para a direita, na ordem da evolução, cada uma no seu quadrado      |
| Fundo             | Transparente de verdade. Muitas IAs desenham um xadrez cinza no lugar, então o prompt proíbe o xadrez                                                                         |
| Pose e ângulo     | Não especifique: a IA escolhe. O dono pediu assim                                                                                                                             |
| Fora da imagem    | Texto, nomes, moldura, chão, sombra no chão e cenário                                                                                                                         |

Cada forma preenche o próprio quadrado, mesmo a menor, porque o jogo mostra cada `front.png` no mesmo espaço. O crescimento aparece nas proporções: o filhote tem cabeça e olhos grandes, e a forma final é mais robusta, com a cabeça menor em relação ao corpo.

## Estilo

Tirado dos `front.png` atuais. Antes de escrever, abra dois ou três deles com a ferramenta Read e confira se o bloco de estilo do modelo ainda descreve o que está lá:

- Ilustração de criatura no estilo anime, bem acabada, de jogo mobile.
- Contorno limpo e escuro, puxado para a cor de cada parte, sem preto puro.
- Sombreamento em cel shading com degradês suaves e textura fina: pelo, rachaduras, escamas.
- Cores vivas e saturadas, com aparência simpática. As formas finais podem ser mais imponentes.
- Corpo inteiro, sem cortes.

## Como montar

1. **Um fio que liga as formas.** Escolha a paleta e um traço que aparece nas três, para que se leiam como a mesma criatura crescendo.
2. **Uma linha por forma.** Diga o animal e o corpo, as cores, o traço marcante e o que mudou em relação à forma anterior. Mostre o Elemento no corpo: Terra é terra, argila, pedra e minério; Metal é placas, ferro e aço. Use cores concretas, como "warm brown" e "steel gray", e não os códigos de `elements.json`.
3. **Sem Pokémon.** Nunca escreva "Pokémon", "Pokémon-style" nem o nome de um jogo ou estúdio no prompt. Se o conceito lembrar uma criatura conhecida, ponha o visual dela em "Avoid", descrito sem o nome. Exemplo: uma toupeira de Terra/Metal não tem uma broca na cabeça.

## Saída

Uma linha em pt-BR com o que você completou. Depois, o prompt num bloco de código:

```
One image, [512 × número de formas]×512 pixels, with a fully transparent background (real alpha channel; no checkerboard, no color, no scenery). It shows the [N] forms of one creature's evolution line from left to right, in order. Each form sits centered in its own 512×512 square, fills most of it and does not touch the others.

Style: polished anime-style creature illustration for a mobile monster-taming game. Clean dark outlines tinted with each area's own color, never pure black. Soft cel shading with gentle gradients and fine texture ([texturas da linha]). Bright, saturated colors and an appealing look. Full body, nothing cropped. No text, no labels, no frame, no ground, no shadow under the creature.

All forms share [o fio que liga as formas], so they read as one creature growing up.

1. [Nome] ([Elementos]): [corpo, cores, traço marcante].
2. [Nome] ([Elementos]): [o que mudou, cores, traço marcante].
3. [Nome] ([Elementos]): [o que mudou, cores, traço marcante].

Avoid: [visuais a evitar], extra creatures, humans, background elements.
```

Depois do bloco, diga em pt-BR o que fazer com a imagem:

1. Cortar cada quadrado de 512×512 e salvar em `client/assets/creatures/<slug>/front.png`, com o `slug` em minúsculas.
2. Conferir que o fundo saiu transparente. Se a IA não fizer transparência, peça fundo branco liso e remova o fundo depois.
3. As folhas de andar e de parado saem da skill `creature-sprites`, a partir de cada `front.png`.
