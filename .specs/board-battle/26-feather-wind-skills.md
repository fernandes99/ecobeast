# 26. Ícone, efeito e som de seis Técnicas de Vento

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [25](25-shadow-metal-ice-mind-skills.md) (o mesmo caminho)

## Contexto

Em 2026-11-19, Claude cruzou as 65 Técnicas do catálogo com os arquivos do cliente e achou 15 sem ícone: as seis de Vento da [puffcoo-line](../puffcoo-line/) e da [browt-line](../browt-line/) (Pena Afiada, Vento a Favor, Rajada de Penas, Nuvem de Penas, Vendaval e Rasante), três de Flora, quatro de Volt e as duas de Terra que já estavam fora da [25](25-shadow-metal-ice-mind-skills.md). O dono mandou a imagem com os ícones das seis de Vento, em 3 colunas e 2 linhas, nessa ordem, e pediu que Claude completasse o que falta nelas, com os efeitos do kit "Effect and FX Pixel All Free".

## Escopo

- Os seis ícones, os seis efeitos, o projétil da Pena Afiada e os seis sons.

## Fora do escopo

- As outras nove Técnicas sem ícone: seis entraram na [27](27-flora-volt-skills.md), e a Tempestade de Algas, o Desabamento e o Abalo Profundo ficam para quando o dono mandar os ícones.
- Mudar os dados das seis Técnicas no catálogo.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, recortados de `art-source/skills/vento_penas_icons.jpg` pelo `cut_icons.gd`.
- **RF-02:** O efeito de cada Técnica, escolhido por Claude pela forma e pelo ícone, na 6ª linha do kit tingida pelo verde-água do Vento, como na [20](20-instinct-wind-skills.md) (_a revisar_):

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Pena Afiada | inimigo | 5/222 | uma pena fina, em diagonal, que treme e crava |
  | Vento a Favor | aliado | 6/296 | um cata-vento de ar que gira e se fecha |
  | Rajada de Penas | inimigo | 6/275 | vários riscos de pena passando juntos |
  | Nuvem de Penas | inimigo | 3/125 | um tufo que estoura em penas curvas e se espalha |
  | Vendaval | inimigo | 10/464 | um redemoinho em pé, girando |
  | Rasante | inimigo | 7/316 | duas asas que se abrem e somem |

- **RF-03:** A Pena Afiada (alcance 3, sem atravessar) ganha o projétil `pena_afiada_projectile.png`, da 6ª linha da `Part 12/579.png`: um risco de ar fino, apontado para a direita, que voa como a Faísca Rápida ([15](15-projectile-effects.md)). A Rajada de Penas ganhou o dela depois, na [28](28-skill-projectiles.md).
- **RF-04:** O som de cada Técnica, por síntese, sem gravação de terceiros, no `element_skills.py` (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Pena Afiada | 0,45 s | um "fiu" curto e agudo da pena cortando o ar e um tique seco quando ela crava |
  | Vento a Favor | 0,65 s | uma brisa que cresce por trás, com o filtro subindo, e três notas leves que sobem |
  | Rajada de Penas | 0,65 s | quatro "fius" de pena em seguida, cada um mais agudo, com o farfalhar das penas |
  | Nuvem de Penas | 0,75 s | um sopro que espalha as penas e um farfalhar macio que treme e vai caindo |
  | Vendaval | 0,8 s | uma ventania que ronca e cresce, um uivo de vento que treme e desce e o rumor grave do redemoinho |
  | Rasante | 0,55 s | o assobio do mergulho, que desce como quem passa rápido, e o tapa pesado das asas abertas |

## Critérios de aceite

- [x] As seis Técnicas têm ícone, efeito e som, e a Pena Afiada tem o projétil.
- [x] O Godot importa os 19 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as seis numa luta.

## Desenho técnico

**Criar:** `art-source/skills/vento_penas_icons.jpg` (a imagem do dono), os seis ícones, efeitos e sons e o projétil, com os `.import`.

**Alterar:** seis linhas do `EFFECTS` e uma do `PROJECTILES` no `cut_effects.gd`; no `element_skills.py`, as seis funções e a tabela `SOUNDS`. A luta acha os arquivos pelo slug, então nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- vento_penas_icons.jpg pena_afiada vento_a_favor rajada_de_penas nuvem_de_penas vendaval rasante
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" pena_afiada vento_a_favor rajada_de_penas nuvem_de_penas vendaval rasante
python -I art-source/sounds/element_skills.py pena_afiada vento_a_favor rajada_de_penas nuvem_de_penas vendaval rasante
godot --headless --path client --import
```

## Resultado da verificação

Em 2026-11-19, sem janela:

- **Escolha dos efeitos:** folhas de contato do kit inteiro na 6ª linha tingida e tiras com todos os quadros dos candidatos. As folhas já usadas pelo Vento (9/438, 12/567 e 1/03) ficaram de fora.
- **Arquivos:** os 6 ícones com 256 × 256; os 6 efeitos, com 8 a 12 quadros; o projétil, com 14; os 6 sons, com a duração da tabela e pico de 0,7, e o volume médio (RMS) entre 0,15 e 0,23, na faixa dos de antes. Uma imagem com cada ícone ao lado de 8 quadros do efeito foi mandada ao dono.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** os sons não foram ouvidos aqui. O dono vê e ouve as seis numa luta com F5, ou no visualizador de conteúdo (F1).
