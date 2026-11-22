# 02. As Técnicas da borboleta torcedora

- **Status:** concluída (falta o dono conferir no Testar técnica)
- **Depende de:** [01-budflit-line](01-budflit-line.md)

## Contexto

O Inseto não tem nenhuma Técnica Especial, e o Psíquico tem só uma de Suporte. Nenhuma Técnica de hoje sobe o ataque de um aliado: o Vento a Favor sobe a Velocidade e a evasão, e a Atadura Firme e o Halo Protetor sobem as defesas. Claude propôs três, sem regra nova no motor, para sustentar o papel de Suporte Inspirador ([README](README.md#papel)): o pó que atinge de longe e pode confundir, o pó que anima um aliado e, na forma final, a ovação que o anima muito. Os números são _a revisar_.

## Escopo

- A migração `20270209000001_cheer_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Requisitos

- **RF-01:** Três Técnicas, com prioridade 0 e um golpe:

  | id | slug | name | Elemento | Categoria | Alvo | Poder | Precisão | Alcance | Área | Contato | PP | Cooldown |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 125 | `po_cintilante` | Pó Cintilante | Inseto (15) | Especial | Inimigo | 50 | 100 | 3 | 1 | não | 25 | 0 |
  | 126 | `po_animador` | Pó Animador | Psíquico (10) | Suporte | Meu time | 0 | 0 | 2 | 1 | não | 15 | 2 |
  | 127 | `ovacao` | Ovação | Psíquico (10) | Suporte | Meu time | 0 | 0 | 3 | 1 | não | 5 | 4 |

  Descrições:
  - **Pó Cintilante:** "Sacode as asas e joga um pó brilhante num inimigo a até 3 hexágonos. Pode deixar o alvo Confuso."
  - **Pó Animador:** "Espalha um pó cheiroso num aliado a até 2 hexágonos, ou em quem usou. Sobe o Ataque e o Ataque Especial."
  - **Ovação:** "Abre as asas, faz festa e chove confete num aliado a até 3 hexágonos, ou em quem usou. Sobe muito o Ataque e o Ataque Especial."

- **RF-02:** Os efeitos em `skill_effects`, de 87 a 91. Os de atributo vão no alvo Meu time (4), como os do Vento a Favor:

  | id | Técnica | Efeito | Detalhe | Chance |
  | --- | --- | --- | --- | --- |
  | 87 | Pó Cintilante | Aplicar status (1) | Confuso (6) | 10% |
  | 88 | Pó Animador | Alterar atributo (2) | Ataque +1 | 100% |
  | 89 | Pó Animador | Alterar atributo (2) | Ataque Especial +1 | 100% |
  | 90 | Ovação | Alterar atributo (2) | Ataque +2 | 100% |
  | 91 | Ovação | Alterar atributo (2) | Ataque Especial +2 | 100% |

- **RF-03:** Os learnsets novos, além dos da [fase 1](01-budflit-line.md). A Galafly aprende a Ovação ao evoluir (método 2, nível 0):

  | Nível | Budflit | Cheerwing | Galafly |
  | --- | --- | --- | --- |
  | 0 (ao evoluir) | — | — | Ovação |
  | 5 | Pó Cintilante | Pó Cintilante | Pó Cintilante |
  | 16 | — | Pó Animador | Pó Animador |
  | 40 | — | — | Ovação |

## Fora do escopo

- Uma Ovação em área, para todos os aliados de uma vez.
- O ícone, o efeito e o som das três Técnicas.

## Critérios de aceite

- [x] O `CatalogValidator` aceita as Técnicas novas (o jogo sem janela abre sem erro).
- [ ] O F1 as mostra na aba Técnicas, e o Testar técnica num 2×2 usa o Pó Animador e a Ovação num aliado, que sobe o Ataque e o Ataque Especial.
- [x] Os testes de unidade e os e2e do servidor passam, menos as falhas antigas.
