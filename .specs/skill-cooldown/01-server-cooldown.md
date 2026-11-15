# 01. O countdown no servidor e as 3 Técnicas

- **Status:** concluída (falta o dono jogar)
- **Depende de:** [board-battle](../board-battle/README.md), [progression](../progression/README.md)

## Contexto

O countdown é uma regra da luta, então quem conta é o servidor ([README](README.md)). Esta fase põe a coluna no catálogo, a regra no motor do tabuleiro e na IA, o limite de 3 Técnicas e a remoção da vaga 4. O cliente só passa a ler os campos novos. A barra de ícones fica para a [02](02-skill-bar.md).

## Escopo

- A coluna `skills.cooldown`, com os valores iniciais.
- O countdown no motor do tabuleiro e na IA dos selvagens e Domadores NPC.
- `cooldown_left` no estado da luta e a recusa da Técnica bloqueada.
- O limite de 3 Técnicas e a migration que apaga a vaga 4.
- O cliente lendo `cooldown` e `cooldown_left`, com a vaga bloqueada desabilitada no botão de hoje e 3 vagas na luta e nos Detalhes.

## Fora do escopo

- A barra de ícones e o detalhe ao segurar ([02](02-skill-bar.md)).
- O countdown nos Detalhes do Ecobeast. (O F1 ganhou a linha "Countdown" depois, a pedido do dono.)

## Requisitos

- **RF-01:** A tabela `ecobeasts.skills` tem a coluna `cooldown` (int, não nula, padrão 0, CHECK 0 a 5).
- **RF-02:** A migration preenche `cooldown` pelo poder (_a revisar_): `power = 0` → 2; 1 a 50 → 0; 51 a 80 → 1; 81 a 110 → 2; acima de 110 → 3. O `seed-data/skills.json` acompanha.
- **RF-03:** `GET /v1/catalog` e `GET /v1/skills` devolvem `cooldown` em cada Técnica.
- **RF-04:** Ao usar uma Técnica da vaga S na rodada R, a vaga guarda `readyRound = R + cooldown + 1`.
- **RF-05:** A vaga só pode ser escolhida quando `state.round >= readyRound`. Uma vaga sem `readyRound` está livre. Escolher uma vaga bloqueada é recusado com "Essa Técnica ainda não voltou."
- **RF-06:** O countdown corre a cada rodada, com o Ecobeast em campo ou na reserva, e não sai da luta.
- **RF-07:** A IA (`board-ai.ts`) só considera as vagas com PP e livres. Sem nenhuma, ela anda e espera, e só usa a emergência quando todas estão sem PP (`hasPp`), como hoje.
- **RF-08:** A Técnica de emergência continua liberada só quando nenhuma vaga tem PP. Vagas bloqueadas por countdown, mas com PP, não liberam a emergência.
- **RF-09:** Cada Técnica de `player.team[].skills[]` no estado da luta tem `cooldown_left = max(0, readyRound - state.round)`.
- **RF-10:** Um Ecobeast novo (selvagem, de Domador NPC ou inicial) nasce com no máximo 3 Técnicas, as 3 mais recentes da lista dele.
- **RF-11:** Ao aprender uma Técnica com 3 já conhecidas, o jogador escolhe qual esquecer ou desiste, pelo fluxo de hoje.
- **RF-12:** A migration apaga as linhas `slot = 4` de `creature_instance_skills` e troca o CHECK para `slot BETWEEN 1 AND 3`.
- **RF-13:** O cliente lê `cooldown` no modelo `Skill`, com o `CatalogValidator` conferindo 0 a 5, e `cooldown_left` no `SkillSlot` (0 quando não vier).
- **RF-14:** Na luta, o botão de Técnica de hoje fica desabilitado com `cooldown_left > 0` e mostra "volta em N" no lugar do PP. A grade passa a ter 3 botões.
- **RF-15:** A tela Detalhes do Ecobeast mostra 3 vagas.

## Critérios de aceite

- [x] Depois da migration, nenhuma linha de `creature_instance_skills` tem `slot` 4, e inserir uma é recusado pelo banco.
- [x] O catálogo baixado tem `cooldown` em todas as Técnicas, e o jogo abre sem erro de dados.
- [x] Num teste do motor, uma Técnica com countdown 1 usada na rodada 1 é recusada na rodada 2 e aceita na 3.
- [x] Num teste do motor, uma Técnica com countdown 0 pode ser usada em todas as rodadas.
- [x] Num teste da IA, um selvagem com a única Técnica de dano bloqueada não a usa e não usa a emergência.
- [x] Um Ecobeast criado pelo `creature-factory` tem no máximo 3 Técnicas.
- [x] Com 3 Técnicas conhecidas, aprender uma nova pede a troca.
- [ ] Na luta (F5), depois de usar uma Técnica com countdown, o botão dela fica desabilitado com "volta em N" e volta a ficar livre na rodada certa.

