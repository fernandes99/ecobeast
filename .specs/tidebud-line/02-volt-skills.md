# 02. As Técnicas de Volt

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-tidebud-line](01-tidebud-line.md)

## Contexto

O catálogo não tinha nenhuma Técnica de Volt, e a linha do Tidebud usava só as de Água, Flora e Instinto. O dono pediu as de Volt que Claude propôs ([README](README.md#decisões)). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270106000000_volt_skills`, com linhas novas em `ground_effects`, `skills`, `skill_effects` e `species_skills`.
- Nenhuma regra nova no motor: o Paralisado (`paralysis`), as marcas com status e as linhas que atravessam já existem.

## Requisitos

- **RF-01:** A marca nova: `ground_effects` 5, `electric_tide`, "Maré Elétrica", sem dano, com o status Paralisado (3), cor `#3FA9F5`. Quem termina a vez nela fica Paralisado, pela mesma regra do Redemoinho, e Volt é imune ao Paralisado (`status_condition_immunities`).
- **RF-02:** Quatro Técnicas de Volt, todas com prioridade 0, crítico 0, um golpe, sem contato, alvo Inimigo e forma linha reta:

  | id | slug | name | Categoria | Poder | Prec | PP | Alcance | Atravessa | Marca | Cooldown | Efeito |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 62 | `faisca_de_alga` | Faísca de Alga | Especial | 40 | 100 | 25 | 3 | não | — | 0 | 10%: Paralisado |
  | 63 | `corrente_viva` | Corrente Viva | Especial | 75 | 95 | 15 | 4 | sim | — | 2 | 10%: Paralisado |
  | 64 | `mare_eletrica` | Maré Elétrica | Suporte | 0 | 0 | 10 | 3 | sim | Maré Elétrica (5), por 4 vezes | 3 | — |
  | 65 | `tempestade_de_algas` | Tempestade de Algas | Especial | 110 | 90 | 5 | 5 | sim | — | 3 | 30%: Paralisado |

  Descrições:
  - **Faísca de Alga:** "Solta uma faísca pelas folhas no primeiro da linha, a até 3 hexágonos. Pode deixar o alvo Paralisado."
  - **Corrente Viva:** "Uma corrente elétrica corre pela água e atravessa a fileira inteira, a até 4 hexágonos. Pode deixar Paralisado."
  - **Maré Elétrica:** "Eletrifica a água numa fileira. Quem para nela fica Paralisado, menos quem é de Volt."
  - **Tempestade de Algas:** "Chama uma tempestade de raios que varre a fileira inteira, a até 5 hexágonos. Tem boa chance de deixar Paralisado."

- **RF-03:** Os efeitos (`skill_effects`, `apply_status`, Paralisado, sem alvo próprio, como a queimadura da Faísca Rápida): 43 na Faísca de Alga (10%), 44 na Corrente Viva (10%) e 45 na Tempestade de Algas (30%).
- **RF-04:** Entram nos learnsets, além dos da [fase 1](01-tidebud-line.md#learnsets). A Corrente Viva no Kelpcoil e a Tempestade de Algas no Tempestide são aprendidas ao evoluir (`evolution`, nível 0):

  | Nível | Tidebud | Kelpcoil | Tempestide |
  | --- | --- | --- | --- |
  | 0 | — | Corrente Viva | Tempestade de Algas |
  | 1 | — | — | Corrente Viva |
  | 3 | Faísca de Alga | Faísca de Alga | Faísca de Alga |
  | 26 | — | Maré Elétrica | Maré Elétrica |

## Fora do escopo

- O ícone, o efeito e o som das Técnicas novas e o desenho da Maré Elétrica no tabuleiro: até lá, a marca é o hexágono tingido com a cor dela.
- O ícone do Elemento Volt (`assets/ui/elements/volt/`), que ainda não existe, como o do Vento.

## Critérios de aceite

- [x] Num teste temporário com o catálogo da luta lido do banco, já apagado:
  - a Faísca de Alga acertou só o primeiro da linha;
  - a Corrente Viva e a Tempestade de Algas acertaram os dois da fileira;
  - a Maré Elétrica pôs a marca em 3 casas, e o inimigo acordado que terminou a vez nela ficou Paralisado, mas o de Volt não.
- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` aceita o catálogo.
- [x] Lint, typecheck e testes de unidade do servidor passam.
- [ ] No F1, as 4 Técnicas aparecem com os dados do RF-02.
- [ ] Numa luta com um Kelpcoil, a Maré Elétrica pinta a fileira de azul, e quem para nela fica Paralisado.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test
godot --headless -d --path client --quit-after 240
```
