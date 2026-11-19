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
| `front.png` final | 512×512, PNG RGBA com fundo transparente (o recorte tira o fundo), uma forma por arquivo, ocupando quase todo o quadro, como os de `client/assets/creatures/<slug>/front.png`                         |
| Imagem pedida     | Uma só, com 512 px de altura e 512 px de largura por forma (1536×512 para três), com as formas da esquerda para a direita, na ordem da evolução, cada uma no seu quadrado      |
| Fundo             | Verde puro e liso (`#00FF00`), sem degradê, sombra ou textura, e sem verde nas bordas da criatura. O Gemini e outras IAs não fazem transparência, e o `crop_line.py` tira um fundo liso. Se a criatura tiver verde-limão, troque por magenta `#FF00FF` |
| Pose e ângulo     | Não especifique: a IA escolhe. O dono pediu assim                                                                                                                             |
| Fora da imagem    | Texto, nomes, moldura, chão, sombra no chão e cenário                                                                                                                         |

Cada forma preenche o próprio quadrado, mesmo a menor, porque o jogo mostra cada `front.png` no mesmo espaço. O crescimento aparece nas proporções: o filhote tem cabeça e olhos grandes, e a forma final é mais robusta, com a cabeça menor em relação ao corpo.

## Estilo

Tirado dos `front.png` atuais. Antes de escrever, abra dois ou três deles com a ferramenta Read e confira se o bloco de estilo do modelo ainda descreve o que está lá:

- Pixel art detalhada de criatura de jogo mobile, com os pixels visíveis (cada um com uns 4 a 5 pixels da imagem) e as bordas duras, sem anti-serrilhado contra o fundo.
- Contorno de pixel escuro, puxado para a cor de cada parte, sem preto puro.
- Sombreamento em blocos de cor, com poucos tons por material e um dither leve, e textura fina: pelo, rachaduras, escamas.
- Brilhos, faíscas e pó são pixels sólidos e separados, sem halo nem brilho difuso, que não se recortam do fundo.
- Cores vivas e saturadas, com aparência simpática. As formas finais podem ser mais imponentes.
- Corpo inteiro, sem cortes.

## Como montar

1. **Um fio que liga as formas.** Escolha a paleta e um traço que aparece nas três, para que se leiam como a mesma criatura crescendo.
2. **Uma linha por forma.** Diga o animal e o corpo, as cores, o traço marcante e o que mudou em relação à forma anterior. Mostre o Elemento no corpo: Terra é terra, argila, pedra e minério; Metal é placas, ferro e aço. Use cores concretas, como "warm brown" e "steel gray", e não os códigos de `elements.json`.
3. **Sem Pokémon.** Nunca escreva "Pokémon", "Pokémon-style" nem o nome de um jogo ou estúdio no prompt. Se o conceito lembrar uma criatura conhecida, ponha o visual dela em "Avoid", descrito sem o nome. Exemplo: uma toupeira de Terra/Metal não tem uma broca na cabeça.

## Saída

Uma linha em pt-BR com o que você completou. Depois, o prompt num bloco de código:

```
One image, [512 × número de formas]×512 pixels, on a flat solid pure green background (#00FF00) that fills the whole image: one single color, no gradient, no texture, no vignette, no scenery, and no green glow or green pixels on the creatures' edges, so the background can be removed with a color key. It shows the [N] forms of one creature's evolution line from left to right, in order. Each form sits centered in its own 512×512 square, fills most of it and does not touch the others.

Style: detailed pixel art creature sprite for a mobile monster-taming game, like a high-resolution game sprite: clearly visible square pixels (each art pixel about 4 to 5 image pixels), crisp hard edges and no anti-aliasing against the background. A 1-pixel dark outline tinted with each area's own color, never pure black. Shading in flat blocks of color with a few tones per material and light dithering, with fine texture ([texturas da linha]). Bright, saturated colors and an appealing look. Glows, sparks and dust are solid separate pixels, with no soft halo or blur. Full body, nothing cropped. No text, no labels, no frame, no ground, no shadow under the creature.

All forms share [o fio que liga as formas], so they read as one creature growing up.

1. [Nome] ([Elementos]): [corpo, cores, traço marcante].
2. [Nome] ([Elementos]): [o que mudou, cores, traço marcante].
3. [Nome] ([Elementos]): [o que mudou, cores, traço marcante].

Avoid: [visuais a evitar], extra creatures, humans, background elements.
```

Depois do bloco, diga em pt-BR o que fazer com a imagem:

1. Salvar a imagem em `art-source/<slug da primeira forma>/line.png` e pedir a Claude para cortar. O `crop_line.py` da skill `creature-sprites` tira o fundo liso (a cor dos cantos), separa as formas e grava cada `client/assets/creatures/<slug>/front.png`.
2. Conferir que o fundo saiu liso. Com degradê ou sombra no fundo, gere de novo pedindo o verde puro.
3. As folhas de andar e de parado saem da skill `creature-sprites`, a partir de cada `front.png`.
