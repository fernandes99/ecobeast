# 02. As Técnicas de Luz

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-glimshell-line](01-glimshell-line.md) e o alvo "Meu time" da [skill-editor](../skill-editor/)

## Contexto

O catálogo só tem duas Técnicas de Luz, o Raio de Sol e a Lâmina Solar. Claude propôs quatro para o jabuti, sem regra nova no motor: um ataque fraco de longe, o casco que sobe muito a Defesa Especial (como a Couraça, que sobe a Defesa), o halo que protege um aliado (como a Atadura Firme) e o raio forte que enfraquece o Ataque Especial do inimigo (como a Geada Silenciosa, que baixa a Velocidade). Os números são _a revisar_.

## Escopo

- A migração `20270129000001_light_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Requisitos

- **RF-01:** Quatro Técnicas de Luz, com prioridade 0, um golpe e sem contato:

  | id | slug | name | Categoria | Alvo | Poder | Precisão | Alcance | Área | PP | Cooldown | Efeito |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 106 | `lampejo` | Lampejo | Especial | Inimigo | 40 | 100 | 3 | 2 | 25 | 0 | — |
  | 107 | `casco_prismatico` | Casco Prismático | Status | Si mesmo | 0 | 0 | 1 | 1 | 10 | 3 | +2 Def.E em si |
  | 108 | `halo_protetor` | Halo Protetor | Status | Meu time | 0 | 0 | 2 | 1 | 15 | 3 | +2 Def.E no aliado |
  | 109 | `raio_prismatico` | Raio Prismático | Especial | Inimigo | 90 | 95 | 4 | 2 | 10 | 3 | 30%: −1 Atq.E no alvo |

  A área 2 é a das Técnicas de longe, como o Raio de Sol.

  Descrições:
  - **Lampejo:** "Solta um brilho rápido da pedra do casco num inimigo a até 3 hexágonos."
  - **Casco Prismático:** "Recolhe-se no casco, que brilha e desvia a energia. Aumenta muito a Defesa Especial."
  - **Halo Protetor:** "Projeta um halo de luz em volta de um aliado a até 2 hexágonos. Aumenta muito a Defesa Especial dele."
  - **Raio Prismático:** "Junta a luz no casco e dispara um raio de arco-íris a até 4 hexágonos. Pode baixar o Ataque Especial do alvo."

- **RF-02:** Os efeitos em `skill_effects`, de 71 a 73: o +2 da Defesa Especial (5) do Casco Prismático em si (alvo 2), o do Halo Protetor no aliado (alvo 4) e o −1 do Ataque Especial (4) do Raio Prismático no inimigo (alvo 1), com 30% de chance.
- **RF-03:** Os learnsets novos, além dos da [fase 1](01-glimshell-line.md). O Lumoshell aprende o Halo Protetor ao evoluir, e o Prismback o Raio Prismático:

  | Nível | Glimshell | Lumoshell | Prismback |
  | --- | --- | --- | --- |
  | 0 (ao evoluir) | — | Halo Protetor | Raio Prismático |
  | 1 | Lampejo | Lampejo | Lampejo |
  | 7 | Casco Prismático | Casco Prismático | Casco Prismático |
  | 22 | Halo Protetor | Halo Protetor | Halo Protetor |
  | 40 | — | Raio Prismático | Raio Prismático |

## Fora do escopo

- Uma marca de luz no chão, que pediria o desenho animado dela.
- O ícone, o efeito e o som das quatro Técnicas.

## Critérios de aceite

- [x] O dono mandou seguir com a linha.
- [x] O `CatalogValidator` aceita as Técnicas novas (o jogo sem janela abre sem erro).
- [ ] O F1 as mostra na aba Técnicas, e o Testar técnica de 2×2 usa o Halo Protetor num aliado.
- [x] Os testes de unidade e os e2e do servidor passam, menos as falhas antigas (veja a [fase 1](01-glimshell-line.md#critérios-de-aceite)).
