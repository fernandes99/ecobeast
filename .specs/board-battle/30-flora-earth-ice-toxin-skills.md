# 30. Ícone, efeito e som de seis Técnicas de Flora, Terra, Gelo e Toxina

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [29](29-earth-volt-water-flora-skills.md) (o mesmo caminho)

## Contexto

Em 2026-11-20, logo depois da [29](29-earth-volt-water-flora-skills.md), o dono mandou a imagem com os ícones das próximas 6 Técnicas sem ícone. Elas estão em 3 colunas e 2 linhas, nesta ordem: Brotar, Semear Jardim, Lama Grudenta, Areia Movediça, Chão de Geada e Espinho Venenoso. Todas vieram da [field-effects](../field-effects/). O pedido foi: "crie agora dessas técnicas".

## Escopo

- Os 6 ícones, os 6 efeitos e os 6 sons.

## Fora do escopo

- A Poça Tóxica, a última Técnica sem ícone.
- Projéteis: nenhuma das 6 lança algo de longe, pela regra da [28](28-skill-projectiles.md).
  - O Brotar e o Semear Jardim são de suporte num aliado.
  - A Lama Grudenta, a Areia Movediça e o Chão de Geada cobrem a fileira e deixam marca.
  - O Espinho Venenoso é de contato.
- O desenho das marcas no tabuleiro.
- Mudar os dados das Técnicas no catálogo.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, com 256 × 256, recortados de `art-source/skills/flora_terra_gelo_toxina_icons.jpg` pelo `cut_icons.gd`, sem retoque.
- **RF-02:** O efeito de cada Técnica foi escolhido por Claude pela forma e pelo ícone (_a revisar_). A cor vem da linha do Elemento ([18](18-element-skill-effects.md)): a 4ª para Flora, a 6ª tingida de `#B07A43` para Terra, a 3ª para Gelo e a 2ª para Toxina.

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Brotar | aliado | 4/185 | cinco brotos que se abrem numa flor de contorno e somem |
  | Semear Jardim | aliado | 12/569 | uma moita que brota do chão, cresce e baixa |
  | Lama Grudenta | fileira | 12/577 | lama que espirra rente ao chão e se espalha em respingos |
  | Areia Movediça | fileira | 6/286 | um anel de areia que gira e afunda para o meio |
  | Chão de Geada | fileira | 8/398 | pontas de gelo que sobem do chão e se quebram |
  | Espinho Venenoso | inimigo | 8/378 | um espinho que sobe e espirra veneno |

- **RF-03:** O som de cada Técnica é feito por síntese no `element_skills.py`, sem gravação de terceiros (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Brotar | 0,75 s | um farfalhar macio de folhas e quatro notas claras que sobem, como brotos crescendo |
  | Semear Jardim | 0,85 s | sementes caindo em batidinhas, a terra se mexendo e um acorde claro que se abre |
  | Lama Grudenta | 0,8 s | a lama arremessada, o espalhar pesado no chão e bolhas grossas estourando |
  | Areia Movediça | 0,85 s | a areia escorrendo num chiado que gira e afunda, com grãos e a sucção grave no fim |
  | Chão de Geada | 0,75 s | estalinhos de gelo correndo, um chiado frio e notas de cristal |
  | Espinho Venenoso | 0,55 s | o espinho furando num estalo seco e o veneno borbulhando e chiando |

## Critérios de aceite

- [x] As 6 Técnicas têm ícone, efeito e som.
- [x] O Godot importa os 18 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as 6 numa luta.

## Desenho técnico

**Criar:**
- `art-source/skills/flora_terra_gelo_toxina_icons.jpg` (a imagem do dono).
- Os 6 ícones, efeitos e sons, com os `.import`.

**Alterar:**
- No `cut_effects.gd`, seis linhas do `EFFECTS`.
- No `element_skills.py`, as seis funções e a tabela `SOUNDS`.

Nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- flora_terra_gelo_toxina_icons.jpg brotar semear_jardim lama_grudenta areia_movedica chao_de_geada espinho_venenoso
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" brotar semear_jardim lama_grudenta areia_movedica chao_de_geada espinho_venenoso
python -I art-source/sounds/element_skills.py brotar semear_jardim lama_grudenta areia_movedica chao_de_geada espinho_venenoso
godot --headless --path client --import
```

## Resultado da verificação

Em 2026-11-20, sem janela:

- **Escolha dos efeitos:** foi feita por uma comparação, na cor do Elemento, de 14 candidatos do kit.
- **Arquivos:**
  - Os 6 ícones têm 256 × 256, e os 6 efeitos têm de 8 a 14 quadros.
  - Os 6 sons têm a duração da tabela e pico de 0,7. O volume médio (RMS) fica entre 0,17 e 0,25, na faixa dos de antes.
  - Uma imagem com cada ícone ao lado de 8 quadros do efeito foi mandada ao dono.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** ouvir os sons, que não foram ouvidos aqui.
