# 36. Ícone, efeito e som do Raio de Sol, da Lâmina Solar e de quatro Técnicas de rastro

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [32](32-toxin-instinct-insect-skills.md) (o mesmo caminho), [28](28-skill-projectiles.md) (a regra do projétil) e [34](34-trail-skills.md) (as Técnicas de rastro)

## Contexto

Em 2026-11-21, Claude listou as 11 Técnicas sem ícone (ids 87 a 97) e as mandou ao dono em dois blocos, o primeiro com 6 e o segundo com 5. O dono mandou a imagem do bloco 1 com os ícones em 3 colunas e 2 linhas, nesta ordem: Raio de Sol, Lâmina Solar, Cometa de Brasa, Jato Gotejante, Faísca Rastejante e Semente Saltitante. Depois pediu: "gere tudo que falta dessas habilidades, utilize o vfx que tem aqui", apontando para o kit "Effect and FX Pixel All Free", "com as cores de acordo com o elemento".

## Escopo

- Os 6 ícones, os 6 efeitos e os 6 sons, e o projétil das 5 que lançam algo.

## Fora do escopo

- As 5 Técnicas do bloco 2, que ainda estão sem ícone: Cometa de Pólen, Bola de Lama, Estaca de Gelo, Dardo Gotejante e Pena Riscante.
- O projétil da Lâmina Solar, que é de contato ([28](28-skill-projectiles.md), RF-01).
- Tinta própria para a Luz: ela usa a 1ª linha do kit, a mesma do Volt ([18](18-element-skill-effects.md)).
- Mudar os dados das Técnicas no catálogo ou o desenho das marcas no chão ([35](35-ground-mark-effects.md)).

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, com 256 × 256, recortados de `art-source/skills/luz_fogo_agua_volt_flora_icons.jpg` pelo `cut_icons.gd`, sem retoque. O dono foi avisado de que a imagem já vem com uns símbolos pequenos na Lâmina Solar e na Faísca Rastejante.
- **RF-02:** O efeito de cada Técnica foi escolhido por Claude pela forma e pelo ícone, numa comparação de 27 candidatos do kit na cor do Elemento (_a revisar_). A cor vem da linha do Elemento ([18](18-element-skill-effects.md)): a 1ª para Luz e Volt, a 8ª para Fogo, a 3ª para Água e a 4ª para Flora.

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Raio de Sol | inimigo, linha | 14/652 | raios de sol que se abrem em volta, em amarelo |
  | Lâmina Solar | inimigo | 5/242 | um corte em meia-lua largo e aceso, em amarelo |
  | Cometa de Brasa | inimigo, linha | 9/448 | a explosão que espalha brasas, em vermelho |
  | Jato Gotejante | inimigo, linha | 7/336 | o respingo que se desfaz em gotas, em azul |
  | Faísca Rastejante | inimigo, linha | 11/506 | faíscas subindo do chão, em amarelo |
  | Semente Saltitante | inimigo, linha | 13/615 | espinhos que brotam em volta, em verde |

- **RF-03:** As 5 que disparam, lançam ou atiram algo têm projétil ([28](28-skill-projectiles.md)), na linha do Elemento: o risco da 579 no Raio de Sol, no Jato Gotejante e na Faísca Rastejante, e o bolo da 578 no Cometa de Brasa (o cometa) e na Semente Saltitante (a semente).
- **RF-04:** O som de cada Técnica é feito por síntese no `element_skills.py`, sem gravação de terceiros (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Raio de Sol | 0,75 s | a luz juntando num tom que sobe, o raio num zumbido claro e um cintilar que ofusca |
  | Lâmina Solar | 0,6 s | a foice acendendo num tom quente, o "shing" do corte e um clarão que tilinta |
  | Cometa de Brasa | 0,85 s | o cometa rugindo e chegando, a explosão num baque e o chão crepitando |
  | Jato Gotejante | 0,65 s | um jato que chia, gotas pingando pelo caminho e o respingo no alvo |
  | Faísca Rastejante | 0,7 s | um zumbido elétrico que corre e chega perto, estalos e o choque no fim |
  | Semente Saltitante | 0,65 s | um "plop", três quiques que descem de altura e os espinhos brotando |

## Critérios de aceite

- [x] As 6 Técnicas têm ícone, efeito e som, e as 5 que lançam algo têm o projétil.
- [x] O Godot importa os 23 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as 6 numa luta (pelo Testar técnica do F1).

## Desenho técnico

**Criar:**
- `art-source/skills/luz_fogo_agua_volt_flora_icons.jpg` (a imagem do dono).
- Os 6 ícones, efeitos e sons e os 5 projéteis, com os `.import`.

**Alterar:**
- No `cut_effects.gd`, seis linhas do `EFFECTS` e cinco do `PROJECTILES`.
- No `element_skills.py`, as seis funções e a tabela `SOUNDS`.

Nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- luz_fogo_agua_volt_flora_icons.jpg raio_de_sol lamina_solar cometa_de_brasa jato_gotejante faisca_rastejante semente_saltitante
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" raio_de_sol lamina_solar cometa_de_brasa jato_gotejante faisca_rastejante semente_saltitante
python -I art-source/sounds/element_skills.py raio_de_sol lamina_solar cometa_de_brasa jato_gotejante faisca_rastejante semente_saltitante
godot --headless --path client --import
```

## Resultado da verificação

Em 2026-11-21, sem janela:

- **Arquivos:**
  - Os 6 ícones têm 256 × 256, e os 6 efeitos têm de 8 a 16 quadros. Os projéteis têm 14 quadros (a 579) e 11 (a 578).
  - Os 6 sons têm a duração da tabela e pico de 0,7. O volume médio (RMS) fica entre 0,16 e 0,25, dentro da faixa dos de antes (0,07 a 0,38).
  - Uma imagem com cada ícone ao lado de 8 quadros do efeito e 4 do projétil foi mandada ao dono.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** ver os efeitos e ouvir os sons no jogo. Os sons não foram ouvidos aqui.
