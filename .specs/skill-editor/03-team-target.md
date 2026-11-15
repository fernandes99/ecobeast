# 03. O alvo "Meu time"

- **Status:** concluída (falta o dono jogar)
- **Depende de:** [01](01-skill-routes.md), [02](02-skill-form.md), [board-battle](../board-battle/README.md)

## Contexto

Em 2026-11-15, editando Técnicas no F1, o dono pediu: "No alvo, vão existir habilidades que serão só para mim e que serão para o meu time (incluindo eu mesmo)", e que o Banho de Sol "vai poder usar para qualquer um do time".

Os alvos do catálogo (`skill_targets`) são três:

- **Inimigo:** a tela pede um inimigo ao alcance.
- **Si mesmo:** sai direto, sem escolher.
- **Todos:** a luta não usa.

O Banho de Sol é "Si mesmo", com alcance 1, e cura 50% do HP de quem a usa.

Decisões do dono:

- O alvo do time vale para os Ecobeasts dele em campo, ele incluído.
- O alcance da Técnica vale ("Vale o alcance").
- O desenho abaixo foi aprovado ("Aprovo").

## Escopo

- O alvo novo `ally` ("Meu time") e o Banho de Sol nele.
- O motor da luta, os efeitos e a IA com o alvo do time.
- As regras do editor e do validador do jogo para esse alvo.
- A tela da luta acendendo e aceitando os aliados ao alcance.

## Fora do escopo

- Usar o alvo "Todos".
- Escolher um Ecobeast da reserva, fora do tabuleiro.
- Mudar o alcance do Banho de Sol (continua 1; o dono muda no F1).

## Requisitos

- **RF-01:** Uma migration cria `skill_targets` id 4, `ally`, "Meu time", e põe o Banho de Sol (`banho_de_sol`) nele. O `seed-data` acompanha.
- **RF-02:** Uma Técnica `ally` escolhe um hexágono a até `range` de onde o autor age, incluindo o dele mesmo (distância 0). Ali precisa estar um Ecobeast do lado do autor, de pé. O autor conta no hexágono para onde andou nesta vez. Fora disso, ela é recusada com "Não há Ecobeast do seu time nesse hexágono." ou com a mensagem de alcance de hoje.
- **RF-03:** Uma Técnica `ally` não rola precisão, e o Proteger do aliado não a bloqueia.
- **RF-04:** Numa Técnica `ally`, cada efeito vale no aliado escolhido, menos:
  - os que têm alvo "Si mesmo";
  - os de dreno (`drain`), recuo (`recoil`) e dano em si (`self_damage`), que valem no autor.

  O `heal` cura o aliado escolhido.
- **RF-05:** Uma Técnica `ally` tem poder 0 e área "Um alvo". O editor de Técnicas recusa o contrário com "Uma Técnica para o time não causa dano: o poder fica 0." e "Uma Técnica para o time atinge um Ecobeast só: a área é Um alvo.". O `CatalogValidator` do jogo confere o mesmo.
- **RF-06:** A IA só usa uma Técnica `ally` quando algum aliado ao alcance está com metade do HP ou menos (_a revisar_). Ela escolhe o mais ferido, pela fração de HP, e prefere ele mesmo no empate. Como as outras de suporte, a Técnica entra no sorteio com o peso de suporte.
- **RF-07:** Na tela da luta, escolher uma Técnica `ally` acende os hexágonos dos Ecobeasts do jogador ao alcance, o do autor incluído. Tocar num deles manda a ação com o `target`. "Si mesmo" continua saindo direto.

## Critérios de aceite

