# 38. Ícone, efeito e som de três Técnicas do Sandlurk e três do Hopling

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [37](37-trail-pincer-skills-art.md) (o mesmo caminho) e [28](28-skill-projectiles.md) (a regra do projétil)

## Contexto

Em 2026-11-21, depois da [37](37-trail-pincer-skills-art.md), o dono pediu o título e a descrição de "+6 técnicas que não temos imagens". Faltavam 11 Técnicas, dos ids 99 a 109. Claude mandou as 6 primeiras pelo id: as três que faltavam da [sandlurk-line](../sandlurk-line/) e três da [hopling-line](../hopling-line/). O dono mandou a imagem com os ícones em 3 colunas e 2 linhas, nesta ordem: Ferroada Paralisante, Enterrar, Bote da Duna, Erva da Bolsa, Atadura Firme e Cochilo.

## Escopo

- Os 6 ícones, os 6 efeitos e os 6 sons.

## Fora do escopo

- As 5 Técnicas que continuam sem ícone: Ninho de Ervas (Instinto) e as quatro de Luz da [glimshell-line](../glimshell-line/) (Lampejo, Casco Prismático, Halo Protetor e Raio Prismático).
- Projétil, pela regra da [28](28-skill-projectiles.md):
  - a Ferroada Paralisante e o Bote da Duna são de contato;
  - o Enterrar e o Cochilo são de suporte em si mesmo;
  - a Erva da Bolsa e a Atadura Firme são de suporte num aliado.
- As 3 "Técnica de teste" do catálogo (ids 119 a 121), sobras dos testes automáticos.
- Mudar os dados das Técnicas no catálogo.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, com 256 × 256, recortados de `art-source/skills/toxina_inseto_instinto_icons.jpg` pelo `cut_icons.gd`, sem retoque.
- **RF-02:** Claude escolheu o efeito de cada Técnica pela forma e pelo ícone, comparando 29 candidatos do kit na cor do Elemento (_a revisar_). A cor vem da linha do Elemento ([18](18-element-skill-effects.md)): a 2ª para Toxina, a 4ª para Inseto e a 5ª para Instinto.

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Ferroada Paralisante | inimigo, linha | 10/485 | a ferroada que estala e solta faíscas, em roxo |
  | Enterrar | si mesmo | 9/429 | torrões que sobem e formam um monte, em verde |
  | Bote da Duna | inimigo | 2/72 | o bote que se fecha num triângulo e se desfaz, em verde |
  | Erva da Bolsa | aliado | 4/194 | ramos de erva girando em volta, em marrom |
  | Atadura Firme | aliado | 1/16 | faixas que giram e se fecham em volta, em marrom |
  | Cochilo | si mesmo | 1/25 | uma nuvem de sono que incha e some, em marrom |

- **RF-03:** O som de cada Técnica é feito por síntese no `element_skills.py`, sem gravação de terceiros (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Ferroada Paralisante | 0,65 s | a cauda rangendo, o ferrão num estalo seco e o veneno estalando como choque |
  | Enterrar | 0,8 s | a areia escorrendo, a carapaça assentando num baque surdo e um tom grave que fica |
  | Bote da Duna | 0,7 s | areia mexendo de leve, a explosão de areia no salto e o golpe forte das pinças |
  | Erva da Bolsa | 0,85 s | a bolsa abrindo, um resmungo baixo e folhas girando com notas que sobem |
  | Atadura Firme | 0,75 s | o pano em voltas rápidas, o puxão do nó e um tom firme que fica |
  | Cochilo | 0,95 s | um bocejo que desce, a respiração lenta e notas de caixinha de música que caem |

## Critérios de aceite

- [x] As 6 Técnicas têm ícone, efeito e som.
- [x] O Godot importa os 18 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as 6 numa luta (pelo Testar técnica do F1).

## Desenho técnico

**Criar:**
- `art-source/skills/toxina_inseto_instinto_icons.jpg` (a imagem do dono).
- Os 6 ícones, efeitos e sons, com os `.import`.

**Alterar:**
- No `cut_effects.gd`, seis linhas do `EFFECTS`.
- No `element_skills.py`, as seis funções e a tabela `SOUNDS`.

Nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- toxina_inseto_instinto_icons.jpg ferroada_paralisante enterrar bote_da_duna erva_da_bolsa atadura_firme cochilo
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" ferroada_paralisante enterrar bote_da_duna erva_da_bolsa atadura_firme cochilo
python -I art-source/sounds/element_skills.py ferroada_paralisante enterrar bote_da_duna erva_da_bolsa atadura_firme cochilo
godot --headless --path client --import
```

## Resultado da verificação

Em 2026-11-21, sem janela:

- **Arquivos:**
  - Os 6 ícones têm 256 × 256, e os 6 efeitos têm de 10 a 14 quadros.
  - Os 6 sons têm a duração da tabela e pico de 0,7. O volume médio (RMS) fica entre 0,14 e 0,24, dentro da faixa dos de antes (0,07 a 0,38).
  - Uma imagem com cada ícone ao lado de 8 quadros do efeito foi mandada ao dono.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** ver os efeitos e ouvir os sons no jogo. Os sons não foram ouvidos aqui.
