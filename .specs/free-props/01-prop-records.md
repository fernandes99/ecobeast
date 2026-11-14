# 01. As peças soltas no banco e no contrato

- **Status:** concluída
- **Depende de:** [island-villages](../island-villages/README.md)

## Contexto

Primeira fase da [free-props](README.md): o servidor passa a guardar, conferir, publicar e entregar as peças soltas das ilhas. O jogo e o editor ainda não as desenham nem as põem (fases 2 e 3).

## Escopo

- O catálogo `prop_types`, com os 21 primeiros tipos ([architecture](architecture.md#o-catálogo-prop_types)).
- A tabela `island_props` e as peças no rascunho, na publicação e no mapa de Explorar numa ilha.
- O Poste de luz, a Placa, o Canteiro e o Banco saindo de `map_object_types`.
- O espelho do catálogo no jogo (`catalog_schema.gd`).

## Fora do escopo

- Desenhar as peças no jogo e pô-las no editor.
- A arte das peças.

## Requisitos

- **RF-01:** `prop_types` (`id`, `slug`, `name`, `variants`) entra no catálogo, com os 21 tipos do [architecture](architecture.md#o-catálogo-prop_types), e vem no `GET /v1/catalog`. O `catalog_schema.gd` do jogo a espelha.
- **RF-02:** Os tipos 36 a 39 de `map_object_types` (e os formatos deles) são apagados.
- **RF-03:** `island_props` guarda as peças de uma versão de ilha ([architecture](architecture.md#a-tabela-da-ilha-island_props)).
- **RF-04:** O rascunho aceita `props` (opcional, vazio se faltar) e sempre o devolve. Salvar recusa (`400`), com a mensagem da primeira peça errada (numerada de 1 em diante):
  - um tipo que não existe: "A peça 3 tem um tipo que não existe.";
  - a variante fora de 1 a `variants`: "A peça 3 tem a variante 5: vai de 1 a 4.";
  - um hexágono que não é da ilha: "A peça 3 fica em (2, 1), que não é da ilha.";
  - o pé fora do próprio hexágono: "A peça 3 tem o pé fora do hexágono (2, 1).";
  - mais de 6000 peças: "A ilha pode ter até 6.000 peças.".
- **RF-05:** O `content_hash` inclui as peças, em ordem de `(r, q, dy, dx, prop_type_id, variant, mirrored)`: mudar uma peça muda o estado da ilha para `changed`.
- **RF-06:** Publicar copia as peças, e o `POST /v1/me/exploration` numa ilha publicada as devolve em `map.props`; no mapa sorteado, `props` é vazio.

## Critérios de aceite

- [x] O catálogo traz os 21 tipos de peça, e não traz mais os objetos 36 a 39.
- [x] Um rascunho com peças é salvo, lido de volta igual e publicado, e Explorar na ilha devolve as peças.
- [x] Cada erro do RF-04 é recusado com a mensagem certa.
- [x] O banco recusa uma variante 0 em `island_props`.

## Desenho técnico

**Servidor**

- `prisma/schema.prisma`: `PropType` (`prop_types`) e `IslandProp` (`island_props`), com `IslandMap.props`.
- A migration `free_props`, com os `CHECK` à mão (o `slug` e `variants >= 1` em `prop_types`, `variant >= 1` em `island_props`), os 21 tipos, a sequência e a saída dos objetos 36 a 39.
- `src/catalog/catalog-tables.ts`: `prop_types`.
- `src/domain/islands/hex-pixels.ts` (novo): `flatCenter` e `gridCoord`, cópia do `HexMapView`.
- `src/domain/islands/island-draft.ts`: `DraftProp`, `IslandDraft.props`, `KnownIds.propVariants` (o máximo de variantes por tipo), `MAX_PROPS`, a conferência e a ordem no `canonicalDraft`.
- `src/editor/islands-editor.dto.ts` e `islands-editor.service.ts`: `DraftPropDto`, a leitura, a conferência e a gravação em lote.
- `src/islands/islands.service.ts`: `readVersion` lê as peças.
- `src/exploration/exploration.dto.ts` e `exploration.service.ts`: `MapPropDto` e `props` no mapa.

**Jogo:** `core/data/catalog_schema.gd`, com `prop_types`.

**Specs:** `.specs/game-data/architecture.md`, a tabela nova.

## Verificação

- Testes de unidade, vistos falhar antes: o `gridCoord` igual ao do jogo em pontos de exemplo, e cada erro do RF-04 no `draftError`, mais o `canonicalDraft` com as peças.
- E2e: o catálogo com `prop_types` e sem os objetos 36 a 39; o banco recusando a variante 0; e o editor salvando, lendo, publicando e Explorar devolvendo as peças.
- `npm run lint`, `typecheck`, `npm test` e `npm run test:e2e`; o jogo sem janela abre sem erros de script (o validador do catálogo com a tabela nova).

## Tarefas

- [x] Spec.
- [x] Migration, schema e catálogo.
- [x] A conferência no domínio, com os testes.
- [x] O editor, a publicação e Explorar, com os e2e.
- [x] O espelho no jogo e as specs.

## Resultado da verificação

Em 2026-11-13:

- **Banco:** a migration `20261120000000_free_props` foi aplicada com `prisma migrate deploy`, e o `prisma migrate diff` não mostrou diferença. Um `prisma migrate dev --create-only` travou antes e chegou a aplicar uma migration automática, sem os `CHECK` e sem os tipos; ela foi desfeita (as duas tabelas estavam vazias) e apagada do histórico antes da certa.
- **Testes de unidade:** os novos falharam antes (sem o `prop_types.json`, sem o `hex-pixels.ts` e sem a conferência das peças) e passaram depois. O `gridCoord` do servidor dá o mesmo hexágono que o `HexMapView.grid_coord` do jogo em 15 pontos, tirados do próprio Godot. Ao todo, 803 testes passaram.
- **E2e:** os quatro arquivos tocados (catálogo inteiro, banco, editor de ilhas e ilhas do jogador) falharam antes e passaram depois: 174 testes. A suíte inteira deu 494 de 495: a falha foi "as Técnicas vêm com o PP cheio e o Traço não é oculto", que não tem relação com esta fase e falha ao acaso, porque o inicial tem 1 chance em 20 de vir com o Traço oculto (`HIDDEN_TRAIT_CHANCE`); rodado de novo, o arquivo passou inteiro (37 de 37). A primeira tentativa da suíte, na véspera, teve um processo de teste que caiu sozinho.
- **Jogo:** sem janela, contra o servidor novo (numa porta à parte, porque o `start:dev` aberto não recompilou o cliente do Prisma), o jogo baixou o catálogo com as 36 tabelas e os 21 tipos de peça, o validador aceitou, e não houve erro de script, com os mesmos 9 avisos de antes.
