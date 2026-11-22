# 02. O Melado e as Técnicas da abelha operária

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-bumbit-line](01-bumbit-line.md) e [field-effects](../field-effects/)

## Contexto

Para ser Controlador, a linha precisa de 3 Técnicas de controle entre as melhores ([README](README.md#papel)). As marcas de hoje que seguram o inimigo fazem uma coisa só: a Areia Movediça deixa Preso, e o Lamaçal baixa a Velocidade. O **Melado** junta as duas, como o mel que gruda e pesa. O motor já aplica o estado e os atributos de uma marca, um depois do outro (`marks.ts`), então não há regra nova.

Claude propôs quatro Técnicas: o mel que marca o chão, o zumbido que confunde quem está perto, o pólen que tira a mira e, na forma final, a chuva de mel que machuca e marca. Os números são _a revisar_.

## Escopo

- A migração `20270212000001_hive_skills`, com linhas novas em `ground_effects`, `ground_effect_stats`, `skills`, `skill_effects` e `species_skills`.
- O desenho animado do Melado no tabuleiro (`GroundEffects._draw_honey`, com as cores `UiPalette.GROUND_HONEY*`): o cliente desenha cada marca pelo slug, por cima da cor do hexágono, e sem ele o Melado seria só a cor.

## Requisitos

- **RF-01:** A marca 12 em `ground_effects`: `honey`, **Melado**, sem dano nem cura, com o estado Preso (8) e a cor `#E8A93A`. Em `ground_effect_stats`, a Velocidade (6) em −1. Quem termina a vez nela fica Preso (o Vento é imune) e perde 1 de Velocidade.

- **RF-01b:** No tabuleiro, o Melado aparece como poças de mel brilhante que incham devagar, com fios de mel esticando e pingando.

- **RF-02:** Quatro Técnicas, com prioridade 0, crítico 0 e um golpe:

  | id | slug | name | Elemento | Categoria | Alvo | Poder | Precisão | Alcance | Área | Contato | PP | Cooldown | Marca |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 128 | `mel_grudento` | Mel Grudento | Inseto (15) | Suporte | Inimigo | 0 | 0 | 3 | Linha reta | não | 10 | 3 | Melado, 4 vezes |
  | 129 | `zumbido` | Zumbido | Inseto (15) | Especial | Inimigo | 55 | 100 | 1 | Triângulo | não | 15 | 2 | — |
  | 130 | `nuvem_de_polen` | Nuvem de Pólen | Flora (3) | Suporte | Inimigo | 0 | 100 | 2 | Triângulo | não | 15 | 2 | — |
  | 131 | `chuva_de_mel` | Chuva de Mel | Inseto (15) | Especial | Inimigo | 80 | 95 | 3 | Linha reta | não | 10 | 3 | Melado, 3 vezes |

  Descrições:
  - **Mel Grudento:** "Espalha um mel grosso no chão a até 3 hexágonos. Quem termina a vez no Melado fica Preso e perde Velocidade."
  - **Zumbido:** "Bate as asas tão rápido que o zumbido atordoa todos à frente. Pode deixar os alvos Confusos."
  - **Nuvem de Pólen:** "Sacode o pelo e solta uma nuvem de pólen à frente, a até 2 hexágonos. Baixa a Precisão dos alvos."
  - **Chuva de Mel:** "Lança uma chuva de mel pesado num inimigo a até 3 hexágonos. O mel que sobra deixa um Melado no chão."

- **RF-03:** Os efeitos em `skill_effects`, 92 e 93. O estado vai sem `skill_target_id`, como no Choque de Pelo, e a mudança de atributo no alvo Inimigo (1), como no Cuspe Ácido (o `CatalogValidator` exige o alvo no `modify_stat`):

  | id | Técnica | Efeito | Detalhe | Chance |
  | --- | --- | --- | --- | --- |
  | 92 | Zumbido | Aplicar status (1) | Confuso (6) | 30% |
  | 93 | Nuvem de Pólen | Alterar atributo (2) | Precisão −1 | 100% |

- **RF-04:** Os learnsets novos, além dos da [fase 1](01-bumbit-line.md). O Bloomarch aprende a Chuva de Mel ao evoluir (método 2, nível 0):

  | Nível | Bumbit | Buzzwork | Bloomarch |
  | --- | --- | --- | --- |
  | 0 (ao evoluir) | — | — | Chuva de Mel |
  | 6 | Nuvem de Pólen | Nuvem de Pólen | Nuvem de Pólen |
  | 11 | Zumbido | Zumbido | Zumbido |
  | 20 | — | Mel Grudento | Mel Grudento |
  | 24 | Mel Grudento | — | — |
  | 42 | — | — | Chuva de Mel |

## Fora do escopo

- Uma Técnica que ponha favos bloqueando hexágonos (o efeito Obstáculo, 🆕).
- O ícone, o efeito e o som das quatro Técnicas e da marca.

## Critérios de aceite

- [x] O `CatalogValidator` aceita a marca e as Técnicas novas (o jogo sem janela abre sem erro).
- [ ] O F1 as mostra na aba Técnicas, e o Testar técnica num 1×1 com o oponente parado mostra o Melado no chão, que deixa o oponente Preso e com −1 de Velocidade no fim da vez dele.
- [ ] O Zumbido atinge os inimigos do triângulo, e a Nuvem de Pólen baixa a Precisão de todos eles.
- [ ] A aba Estados do F1 continua certa (o Preso não muda).
- [x] Os testes de unidade e os e2e do catálogo passam (veja a [fase 1](01-bumbit-line.md#critérios-de-aceite)).
