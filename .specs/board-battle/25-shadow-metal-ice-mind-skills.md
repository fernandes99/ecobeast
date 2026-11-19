# 25. Ícone, efeito e som de seis Técnicas de Sombra, Metal, Gelo e Psíquico

- **Status:** concluída (falta o dono ver e ouvir no editor)
- **Depende de:** [22](22-earth-ice-mind-skills.md) (o mesmo caminho)

## Contexto

Em 2026-11-14, Claude cruzou as Técnicas do catálogo com os arquivos do cliente e achou oito sem ícone, efeito e som: Garra do Eclipse (Sombra), Martelo de Ferro (Metal), Lança de Cristal (Gelo), Inverno Mudo (Gelo), Grito Congelado (Psíquico), Palavra Guardada (Psíquico), Desabamento (Terra) e Abalo Profundo (Terra). O dono mandou a imagem com os ícones das seis primeiras, em 3 colunas e 2 linhas, nessa ordem, e pediu que Claude criasse os sons e escolhesse os efeitos no kit.

## Escopo

- Os seis ícones, os seis efeitos e os seis sons.

## Fora do escopo

- Desabamento e Abalo Profundo, que ficam para quando o dono mandar os ícones.
- Mudar os dados das seis Técnicas no catálogo.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, recortados de `art-source/skills/sombra_metal_gelo_mente_icons.webp` pelo `cut_icons.gd`.
- **RF-02:** O efeito de cada Técnica, escolhido por Claude pela forma e pelo ícone, na linha do Elemento da [18](18-element-skill-effects.md) (_a revisar_). Todas têm alcance 1, então nenhuma tem projétil, e a Palavra Guardada toca o efeito sobre quem a usou.

  | Técnica | Elemento (linha) | Alvo | Folha | Forma |
  | --- | --- | --- | --- | --- |
  | Garra do Eclipse | Sombra (9ª, roxo) | inimigo | 3/123 | uma lua crescente que risca e se enrola até sumir |
  | Martelo de Ferro | Metal (6ª, cinza) | inimigo | 10/486 | uma pancada que estoura em lascas e faíscas |
  | Lança de Cristal | Gelo (3ª, azul-claro) | inimigo | 11/529 | um espinho de gelo que sobe do chão e se desfaz |
  | Inverno Mudo | Gelo (3ª, azul-claro) | inimigo | 13/615 | um floco de neve enorme que se abre e se parte |
  | Grito Congelado | Psíquico (2ª, rosa e roxo) | inimigo | 13/633 | uma caveira que cresce e se desfaz, o medo |
  | Palavra Guardada | Psíquico (2ª, rosa e roxo) | si mesmo | 14/655 | uma flor de lótus que se abre devagar |

- **RF-03:** O som de cada Técnica, por síntese, sem gravação de terceiros, no `element_skills.py` (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Garra do Eclipse | 0,6 s | a escuridão puxando o ar, um risco fundo de garra e um zumbido grave e desafinado que fica no ar |
  | Martelo de Ferro | 0,6 s | o punho cortando o ar, a pancada de ferro na bigorna, que ressoa, e faíscas estalando |
  | Lança de Cristal | 0,65 s | o cristal crescendo num brilho que sobe, a ponta furando o ar e a lança se desfazendo em cacos |
  | Inverno Mudo | 0,7 s | uma rajada gelada que cresce e se corta de repente, com um brilho fino e o gelo estalando no silêncio |
  | Grito Congelado | 0,75 s | um grito fantasma que desce e treme, preso num eco gelado |
  | Palavra Guardada | 0,75 s | um sussurro e um acorde calmo que se abre nota a nota, com um brilho no fim |

## Critérios de aceite

- [x] As seis Técnicas têm ícone, efeito e som.
- [x] O Godot carrega os 18 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as seis numa luta.

## Desenho técnico

**Criar:** `art-source/skills/sombra_metal_gelo_mente_icons.webp` (a imagem do dono), os seis ícones, efeitos e sons, com os `.import`.

**Alterar:** as seis linhas do `EFFECTS` no `cut_effects.gd`; no `element_skills.py`, as seis funções e a tabela `SOUNDS`. A luta acha os arquivos pelo slug, então nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- sombra_metal_gelo_mente_icons.webp garra_do_eclipse martelo_de_ferro lanca_de_cristal inverno_mudo grito_congelado palavra_guardada
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" garra_do_eclipse martelo_de_ferro lanca_de_cristal inverno_mudo grito_congelado palavra_guardada
python -I art-source/sounds/element_skills.py garra_do_eclipse martelo_de_ferro lanca_de_cristal inverno_mudo grito_congelado palavra_guardada
```

## Verificação

Como na [22](22-earth-ice-mind-skills.md): a imagem dos ícones com os efeitos ao dono, o resumo do volume, a carga dos arquivos sem janela e o jogo abrindo sem erros.

## Tarefas

- [x] Spec.
- [x] Os ícones, os efeitos e os sons.
- [x] A imagem, o resumo do volume e a carga sem janela.
- [ ] O dono ver e ouvir com F5.

## Resultado da verificação

Em 2026-11-14, sem janela:

- **Escolha dos efeitos:** folhas de contato do kit inteiro e tiras com todos os quadros dos candidatos, na linha de cada Elemento.
- **Arquivos:** os 6 ícones com 256 × 256; os 6 efeitos, com 12 a 15 quadros; os 6 sons, com a duração da tabela e pico de 0,7. O volume médio (RMS) fica entre 0,13 e 0,30, na faixa dos sons da [22](22-earth-ice-mind-skills.md) (0,17 a 0,22); o Inverno Mudo é o mais baixo de propósito, porque termina em silêncio. Uma imagem com cada ícone ao lado de 8 quadros do efeito foi mandada ao dono.
- **Projeto:** uma cena temporária (já apagada) carregou os 18 arquivos, e o jogo sem janela abre sem erros de script. Diferente da 22, não houve luta montada à mão: o caminho da luta é o mesmo, pelo slug.
- **Falta o dono:** os sons não foram ouvidos aqui. O dono vê e ouve as seis numa luta com F5, ou no visualizador de conteúdo.
