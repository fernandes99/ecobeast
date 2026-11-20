# 03. As Técnicas de Inseto e de Luz

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02-prayling-line](02-prayling-line.md)

## Contexto

Não há nenhuma Técnica de Inseto nem de Luz no catálogo, e a linha do louva-a-deus luta na fase 2 com Técnicas de Instinto, de Flora, de Sombra e de Vento. Claude propôs cinco Técnicas, e o dono aprovou ("Sim, fase 3"), sem regra nova no motor: o Amedrontado (`flinch`), o Atordoado (`dazed`) e a mudança de atributo já existem. Os números são _a revisar_.

## Requisitos

- **RF-01:** Cinco Técnicas, todas com prioridade 0, um golpe e cooldown em rodadas:

  | id | slug | name | Elemento | Categoria | Alvo | Poder | Prec | PP | Alcance | Contato | Cooldown | Efeito |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 84 | `golpe_de_foice` | Golpe de Foice | Inseto | Físico | Inimigo | 55 | 100 | 25 | 1 | sim | 0 | Crítico +1 |
  | 85 | `emboscada` | Emboscada | Inseto | Físico | Inimigo | 75 | 100 | 15 | 1 | sim | 2 | 30%: Amedrontado |
  | 86 | `danca_da_foice` | Dança da Foice | Inseto | Suporte | Si mesmo | 0 | 0 | 10 | 1 | não | 3 | +2 Atq em si |
  | 87 | `raio_de_sol` | Raio de Sol | Luz | Especial | Inimigo, linha | 70 | 100 | 15 | 3 | não | 1 | 20%: Atordoado |
  | 88 | `lamina_solar` | Lâmina Solar | Luz | Físico | Inimigo | 90 | 95 | 10 | 1 | sim | 2 | 30%: −1 Precisão no alvo |

  Descrições:
  - **Golpe de Foice:** "Corta com a foice dobrada, rápido como um bote. Acerta um golpe crítico com mais facilidade."
  - **Emboscada:** "Espera imóvel e ataca de surpresa. Pode deixar o alvo Amedrontado."
  - **Dança da Foice:** "Afia as foices num movimento lento e preciso. Aumenta muito o Ataque."
  - **Raio de Sol:** "Junta a luz do sol nas asas e dispara um raio no primeiro da linha, a até 3 hexágonos. Pode deixar o alvo Atordoado."
  - **Lâmina Solar:** "Golpeia com a foice acesa como o sol, que ofusca o alvo. Pode baixar a Precisão."

- **RF-02:** O crítico do Golpe de Foice é o `crit_stage` 1, como o da Lâmina Sombria, sem efeito. Os efeitos (`skill_effects`), do 58 ao 61: o Amedrontado da Emboscada é o `flinch`, o +2 de Ataque da Dança da Foice é um `modify_stat` em si mesmo, o Atordoado do Raio de Sol é o `apply_status` com o `dazed`, e a Lâmina Solar tem um `modify_stat` de −1 na Precisão do alvo. A Técnica em si mesma tem alcance 1, como a Dança do Vento.
- **RF-03:** Nos learnsets, além dos da fase 2:

  | Nível | Prayling | Mantorn | Solantis | Umbrantis |
  | --- | --- | --- | --- | --- |
  | 0 | — | — | Lâmina Solar | — |
  | 9 | Golpe de Foice | Golpe de Foice | Golpe de Foice | Golpe de Foice |
  | 20 | — | Emboscada | Emboscada | Emboscada |
  | 30 | — | Dança da Foice | Dança da Foice | Dança da Foice |
  | 40 | — | — | Raio de Sol | — |

## Escopo

- A migração `20270116000001_insect_light_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Fora do escopo

- O ícone, o efeito e o som das Técnicas novas.

## Critérios de aceite

- [x] As rotas `/v1/skills/<slug>` das 5 Técnicas respondem 200.
- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` aceita o catálogo.
- [x] Testes de unidade do servidor passam (a fase não muda código), menos os do `map-generator.spec.ts`, que falham pelas mudanças da `map-realism` em andamento noutra sessão.
- [ ] No F1, as 5 Técnicas aparecem com os dados do RF-01, e na luta elas acertam e aplicam os efeitos.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test
godot --headless -d --path client --quit-after 240
```

## Tarefas

- [x] A migração das 5 Técnicas, dos efeitos e dos learnsets.
- [x] README, índice das specs, roadmap e `CLAUDE.md`.
