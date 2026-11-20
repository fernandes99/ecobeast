# 31. Ícone, efeito e som de seis Técnicas de Toxina, Sombra e Instinto

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [30](30-flora-earth-ice-toxin-skills.md) (o mesmo caminho) e [28](28-skill-projectiles.md) (a regra do projétil)

## Contexto

Em 2026-11-20, Claude listou as Técnicas do catálogo sem ícone: 14 de 88. O dono mandou a imagem com os ícones das 6 primeiras, em 3 colunas e 2 linhas, nesta ordem: Poça Tóxica, Pena Sombria, Olhar da Lua, Voo Silencioso, Eclipse Lunar e Bote. Ele pediu: "Faça desses 6". A Poça Tóxica veio da [field-effects](../field-effects/), as quatro de Sombra da [lume-line](../lume-line/) e o Bote da [snekit-line](../snekit-line/).

## Escopo

- Os 6 ícones, os 6 efeitos e os 6 sons, e o projétil da Pena Sombria.

## Fora do escopo

- As 8 Técnicas que continuam sem ícone: Presa Venenosa, Constrição, Cuspe Ácido, Golpe de Foice, Emboscada, Dança da Foice, Raio de Sol e Lâmina Solar.
- Projétil nas outras 5, pela regra da [28](28-skill-projectiles.md):
  - a Poça Tóxica cobre a fileira e deixa marca;
  - o Olhar da Lua é um olhar, uma Técnica de estado;
  - o Voo Silencioso é de suporte em si mesmo;
  - o Eclipse Lunar acontece na fileira inteira, sem nada voando;
  - o Bote é de contato.
- O desenho das marcas no tabuleiro.
- Mudar os dados das Técnicas no catálogo.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, com 256 × 256, recortados de `art-source/skills/sombra_toxina_instinto_icons.jpg` pelo `cut_icons.gd`, sem retoque.
- **RF-02:** O efeito de cada Técnica foi escolhido por Claude pela forma e pelo ícone, numa comparação de 25 candidatos do kit na cor do Elemento (_a revisar_). A cor vem da linha do Elemento ([18](18-element-skill-effects.md)): a 2ª para Toxina, a 9ª para Sombra e a 5ª para Instinto.

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Poça Tóxica | fileira | 10/466 | anéis que se abrem rente ao chão, a mesma da Poça d'Água, em roxo |
  | Pena Sombria | inimigo, linha | 5/222 | o corte de pena da Pena Afiada, em roxo-escuro |
  | Olhar da Lua | inimigo, linha | 10/475 | um ponto que vira um anel e se abre, como o anel do ícone |
  | Voo Silencioso | si mesmo | 12/567 | o redemoinho da Dança do Vento, em roxo-escuro |
  | Eclipse Lunar | inimigo, linha | 2/79 | uma esfera escura que cresce e se desfaz |
  | Bote | inimigo | 11/509 | a mordida, as presas fechando |

- **RF-03:** A Pena Sombria tem projétil, porque "dispara uma pena": o risco da 579, na linha da Sombra (`pena_sombria_projectile.png`).
- **RF-04:** O som de cada Técnica é feito por síntese no `element_skills.py`, sem gravação de terceiros (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Poça Tóxica | 0,75 s | o veneno grosso derramando, bolhas pesadas estourando e um chiado ácido |
  | Pena Sombria | 0,5 s | um "fiu" mais grave que o da Pena Afiada, um zumbido sombrio junto e o tique ao cravar |
  | Olhar da Lua | 0,7 s | notas de vidro que se acendem, um tom trêmulo e estranho e um anel que se abre |
  | Voo Silencioso | 0,7 s | duas batidas de asa abafadas e notas escuras que sobem |
  | Eclipse Lunar | 0,8 s | a luz puxada para dentro, um zumbido grave que desafina e um baque fundo |
  | Bote | 0,45 s | um chiado curto de cobra, o avanço num sopro e as presas fechando num estalo |

## Critérios de aceite

- [x] As 6 Técnicas têm ícone, efeito e som, e a Pena Sombria tem o projétil.
- [x] O Godot importa os 19 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as 6 numa luta.

## Desenho técnico

**Criar:**
- `art-source/skills/sombra_toxina_instinto_icons.jpg` (a imagem do dono).
- Os 6 ícones, efeitos e sons e o projétil, com os `.import`.

**Alterar:**
- No `cut_effects.gd`, seis linhas do `EFFECTS` e uma do `PROJECTILES`.
- No `element_skills.py`, as seis funções e a tabela `SOUNDS`.

Nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- sombra_toxina_instinto_icons.jpg poca_toxica pena_sombria olhar_da_lua voo_silencioso eclipse_lunar bote
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" poca_toxica pena_sombria olhar_da_lua voo_silencioso eclipse_lunar bote
python -I art-source/sounds/element_skills.py poca_toxica pena_sombria olhar_da_lua voo_silencioso eclipse_lunar bote
godot --headless --path client --import
```

## Resultado da verificação

Em 2026-11-20, sem janela:

- **Arquivos:**
  - Os 6 ícones têm 256 × 256, os 6 efeitos têm de 9 a 13 quadros, e o projétil tem 14.
  - Os 6 sons têm a duração da tabela e pico de 0,7. O volume médio (RMS) fica entre 0,16 e 0,25, na faixa dos de antes.
  - Uma imagem com cada ícone ao lado de 8 quadros do efeito foi mandada ao dono.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** ouvir os sons, que não foram ouvidos aqui.
