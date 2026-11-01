# 01. Rotas da equipe e do Santuário

- **Status:** rascunho
- **Depende de:** [capture/01-capture-rules](../capture/01-capture-rules.md)

## Contexto

O banco já guarda quem está na equipe e quem está no Santuário, mas nenhuma rota lista o Santuário nem move ninguém. Esta fase cria as rotas descritas em [architecture.md](architecture.md#rotas). As telas vêm nas fases seguintes.

## Escopo

- Listar o Santuário.
- Reordenar a equipe.
- Trazer um Ecobeast do Santuário, com ou sem troca.
- Mandar um Ecobeast para o Santuário.

## Fora do escopo

- Qualquer mudança no cliente.
- Novas colunas ou migrations.
- A troca na luta ([04](04-battle-switch.md)).

## Requisitos

- **RF-01:** `GET /v1/me/storage` devolve os Ecobeasts do Santuário do Domador, com o `CreatureDto` da equipe, dos capturados mais recentes para os mais antigos.
- **RF-02:** A lista nunca traz Ecobeasts da equipe nem de outro Domador.
- **RF-03:** `POST /v1/me/team/order` põe a equipe nas vagas de 1 a N, na ordem recebida.
- **RF-04:** `order` recusa uma lista que não seja exatamente a equipe atual, com "Ordem inválida."
- **RF-05:** `POST /v1/me/team/bring` sem `replace_uid` põe o Ecobeast na primeira vaga livre.
- **RF-06:** Sem vaga e sem `replace_uid`, a rota responde `409` "A equipe está cheia."
- **RF-07:** Com `replace_uid`, os dois trocam de lugar, e quem entra fica com a vaga de quem saiu.
- **RF-08:** `POST /v1/me/team/store` manda o Ecobeast para o Santuário, com `party_slot` nulo.
- **RF-09:** O último Ecobeast da equipe não vai para o Santuário: "A equipe precisa de ao menos 1 Ecobeast."
- **RF-10:** Mover e reordenar não mudam HP, status, PP, Genes, Treino nem apelido.
- **RF-11:** As rotas de escrita descartam a batalha aberta, sem gravar nada dela.
- **RF-12:** Dois pedidos ao mesmo tempo nunca deixam a equipe sem ninguém, acima de 6 ou com dois Ecobeasts na mesma vaga.
- **RF-13:** Um uid malformado é tratado como Ecobeast inexistente, com `404`.
- **RF-14:** Toda rota fica documentada no OpenAPI, em pt-BR.

## Critérios de aceite

- [ ] Um Domador novo lista o Santuário vazio.
- [ ] Sem Domador, as quatro rotas respondem `409` "Crie seu Domador primeiro."
- [ ] O Santuário não traz o Ecobeast de outro Domador.
- [ ] Os capturados mais recentes vêm primeiro.
- [ ] `order` muda a ordem de `GET /v1/me`.
- [ ] `order` com vagas 1, 3 e 5 ocupadas deixa os três nas vagas 1, 2 e 3.
- [ ] `order` com alguém faltando, sobrando, repetido ou do Santuário dá `400`, sem mudar nada.
- [ ] `bring` com vaga entra na primeira vaga livre, mesmo no meio.
- [ ] `bring` com a equipe cheia e sem `replace_uid` dá `409`, sem mudar nada.
- [ ] `bring` com `replace_uid` troca os dois, e quem entra fica na vaga de quem saiu.
- [ ] `bring` de quem já está na equipe dá `400`.
- [ ] `replace_uid` do Santuário ou de outro Domador dá `404`.
- [ ] `store` tira o Ecobeast de `GET /v1/me` e o põe em `GET /v1/me/storage`.
- [ ] `store` do último Ecobeast dá `400`, sem mudar nada.
- [ ] `store` de quem já está no Santuário dá `400`.
- [ ] Um Ecobeast de outro Domador dá `404` em `bring` e `store`.
- [ ] Depois de mover, HP, status, PP, Genes, Treino e apelido continuam iguais.
- [ ] Uma batalha aberta some depois de `order`, `bring` e `store`, sem gravar HP.
- [ ] Dois `store` ao mesmo tempo com 2 Ecobeasts na equipe deixam 1 na equipe.
- [ ] Dois `bring` ao mesmo tempo com 1 vaga deixam 6 na equipe.
- [ ] Uma falha no meio de `order` não muda a equipe.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/domain/team/party.ts`, com `party.spec.ts`: o que [architecture.md](architecture.md#regras-puras) lista.
- `server/src/team/team.module.ts`, `team.controller.ts`, `team.service.ts` e `team.dto.ts`: tag "Equipe e Santuário" no OpenAPI.
- `server/test/team.e2e-spec.ts`: o fluxo com o banco.

**Alterar**

- `server/src/domain/battle/capture.ts`: sai `firstFreePartySlot`.
- `server/src/domain/battle/capture.spec.ts`: os testes vão para `party.spec.ts`.
- `server/src/battle/battle.service.ts`: o import de `firstFreePartySlot`.
- `server/src/player/player.mapper.ts`: exporta `toCreatureDto` e a parte do `PLAYER_INCLUDE` que lê um Ecobeast, sem o filtro da equipe.
- `server/src/app.module.ts`: o módulo novo.
- `server/CLAUDE.md`: `src/team/` na estrutura.

**Reaproveitar**

`toPlayerDto`, `PLAYER_INCLUDE`, `ParseUUIDPipe` como em `setNickname`, e `BattleStore` como em `InventoryService`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Sem passos do dono nesta fase: ela não muda nada na tela.

## Tarefas

- [ ] Testes de `party.ts`; ver falhar; implementar e mover `firstFreePartySlot`.
- [ ] Testes e2e de `GET /v1/me/storage`; ver falhar; implementar (RF-01, RF-02).
- [ ] Testes e2e de `order`; ver falhar; implementar (RF-03, RF-04).
- [ ] Testes e2e de `bring` e `store`; ver falhar; implementar (RF-05 a RF-13).
- [ ] OpenAPI (RF-14) e `server/CLAUDE.md`.
- [ ] Marcar esta spec e a tabela do README como `concluída`; commit `feat: rotas da equipe e do Santuário`.
