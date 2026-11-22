# 02. As Técnicas de Metal

- **Status:** concluída
- **Depende de:** [01-snelt-line](01-snelt-line.md)

## Contexto

O catálogo tem quatro Técnicas de Metal, três Físicas de contato (Pinça de Aço, Martelo de Ferro e Garra de Picareta) e a Couraça, e nenhuma Especial. Claude propôs quatro para o caracol-fornalha, sem regra nova no motor: um tiro fraco de longe, um jato médio que pode queimar, a têmpera que sobe a Defesa e o Ataque Especial de uma vez e o golpe forte que despeja metal derretido num leque e deixa o chão em chamas, como a Chama Espiral. Os números são _a revisar_.

## Escopo

- A migração `20270203000001_metal_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Requisitos

- **RF-01:** Quatro Técnicas de Metal (8), com prioridade 0, um golpe e sem contato:

  | id | slug | name | Categoria | Alvo | Poder | Precisão | Alcance | Área | PP | Cooldown | Marca |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 114 | `estilhaco` | Estilhaço | Especial | Inimigo | 40 | 100 | 3 | 2 | 25 | 0 | — |
  | 115 | `jato_de_escoria` | Jato de Escória | Especial | Inimigo | 75 | 95 | 3 | 2 | 15 | 2 | — |
  | 116 | `tempera` | Têmpera | Status | Si mesmo | 0 | 0 | 1 | 1 | 15 | 3 | — |
  | 117 | `metal_fundido` | Metal Fundido | Especial | Inimigo | 110 | 85 | 2 | 3 | 5 | 3 | Chão em chamas (1), 4 vezes |

  A área 2 é a linha reta das Técnicas de longe, como o Lampejo; a 3 é o triângulo da Chama Espiral.

  Descrições:
  - **Estilhaço:** "Atira uma lasca de ferro quente da concha num inimigo a até 3 hexágonos."
  - **Jato de Escória:** "Cospe um jato de escória fervendo a até 3 hexágonos. Pode deixar o alvo Queimado."
  - **Têmpera:** "Esquenta e esfria a concha de uma vez só, até ela ficar perfeita. Aumenta a Defesa e o Ataque Especial."
  - **Metal Fundido:** "Abre a fornalha e despeja metal derretido num leque à frente, a até 2 hexágonos. O chão fica em chamas."

- **RF-02:** Os efeitos em `skill_effects`, de 77 a 79: o Queimado (1) do Jato de Escória, com 20% de chance, e o +1 da Defesa (3) e o +1 do Ataque Especial (4) da Têmpera em si (alvo 2).
- **RF-03:** Os learnsets novos, além dos da [fase 1](01-snelt-line.md). O Magmollusk aprende o Metal Fundido ao evoluir (método 2, nível 0):

  | Nível | Snelt | Smeltrudge | Magmollusk |
  | --- | --- | --- | --- |
  | 0 (ao evoluir) | — | — | Metal Fundido |
  | 1 | Estilhaço | Estilhaço | Estilhaço |
  | 12 | Têmpera | Têmpera | Têmpera |
  | 20 | Jato de Escória | Jato de Escória | Jato de Escória |
  | 44 | — | — | Metal Fundido |

## Fora do escopo

- Uma marca de metal derretido no chão, que pediria o desenho animado dela.
- O ícone, o efeito e o som das quatro Técnicas.

## Critérios de aceite

- [x] O `CatalogValidator` aceita as Técnicas novas (o jogo sem janela abre sem erro).
- [x] O F1 as mostra na aba Técnicas, e o Testar técnica usa o Metal Fundido, que deixa o chão em chamas.
- [x] Os testes de unidade e os e2e do servidor passam, menos as falhas antigas (veja a [fase 1](01-snelt-line.md#critérios-de-aceite)).