- [x] Num teste do motor, o Banho de Sol (`ally`, cura 50%) usado num aliado a 1 hexágono cura o aliado, não o autor.
- [x] Num teste do motor, ela usada no próprio hexágono cura o autor, também depois de andar.
- [x] Num teste do motor, um hexágono a 2 de distância, com alcance 1, é recusado, e um inimigo no hexágono também.
- [x] Num teste do motor, ela não erra com precisão 0 e não é bloqueada pelo Proteger do aliado.
- [x] Num teste da IA, um selvagem com o Banho de Sol e um aliado com 40% de HP ao lado o cura. Com todos acima da metade, ele não usa.
- [x] Num teste de `skill-draft`, uma Técnica `ally` com poder 30, ou com área em linha, é recusada.
- [x] Depois da migration, o catálogo traz "Meu time", e o Banho de Sol tem o alvo dele. O jogo abre sem erro no `CatalogValidator`.
- [ ] Na luta (F5), o Banho de Sol acende os seus Ecobeasts ao alcance, e tocar num aliado ferido o cura.

## Desenho técnico

**Criar:**
- `server/prisma/migrations/20261201000000_team_target/migration.sql`: o `INSERT` do alvo, com o contador de id ajustado, e o `UPDATE` do Banho de Sol.

**Alterar no servidor:**
- `server/prisma/seed-data/skill_targets.json` e `skills.json`.
- `server/src/domain/board/areas.ts`:
  - `areaOf` com o alvo `ally`.
  - `ALLY_ONLY` com a mensagem do RF-02.
  - O autor visto em `from`.
- `server/src/domain/board/board-engine.ts`: a Técnica `ally` passa pelo `areaOf` sem o atalho do inimigo único, e o aliado vai como alvo para `resolveSkill`.
- `server/src/domain/battle/actions.ts`: `aimsAtTarget` só para o alvo que não é `self` nem `ally`.
- `server/src/domain/battle/effects.ts`: o `heal` no aliado escolhido quando o alvo da Técnica é `ally`.
- `server/src/domain/board/board-ai.ts`: as Técnicas `ally` no `chooseAction`.
- `server/src/domain/skills/skill-draft.ts`: as duas regras do RF-05, com o `slug` do alvo e da área nas tabelas.
- Os testes: `board-engine.spec.ts`, `board-ai.spec.ts`, `skill-draft.spec.ts` e `catalog.e2e-spec.ts`.

**Alterar no jogo:**
- `res://domain/rules/board_geometry.gd`: `ally_targets(skill, allies, from)`.
- `res://screens/board_battle/board_battle_screen.gd`: no `_choose_skill`, o alvo `ally` acende os aliados ao alcance.
- `res://core/data/catalog_validator.gd`: as regras do RF-05.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run db:generate
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```

À mão (F5): numa luta com um Ecobeast que conhece o Banho de Sol, ferir um aliado ao lado, usar a Técnica nele e ver o HP subir.

## Tarefas

- [x] Migration e `seed-data`.
- [x] `areaOf`, o motor e os efeitos, com testes.
- [x] A IA, com testes.
- [x] As regras do editor e do validador.
- [x] A tela da luta.
- [x] Testes do servidor e jogo sem janela.
- [ ] O passo à mão, com o dono.

## Resultado da verificação

Em 2026-11-15:

- **Banco:** a migration `20261201000000_team_target` foi aplicada com `migrate deploy`, e o `migrate diff` ficou vazio. O Banho de Sol tem o alvo `ally`, com alcance 1 e poder 0.
- **Testes:**
  - 4 testes do motor e 2 da IA, em `board-engine.spec.ts` e `board-ai.spec.ts`.
  - 1 de `skill-draft.spec.ts` e 1 de `catalog.e2e-spec.ts`.
  - As suítes de unidade e e2e passam, com o lint e o typecheck. Na primeira rodada, o `player.e2e-spec.ts` falhou por acaso: o Ruvo nasce com o Traço oculto 1 vez em 20 ([hidden-traits](../hidden-traits/README.md)). Rodado de novo, passou.
- **Jogo:** sem janela, o catálogo passou no `CatalogValidator` com as regras novas. O `BoardGeometry.ally_targets` acendeu o autor e o aliado ao lado, e não o que estava a 3 hexágonos.
- **Escolhas na implementação:**
  - A IA não anda quando já pode curar alguém de onde está.
  - Na tela, a cura de uma Técnica para o time toca o efeito sobre quem recebe, porque o efeito só tocava no dano.
- **Falta o dono:** a luta com F5, curando um aliado ferido com o Banho de Sol.

