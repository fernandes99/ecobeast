# 22. Ícone, efeito e som de seis Técnicas de Terra, Gelo e Mente

- **Status:** concluída (falta o dono ver e ouvir no editor)
- **Depende de:** [21](21-metal-shadow-ice-skills.md) (o mesmo caminho)

## Contexto

Em 2026-11-13, depois da [21](21-metal-shadow-ice-skills.md), Claude listou as próximas seis Técnicas sem ícone, pelo nível em que os Ecobeasts as aprendem: Nuvem de Poeira (Terra), Floco Cortante (Gelo), Arremesso de Torrão (Terra), Manto de Neve (Gelo), Eco Mental (Mente) e Garra de Pedra (Terra). O dono mandou a imagem com os seis ícones, em 3 colunas e 2 linhas, nessa ordem.

São as primeiras Técnicas de Terra com efeito. A 7ª linha do kit, a da Terra na [18](18-element-skill-effects.md) (RF-01), é um marrom arroxeado que, num teste, saiu rosado e não parecia terra nem poeira. Por isso, a Terra passa a usar a 6ª linha, cinza, tingida com a cor dela, como o Vento na [20](20-instinct-wind-skills.md).

## Escopo

- Os seis ícones, os seis efeitos e os seis sons.
- A Terra na 6ª linha, tingida com `#B07A43`.

## Fora do escopo

- Mudar os dados das seis Técnicas no catálogo.
- Mudar outros Elementos.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, recortados de `art-source/skills/terra_gelo_mente_icons.webp` pelo `cut_icons.gd`.
- **RF-02:** No `cut_effects.gd`, a Terra passa para a 6ª linha e entra em `ELEMENT_TINTS` com `#B07A43`. Nenhuma Técnica de Terra tinha efeito antes, então nada muda nos arquivos de antes. A 7ª linha fica sem Elemento.
- **RF-03:** O efeito de cada Técnica, escolhido por Claude pela forma e pelo ícone (_a revisar_). Todas têm alcance 1, então nenhuma tem projétil, e o Manto de Neve toca o efeito sobre quem o usou.

  | Técnica | Elemento (linha) | Alvo | Folha | Forma |
  | --- | --- | --- | --- | --- |
  | Nuvem de Poeira | Terra (6ª, tingida) | inimigo | 10/476 | uma nuvem de poeira que sobe e se desfaz (a forma da Fumaça Densa, em marrom) |
  | Floco Cortante | Gelo (3ª, azul-claro) | inimigo | 7/325 | um floco em estrela que se abre e se parte |
  | Arremesso de Torrão | Terra (6ª, tingida) | inimigo | 2/76 | um torrão que bate e se esfarela em pedaços |
  | Manto de Neve | Gelo (3ª, azul-claro) | si mesmo | 1/26 | anéis de neve girando em volta do corpo |
  | Eco Mental | Mente (2ª, rosa e roxo) | inimigo | 10/475 | uma onda em anel que se espalha, como um eco |
  | Garra de Pedra | Terra (6ª, tingida) | inimigo | 6/295 | garras curvas de pedra que giram e riscam |

- **RF-04:** O som de cada Técnica, por síntese, sem gravação de terceiros, no `element_skills.py` (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Nuvem de Poeira | 0,6 s | um sopro seco que levanta e se espalha, com grãos de areia chiando |
  | Floco Cortante | 0,4 s | um "tsing" de cristal, um corte agudo e cacos de gelo tilintando |
  | Arremesso de Torrão | 0,55 s | o zunido do torrão voando, o baque pesado de terra e o torrão se desfazendo |
  | Manto de Neve | 0,7 s | neve girando, macia, com sininhos de gelo que descem |
  | Eco Mental | 0,6 s | um tom estranho e trêmulo que se repete três vezes, cada vez mais longe |
  | Garra de Pedra | 0,55 s | um golpe pesado de garra e pedra rangendo e se partindo |

## Critérios de aceite

- [x] As seis Técnicas têm ícone, efeito e som.
- [x] Numa luta sem janela, cada uma toca o efeito e o som juntos, no Ecobeast certo.
- [ ] O dono vê e ouve as seis numa luta.

## Desenho técnico

**Criar:** `art-source/skills/terra_gelo_mente_icons.webp` (a imagem do dono), os seis ícones, efeitos e sons, com os `.import`.

**Alterar:** no `cut_effects.gd`, a linha da Terra, o `ELEMENT_TINTS` e as seis linhas do `EFFECTS`; no `element_skills.py`, as seis funções e a tabela `SOUNDS`.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- terra_gelo_mente_icons.webp nuvem_de_poeira floco_cortante arremesso_de_torrao manto_de_neve eco_mental garra_de_pedra
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" nuvem_de_poeira floco_cortante arremesso_de_torrao manto_de_neve eco_mental garra_de_pedra
python -I art-source/sounds/element_skills.py nuvem_de_poeira floco_cortante arremesso_de_torrao manto_de_neve eco_mental garra_de_pedra
```

## Verificação

Como na [20](20-instinct-wind-skills.md): a imagem dos ícones com os efeitos ao dono, o resumo do volume, o teste sem janela numa luta montada à mão e o jogo abrindo sem erros.

## Tarefas

- [x] Spec.
- [x] Os ícones, os efeitos e os sons.
- [x] A imagem, o resumo do volume e o teste sem janela.
- [ ] O dono ver e ouvir com F5.

## Resultado da verificação

Em 2026-11-13, sem janela:

- **Cor da Terra:** uma imagem com a Nuvem de Poeira na 7ª linha e na 6ª tingida mostrou a 7ª rosada e a tingida marrom-terra.
- **Arquivos:** os 6 ícones com 256 × 256; os 6 efeitos, com 8 a 14 quadros; os 6 sons, com a duração da tabela, sem estourar. Uma imagem com cada ícone ao lado de 6 quadros do efeito foi mandada ao dono.
- **Luta:** uma cena temporária (já apagada) usou as seis numa luta montada à mão. Cada uma mostrou o efeito uma vez, com o som dela tocando no mesmo quadro; o Manto de Neve sobre quem o usou, e as outras sobre o alvo.
- **Projeto:** importa sem erros, e o jogo sem janela abre sem erros de script.
- **Falta o dono:** os sons não foram ouvidos aqui. O dono vê e ouve as seis numa luta com F5.
