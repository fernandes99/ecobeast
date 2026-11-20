# 02. As Técnicas de serpente

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-snekit-line](01-snekit-line.md)

## Contexto

O catálogo só tem duas Técnicas de Toxina, o Espinho Venenoso e a Poça Tóxica, e nenhuma Técnica de Instinto lembra uma serpente. Claude propôs quatro Técnicas para a linha, sem regra nova no motor: os estados Envenenado e Preso e a mudança de atributo já existem. Siga a [lume-line/02](../lume-line/02-shadow-skills.md), que fez o mesmo para as Técnicas de Sombra.

O dono viu as quatro na ficha da linha e mandou seguir ("pode seguir"). Os números são _a revisar_.

## Escopo

- A migração `20270115000001_serpent_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`. Confira na migração `20270114000001_shadow_skills` as colunas e a forma dos efeitos.

## Requisitos

- **RF-01:** Quatro Técnicas, todas com prioridade 0 e um golpe:

  | id | slug | name | Elemento | Categoria | Alvo | Forma | Poder | Prec | PP | Alcance | Contato | Crítico | Cooldown | Efeito |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 80 | `bote` | Bote | Instinto | Física | Inimigo | um alvo | 60 | 100 | 20 | 1 | sim | +1 | 0 | — |
  | 81 | `presa_venenosa` | Presa Venenosa | Toxina | Física | Inimigo | um alvo | 75 | 100 | 15 | 1 | sim | 0 | 1 | 30%: Envenenado |
  | 82 | `constricao` | Constrição | Instinto | Física | Inimigo | um alvo | 50 | 95 | 15 | 1 | sim | 0 | 2 | 100%: Preso |
  | 83 | `cuspe_acido` | Cuspe Ácido | Toxina | Especial | Inimigo | linha | 50 | 100 | 20 | 3 | não | 0 | 1 | 30%: −1 Def.E no alvo |

  Descrições:
  - **Bote:** "Dá um bote rápido e certeiro no alvo. Acerta um ponto fraco com mais facilidade."
  - **Presa Venenosa:** "Crava as presas cheias de veneno no alvo. Pode deixá-lo Envenenado."
  - **Constrição:** "Enrola o corpo no alvo e aperta. Ele fica Preso e não anda por duas vezes."
  - **Cuspe Ácido:** "Cospe ácido no primeiro da linha, a até 3 hexágonos. Pode baixar a Defesa Especial."

- **RF-02:** Os learnsets novos, por nível, além dos da [fase 1](01-snekit-line.md):

  | Nível | Snekit | Venomaw |
  | --- | --- | --- |
  | 9 | Bote | Bote |
  | 18 | Constrição | Constrição |
  | 26 | Cuspe Ácido | Cuspe Ácido |
  | 40 | — | Presa Venenosa |

## Fora do escopo

- O ícone, o efeito e o som das quatro Técnicas, que o dono manda depois, como na [board-battle/29](../board-battle/29-earth-volt-water-flora-skills.md).

## Critérios de aceite

- [x] O dono mandou seguir com as quatro.
- [x] O `CatalogValidator` aceita as Técnicas novas (o jogo sem janela abre sem erro).
- [ ] O F1 as mostra na aba Técnicas.
- [x] Os testes de unidade e os e2e do servidor passam, menos as 2 falhas antigas. Em 2026-11-20: 1046 de unidade e 690 de 692 e2e; as 2 falhas (`species_day_phases` e `species_skills`, das espécies 7 a 9) já existiam antes desta linha, porque essas linhas foram apagadas direto no banco.
