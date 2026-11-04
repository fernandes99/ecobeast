# progression — arquitetura

O desenho que as quatro fases compartilham. As regras moram em funções puras em `server/src/domain/progression/`, sem Nest nem banco, como o resto de `server/src/domain/`. O jogo só mostra o que o servidor devolveu e envia as escolhas do jogador.

## Quem recebe XP

- O XP nasce quando um Ecobeast inimigo desmaia. Hoje há um inimigo só, então isso acontece uma vez, no fim da luta. A regra já vale por inimigo para a `npc-tamers`, que terá vários.
- Cada inimigo guarda `foughtBy: number[]`, os índices da equipe do jogador que estiveram em campo contra ele. Quando um inimigo entra, a lista começa com o Ecobeast do jogador que está em campo. Quando um Ecobeast do jogador entra, seja no começo, numa troca ou depois de um desmaio, o índice dele entra na lista do inimigo em campo. Não há repetição.
- Quando o inimigo desmaia, recebem XP os índices de `foughtBy` com `currentHp > 0` e nível menor que 100. Quem desmaiou antes ou está no nível 100 fica de fora e não conta na divisão.
- Total: `xpYield(xp_base, nível do inimigo) = floor(xp_base × nível ÷ 7)`, em que `xp_base` é o `species.base_xp_yield` do inimigo. A parte de cada um é `max(1, floor(total ÷ quantidade))`.
- Se ninguém puder receber, por exemplo se todos estiverem no nível 100, ninguém recebe, e não sai evento.
- Captura, fuga e derrota não dão XP. Na captura e na fuga o inimigo não desmaia, então a regra já cobre os dois casos.

Os números são _a revisar_. Como referência, com as curvas atuais (Média = n³), a tabela abaixo mostra quantas vitórias sozinho são precisas contra um selvagem do mesmo nível:

| Passo | XP que falta | XP por vitória | Vitórias |
| --- | --- | --- | --- |
| Ruvo, do nível 5 para o 6, contra um base de nível 5 (xp_base 62) | 91 | 44 | 3 |
| Do nível 15 para o 16, contra um base de nível 15 | 721 | 132 | 6 |
| Ruvak, do nível 35 para o 36, contra um Ruvak de nível 35 (xp_base 142) | 3.781 | 710 | 6 |

Com dois participantes, cada um recebe metade, e as vitórias dobram.

## Nível e stats

- O XP total do nível `n` é `totalXpForLevel(xp_multiplier, n)`, que já existe em `server/src/domain/rules/xp-curve.ts`. O XP soma no `current_xp`, que é o XP total, e não o XP dentro do nível. O nível novo é o maior `n` com `totalXpForLevel(n) ≤ current_xp`, e o XP para no total do nível 100 (`MAX_LEVEL`).
- Os stats vêm do `calculateStats` (`server/src/domain/rules/stat-calculator.ts`) com o nível novo. O HP atual sobe o mesmo tanto que o HP máximo: com 10 de 28, quem ganha +3 fica com 13 de 31. Só quem tem HP acima de 0 recebe XP, então ninguém volta de um desmaio por subir de nível.
- Pular mais de um nível de uma vez é um resultado só, de `level_before` para `level_after`, e não um por nível.
- O nível e os stats só mudam no fim da luta. O XP de cada desmaio é somado em `xpEarned`, e quem subiu não fica mais forte no meio da mesma luta. Isso importa só quando houver vários inimigos.

## Técnicas

- **Quais:** as linhas de `species_skills` com método `level_up` e `level_before < level ≤ level_after`, na ordem do nível e depois do `skill_id`. Na evolução aceita, entram as linhas de método `evolution` da espécie nova, que hoje são de nível 0, e depois as `level_up` dessa espécie no mesmo intervalo. Uma Técnica que o Ecobeast já conhece ou que se repete na lista sai dela.
- **Com vaga:** enquanto houver menos de 4 Técnicas, a próxima da lista é aprendida, com o PP cheio (`max_pp`), na primeira vaga livre. Isso vai para `learned_skill_ids`.
- **Sem vaga:** as que sobram vão para `pending_skill_ids`. Para cada uma, o jogador escolhe uma Técnica para esquecer, e a nova entra na mesma vaga com o PP cheio, ou escolhe não aprender. Não aprender é definitivo, e a Técnica não é oferecida de novo.
- Só o servidor sabe o que está pendente. O jogo não consegue ensinar uma Técnica que não foi oferecida.

## Evolução

- **Oferta:** quando `level_after > level_before`, a espécie tem uma linha de `evolutions` com o gatilho `level` e `level_after ≥ min_level`. Se houver mais de uma linha, vale a de menor `id`. Quem cancelou numa luta recebe a oferta de novo no próximo nível, porque a regra só olha o nível. Não existe uma recusa gravada.
- **Com oferta,** as Técnicas da luta só são calculadas depois da escolha. Por isso, nesse caso, `learned_skill_ids` e `pending_skill_ids` vêm vazios no fim da luta.
- **Evoluir:**
  - O `species_id` muda para a espécie nova. O apelido, o nível, o XP, os Genes, o Treino, o Temperamento, o Vínculo, o status e as Técnicas continuam.
  - O Traço vai para a linha de `species_traits` da espécie nova com o mesmo `slot` e o mesmo `is_hidden` da linha antiga. Sem essa linha, vai para a de slot 1 não oculta, depois para a primeira não oculta, e, sem nenhuma, fica o Traço atual.
  - Os stats são recalculados, e o HP atual sobe o mesmo tanto que o máximo, e pelo menos 1.
  - Depois, as Técnicas da espécie nova seguem a regra acima.
