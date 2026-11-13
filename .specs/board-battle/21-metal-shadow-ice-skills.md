# 21. Ícone, efeito e som de seis Técnicas de Sombra, Metal, Instinto e Gelo

- **Status:** concluída (falta o dono ver e ouvir no editor)
- **Depende de:** [20](20-instinct-wind-skills.md) (o mesmo caminho: ícones da imagem do dono, efeitos do kit e sons por síntese)

## Contexto

Em 2026-11-13, depois da [20](20-instinct-wind-skills.md), o dono pediu mais seis Técnicas sem ícone. Claude listou as seis que os Ecobeasts aprendem mais cedo: Lâmina Sombria (Sombra), Pinça de Aço (Metal), Garra de Picareta (Metal), Beliscão (Instinto), Couraça (Metal) e Geada Silenciosa (Gelo). O dono mandou a imagem com os seis ícones, em 3 colunas e 2 linhas, nessa ordem, e pediu: "crie as técnicas que você me enviou".

## Escopo

- Os seis ícones, os seis efeitos e os seis sons.

## Fora do escopo

- Mudar os dados das seis Técnicas no catálogo.
- Tingir a linha da Sombra, do Metal ou do Gelo: elas ficam como vêm no kit ([18](18-element-skill-effects.md), RF-01).

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, recortados de `art-source/skills/metal_sombra_gelo_icons.jpg` pelo `cut_icons.gd`, como na [20](20-instinct-wind-skills.md).
- **RF-02:** O efeito de cada Técnica, escolhido por Claude pela forma e pelo ícone (_a revisar_). Todas têm alcance 1, então nenhuma tem projétil, e a Couraça toca o efeito sobre quem a usou.

  | Técnica | Elemento (linha) | Alvo | Folha | Forma |
  | --- | --- | --- | --- | --- |
  | Lâmina Sombria | Sombra (9ª, violeta) | inimigo | 5/242 | um corte grande em meia-lua que se desfaz em fumaça |
  | Pinça de Aço | Metal (6ª, cinza) | inimigo | 13/622 | duas pontas de pinça que se fecham no meio |
  | Garra de Picareta | Metal (6ª, cinza) | inimigo | 3/126 | um rasgo na diagonal que crava para baixo |
  | Beliscão | Instinto (5ª, marrom) | inimigo | 2/64 | duas pinças que se fecham (a forma de antes da Mordida Brasa) |
  | Couraça | Metal (6ª, cinza) | si mesmo | 13/623 | uma placa quadrada que se forma e brilha |
  | Geada Silenciosa | Gelo (3ª, azul-claro) | inimigo | 4/176 | um floco de neve que gira e se espalha |

- **RF-03:** O som de cada Técnica, por síntese, sem gravação de terceiros, no `element_skills.py` (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Lâmina Sombria | 0,5 s | um "shing" de lâmina, um corte que desce e um zumbido grave e sombrio que pulsa |
  | Pinça de Aço | 0,7 s | um rangido de metal abrindo, o estalo da pinça fechando com um tinido e o aperto rangendo |
  | Garra de Picareta | 0,6 s | três garras de metal raspando, o golpe cravando na pedra e o chão se partindo |
  | Beliscão | 0,4 s | dois estalos secos de uma pinça pequena, com um guinchinho |
  | Couraça | 0,65 s | um zumbido metálico que sobe e uma batida de bigorna no fim |
  | Geada Silenciosa | 0,5 s | um chiado de gelo baixo e tinidos de cristal leves |

## Critérios de aceite

- [x] As seis Técnicas têm ícone, efeito e som.
- [x] Numa luta sem janela, cada uma toca o efeito e o som juntos, no Ecobeast certo.
- [ ] O dono vê e ouve as seis numa luta.

## Desenho técnico

**Criar:** `art-source/skills/metal_sombra_gelo_icons.jpg` (a imagem do dono), os seis ícones, efeitos e sons, com os `.import`.

**Alterar:** as seis linhas do `EFFECTS` no `cut_effects.gd`, e as seis funções e a tabela `SOUNDS` no `element_skills.py`.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- metal_sombra_gelo_icons.jpg lamina_sombria pinca_de_aco garra_de_picareta beliscao couraca geada_silenciosa
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" lamina_sombria pinca_de_aco garra_de_picareta beliscao couraca geada_silenciosa
python -I art-source/sounds/element_skills.py lamina_sombria pinca_de_aco garra_de_picareta beliscao couraca geada_silenciosa
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

- **Arquivos:** os 6 ícones com 256 × 256; os 6 efeitos, com 8 a 14 quadros; os 6 sons, com a duração da tabela, sem estourar. O Beliscão, curto e seco, saía baixo e ganhou mais saturação. Uma imagem com cada ícone ao lado de 6 quadros do efeito foi mandada ao dono.
- **Luta:** uma cena temporária (já apagada) usou as seis numa luta montada à mão. Cada uma mostrou o efeito uma vez, com o som dela tocando no mesmo quadro; a Couraça sobre quem a usou, e as outras sobre o alvo.
- **Projeto:** importa sem erros, e o jogo sem janela abre sem erros de script.
- **Falta o dono:** os sons não foram ouvidos aqui. O dono vê e ouve as seis numa luta com F5.