## Desenho técnico

O desenho compartilhado está no [architecture.md](architecture.md).

**Criar:**
- A migration `server/prisma/migrations/<data>_skill_cooldown/migration.sql`, escrita à mão e aplicada com `migrate deploy`. Ela adiciona a coluna, preenche pelo poder, apaga a vaga 4 e troca o CHECK.

**Alterar no servidor:**
- `server/prisma/schema.prisma`: `cooldown` em `Skill`, com o comentário do CHECK. Em `CreatureInstanceSkill`, o comentário do CHECK de `slot` passa a dizer 1–3.
- `server/prisma/seed-data/skills.json`: `cooldown` em cada Técnica.
- `server/src/catalog/skills/skills.resource.ts`: expor `cooldown`.
- `server/src/battle/battle-catalog.ts` e `server/src/domain/battle/types.ts`: `cooldown` em `BattleSkill`, e `readyRound?: number` em `CombatantSkill`.
- `server/src/domain/battle/emergency.ts`: `cooldown: 0` em `EMERGENCY_SKILL`.
- `server/src/domain/board/board-engine.ts`:
  - `useSkill` grava `readyRound`.
  - `actionRefusal` recusa a vaga bloqueada.
- `server/src/domain/board/board-ai.ts`: o filtro `usable` também exige a vaga livre.
- `server/src/battle/battle.mapper.ts`: `cooldown_left` em cada Técnica do time.
- `server/src/domain/rules/creature-factory.ts` e `server/src/domain/progression/learnset.ts`: `MAX_SKILLS = 3`.
- Os testes: `board-engine.spec.ts`, `board-ai.spec.ts`, `creature-factory.spec.ts`, os de `learnset`, o `catalog.e2e-spec.ts` e o `board-battle.e2e-spec.ts`. Ajuste também os que montam Ecobeasts com 4 Técnicas.

**Alterar no cliente:**
- `res://domain/models/skill.gd`: `cooldown`.
- `res://core/data/catalog_schema.gd`: `"cooldown": {"type": "int", "min": 0, "max": 5}`.
- `res://domain/models/skill_slot.gd`: `cooldown_left`.
- `res://screens/board_battle/battle_skill_button.gd`: desabilitado e "volta em N".
- `res://screens/board_battle/board_battle_screen.gd`: `SKILL_SLOTS := 3`, e a grade em 3 colunas ou 3 linhas.
- `res://screens/creature_details/creature_details_screen.gd`: `SKILL_SLOTS := 3`.

**Alterar nos documentos:**
- `GDD.md` e `TELAS.md`: "4 técnicas" passa a ser 3, e o countdown entra nas regras de batalha.

## Verificação

```bash
cd server && npx prisma migrate deploy && npx prisma generate
cd server && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```

À mão (F5): numa luta de selvagem, usar uma Técnica com countdown 1 e conferir o botão desabilitado com "volta em 1" na rodada seguinte e livre na outra. Abrir os Detalhes de um Ecobeast e ver 3 vagas.

## Tarefas

- [x] Migration, `schema.prisma` e `seed-data`.
- [x] `cooldown` no catálogo e no `BattleSkill`.
- [x] `readyRound`, a recusa e `cooldown_left` no motor e no mapeador.
- [x] A IA respeitando o countdown.
- [x] `MAX_SKILLS = 3` e os testes.
- [x] O cliente: modelos, validador, botão e as 3 vagas.
- [x] GDD e TELAS.
- [x] Testes do servidor e jogo sem janela.
- [ ] O passo à mão, com o dono.

## Resultado da verificação

Em 2026-11-15:

- **Banco:** a migration `20261130000000_skill_cooldown` foi aplicada com `migrate deploy`, e o `migrate diff` depois dela ficou vazio. Na API, a Erupção Solar (poder 120) veio com `cooldown` 3.
- **Testes:** os de unidade passam, com os casos novos em `cooldown.spec.ts`, `board-engine.spec.ts` e `board-ai.spec.ts`. O lint e o typecheck também passam. Os e2e do catálogo e da luta passam, e a suíte e2e inteira rodou antes de fechar.
- **Jogo:** com o servidor novo, o catálogo baixou sem erro no `CatalogValidator`, e o jogo sem janela abre sem erros de script.
- **Divergência:** o RF-14 ("volta em N" no botão retangular) foi feito direto no botão em ícone da [02](02-skill-bar.md), que entrou junto. O número de rodadas aparece em destaque sobre o ícone.
- **Falta o dono:** jogar uma luta e conferir o countdown com F5.
