# 03. As zonas nas ilhas e a ferramenta Zona do F2

- **Status:** concluída (falta o dono conferir no F2 e no F5)
- **Depende de:** [01-zone-records](01-zone-records.md), [02-zone-plants](02-zone-plants.md), [map-editor](../map-editor/), [islands](../islands/)

## Contexto

Nas ilhas, o dono pinta as zonas por cima do bioma. Elas só mudam as plantas: quem nasce continua sendo a lista da área ([README](README.md#decisões)).

## Escopo

- A coluna `island_tiles.biome_zone_id` e a zona nas rotas das ilhas e do editor.
- A ferramenta Zona do F2, no grupo Terreno.
- A ilha nova pelo gerador já vem com as zonas.

## Fora do escopo

- A zona mudar o sorteio das áreas.
- O Carimbo levar a zona.

## Requisitos

- **RF-01:** A migration `island_zones` cria `island_tiles.biome_zone_id` (int, nulo, FK → biome_zones, `ON DELETE SET NULL`), com índice. Nulo é a Comum. Nenhuma linha de hoje muda.
- **RF-02:** As rotas de ler e salvar a ilha (as do editor e a de Explorar) levam `zone` (o slug) no hexágono, só fora da Comum. Ao salvar, o servidor recusa com 400 uma zona que não existe ou que é de outro bioma, e grava o slug da Comum como nulo.
- **RF-03:** A ferramenta Zona, no grupo Terreno, depois de Altura:
  - o painel lista as zonas, separadas por bioma, só dos biomas com mais de uma zona, cada uma com uma cor própria;
  - o pincel tem o mesmo raio do Bioma;
  - o clique pinta a zona escolhida nos hexágonos do bioma dela e não mexe nos de outro bioma;
  - o clique com o botão de trás (ou a borracha do painel) volta os hexágonos para a Comum;
  - com a ferramenta aberta, cada hexágono fora da Comum ganha a cor da zona por cima, como a ferramenta Área;
  - tudo entra no desfazer.
- **RF-04:** Trocar o bioma de um hexágono pela ferramenta Bioma volta a zona dele para a Comum.
- **RF-05:** A ilha nova pelo gerador do F2 guarda as zonas que vieram do gerador (fase 01).
- **RF-06:** Em Explorar numa ilha, as plantas seguem a zona, e o tabuleiro da luta também (fase 02).

## Critérios de aceite

- [x] Uma ilha de hoje abre igual, sem nenhuma zona.
- [x] No F2, pintar Bosque numa Planície enche de árvores, e pintar em cima de uma Neve não muda nada.
- [x] Trocar o bioma de um hexágono do Bosque o deixa na Comum.
- [ ] Salvar, publicar e entrar na ilha mostra as mesmas zonas em Explorar.
- [x] A rota recusa uma zona de outro bioma.
- [x] `npm run lint`, `npm run typecheck`, `npm test`, a suíte e2e e `godot --headless --path client --quit-after 30` passam.

## Desenho técnico

- `server/prisma/schema.prisma` (`IslandTile.biomeZoneId`), a migration à mão, `server/src/islands/` (o DTO, o service, a validação) e os e2e das ilhas.
- `client/tools/map_editor/editor_tools.gd` (`Tool.ZONE`, o nome, o ícone e a dica), um `zone_panel.gd` novo, `island_draft.gd` (a zona no JSON e no estado do desfazer) e `editor_canvas.gd` (a cor por cima).
- Um ícone `zone` em `client/tools/map_editor/icons/`, no estilo dos outros.
- Os testes não escrevem na ilha 1 (Liora): a conferência usa uma ilha de teste criada e apagada pelo próprio e2e.

## Tarefas

- [x] A coluna, as rotas e os e2e.
- [x] A ferramenta Zona e o Bioma limpando a zona.
- [x] O gerador da ilha nova e a conferência em Explorar.
