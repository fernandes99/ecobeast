# 37. Ícone, efeito e som de cinco Técnicas de rastro e da Pinça Firme

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [36](36-light-trail-skills-art.md) (o mesmo caminho), [28](28-skill-projectiles.md) (a regra do projétil) e [34](34-trail-skills.md) (as Técnicas de rastro)

## Contexto

Em 2026-11-21, depois da [36](36-light-trail-skills-art.md), o dono pediu "o titulo e descrição de +6 técnicas que faltam". Faltavam 9: as 5 de rastro do bloco 2 e as 4 do escorpião da [sandlurk-line](../sandlurk-line/) (ids 98 a 101). Claude mandou as 6 primeiras pelo id. O dono mandou a imagem com os ícones em 3 colunas e 2 linhas, nesta ordem: Cometa de Pólen, Bola de Lama, Estaca de Gelo, Dardo Gotejante, Pena Riscante e Pinça Firme. O pedido foi: "vamos agora fazer tudo dessas técnicas".

## Escopo

- Os 6 ícones, os 6 efeitos e os 6 sons, e o projétil das 5 que lançam algo.

## Fora do escopo

- As 3 Técnicas que continuam sem ícone, todas do Sandlurk: Ferroada Paralisante, Enterrar e Bote da Duna.
- O projétil da Pinça Firme, que é de contato ([28](28-skill-projectiles.md), RF-01).
- Mudar os dados das Técnicas no catálogo ou o desenho das marcas no chão ([35](35-ground-mark-effects.md)).

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, com 256 × 256, recortados de `art-source/skills/flora_terra_gelo_toxina_vento_inseto_icons.jpg` pelo `cut_icons.gd`, sem retoque.
- **RF-02:** Claude escolheu o efeito de cada Técnica pela forma e pelo ícone, comparando 28 candidatos do kit na cor do Elemento (_a revisar_). A cor vem da linha do Elemento ([18](18-element-skill-effects.md)): a 4ª para Flora e Inseto, a 6ª com a tinta para Terra e Vento, a 3ª para Gelo e a 2ª para Toxina.

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Cometa de Pólen | inimigo, linha | 4/186 | uma flor rendada que se abre e se desfaz, em verde |
  | Bola de Lama | inimigo, linha | 11/519 | bolotas que respingam e se espalham, em marrom |
  | Estaca de Gelo | inimigo, linha | 2/63 | o estilhaço que se espalha em cristais, em azul |
  | Dardo Gotejante | inimigo, linha | 9/428 | uma gota que escorre e borbulha, em roxo |
  | Pena Riscante | inimigo, linha | 1/24 | quatro penas girando em volta, em verde-água |
  | Pinça Firme | inimigo | 2/64 | duas pinças que se fecham, a mesma da Presa Venenosa, em verde |

- **RF-03:** As 5 de rastro têm projétil ([28](28-skill-projectiles.md)), na linha do Elemento. O Cometa de Pólen (o cometa) e a Bola de Lama (a bola) usam o bolo da 578. A Estaca de Gelo, o Dardo Gotejante e a Pena Riscante usam o risco da 579.
- **RF-04:** O som de cada Técnica é feito por síntese no `element_skills.py`, sem gravação de terceiros (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Cometa de Pólen | 0,8 s | um sopro macio que cintila, o pólen abrindo num "puf" e notas suaves que sobem |
  | Bola de Lama | 0,65 s | a bola saindo num sopro grosso, o "splosh" pesado e a lama respingando e borbulhando |
  | Estaca de Gelo | 0,65 s | o gelo estalando, a estaca num assobio frio e o impacto que estilhaça em cristais |
  | Dardo Gotejante | 0,6 s | o silvo do dardo, o espeto no alvo e o veneno pingando e chiando |
  | Pena Riscante | 0,6 s | o risco agudo que passa, um corte leve e penas soltas num sopro |
  | Pinça Firme | 0,7 s | as pinças abrindo num estalo, fechando num baque duplo e o aperto que range |

## Critérios de aceite

- [x] As 6 Técnicas têm ícone, efeito e som, e as 5 que lançam algo têm o projétil.
- [x] O Godot importa os 23 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as 6 numa luta (pelo Testar técnica do F1).

## Desenho técnico

**Criar:**
- `art-source/skills/flora_terra_gelo_toxina_vento_inseto_icons.jpg` (a imagem do dono).
- Os 6 ícones, efeitos e sons e os 5 projéteis, com os `.import`.

**Alterar:**
- No `cut_effects.gd`, seis linhas do `EFFECTS` e cinco do `PROJECTILES`.
- No `element_skills.py`, as seis funções e a tabela `SOUNDS`.

Nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- flora_terra_gelo_toxina_vento_inseto_icons.jpg cometa_de_polen bola_de_lama estaca_de_gelo dardo_gotejante pena_riscante pinca_firme
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" cometa_de_polen bola_de_lama estaca_de_gelo dardo_gotejante pena_riscante pinca_firme
python -I art-source/sounds/element_skills.py cometa_de_polen bola_de_lama estaca_de_gelo dardo_gotejante pena_riscante pinca_firme
godot --headless --path client --import
```

## Resultado da verificação

Em 2026-11-21, sem janela:

- **Arquivos:**
  - Os 6 ícones têm 256 × 256, e os 6 efeitos têm de 7 a 14 quadros. Os projéteis têm 11 quadros (a 578) e 14 (a 579).
  - Os 6 sons têm a duração da tabela e pico de 0,7. O volume médio (RMS) fica entre 0,12 e 0,26, dentro da faixa dos de antes (0,07 a 0,38).
  - Uma imagem com cada ícone ao lado de 8 quadros do efeito e 4 do projétil foi mandada ao dono.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** ver os efeitos e ouvir os sons no jogo. Os sons não foram ouvidos aqui.
