# 01. XP do nível e rota do apelido

- **Status:** aprovada
- **Depende de:** [auth-google/03-player-api](../auth-google/03-player-api.md)

## Contexto

A tela de detalhes ([02](02-details-screen.md)) mostra quanto falta para o próximo nível, mas a criatura só traz `current_xp`, e a curva de XP é regra de jogo: o cliente não a calcula. O apelido também precisa de uma rota, porque a coluna `creature_instances.nickname` existe desde a [backend-api/02](../backend-api/02-database-schema.md), mas nada a grava. Esta fase só mexe no servidor; o jogo continua funcionando, porque campos a mais no JSON são ignorados.

## Escopo

- `level_xp` e `next_level_xp` em cada criatura do JSON do jogador.
- `PATCH /v1/me/creatures/:uid`, que grava o apelido.
- Testes e documentação da API.

## Fora do escopo

- Qualquer mudança no cliente.
- Migrations: as colunas já existem.
- Mudar outros campos da criatura pela rota.

## Requisitos

- **RF-01:** Cada criatura do JSON do jogador ganha `level_xp`, o XP total para chegar ao nível atual (`totalXpForLevel(multiplicador, level)`), e `next_level_xp`, o mesmo para `level + 1`.
- **RF-02:** No nível máximo (100), `next_level_xp` é `null`.
- **RF-03:** `PATCH /v1/me/creatures/:uid`, com sessão e corpo `{"nickname": string}`, normaliza o texto como o nome do Domador (pontas sem espaço, sequências de espaço viram uma).
- **RF-04:** Texto vazio depois de normalizar remove o apelido (`nickname` nulo no banco, `""` no JSON).
- **RF-05:** Texto que não passa em `^[\p{L}\p{N} ]{2,16}$` (flag `u`), ou `nickname` que não seja texto, dá `400` "Use de 2 a 16 letras, números ou espaços."
- **RF-06:** `uid` malformado, de criatura de outro jogador ou inexistente dá `404` "Ecobeast não encontrado." As três situações são iguais para quem chama.
- **RF-07:** Sucesso dá `200 {"player": <Player>}`, o jogador inteiro, como as outras rotas de escrita.
- **RF-08:** A rota vale para qualquer criatura do jogador, não só as da equipe.
- **RF-09:** A rota e os campos novos estão documentados no OpenAPI, em pt-BR, com exemplos.

## Critérios de aceite

- [ ] Sem token, `PATCH /v1/me/creatures/<uid>` dá `401`.
- [ ] Com o inicial recém-criado, `current_xp` é igual a `level_xp`, e `next_level_xp` é maior que `level_xp`.
- [ ] Num teste de unidade do mapper com multiplicador 1, o nível 5 dá `level_xp` 125 e `next_level_xp` 216, e o nível 100 dá `next_level_xp` `null`.
- [ ] `"  Chama   Viva "` grava "Chama Viva"; o `GET /v1/me` seguinte devolve o apelido.
- [ ] `""` e `"   "` removem o apelido; `"A"`, `"Fogo!"` e 17 caracteres dão `400` com a mensagem; `{}` e `{"nickname": 5}` também.
- [ ] A criatura de outro jogador, um `uid` que não existe e `abc` dão `404` com a mensagem, e o apelido da outra criatura não muda.
- [ ] `/docs` mostra a rota e os campos.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Alterar**

- `server/src/domain/rules/xp-curve.ts`: `MAX_LEVEL = 100`, com um teste.
- `server/src/player/player.mapper.ts`: `PLAYER_INCLUDE` passa a ler `species.growthRate.xpMultiplier`; `toCreatureDto` preenche os dois campos.
- `server/src/player/player.dto.ts`: `level_xp` e `next_level_xp` no `CreatureDto`; novo `SetNicknameBodyDto`, com `@IsString({ message: INVALID_NAME })`.
- `server/src/player/player.service.ts`: `normalizeName(raw)` sai do `create` e passa a ser usado pelos dois; novo `setNickname(userId, uid, rawNickname): Promise<PlayerDto>`. Grava com `updateMany` filtrando `uid` e `playerId`; zero linhas alteradas dá o `404`.
- `server/src/player/player.controller.ts`: `@Patch('creatures/:uid')`. O `uid` passa por `ParseUUIDPipe`, com `exceptionFactory` que dá o `404` do RF-06; sem isso, um `uid` malformado viraria erro do banco.
- `server/src/player/player.mapper.spec.ts` e `server/test/player.e2e-spec.ts`: os testes dos critérios.
- `.specs/auth-google/architecture.md` (tabela de rotas) e `.specs/onboarding/architecture.md` (campos da `CreatureInstance`).

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Os e2e criam Domadores com `sub` novo e os apagam no fim. Conferir `/docs` com o servidor no ar.

## Tarefas

- [ ] Testes do mapper e `MAX_LEVEL`; ver falhar; `level_xp` e `next_level_xp` (RF-01, RF-02).
- [ ] Testes e2e da rota; ver falhar; serviço, DTO e controller (RF-03 a RF-08).
- [ ] Documentação da rota (RF-09) e dos documentos citados.
- [ ] Marcar esta spec e a tabela do README como `concluída`; commit `feat: XP do nível e apelido no servidor`.