- **Cancelar:** a espécie fica a mesma, e as Técnicas seguem a regra acima com a espécie antiga.

## Escolhas pendentes

- `ProgressionStore` (`server/src/progression/progression.store.ts`) fica em memória, como o `ExplorationStore`, com uma entrada por jogador e 2 h sem uso. Cada entrada é um `Map` de `uid` para `{ evolutionSpeciesId: number | null, levelBefore, levelAfter, pendingSkillIds: number[] }`.
- O fim de uma vitória substitui a entrada inteira do jogador, então uma escolha não feita da luta anterior se perde.
- O `uid` sai do mapa quando não sobra nada pendente para ele.
- Se o servidor reiniciar ou a entrada expirar, a evolução volta no próximo nível, e uma Técnica não escolhida conta como "Não aprender".

## Contrato

O fim da luta (`POST /v1/me/battle/action`) ganha:

- **O evento `xp_gained`**, `{ type: 'xp_gained', team_index, amount }`, logo depois do `fainted` do inimigo, um para cada Ecobeast que recebeu, na ordem do índice.
- **`progression`** na resposta. Na vitória, é a lista de quem recebeu XP, na ordem do `team_index`. Nos outros resultados e no meio da luta, é `[]`.

```jsonc
{
  "uid": "…",
  "team_index": 0,
  "xp_gained": 42,
  "level_before": 11,
  "level_after": 12,
  "current_xp": 1750,     // XP total, já gravado (era 1708, no nível 11)
  "level_xp": 1728,       // XP total do nível atual
  "next_level_xp": 2197,  // nulo no nível 100
  "stats_before": { "hp": 28, "atk": 17, "def": 14, "sp_atk": 16, "sp_def": 13, "spd": 19 },
  "stats_after":  { "hp": 31, "atk": 19, "def": 15, "sp_atk": 18, "sp_def": 14, "spd": 21 },
  "evolution": { "species_id": 2 },   // ou null
  "learned_skill_ids": [5],
  "pending_skill_ids": [6]
}
```

O XP, o nível, os stats e o HP de todos, e as Técnicas aprendidas com vaga, são gravados na mesma transação que já guarda o HP, o PP e os itens da luta (`BattleService.saveTeam`).

As rotas das escolhas ficam em `server/src/progression/progression.controller.ts`, sob `me`:

| Rota | Corpo | Resposta 200 |
| --- | --- | --- |
| `POST /v1/me/creatures/:uid/evolution` | `{ "accept": true }` | `{ creature, learned_skill_ids, pending_skill_ids }` |
| `POST /v1/me/creatures/:uid/skills` | `{ "skill_id": 6, "forget_skill_id": 1 }`, ou `null` para não aprender | `{ creature, pending_skill_ids }` |

`creature` tem o formato do Ecobeast em `GET /v1/me` (`CreatureDto`).

Para testar, `POST /v1/me/debug/xp` deixa a equipe a 1 XP do próximo nível ([04](04-evolution-and-skills-screens.md), RF-14). Só existe com `ENABLE_TEST_BATTLE` ligada.

| Falha | Status | Mensagem |
| --- | --- | --- |
| Corpo inválido, incluindo `forget_skill_id` ausente (para não aprender, ele vem `null`) | 400 | "Escolha inválida." |
| Sem evolução pendente para o `uid`, ou o `skill_id` não está pendente | 404 | "Essa escolha não está mais disponível." |
| `forget_skill_id` não é uma Técnica do Ecobeast | 400 | "Esse Ecobeast não conhece essa Técnica." |
| Há uma evolução pendente e chegou uma escolha de Técnica para o mesmo `uid` | 409 | "Escolha primeiro se ele vai evoluir." |

## No jogo

- O jogo segue a resposta, em ordem: o log mostra "Nilu selvagem foi derrotado." e depois uma linha "Ruvo recebeu 42 de XP." para cada `xp_gained`. A barra de XP do Ecobeast em campo enche até o valor novo. Se ele subiu de nível, a barra enche até o fim, volta a zero e enche de novo.
- Depois do log e antes do botão "Voltar", abre por cima da batalha, para cada item de `progression` que subiu de nível, na ordem:
  1. A tela de comemoração.
  2. A tela de evolução, se houver `evolution`.
  3. "Ruvo aprendeu X!" para cada Técnica aprendida.
  4. A escolha de cada Técnica pendente.
- Os textos usam o apelido, quando houver, e senão o nome da espécie. Depois da evolução, sem apelido, o nome passa a ser o da espécie nova.
- No fim, o "Voltar" recarrega o jogador (`Session.load_player`), como já faz depois de uma luta, e a Equipe, o Hub e os detalhes mostram o nível novo.
- O nível médio que a exploração usa para os Ecobeasts do mapa continua sendo o do começo da exploração. Ele muda na próxima exploração.
