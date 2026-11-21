# 02. As Técnicas de escorpião

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-sandlurk-line](01-sandlurk-line.md)

## Contexto

O catálogo tem três Técnicas de Inseto, do louva-a-deus, e nenhuma lembra um escorpião. Claude propôs quatro na ficha da linha, sem regra nova no motor: o Preso, o Paralisado, a mudança de atributo e o crítico já existem. O dono mandou seguir ("Pode seguir"). Siga a [snekit-line/02](../snekit-line/02-serpent-skills.md). Os números são _a revisar_.

## Escopo

- A migração `20270127000001_dune_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Requisitos

- **RF-01:** Quatro Técnicas, todas com prioridade 0, um golpe e sem marca no chão:

  | id | slug | name | Elemento | Categoria | Alvo | Forma | Poder | Prec | PP | Alcance | Contato | Crítico | Cooldown | Efeito |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 98 | `pinca_firme` | Pinça Firme | Inseto | Física | Inimigo | um alvo | 55 | 95 | 15 | 1 | sim | 0 | 2 | 100%: Preso |
  | 99 | `ferroada_paralisante` | Ferroada Paralisante | Toxina | Física | Inimigo | linha | 70 | 100 | 15 | 2 | sim | 0 | 2 | 30%: Paralisado |
  | 100 | `enterrar` | Enterrar | Inseto | Status | Si mesmo | um alvo | 0 | 0 | 10 | 1 | não | 0 | 3 | +1 Def e +1 Def.E em si |
  | 101 | `bote_da_duna` | Bote da Duna | Inseto | Física | Inimigo | um alvo | 95 | 90 | 10 | 1 | sim | +1 | 3 | — |

  Descrições:
  - **Pinça Firme:** "Agarra o alvo com as pinças e não solta. Ele fica Preso e não anda por duas vezes."
  - **Ferroada Paralisante:** "Estica a cauda por cima das pinças e crava o ferrão no primeiro da linha, a até 2 hexágonos. Pode deixá-lo Paralisado."
  - **Enterrar:** "Afunda na areia e deixa só a carapaça de fora. Aumenta a Defesa e a Defesa Especial."
  - **Bote da Duna:** "Sai de repente da areia num bote só, depois de muito esperar. Acerta um ponto fraco com mais facilidade."

- **RF-02:** Os efeitos em `skill_effects`, de 63 a 66: o Preso (8) da Pinça Firme, o Paralisado (3) da Ferroada Paralisante e o +1 da Defesa (3) e da Defesa Especial (5) do Enterrar, no próprio autor (alvo 2).
- **RF-03:** Os learnsets novos, além dos da [fase 1](01-sandlurk-line.md). O Bote da Duna é a Técnica que o Dunestrike aprende ao evoluir (`evolution`, método 2, nível 0).

  | Nível | Sandlurk | Dunestrike |
  | --- | --- | --- |
  | 0 (ao evoluir) | — | Bote da Duna |
  | 9 | Pinça Firme | Pinça Firme |
  | 17 | Enterrar | Enterrar |
  | 25 | Ferroada Paralisante | Ferroada Paralisante |
  | 46 | — | Bote da Duna |

## Fora do escopo

- O ícone, o efeito e o som das quatro Técnicas, que o dono manda depois.

## Critérios de aceite

- [x] O dono mandou seguir com as quatro.
- [x] O `CatalogValidator` aceita as Técnicas novas (o jogo sem janela abre sem erro).
- [ ] O F1 as mostra na aba Técnicas, e o Testar técnica usa cada uma.
- [x] Os testes de unidade e os e2e do servidor passam, menos as falhas antigas (veja a [fase 1](01-sandlurk-line.md#critérios-de-aceite)).
