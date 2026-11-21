# 03. O Teleporte

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02-arcane-skills](02-arcane-skills.md), a [board-battle](../board-battle/), o alvo "Meu time" da [skill-editor](../skill-editor/) e o Testar técnica da [skill-test](../skill-test/)

## Contexto

O pedido do dono está no [README](README.md#contexto): uma Técnica rara que leva qualquer Ecobeast do campo (o próprio, um aliado ou um inimigo) para qualquer lugar do tabuleiro, com countdown de 3.

Hoje toda Técnica escolhe um hexágono só (`target` da ação `skill`, em `server/src/domain/board/types.ts`), e a área sai do alvo (`areaOf`, em `server/src/domain/board/areas.ts`). O Teleporte pede duas escolhas: quem vai e para onde. Esta fase cria um alvo novo, um efeito novo e o destino na ação, com a tela de dois toques. Os números são _a revisar_.

## Escopo

- A migração `20270130000002_teleport`: o alvo, o efeito, a Técnica e os learnsets.
- O motor da luta, a IA e a rota da luta no servidor.
- O editor de Técnicas do F1 no servidor (`skill-draft.ts`).
- A tela da luta, a conferência do catálogo e o narrador no jogo.

## Fora do escopo

- O ícone, o efeito animado caprichado e o som do Teleporte: esta fase só faz o sumir e aparecer do RF-12.
- O teleporte entre as ilhas pelo altar.
- Outro Ecobeast aprendendo o Teleporte.

## Requisitos

**O catálogo**

- **RF-01:** O alvo 5 de `skill_targets`, `any` ("Qualquer Ecobeast"), e o tipo de efeito 12 de `effect_types`, `teleport` ("Teleportar").
- **RF-02:** A Técnica 113, `teleporte` ("Teleporte"), de Arcano (14), Status, com o alvo Qualquer Ecobeast, poder 0, precisão 0 (não erra), alcance 1 (o mínimo do `CHECK` do banco; o alvo Qualquer Ecobeast não olha o alcance), área Um alvo, PP 5, cooldown 3, prioridade 0, um golpe e sem contato. O efeito 76 de `skill_effects`: Teleportar (12) no alvo (5), com 100%.

  Descrição: "Desfaz em pó violeta um Ecobeast do campo (ele mesmo, um aliado ou um inimigo), que reaparece em qualquer hexágono vazio."

- **RF-03:** O Veilmoth e o Gatemoth aprendem o Teleporte no nível 20 (método 1). Nenhuma outra espécie o aprende.
- **RF-03b:** Antes de gravar, confira no banco os maiores ids de `skill_targets`, `effect_types`, `skills` e `skill_effects`. Em 2026-11-21, depois da [fase 2](02-arcane-skills.md), seriam 4, 11, 112 e 75.

**A regra no servidor**

- **RF-04:** O alvo Qualquer Ecobeast é qualquer Ecobeast de pé no campo, de qualquer lado, o autor incluído, a qualquer distância. O autor conta no hexágono para onde andou nesta vez, como no Meu time.
- **RF-05:** A ação `skill` ganha o campo opcional `destination` (um hexágono). Ele é obrigatório na Técnica com o efeito Teleportar, e nas outras é recusado. Sem ele, a recusa é "Escolha para onde."
- **RF-06:** O destino precisa ser um hexágono do tabuleiro, sem ninguém de pé e diferente de onde o alvo está. Pode ter uma marca no chão. Senão, a recusa é "Esse hexágono não está livre." O hexágono de onde o autor saiu ao andar nesta vez conta como livre.
- **RF-07:** O alvo muda de hexágono na hora, sem andar pelo caminho. Nada mais muda nele: o HP, o estado, as mudanças de atributo e o lugar na fila continuam. O Preso não impede o Teleporte e continua depois dele. A marca do destino age pelas regras de hoje, quando ele terminar a vez nela.
- **RF-08:** Um inimigo Protegido (`isProtected`) não é teleportado. A Técnica conta como usada (gasta o PP e começa o countdown), e o log diz que ele se protegeu, como num ataque.
- **RF-09:** O `skill_used` do Teleporte manda em `cells` o hexágono do alvo e o destino. Depois dele vem o evento novo `teleported`, com `side`, `position`, `from` e `to`.
- **RF-10:** A IA (`board-ai.ts`) só escolhe o Teleporte para fugir: com o HP na metade ou menos e um Ecobeast do jogador a até 2 hexágonos, ela teleporta a si mesma para o hexágono livre mais longe dos Ecobeasts do jogador (no empate, o primeiro na ordem do tabuleiro). Fora disso, ela não o escolhe.

**O F1**

- **RF-11:** O editor de Técnicas (`skill-draft.ts`) aceita o alvo e o efeito novos, com duas regras:
  - o efeito Teleportar só vai numa Técnica com o alvo Qualquer Ecobeast, e o alvo Qualquer Ecobeast só numa Técnica com o efeito Teleportar;
  - com o alvo Qualquer Ecobeast, o poder fica 0 e a área é Um alvo, como no Meu time.

  O Testar técnica funciona com o Teleporte, também num inimigo parado.

**A tela da luta**

- **RF-12:** Escolher o Teleporte acende todos os Ecobeasts de pé, dos dois lados e ele incluído.
  - Tocar num deles o escolhe, com a cor de alvo, e acende os hexágonos livres do campo.
  - Tocar num hexágono livre manda a ação com `target` (quem vai) e `destination`.
  - Tocar de novo no escolhido, ou fora dos acesos, volta à escolha de quem vai.
  - Tocar de novo no botão da Técnica cancela tudo, como hoje.
- **RF-13:** No `teleported`, o Ecobeast some no hexágono de origem em 0,3 s, com pixels violeta e ciano do Arcano (`#a99bff` e `#7fe8ff`) subindo, e aparece no destino do mesmo jeito, ao contrário. O narrador diz "{Nome} se teleportou." quando é o autor, e "{Nome} foi teleportado." quando é outro.
- **RF-14:** O `CatalogValidator` aceita o alvo `any` e o efeito `teleport` nas mesmas regras do RF-11.

## Critérios de aceite

- [x] Testes de unidade do motor (`server/src/domain/board/teleport.spec.ts`):
  - teleporta a si mesmo, um aliado e um inimigo;
  - recusa um destino ocupado, fora do campo ou igual ao do alvo, e a ação sem destino;
  - aceita como destino o hexágono de onde o autor saiu ao andar;
  - o inimigo Protegido fica onde está, e o PP e o countdown são gastos;
  - quem está Preso é teleportado e continua Preso;
  - a marca do destino age quando o teleportado termina a vez nela.
- [x] Teste da IA: com o HP na metade e um inimigo ao lado, ela se teleporta para o hexágono livre mais longe; com o HP cheio, não usa o Teleporte.
- [x] Testes do `skill-draft` para as duas regras do RF-11.
- [x] Os testes de unidade e e2e do servidor passam, menos as falhas antigas, e o jogo sem janela abre sem erro.
- [ ] No Testar técnica (2×2, oponente parado), o Teleporte leva o próprio Ecobeast, o aliado e o inimigo para um hexágono livre, com o sumir e aparecer.

## Desenho técnico

**Servidor**

- `server/src/domain/board/types.ts`: o `destination?: HexCoord` na ação `skill`, e o evento `teleported`.
- `server/src/domain/board/areas.ts`: `ANY_TARGET = 'any'` e o `anyArea` (o hexágono de quem está de pé nele, qualquer lado), ao lado do `allyArea`.
- `server/src/domain/board/board-engine.ts`:
  - o `actionRefusal` confere o destino (RF-05 e RF-06);
  - o `useSkill` move o alvo depois do `skill_used` e manda o `teleported`;
  - o efeito `teleport` não entra no `resolveSkill`.
- `server/src/domain/battle/effects.ts`: o `teleport` fica fora dos efeitos que mudam o Ecobeast, como o `fixed_damage`.
- `server/src/domain/board/board-ai.ts`: a escolha do RF-10.
- `server/src/board-battle/board-battle.dto.ts` (`BoardActionDto`) e o `board-battle.mapper.ts`: o `destination` na ação e o `teleported` na resposta, com a documentação do OpenAPI.
- `server/src/domain/skills/skill-draft.ts`: as regras do RF-11.

**Jogo**

- `client/screens/board_battle/board_battle_screen.gd`: a escolha em dois toques (RF-12: `_pick_teleport` e `_free_cells`, ao lado da do triângulo), o evento `teleported` e as frases dele (`_line_for`).
- `client/screens/board_battle/board_view.gd`: o sumir e aparecer (RF-13: `teleport` e `_puff`).
- `client/core/data/catalog_schema.gd` (`EFFECT_PARAMS`) e `client/core/data/catalog_validator.gd`: o RF-14.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```

Depois, no F1, o Testar técnica com o Teleporte, de 1×1 e de 2×2.

## Tarefas

- [x] Conferir os maiores ids no banco e escrever a migração.
- [x] O alvo `any`, o destino e o `teleported` no motor, com os testes.
- [x] A IA, com o teste.
- [x] O DTO, o mapper e o `skill-draft`, com os testes.
- [x] A tela de dois toques, o sumir e aparecer, as frases e o `CatalogValidator`.
- [x] A verificação.

## Resultado da verificação

Em 2026-11-21:

- O lint, o typecheck e os 1116 testes de unidade do servidor passaram, e nos e2e passaram 696 de 698 (as 2 falhas antigas do `seed.e2e-spec.ts`).
- O jogo sem janela, apontado para um servidor com o código novo, abriu sem erro, com o `CatalogValidator` aceitando o alvo, o efeito e as 4 Técnicas.
- Uma cena temporária do jogo confirmou que a tela da luta e o tabuleiro compilam e que o `teleport` do `BoardView` leva o Ecobeast do hexágono (0, 4) ao (2, 1).
- Não foi visto rodando: a escolha em dois toques numa luta de verdade e o Testar técnica com o Teleporte. Fica para o dono, no último critério de aceite.
