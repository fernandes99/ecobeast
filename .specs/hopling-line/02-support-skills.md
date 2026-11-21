# 02. As Técnicas de suporte

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-hopling-line](01-hopling-line.md) e o alvo "Meu time" da [skill-editor](../skill-editor/)

## Contexto

As Técnicas de suporte do catálogo são de Fogo, Flora e Vento, e nenhuma é de Instinto. Claude propôs quatro para a médica, sem regra nova no motor: a cura de um aliado (como o Banho de Sol), a mudança de atributo num aliado (como o Vento a Favor), a cura de si (como a Palavra Guardada) e a marca Jardim (como o Semear Jardim). O dono mandou seguir com a linha. Os números são _a revisar_.

Numa Técnica de alvo "Meu time" (`ally`), a cura vai para o aliado escolhido, e um `modify_stat` com o alvo 4 também; com o alvo 2, vai para o autor (`server/src/domain/battle/effects.ts`).

## Escopo

- A migração `20270128000001_support_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Requisitos

- **RF-01:** Quatro Técnicas de Instinto, de Status, todas com prioridade 0, poder 0, precisão 0, um golpe, área de um alvo e sem contato:

  | id | slug | name | Alvo | Alcance | PP | Cooldown | Marca | Efeito |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 102 | `erva_da_bolsa` | Erva da Bolsa | Meu time | 2 | 10 | 2 | — | Cura 50% do HP do aliado |
  | 103 | `atadura_firme` | Atadura Firme | Meu time | 2 | 15 | 3 | — | +1 Def e +1 Def.E no aliado |
  | 104 | `cochilo` | Cochilo | Si mesmo | 1 | 10 | 3 | — | Cura 50% do próprio HP |
  | 105 | `ninho_de_ervas` | Ninho de Ervas | Meu time | 2 | 5 | 4 | Jardim (10), por 6 vezes | — |

  Descrições:
  - **Erva da Bolsa:** "Tira uma erva da bolsa e trata um aliado a até 2 hexágonos, resmungando. Recupera metade do HP dele."
  - **Atadura Firme:** "Enrola uma atadura bem apertada num aliado a até 2 hexágonos. Aumenta a Defesa e a Defesa Especial dele."
  - **Cochilo:** "Fecha os olhos por um instante, enfim. Recupera metade do próprio HP."
  - **Ninho de Ervas:** "Espalha ervas no chão em volta de um aliado. Quem termina a vez ali recupera HP."

- **RF-02:** Os efeitos em `skill_effects`, de 67 a 70: a cura (`heal`, 50%) da Erva da Bolsa, o +1 da Defesa (3) e da Defesa Especial (5) da Atadura Firme no aliado (alvo 4) e a cura do Cochilo.
- **RF-03:** Os learnsets novos, além dos da [fase 1](01-hopling-line.md):

  | Nível | Hopling | Pouchmend |
  | --- | --- | --- |
  | 5 | Erva da Bolsa | Erva da Bolsa |
  | 17 | Atadura Firme | Atadura Firme |
  | 22 | Cochilo | Cochilo |
  | 26 | Ninho de Ervas | Ninho de Ervas |

## Fora do escopo

- Tirar os estados ruins de um aliado, que pede um efeito novo no motor ([README](README.md#fora-do-escopo)).
- O ícone, o efeito e o som das quatro Técnicas.

## Critérios de aceite

- [x] O dono mandou seguir com a linha.
- [x] O `CatalogValidator` aceita as Técnicas novas (o jogo sem janela abre sem erro).
- [ ] O F1 as mostra na aba Técnicas, e o Testar técnica de 2×2 usa cada uma num aliado.
- [x] Os testes de unidade e os e2e do servidor passam, menos as falhas antigas (veja a [fase 1](01-hopling-line.md#critérios-de-aceite)).
