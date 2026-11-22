# 01. A ordem das ilhas e as ilhas abertas

- **Status:** concluída
- **Depende de:** [islands](../islands/), [hub-start](../hub-start/)

## Contexto

O [README](README.md) decidiu o desenho. Esta fase põe no servidor a configuração do Arquipélago e o que cada jogador já abriu. Ela ainda não muda o que o jogo mostra: o mapa aleatório filtrado fica para a [02](README.md#fases), e a tela do Arquipélago, para a 03.

Hoje:

- `islands` tem só o `id`, o `published_at` e o `is_home`. O nome mora no `island_maps` da versão publicada.
- O `POST /v1/me/exploration` com `{island_id}` abre qualquer ilha publicada (`ExplorationService.startIsland`). Sem equipe, só a ilha casa abre.
- O `GET /v1/me/islands` (`IslandsService.listPublished`) lista toda ilha publicada, com o nome e o `home`. O cliente o usa para achar a casa (`Session.load_home`) e na tela Viagem, que não tem entrada desde a hub-start.
- Os e2e criam ilhas pelo editor e entram nelas com um jogador comum.

## Escopo

- A ordem das ilhas no Arquipélago (`islands.archipelago_order`).
- O que cada ilha destrava (`island_unlock_biomes` e `island_unlock_species`), só como configuração. Quem lê é a 02.
- As ilhas que o jogador abriu (`player_islands`).
- Liora (ilha 1199) como a 1ª, com as listas começando pelo que ela já tem.
- A regra pura do estado de cada ilha.
- A rota `GET /v1/me/archipelago` e as rotas de depuração que abrem e fecham uma ilha.
- A entrada numa ilha trancada recusada, e o `GET /v1/me/islands` sem as trancadas.

## Fora do escopo

- Qualquer tela: a escolha do Explorar e a tela do Arquipélago ficam para a 03.
- As condições que abrem a ilha seguinte (Domadores, Arenas e missões).
- O mapa aleatório filtrado e o `biomes.locked_fallback_biome_id`, que ficam para a 02.
- As listas no catálogo do cliente: elas mostrariam o que está travado.

## Onde ficou

- A regra: `server/src/domain/islands/archipelago.ts` (`archipelagoStates` e `isLocked`), com os testes ao lado.
- O serviço e as rotas: `server/src/islands/archipelago.service.ts` e `archipelago.controller.ts`. A exploração chama o `ArchipelagoService.assertOpen` depois de achar a ilha, e o `GET /v1/me/islands` tira as do `lockedIds`.
- A migration `20270211000000_archipelago`. Liora começou com 7 biomas (Planície, Boreal, Pedra, Montanha, Praia, Água rasa e Água profunda) e 4 Ecobeasts (Seedlet, Puffcoo, Lume e Prayling).
- O e2e: `server/test/archipelago.e2e-spec.ts`. Ele usa ilhas de ordem acima de 900.000, porque Liora já ocupa a 1.

## Requisitos

- **RF-01:** `islands.archipelago_order` é um inteiro opcional, maior que 0 e único. Nulo deixa a ilha fora do Arquipélago.
- **RF-02:** `island_unlock_biomes` (`island_id`, `biome_id`) e `island_unlock_species` (`island_id`, `species_id`, `random_only`, que começa falso) têm a chave nos dois ids e apagam junto com a ilha.
- **RF-03:** `player_islands` (`player_id`, `island_id`, `unlocked_at`) guarda as ilhas que o jogador abriu. Ela apaga junto com o jogador e com a ilha.
- **RF-04:** a migration põe `archipelago_order = 1` na ilha 1199, se ela existir. Ela também enche as listas dela com os biomas dos hexágonos da versão publicada e com as espécies das áreas dela, todas com `random_only` falso, para o dono ajustar no painel.
- **RF-05:** só contam no Arquipélago as ilhas com ordem e com versão publicada. Entre elas, o estado de cada uma é:
  - **aberta (`open`):** a de menor ordem, e toda ilha com linha em `player_islands`;
  - **próxima (`next`):** a de menor ordem entre as que não estão abertas;
  - **escondida (`hidden`):** todas as outras.
- **RF-06:** `GET /v1/me/archipelago` devolve `islands`, em ordem, com `order` e `state`. O `id` e o `name` vêm nas abertas e na próxima e são nulos nas escondidas. Sem Domador, dá 409, como a exploração.
- **RF-07:** o `POST /v1/me/exploration` com o `island_id` de uma ilha do Arquipélago que não está aberta dá 403 com "Essa ilha ainda está trancada.". A ilha que não existe continua dando 404 antes. As ilhas fora do Arquipélago abrem como hoje.
- **RF-08:** o `GET /v1/me/islands` deixa de fora as ilhas do Arquipélago que não estão abertas para quem chama.
- **RF-09:** com `ENABLE_TEST_BATTLE` ligada, `PUT /v1/me/archipelago/:id/unlock` abre a ilha para quem chama, e repetir não dá erro. `DELETE` na mesma rota a fecha de novo. A ilha de menor ordem continua aberta mesmo assim. Uma ilha que não está no Arquipélago dá 404. Com a chave desligada, as duas rotas dão 404.

## Critérios de aceite

- [x] Com duas ilhas do Arquipélago (ordem 1 e 2) e uma terceira (ordem 3), um jogador novo vê a 1 aberta, a 2 como a próxima, com o nome, e a 3 escondida, sem id nem nome.
- [x] Entrar na 2 dá 403. Depois do `PUT .../2/unlock`, ela abre, e a 3 vira a próxima.
- [x] Depois do `DELETE .../2/unlock`, entrar na 2 volta a dar 403.
- [x] Uma ilha publicada sem ordem abre como antes, e aparece no `GET /v1/me/islands`. A 2, trancada, não aparece.
- [x] Uma ilha com ordem e sem versão publicada não aparece no Arquipélago.
- [x] Os e2e das ilhas, da casa, da descoberta e da exploração passam sem mudança.
- [x] Depois da migration, Liora tem a ordem 1 e as duas listas cheias.
