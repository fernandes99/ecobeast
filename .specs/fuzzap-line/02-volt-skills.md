# 02. As Técnicas de estática

- **Status:** concluída
- **Depende de:** [01-fuzzap-line](01-fuzzap-line.md)

## Contexto

O catálogo tem cinco Técnicas de Volt, quatro Especiais (Faísca de Alga, Corrente Viva, Tempestade de Algas e Faísca Rastejante) e a Maré Elétrica, e nenhuma Física. Claude propôs quatro para o lêmingue, sem regra nova no motor: o choque de contato que pode paralisar, a estática que paralisa de certeza, a investida forte de contato e, na forma final, a avalanche de Gelo que deixa a marca Geada. Os números são _a revisar_.

## Escopo

- A migração `20270205000001_volt_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Requisitos

- **RF-01:** Quatro Técnicas, com prioridade 0 e um golpe:

  | id | slug | name | Elemento | Categoria | Alvo | Poder | Precisão | Alcance | Área | Contato | PP | Cooldown | Marca |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 118 | `choque_de_pelo` | Choque de Pelo | Volt (4) | Física | Inimigo | 40 | 100 | 1 | 1 | sim | 30 | 0 | — |
  | 119 | `estatica` | Estática | Volt (4) | Status | Inimigo | 0 | 90 | 2 | 1 | não | 20 | 3 | — |
  | 120 | `investida_faiscante` | Investida Faiscante | Volt (4) | Física | Inimigo | 80 | 95 | 1 | 1 | sim | 15 | 2 | — |
  | 121 | `avalanche_estatica` | Avalanche Estática | Gelo (7) | Física | Inimigo | 95 | 90 | 2 | 3 | não | 10 | 3 | Geada (7), 4 vezes |

  A área 3 é o triângulo da Chama Espiral e do Metal Fundido.

  Descrições:
  - **Choque de Pelo:** "Esbarra no inimigo com o pelo cheio de estática. Pode deixar o alvo Paralisado."
  - **Estática:** "Arrepia o pelo e solta uma descarga num inimigo a até 2 hexágonos. Deixa o alvo Paralisado."
  - **Investida Faiscante:** "Corre soltando faíscas e se joga no inimigo. Pode deixar o alvo Paralisado."
  - **Avalanche Estática:** "Sacode a cauda de cristal e derruba neve carregada num leque à frente, a até 2 hexágonos. O chão fica coberto de geada."

- **RF-02:** Os efeitos em `skill_effects`, de 80 a 82, todos o Paralisado (3): 20% no Choque de Pelo, 100% na Estática e 30% na Investida Faiscante.
- **RF-03:** Os learnsets novos, além dos da [fase 1](01-fuzzap-line.md). O Blizzvolt aprende a Avalanche Estática ao evoluir (método 2, nível 0):

  | Nível | Fuzzap | Blizzvolt |
  | --- | --- | --- |
  | 0 (ao evoluir) | — | Avalanche Estática |
  | 1 | Choque de Pelo | Choque de Pelo |
  | 10 | Estática | Estática |
  | 20 | Investida Faiscante | Investida Faiscante |
  | 38 | — | Avalanche Estática |

## Fora do escopo

- Uma marca de estática no chão, que pediria o desenho animado dela.
- O ícone, o efeito e o som das quatro Técnicas.

## Critérios de aceite

- [x] O `CatalogValidator` aceita as Técnicas novas (o jogo sem janela abre sem erro).
- [x] O F1 as mostra na aba Técnicas, e o Testar técnica usa a Estática, que paralisa, e a Avalanche Estática, que deixa a geada.
- [x] Os testes de unidade e os e2e do servidor passam, menos as falhas antigas.
