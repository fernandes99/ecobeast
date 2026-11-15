# 05. Madeira e corda, a largura e o desenho sem cortes

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [04-water-walking](04-water-walking.md)

## Contexto

Vendo as pontes das fases 1 a 4, o dono pediu: "Ficou muito ruim, vamos manter apenas a ponte de madeira e a ponte de corda. E vamos melhorar ela, quero controlar a largura dela, e também tá tendo muitos cortes nela."

Claude achou três cortes:
- triângulos de água aparecendo no piso da ponte de madeira;
- pranchas da ponte de corda cortadas ao meio onde o meio do pacote se repete;
- a cabeceira de cima coberta pela borda da margem.

A causa maior era a ordem de desenho: cada fatia alta da ponte deitada entrava numa linha só do mapa, e o chão da linha seguinte cobria a parte dela que descia.

Claude montou uma primeira versão só pela vista de cima, girada. O dono jogou e disse: "Ficou pior agora, mas pelo menos conseguimos controlar a largura dela. Pelo menos anteriormente tinha como ver as paredes/cerca da ponte em isométrico, agora nem isso direito. E também tá tendo muito corte dela." A versão final voltou à vista de lado na ponte deitada.

Depois, o dono jogou de novo: "a ponte de corda tá ok, mas a ponte de pedra tem esse recorte nas pontas, mas não deve ter!" (a da imagem era a de madeira). O vão vinha do pacote: a cabeceira e o meio são peças soltas, e o começo do meio só tem os postes. O `make_bridges.py` passou a tirar as linhas sem piso entre a cabeceira e o meio da madeira.

## Escopo

- Apagar os outros 6 estilos, no banco, no `seed-data` e na arte.
- A largura de cada ponte: no banco, no contrato, no editor e no piso do andar.
- O desenho novo do `HexBridges`.

## Requisitos

- **RF-01:** O catálogo fica com `rope_bridge` (4) e `wood_bridge` (5). A migration apaga os outros tipos e as pontes que os usam, sem renumerar.
- **RF-02:** `island_bridges.width`, de 16 a 64, 28 por padrão. O contrato leva `width`; sem ele, vale 28; fora da faixa, o servidor recusa ("A ponte N precisa ter de 16 a 64 px de largura."). O `content_hash` leva a largura.
- **RF-03:** O painel da ferramenta Ponte tem a largura (de 16 a 64). Ela vale para a próxima ponte e troca a da escolhida, com desfazer.
- **RF-04:** O desenho é o da [arquitetura](architecture.md#o-desenho-fases-2-e-5):
  - a ponte deitada usa a vista de lado, com os corrimãos em pé, e repete linhas do piso com a largura;
  - a ponte em pé usa a vista de cima e repete colunas do miolo do piso;
  - tudo é cortado em fatias de 1 px de altura, cada uma na linha do mapa do pé dela.
- **RF-05:** O piso do andar acompanha a largura (`HexBridges.deck_reach`).

## Critérios de aceite

- [x] Uma prévia desenhada pelo jogo mostra as duas pontes deitadas, em pé e inclinadas, com larguras 20, 28, 36 e 44, sem nenhum pedaço coberto pelo chão e com o Domador em cima e dos lados.
- [x] Sem janela: com largura 28, 7 px do eixo de uma ponte em pé ainda é piso e 10 px já é água; com 44, 14 px é piso.
- [x] Testes do servidor: a largura de 16 a 64, o padrão 28 e o hash.
- [x] Uma prévia desenhada pelo jogo mostra as quatro pontas da ponte de madeira emendadas no piso, sem vão.
- [ ] No jogo (F5) e no editor (F2), o dono desenha as duas pontes com larguras diferentes e atravessa.

## Desenho técnico

**Criar:**
- `server/prisma/migrations/20261212000000_bridge_width/migration.sql`.

**Alterar:**
- `client/assets/bridges/make_bridges.py` e as pastas `wood_bridge` e `rope_bridge`.
- `client/ui/components/hex_bridges.gd` e `client/ui/components/hex_map_view.gd` (`_bridge_entries`, `_add_bridge_mesh`).
- `client/domain/models/map_bridge.gd`, `exploration_map.gd` e, no editor, `bridge_panel.gd`, `editor_tools.gd`, `island_draft.gd` e `island_overview.gd`.
- No servidor: `schema.prisma`, `seed-data/bridge_types.json`, `island-draft.ts`, os DTOs e serviços do editor, de Explorar e das ilhas, e os testes.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```
