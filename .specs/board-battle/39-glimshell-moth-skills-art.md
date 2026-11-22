# 39. Ícone, efeito e som do Ninho de Ervas, de quatro Técnicas do Glimshell e do Pó Arcano

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [38](38-dune-support-skills-art.md) (o mesmo caminho) e [28](28-skill-projectiles.md) (a regra do projétil)

## Contexto

Em 2026-11-21, depois da [38](38-dune-support-skills-art.md), o dono pediu o título e a descrição das Técnicas que faltavam ícone, em lotes de 6. Faltavam 9 Técnicas, dos ids 105 a 113. Claude mandou:

- o lote 1, com Ninho de Ervas, Lampejo, Casco Prismático, Halo Protetor, Raio Prismático e Pó Arcano;
- o lote 2, com Olhar do Véu, Vórtice do Portal e Teleporte.

O dono mandou a imagem do lote 1, com os ícones em 3 colunas e 2 linhas, na mesma ordem. Ele pediu: "Crie dessas habilidades, use os efeitos dentro dos padrões", com o kit "Effect and FX Pixel All Free".

## Escopo

- Os 6 ícones, os 6 efeitos e os 6 sons.
- O projétil do Lampejo, do Raio Prismático e do Pó Arcano.

## Fora do escopo

- O lote 2: Olhar do Véu, Vórtice do Portal e Teleporte, que esperam a imagem do dono.
- As 3 "Técnica de teste" do catálogo (ids 119 a 121), sobras dos testes automáticos.
- Mudar os dados das Técnicas no catálogo, ou a marca do chão do Ninho de Ervas (a `ground_effect` 10, que já tem o desenho dela).

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, com 256 × 256. Eles são recortados de `art-source/skills/instinto_luz_arcano_icons.jpg` pelo `cut_icons.gd`, sem retoque.
- **RF-02:** Claude escolheu o efeito de cada Técnica pela forma e pelo ícone (_a revisar_). Ele comparou os 180 efeitos do kit e depois 14 candidatos na cor do Elemento. A cor vem da linha do Elemento ([18](18-element-skill-effects.md)): a 1ª para Luz, a 5ª para Instinto e a 9ª para Arcano.

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Ninho de Ervas | aliado, marca no chão | 4/184 | um anel de brotos que se abre em volta e se espalha, em marrom |
  | Lampejo | inimigo, a até 3 | 5/230 | um clarão curto em estrela que solta raios, em amarelo |
  | Casco Prismático | si mesmo | 13/623 | um quadrado de luz que gira até virar um losango, como um prisma, em amarelo |
  | Halo Protetor | aliado | 9/439 | uma auréola que fica sobre o alvo, em amarelo |
  | Raio Prismático | inimigo, a até 4 | 6/293 | um clarão que incha e estoura em raios, em amarelo |
  | Pó Arcano | inimigo, a até 3 | 7/336 | uma nuvem de pó que se espalha em pontos e some, em violeta |

- **RF-03:** Ganham projétil, pela regra da [28](28-skill-projectiles.md), as três Técnicas de dano que mandam algo de longe: o Lampejo (o brilho), o Raio Prismático (o raio) e o Pó Arcano (o pó). Todas usam a folha 12/579 na linha do Elemento delas. Não ganham projétil:
  - o Ninho de Ervas e o Halo Protetor, de suporte num aliado;
  - o Casco Prismático, de suporte em si mesmo.
- **RF-04:** O som de cada Técnica é feito por síntese no `element_skills.py`, sem gravação de terceiros (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Ninho de Ervas | 0,9 s | as ervas jogadas, as folhas assentando em farfalhos curtos e os brotos abrindo em notas que sobem |
  | Lampejo | 0,45 s | a pedra acendendo num tom curto, um zumbido rápido e um clarão que tilinta |
  | Casco Prismático | 0,95 s | o corpo se recolhendo num baque surdo, acordes de cristal que sobem e um brilho que vibra e fica |
  | Halo Protetor | 0,9 s | um sopro de luz que sobe, um acorde claro com vibrato e um sino suave que fica |
  | Raio Prismático | 0,95 s | a carga em três vozes, o raio num zumbido largo que ondula e o clarão com notas que descem |
  | Pó Arcano | 0,8 s | as asas em dois sopros, um chiado fino e um cintilar de notas fora da escala |

## Critérios de aceite

- [x] As 6 Técnicas têm ícone, efeito e som, e as três de longe têm o projétil.
- [x] O Godot importa os 21 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as 6 numa luta (pelo Testar técnica do F1).

## Desenho técnico

**Criar:**

- `art-source/skills/instinto_luz_arcano_icons.jpg` (a imagem do dono).
- Os 6 ícones, os 6 efeitos, os 3 projéteis e os 6 sons, com os `.import`.

**Alterar:**

- No `cut_effects.gd`, seis linhas do `EFFECTS` e três do `PROJECTILES`.
- No `element_skills.py`, as seis funções e a tabela `SOUNDS`.

Nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- instinto_luz_arcano_icons.jpg ninho_de_ervas lampejo casco_prismatico halo_protetor raio_prismatico po_arcano
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" ninho_de_ervas lampejo casco_prismatico halo_protetor raio_prismatico po_arcano
python -I art-source/sounds/element_skills.py ninho_de_ervas lampejo casco_prismatico halo_protetor raio_prismatico po_arcano
godot --headless --path client --import
```

## Resultado da verificação

Em 2026-11-21, sem janela:

- **Arquivos:**
  - Os 6 ícones têm 256 × 256.
  - Os 6 efeitos têm de 5 a 13 quadros. O Lampejo, com 5, é o clarão rápido que a descrição pede.
  - Os 3 projéteis têm 14 quadros.
  - Os 6 sons têm a duração da tabela e pico de 0,7. O volume médio (RMS) fica entre 0,16 e 0,23, dentro da faixa dos de antes (0,07 a 0,38).
  - Uma imagem com cada ícone, 8 quadros do efeito e o projétil foi mandada ao dono.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** ver os efeitos e ouvir os sons no jogo. Os sons não foram ouvidos aqui.
