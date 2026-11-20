# 02. As Técnicas de Sombra da coruja

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-lume-line](01-lume-line.md)

## Contexto

As duas Técnicas de Sombra do catálogo, a Lâmina Sombria e a Garra do Eclipse, são físicas e de contato, e a linha do Lume é atacante especial e de longe. Claude propôs quatro Técnicas de Sombra para ela, e o dono aprovou ("Sim, faça a fase 2"), sem regra nova no motor: os estados Amedrontado e Atordoado, a mudança de atributo e as linhas que atravessam já existem. Os números são _a revisar_.

## Escopo

- A migração `20270114000001_shadow_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Requisitos

- **RF-01:** Quatro Técnicas de Sombra, todas com prioridade 0, crítico 0, um golpe e sem contato:

  | id | slug | name | Categoria | Alvo | Forma | Poder | Prec | PP | Alcance | Atravessa | Cooldown | Efeito |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 76 | `pena_sombria` | Pena Sombria | Especial | Inimigo | linha | 40 | 100 | 25 | 3 | não | 0 | 10%: Amedrontado |
  | 77 | `olhar_da_lua` | Olhar da Lua | Especial | Inimigo | linha | 70 | 95 | 15 | 3 | não | 2 | 20%: Atordoado |
  | 78 | `voo_silencioso` | Voo Silencioso | Suporte | Si mesmo | um alvo | 0 | 0 | 10 | 1 | não | 3 | +1 Atq.E e +1 Vel em si |
  | 79 | `eclipse_lunar` | Eclipse Lunar | Especial | Inimigo | linha | 110 | 90 | 5 | 4 | sim | 3 | 30%: −1 Def.E no alvo |

  Descrições:
  - **Pena Sombria:** "Dispara uma pena escura no primeiro da linha, a até 3 hexágonos. Pode deixar o alvo Amedrontado."
  - **Olhar da Lua:** "Os olhos brilham como a lua e prendem o alvo no lugar, a até 3 hexágonos. Pode deixá-lo Atordoado."
  - **Voo Silencioso:** "Bate as asas sem nenhum som e se prepara para caçar. Aumenta o Ataque Especial e a Velocidade."
  - **Eclipse Lunar:** "Apaga a lua e atravessa a fileira inteira com a escuridão, a até 4 hexágonos. Pode baixar a Defesa Especial."

- **RF-02:** Os efeitos (`skill_effects`), do 50 ao 54: o Amedrontado da Pena Sombria é o `flinch` (como no Ciclone), o Atordoado do Olhar da Lua é o `apply_status` com o `dazed`, o Voo Silencioso tem os dois `modify_stat` da Dança do Vento em si mesmo, e o Eclipse Lunar um `modify_stat` de −1 na Defesa Especial do alvo. O alcance do Voo Silencioso é 1, como o da Dança do Vento, porque Técnica em si mesma usa 1.
- **RF-03:** Entram nos learnsets, além dos da [fase 1](01-lume-line.md#learnsets):

  | Nível | Lume | Owlume | Noclume |
  | --- | --- | --- | --- |
  | 0 | — | — | Eclipse Lunar |
  | 3 | Pena Sombria | Pena Sombria | Pena Sombria |
  | 22 | Olhar da Lua | Olhar da Lua | Olhar da Lua |
  | 28 | — | Voo Silencioso | Voo Silencioso |
  | 50 | — | Eclipse Lunar | — |

## Fora do escopo

- O ícone, o efeito e o som das Técnicas novas.

## Critérios de aceite

- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` aceita o catálogo.
- [x] Testes de unidade do servidor passam (a fase não muda código, então o lint e o typecheck não mudam).
- [ ] No F1, as 4 Técnicas aparecem com os dados do RF-01.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test
godot --headless -d --path client --quit-after 240
```

## Tarefas

- [x] A migração das 4 Técnicas, dos efeitos e dos learnsets.
- [x] `CLAUDE.md`, README, índice das specs e roadmap.
