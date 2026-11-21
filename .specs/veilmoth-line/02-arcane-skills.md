# 02. As Técnicas de Arcano

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-veilmoth-line](01-veilmoth-line.md) e o estado Atordoado da [puffcoo-line](../puffcoo-line/)

## Contexto

O catálogo não tem nenhuma Técnica de Arcano. Claude propôs três para a mariposa, sem regra nova no motor: um ataque fraco de longe, o olhar dos olhos-portal que deixa Atordoado (como o Olhar da Lua, da [lume-line](../lume-line/)) e o vórtice forte do Gatemoth. O Teleporte é a [fase 3](03-teleport.md). Os números são _a revisar_.

## Escopo

- A migração `20270130000001_arcane_skills`, com linhas novas em `skills`, `skill_effects` e `species_skills`.

## Requisitos

- **RF-01:** Três Técnicas de Arcano (14), com prioridade 0, um golpe e sem contato:

  | id | slug | name | Categoria | Alvo | Poder | Precisão | Alcance | Área | PP | Cooldown | Efeito |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 110 | `po_arcano` | Pó Arcano | Especial | Inimigo | 40 | 100 | 3 | Um alvo | 25 | 0 | — |
  | 111 | `olhar_do_veu` | Olhar do Véu | Status | Inimigo | 0 | 90 | 3 | Um alvo | 15 | 3 | Atordoado no alvo |
  | 112 | `vortice_do_portal` | Vórtice do Portal | Especial | Inimigo | 90 | 95 | 4 | Linha reta | 10 | 3 | 20%: Atordoado no alvo |

  Descrições:
  - **Pó Arcano:** "Sacode as asas e sopra um pó violeta brilhante num inimigo a até 3 hexágonos."
  - **Olhar do Véu:** "Abre os olhos-portal das asas, e o alvo a até 3 hexágonos se perde olhando para dentro deles. Deixa Atordoado."
  - **Vórtice do Portal:** "Abre um portal giratório que puxa tudo na linha, a até 4 hexágonos. Pode deixar o alvo Atordoado."

- **RF-02:** Os efeitos em `skill_effects`, 74 e 75: Aplicar status (1) Atordoado (9), sem coluna de alvo (o `apply_status` vai em quem a Técnica atinge), com 100% no Olhar do Véu e 20% no Vórtice do Portal. O Vento continua imune ao Atordoado.
- **RF-02b:** Antes de gravar, confira no banco os maiores ids de `skills` e `skill_effects`. Em 2026-11-21 eram 109 e 73.
- **RF-03:** Os learnsets novos, além dos da [fase 1](01-veilmoth-line.md). O Gatemoth aprende o Vórtice do Portal ao evoluir (método 2, nível 0):

  | Nível | Veilmoth | Gatemoth |
  | --- | --- | --- |
  | 0 (ao evoluir) | — | Vórtice do Portal |
  | 1 | Pó Arcano | Pó Arcano |
  | 9 | Olhar do Véu | Olhar do Véu |
  | 38 | — | Vórtice do Portal |

## Fora do escopo

- O ícone, o efeito e o som das três Técnicas.
- Uma marca de Arcano no chão, que pediria o desenho animado dela.

## Critérios de aceite

- [x] O `CatalogValidator` aceita as Técnicas novas (o jogo sem janela abre sem erro).
- [ ] O F1 as mostra na aba Técnicas, e o Testar técnica com o Olhar do Véu deixa o alvo Atordoado.
- [x] Os testes de unidade e os e2e do servidor passam, menos as falhas antigas.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```

Depois, no F1, o Testar técnica com cada uma das três.

## Tarefas

- [x] Conferir os maiores ids no banco (109 e 73, como previsto).
- [x] A migração, aplicada com `migrate deploy`.
- [x] A verificação. O `CatalogValidator` recusou a primeira versão, com o alvo no `apply_status`; a migração e o banco foram corrigidos antes do commit.
