# 04. A conversão das cercas de grade

- **Status:** concluída (falta o dono ver a ilha 1199 no editor e no jogo)
- **Depende de:** [01](01-wall-records.md), [02](02-wall-blocking.md) e [03](03-fence-tool.md)

## Contexto

As paredes já existem, bloqueiam e se desenham no editor. A Cerca (cidade) (`town_fence`, id 29 de `map_object_types`) ainda é um objeto de grade que bloqueia o hexágono inteiro. Esta fase a converte em paredes e a tira do jogo, como no [architecture.md](architecture.md#a-conversão-fase-4).

Em 2026-11-14, o banco tem 20 cercas de grade: 10 no rascunho e 10 na publicada da ilha 1199, todas de madeira (variante 1). As duas versões já têm 3 paredes cada.

## Escopo

- A migration `free_fences_conversion`: as cercas viram paredes, e os objetos e o tipo 29 saem.
- No servidor: o `seed-data` e o teste do catálogo sem o tipo 29.
- No cliente: sai o `HexFences`, a arte de `town_fence`, a Cerca no `MapObjectSprite` e no `HexMapView` e o tipo no `make_town.gd`.

## Fora do escopo

- Juntar as paredes convertidas em linhas longas.
- Os carimbos guardados no computador do dono (`tools/map_editor/stamps/`, fora do git). Um carimbo com uma Cerca (cidade) a põe, e o servidor recusa o salvar com "tipo que não existe". O único de hoje não tem objetos.

## Requisitos

- **RF-01:** a migration, em SQL escrito à mão, em cada `island_map`:
  - **Os pares:** duas cercas vizinhas (os 6 vizinhos de `HexFences.EDGE_NEIGHBORS`) na mesma altura de `island_tiles` estão ligadas, qualquer que seja a variante.
  - **Mesma variante:** uma parede do centro de uma ao centro da outra.
  - **Variantes diferentes:** duas paredes, cada uma do centro da sua cerca até o meio do lado, no tipo da sua variante.
  - **A cerca sem ligação:** a parede de (−30, 0) a (30, 0) a partir do centro dela.
  - **O tipo:** variante 1 vira `wood_fence`, e 2 vira `stone_fence`.
  - **Os pontos:** a partir do centro plano do (0, 0), o centro de (q, r) é `(64q + 32r, 42r)`.
  - **O `position`:** começa depois da maior das paredes que o mapa já tem, na ordem do id das cercas (e, num par, da cerca de id menor).
- **RF-02:** a mesma migration apaga os objetos de tipo 29 (os `island_object_tiles` vão junto) e o tipo 29 (os `map_object_type_tiles` vão junto). O `content_hash` não é recalculado.
- **RF-03:** o `seed-data` fica sem o tipo 29, e o teste do catálogo passa a esperar só os 5 objetos.
- **RF-04:** no cliente saem:
  - o `HexFences` (`ui/components/hex_fences.gd`);
  - a pasta `assets/map_objects/town_fence/`;
  - a Cerca no `MapObjectSprite` (`fence`, `setup_fence`, `set_fence_texture`) e no `HexMapView` (`_fence_art` e o refresh dela);
  - no `make_town.gd`, o tipo `town_fence` e as peças dele. O poste, a travessa e o pilar ficam, porque montam a folha das paredes.

## Critérios de aceite

- [x] Toda parede convertida passa nas regras do contrato (`draftError`): pontos dentro da ilha e até 2.000 paredes.
- [x] As 10 cercas da ilha 1199 viram as paredes esperadas, iguais no rascunho e na publicada.
- [x] Depois da migration, não há objeto nem tipo 29, e a ilha passa no `draftError` e no `publishError` (o salvar pelo editor aberto fica com o dono).
- [x] O jogo e o editor abrem sem erros de script e sem avisos novos.

## Desenho técnico

- `server/prisma/migrations/20261129000000_free_fences_conversion/migration.sql`: as cercas com a altura, os pares, as paredes novas e a limpeza, num só arquivo.
- `server/prisma/seed-data/map_object_types.json` e `map_object_type_tiles.json`.
- `server/src/catalog/catalog-tables.spec.ts`.
- Cliente: `ui/components/map_object_sprite.gd`, `ui/components/hex_map_view.gd` e `assets/map_objects/make_town.gd`.

## Verificação

- **Antes de aplicar:** a migration roda numa transação desfeita no fim, sobre o banco real. Um script lê as paredes que ela faria e confere cada mapa pelo `draftError` do servidor e pelas paredes esperadas, calculadas à parte.
- **Depois:** `migrate deploy`, a suíte inteira do servidor e o jogo sem janela.
- **Com o dono:** a ilha 1199 no editor e no jogo, com as cercas no lugar.

## Tarefas

- [x] A migration e a conferência numa transação desfeita.
- [x] Aplicar a migration.
- [x] O `seed-data` e o teste do catálogo.
- [x] O cliente sem a Cerca (cidade).
- [x] Testes e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Antes de aplicar** (um script fora do repositório, numa transação desfeita): a migration rodou sobre o banco real e sobre uma ilha de mentira criada na mesma transação. Ela confere:
  - nos 2 mapas da ilha 1199, as 10 cercas viram 8 paredes de madeira, depois das 3 que já existiam, com as posições de 0 a 10;
  - na ilha de mentira, um par de variantes diferentes (as duas metades até o meio do lado), um par igual, uma cerca sozinha na beira e duas vizinhas em alturas diferentes (cada uma sozinha);
  - as paredes novas iguais às calculadas à parte, todo ponto dentro da ilha e nenhum objeto, tipo ou hexágono de tipo 29 depois.
- **Depois de aplicar:** o rascunho e a publicada da ilha 1199 passam no `draftError` e no `publishError` do servidor, com 11 paredes e 7 objetos, e dão o mesmo hash.
- **Servidor:** lint, typecheck, 853 testes de unidade e 556 e2e.
- **Cliente:**
  - a folha das paredes e as casas, geradas de novo pelo `make_town.gd`, saem iguais às de antes;
  - uma cena temporária sem janela (apagada) baixa o catálogo sem o tipo 29, põe uma casa no `HexMapView` e abre o `MapEditor`;
  - o jogo sem janela dá os mesmos avisos da versão de antes (o `ratio` do `xp_line.gd` e os vazamentos ao fechar), nenhum novo.
- **Não conferido:** a ilha 1199 no editor aberto (F2) e no jogo, com as cercas no lugar.
