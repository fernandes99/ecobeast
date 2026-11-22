# 02. As Técnicas do sapo do néctar

- **Status:** concluída (falta o dono conferir no Testar técnica)
- **Depende de:** [01-nectoad-line](01-nectoad-line.md)

## Contexto

O catálogo tem seis Técnicas de Toxina: quatro Físicas (Espinho Venenoso, Presa Venenosa, Dardo Gotejante e Ferroada Paralisante), uma Especial (Cuspe Ácido) e uma de Suporte (Poça Tóxica). Nenhuma protege quem a usa. Claude propôs três para o sapo, sem regra nova no motor, escolhidas para sustentar o papel de Guardião Muralha com Arquiteto de secundário ([README](README.md#papel)): a língua que envenena de perto, a pele que sobe as defesas e cura aos poucos e, na forma final, o abraço forte que deixa a Poça Tóxica no chão. Os números são _a revisar_.

## Escopo

- A migração `20270208000001_toxin_guard_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Requisitos

- **RF-01:** Três Técnicas, com prioridade 0 e um golpe:

  | id | slug | name | Elemento | Categoria | Alvo | Poder | Precisão | Alcance | Área | Contato | PP | Cooldown | Marca |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 122 | `lingua_acida` | Língua Ácida | Toxina (9) | Física | Inimigo | 60 | 100 | 2 | 1 | sim | 20 | 1 | — |
  | 123 | `pele_de_nectar` | Pele de Néctar | Toxina (9) | Suporte | O próprio | 0 | 0 | 1 | 1 | não | 10 | 3 | — |
  | 124 | `abraco_da_flor` | Abraço da Flor | Toxina (9) | Física | Inimigo | 90 | 90 | 1 | 1 | sim | 10 | 3 | Poça Tóxica (8), 4 vezes |

  Descrições:
  - **Língua Ácida:** "Estica a língua grudenta num inimigo a até 2 hexágonos. Pode deixar o alvo Envenenado."
  - **Pele de Néctar:** "Cobre a pele de néctar grosso. Sobe a Defesa e a Defesa Especial e deixa quem usou Brotando."
  - **Abraço da Flor:** "Agarra o inimigo com as patas e as pétalas e aperta forte. O néctar que escorre deixa uma Poça Tóxica no chão."

- **RF-02:** Os efeitos em `skill_effects`, de 83 a 86:

  | id | Técnica | Efeito | Detalhe | Chance |
  | --- | --- | --- | --- | --- |
  | 83 | Língua Ácida | Aplicar status (1) | Envenenado (2) | 30% |
  | 84 | Pele de Néctar | Alterar atributo (2) | Defesa +1, no próprio | 100% |
  | 85 | Pele de Néctar | Alterar atributo (2) | Def. Especial +1, no próprio | 100% |
  | 86 | Pele de Néctar | Aplicar status (1) | Brotando (11), no próprio | 100% |

  O efeito 86 fica sem alvo próprio (`skill_target_id` nulo, como pede o `apply_status`): numa Técnica de alvo O próprio, o servidor aplica todo efeito em quem usou (`isOnAuthor`, em `server/src/domain/battle/effects.ts`).

- **RF-03:** Os learnsets novos, além dos da [fase 1](01-nectoad-line.md). O Toxbloom aprende o Abraço da Flor ao evoluir (método 2, nível 0):

  | Nível | Nectoad | Toxbloom |
  | --- | --- | --- |
  | 0 (ao evoluir) | — | Abraço da Flor |
  | 12 | Língua Ácida | Língua Ácida |
  | 18 | Pele de Néctar | Pele de Néctar |
  | 36 | — | Abraço da Flor |

## Fora do escopo

- Um efeito que envenene quem encosta no sapo, que pediria uma regra nova no motor.
- O ícone, o efeito e o som das três Técnicas.

## Critérios de aceite

- [x] O `CatalogValidator` aceita as Técnicas novas (o jogo sem janela abre sem erro).
- [ ] O F1 as mostra na aba Técnicas, e o Testar técnica usa a Pele de Néctar, que sobe as defesas e deixa Brotando, e o Abraço da Flor, que deixa a Poça Tóxica.
- [x] Os testes de unidade e os e2e do servidor passam, menos as falhas antigas.
