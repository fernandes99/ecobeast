# 32. Ícone, efeito e som de seis Técnicas de Toxina, Instinto e Inseto

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [31](31-shadow-toxin-instinct-skills.md) (o mesmo caminho) e [28](28-skill-projectiles.md) (a regra do projétil)

## Contexto

Em 2026-11-20, logo depois da [31](31-shadow-toxin-instinct-skills.md), o dono mandou a imagem com os ícones das próximas 6 Técnicas sem ícone. Elas estão em 3 colunas e 2 linhas, nesta ordem: Presa Venenosa, Constrição, Cuspe Ácido, Golpe de Foice, Emboscada e Dança da Foice. As três primeiras vieram da [snekit-line](../snekit-line/), e as outras da [prayling-line](../prayling-line/). O pedido foi: "faça desses 6 agora".

## Escopo

- Os 6 ícones, os 6 efeitos e os 6 sons, e o projétil do Cuspe Ácido.

## Fora do escopo

- O Raio de Sol e a Lâmina Solar, as duas últimas Técnicas sem ícone.
- Projétil nas outras 5, pela regra da [28](28-skill-projectiles.md):
  - a Presa Venenosa, a Constrição, o Golpe de Foice e a Emboscada são de contato;
  - a Dança da Foice é de suporte em si mesmo.
- O Elemento Inseto usa a linha verde do kit, a mesma da Flora (`"bug": 4` no `ELEMENT_ROWS`), sem tinta própria.
- Mudar os dados das Técnicas no catálogo.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, com 256 × 256, recortados de `art-source/skills/toxina_instinto_inseto_icons.jpg` pelo `cut_icons.gd`, sem retoque.
- **RF-02:** O efeito de cada Técnica foi escolhido por Claude pela forma e pelo ícone, numa comparação de 23 candidatos do kit na cor do Elemento (_a revisar_). A cor vem da linha do Elemento ([18](18-element-skill-effects.md)): a 2ª para Toxina, a 5ª para Instinto e a 4ª para Inseto.

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Presa Venenosa | inimigo | 2/64 | duas presas que cravam, em roxo |
  | Constrição | inimigo | 3/134 | uma corda que se enrola, a mesma do Laço de Raízes, em marrom |
  | Cuspe Ácido | inimigo, linha | 12/577 | o respingo que se espalha, em roxo |
  | Golpe de Foice | inimigo | 12/589 | um corte em meia-lua, em verde |
  | Emboscada | inimigo | 13/622 | uma foice que se fecha, em verde |
  | Dança da Foice | si mesmo | 12/586 | um anel que cresce e solta espinhos, em verde |

- **RF-03:** O Cuspe Ácido tem projétil, porque "cospe ácido no primeiro da linha": o risco da 579, na linha da Toxina (`cuspe_acido_projectile.png`).
- **RF-04:** O som de cada Técnica é feito por síntese no `element_skills.py`, sem gravação de terceiros (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Presa Venenosa | 0,55 s | as presas cravando num estalo duplo e o veneno borbulhando e chiando |
  | Constrição | 0,75 s | as escamas deslizando ao se enrolar, um rangido que aperta e um estalo |
  | Cuspe Ácido | 0,6 s | um chiado de cobra, o cuspe num sopro molhado e o ácido chiando no alvo |
  | Golpe de Foice | 0,5 s | um "shing" de lâmina, o corte que desce e o impacto com estilhaços |
  | Emboscada | 0,6 s | folhas mexendo de leve, o bote num sopro e duas foices fechando |
  | Dança da Foice | 0,75 s | dois raspados metálicos, um tinido e notas que sobem |

## Critérios de aceite

- [x] As 6 Técnicas têm ícone, efeito e som, e o Cuspe Ácido tem o projétil.
- [x] O Godot importa os 19 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as 6 numa luta.

## Desenho técnico

**Criar:**
- `art-source/skills/toxina_instinto_inseto_icons.jpg` (a imagem do dono).
- Os 6 ícones, efeitos e sons e o projétil, com os `.import`.

**Alterar:**
- No `cut_effects.gd`, seis linhas do `EFFECTS` e uma do `PROJECTILES`.
- No `element_skills.py`, as seis funções e a tabela `SOUNDS`.

Nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- toxina_instinto_inseto_icons.jpg presa_venenosa constricao cuspe_acido golpe_de_foice emboscada danca_da_foice
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" presa_venenosa constricao cuspe_acido golpe_de_foice emboscada danca_da_foice
python -I art-source/sounds/element_skills.py presa_venenosa constricao cuspe_acido golpe_de_foice emboscada danca_da_foice
godot --headless --path client --import
```

## Resultado da verificação

Em 2026-11-20, sem janela:

- **Arquivos:**
  - Os 6 ícones têm 256 × 256, os 6 efeitos têm de 8 a 14 quadros, e o projétil tem 14.
  - Os 6 sons têm a duração da tabela e pico de 0,7. O volume médio (RMS) fica entre 0,16 e 0,22, na faixa dos de antes.
  - Uma imagem com cada ícone ao lado de 8 quadros do efeito foi mandada ao dono.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** ouvir os sons, que não foram ouvidos aqui.
