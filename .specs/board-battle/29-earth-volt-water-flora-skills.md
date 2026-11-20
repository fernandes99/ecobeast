# 29. Ícone, efeito e som de seis Técnicas de Terra, Volt, Água e Flora

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [27](27-flora-volt-skills.md) e [28](28-skill-projectiles.md) (o mesmo caminho)

## Contexto

Em 2026-11-20, Claude listou as Técnicas do catálogo sem ícone: 13 de 75. O dono mandou a imagem com os ícones das 6 primeiras, em 3 colunas e 2 linhas, nesta ordem: Desabamento, Abalo Profundo, Tempestade de Algas, Esguicho, Poça d'Água e Laço de Raízes. Ele pediu: "Crie tudo que falta dessas 6 técnicas. Lembre se de usar aquele pacote de vfx." O pacote é o "Effect and FX Pixel All Free", o mesmo da [18](18-element-skill-effects.md). O Esguicho, a Poça d'Água e o Laço de Raízes vieram da [field-effects](../field-effects/).

## Escopo

- Os 6 ícones, os 6 efeitos, o projétil do Esguicho e os 6 sons.

## Fora do escopo

- As outras 7 Técnicas sem ícone: Brotar, Semear Jardim, Lama Grudenta, Areia Movediça, Chão de Geada, Espinho Venenoso e Poça Tóxica.
- O desenho das marcas no tabuleiro (a Poça d'Água continua sendo o hexágono tingido).
- Mudar os dados das Técnicas no catálogo.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, com 256 × 256, recortados de `art-source/skills/terra_volt_agua_flora_icons.jpg` pelo `cut_icons.gd`, sem retoque.
- **RF-02:** Claude escolheu o efeito de cada Técnica pela forma e pelo ícone (_a revisar_). A cor vem da linha do Elemento ([18](18-element-skill-effects.md)): a 6ª linha tingida de `#B07A43` para Terra, a 1ª para Volt, a 3ª para Água e a 4ª para Flora.

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Desabamento | inimigo | 13/634 | um bloco que cai, se parte em pedaços e se espalha |
  | Abalo Profundo | inimigo | 2/70 | um monte de terra que sobe do chão e estoura em lascas |
  | Tempestade de Algas | fileira | 4/196 | um raio em pé, em zigue-zague, que pisca em cada hexágono |
  | Esguicho | inimigo | 11/517 | um jato de lado que respinga e se desfaz |
  | Poça d'Água | fileira | 10/466 | anéis de água que se abrem no chão |
  | Laço de Raízes | inimigo | 3/134 | um fio que ondula e se enrola num nó |

  Para o Abalo Profundo, Claude testou antes a 8/398 (pontas de rachadura no chão), mas na linha tingida ela ficou escura e fina demais.
- **RF-03:** O Esguicho (alcance 3, acerta o primeiro da linha, como a Faísca de Alga) ganha o projétil `esguicho_projectile.png`, o risco da `Part 12/579.png` em azul, pela regra da [28](28-skill-projectiles.md): ele esguicha água no alvo. As outras 5 não lançam nada. O Desabamento e o Abalo Profundo acontecem no alvo. A Tempestade de Algas e a Poça d'Água cobrem a fileira. O Laço de Raízes enrola o alvo.
- **RF-04:** O som de cada Técnica é feito por síntese no `element_skills.py`, sem gravação de terceiros (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Desabamento | 0,85 s | a pedra se soltando num estalo, um ronco que cai, as pedras batendo e o baque grande no fim |
  | Abalo Profundo | 0,9 s | um ronco grave que treme cada vez mais forte, o chão rachando e o baque que sacode tudo |
  | Tempestade de Algas | 0,95 s | a chuva chiando, o zumbido elétrico que cresce e o trovão que estala e ronca, com faíscas |
  | Esguicho | 0,5 s | um esguicho fino que chia e sobe de altura, e o respingo com gotas |
  | Poça d'Água | 0,75 s | a água caindo e se espalhando num chiado largo, e as gotas pingando na poça |
  | Laço de Raízes | 0,7 s | as raízes brotando num farfalhar de terra, rangendo enquanto se enrolam, e o aperto num estalo de madeira |

## Critérios de aceite

- [x] As 6 Técnicas têm ícone, efeito e som, e o Esguicho tem o projétil.
- [x] O Godot importa os 19 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as 6 numa luta.

## Desenho técnico

**Criar:**
- `art-source/skills/terra_volt_agua_flora_icons.jpg` (a imagem do dono).
- Os 6 ícones, os 6 efeitos, o projétil e os 6 sons, cada um com o `.import`.

**Alterar:**
- No `cut_effects.gd`, seis linhas do `EFFECTS` e uma do `PROJECTILES`.
- No `element_skills.py`, as seis funções e a tabela `SOUNDS`.

Nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- terra_volt_agua_flora_icons.jpg desabamento abalo_profundo tempestade_de_algas esguicho poca_d_agua laco_de_raizes
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" desabamento abalo_profundo tempestade_de_algas esguicho poca_d_agua laco_de_raizes
python -I art-source/sounds/element_skills.py desabamento abalo_profundo tempestade_de_algas esguicho poca_d_agua laco_de_raizes
godot --headless --path client --import
```

## Resultado da verificação

Verificado em 2026-11-20, sem janela:

- **Escolha dos efeitos:** Claude fez miniaturas das 180 folhas do kit e uma comparação na cor do Elemento dos candidatos de raio e de terra.
- **Arquivos:**
  - Os 6 ícones têm 256 × 256.
  - Os 6 efeitos têm de 9 a 15 quadros, e o projétil tem 14.
  - Os 6 sons têm a duração da tabela, com pico de 0,7. O volume médio (RMS) fica entre 0,16 e 0,26, na faixa dos sons de antes.
  - Claude montou uma imagem com cada ícone ao lado de 8 quadros do efeito.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:**
  - Os sons não foram ouvidos.
  - A Tempestade de Algas sai laranja e rosada, a cor que o kit dá ao Volt e que as outras Técnicas de Volt já usam. Para ela ficar amarela, todo o Volt teria de ser tingido pela cor dele, como o Vento e a Terra (`ELEMENT_TINTS`).
