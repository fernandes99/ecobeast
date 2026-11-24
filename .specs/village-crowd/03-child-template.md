# 03. A criança pelo template 16x16

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [02](02-children.md)

## Contexto

Em 2026-11-24, o dono perguntou se a criança usava o template de 16x16 do pacote da Eris Esra e, ao saber que não (ela era o template 16x32 do adulto sem 3 linhas do tronco), pediu para trocar. O 16x16 do pacote tem quadros de 24×24 e um boneco de 12×16 pixels, com a cabeça, o tronco e as pernas menores, no mesmo esquema de cores e nas mesmas 5 linhas, 4 quadros no Idle e 6 no Run.

## Escopo

- O `make_wardrobe.gd` gera os corpos Menino e Menina e as peças de `parts/<slug>/child/` a partir do template 16x16.

## Fora do escopo

- O catálogo, o servidor e as regras da criança da fase 2 não mudam.
- As folhas de adulto não mudam, pixel a pixel.

## Requisitos

- **RF-01:** As folhas `16x16 Idle-Sheet.png` e `16x16 Run-Sheet.png` do pacote ficam em `assets/tamer/template/child/idle.png` e `run.png`.
- **RF-02:** As folhas da criança continuam com quadros de 32×32: o quadro de 24×24 do template entra com 4 pixels de margem dos lados e 8 em cima, com os pés na base, como o adulto. Assim o `TamerSprite` e o `SheetSprite` não mudam.
- **RF-03:** Cada quadro guarda as medidas do próprio corpo: no 16x16, a cabeça vai até a linha 8 a partir do alto, o pescoço é a 9, o tronco vai de 10 a 13, a linha 14 é a do quadril e do alto das pernas e a 15 a dos pés. As alturas do cabelo, do chapéu e do capacete, contadas no adulto, encolhem na proporção da cabeça (9 linhas contra 11), e as que ficam no pé da cabeça contam a partir dela. Na criança, a manga tem 2 linhas, a saia sobe 1 linha e tem 2, para não cobrir os pés, e o cabelo Comprido, visto de trás na diagonal, começa na nuca.
- **RF-04:** A criança passa a ter 16 pixels de altura, contra os 25 do adulto.

## Critérios de aceite

- [x] As folhas de adulto saem iguais do `make_wardrobe.gd`.
- [x] As 17 peças vestem a criança nas 5 vistas sem sair do corpo nem cobrir o rosto.
- [ ] No F2, a Nina aparece bem menor que um adulto, de saia.

## Desenho técnico

- `client/assets/tamer/make_wardrobe.gd`: o template da criança, o quadro de 24×24 dentro do de 32×32 e as medidas por quadro (`head_end`, `neck`, `shoulders`, `sleeve`, `hips`, `legs`, `hair_end` e a escala das alturas do cabelo); sai o corte das 3 linhas.
- `client/assets/tamer/CREDITOS.md`, `.specs/tamer-appearance/architecture.md` e o `CLAUDE.md`.

## Verificação

```bash
cd client && godot --headless -s res://assets/tamer/make_wardrobe.gd
godot --headless --path client --editor --quit
```

E a prévia ampliada de cada peça na criança, nas 5 vistas.

## Tarefas

- [x] O template 16x16 e as medidas no `make_wardrobe.gd`.
- [x] As specs, os créditos e o `CLAUDE.md`.
