# 03. As luzes da noite

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [02](02-day-light.md), [prop-depth-blocks/02](../prop-depth-blocks/)

## Contexto

O dono escolheu que, à noite, as peças (postes e janelas) acendam e o Domador leve uma luz em volta dele ([README](README.md#decisões)). O filtro da [02](02-day-light.md) já sabe desenhar luzes em degraus. Falta dizer onde elas ficam e entregar a lista a ele.

## Escopo

- A tabela `prop_type_lights` no banco, na carga inicial e no catálogo (servidor e jogo).
- Os pontos de luz iniciais: o Poste de luz e as janelas dos prédios e das casas.
- A lista de luzes no `HexMapView` e a luz do Domador.

## Fora do escopo

- Editar luzes no editor de ilhas (F2); por enquanto, pelo painel do Supabase.
- Luzes no tabuleiro da luta, nos NPCs e nos Ecobeasts.
- Luzes que piscam ou tremem.

## Requisitos

- **RF-01:** A migração `<data>_prop_type_lights` (SQL à mão, aplicado com `prisma migrate deploy`) cria `ecobeasts.prop_type_lights` com as colunas e as regras do [architecture.md](architecture.md#os-pontos-de-luz). O `schema.prisma` ganha o modelo `PropTypeLight`, e `prop_types` ganha a relação `lights`.
- **RF-02:** `GET /v1/catalog` traz `prop_type_lights`, e o jogo as lê (`catalog_schema.gd`, o modelo `PropTypeLight` e o acesso por tipo e variante no `GameData`, com a variante 0 valendo para as que não têm luzes próprias, como os bloqueios). O `CatalogValidator` recusa uma luz com `prop_type_id` inexistente ou `variant` acima do `variants` do tipo.
- **RF-03:** `seed-data/prop_type_lights.json` acende, _a revisar_:
  - o Poste de luz (18), na lâmpada das 2 variantes: raio 28, cor `ffd890`;
  - as janelas dos prédios do Refúgio, da Loja e do Observatório (22, 23 e 27) e as das casas da cidade (24 a 26) e do pacote (95 a 97), uma luz por janela, em cada variante que tem as janelas em outro lugar: raio 6 a 10, cor `ffcf70`.
  
  Os pontos saem da arte pelo `client/assets/props/find_lights.py`, e o `client/assets/props/LUZES.md` explica como ele acha cada luz, para as próximas peças. São 142 linhas: as casas do pacote (95 a 97) só mudam de cor e valem pela variante 0, e as casas da cidade (24 a 26) mudam de formato e têm linhas por variante.
- **RF-04:** Ao montar as peças do mapa, o `HexMapView` guarda as luzes de cada peça em pixels da arte do mapa, no mesmo ponto em que a peça é desenhada. Esse ponto é o pé da peça erguido pela altura do hexágono (`flat_center(...) - _rise(tile.height) + offset`, como no desenho das peças), mais o `x` e o `y` da luz, com a coluna `−x − 1 + largura % 2` na peça espelhada, o pixel exato do espelho. Sem a altura, a luz de uma peça num hexágono alto cairia abaixo da janela.
- **RF-05:** Sempre que a vista muda (andar, zoom, Domador se mexendo), a tela `exploration` entrega ao `DayLightLayer.set_lights(...)` a luz do Domador primeiro e, depois, as luzes cujo círculo toca a área visível, das mais perto do Domador para as mais longe, até 32 no total.
- **RF-06:** A luz do Domador é uma constante do jogo, _a revisar_: centro 10 px acima do pé, raio 36 px, cor `ffe8c0`. Ela acompanha o pé do Domador enquanto ele anda, também no mapa sorteado.
- **RF-07:** As luzes acendem e apagam pela força das luzes da [02](02-day-light.md): apagadas das 7h às 17h, acendendo até as 19h e apagando das 5h às 7h.

## Critérios de aceite

- [ ] Numa ilha com vila, as janelas e os postes acendem no final de tarde e ficam acesos a noite toda.
- [ ] A luz fica em cima da janela certa em todas as variantes, nas peças espelhadas e nas peças em hexágonos altos.
- [ ] O círculo de luz anda em degraus do tamanho do pixel da arte em qualquer zoom.
- [ ] O Domador anda à noite com a luz em volta dele, no mapa sorteado e nas ilhas.
- [ ] Numa vila com mais de 32 luzes na tela, as que ficam de fora são as mais longe do Domador, e nenhuma pisca ao andar devagar.
- [ ] Mudar o raio de uma luz no painel do Supabase muda o jogo na próxima abertura do catálogo.
- [ ] Os testes do servidor passam, e `godot --headless --path client --quit-after 60` roda sem erro de script.

## Desenho técnico

- **Servidor:**
  - `server/prisma/migrations/<data>_prop_type_lights/migration.sql`
  - `schema.prisma`
  - `seed-data/prop_type_lights.json` e a carga inicial
  - `src/catalog/catalog-tables.ts` e os testes que contam tabelas
- **Jogo:**
  - `core/data/catalog_schema.gd`, `domain/models/prop_type_light.gd`, `core/autoload/game_data.gd` e o `CatalogValidator`
  - `ui/components/hex_map_view.gd` (as luzes das peças)
  - `screens/exploration/exploration_screen.gd` (a escolha das 32 e a luz do Domador)
- **Reutilizar:** o padrão de `prop_type_blocks` em todas as camadas, o `MapProp.world_lines` para o espelho e o ponto de desenho das peças no `HexMapView` para a altura.

## Verificação

- `npm test` e os e2e do catálogo em `server/`.
- F5 no Godot: numa ilha com casas e postes, adiantar até as 19h com "Debug: +1 hora", andar pela vila e dar zoom. Espelhar uma casa no editor (F2), publicar e conferir a luz.
- No celular Android: conferir se a exploração continua lisa com 32 luzes na tela.

## Tarefas

- [x] Migração (`20261219000000_prop_type_lights`), modelo, carga inicial e catálogo do servidor.
- [x] Catálogo no jogo (`GameData.prop_lights_by_key`) e o `CatalogValidator`.
- [x] Achar os pontos das janelas e dos postes (`find_lights.py`) e escrever o `LUZES.md`.
- [x] Luzes das peças no `HexMapView` (`prop_lights`).
- [x] Escolha das 32 e a luz do Domador na exploração.
- [x] Atualizar `CLAUDE.md`, `client/CLAUDE.md`, o README da iniciativa e as tabelas das specs.

Conferido por Claude: as luzes desenhadas sobre a arte de cada tipo, e uma ilha publicada às 18h e às 22h, com os postes, as lanternas do Observatório e a luz do Domador acesos. Fica para o dono: uma vila com casas e peças espelhadas, um hexágono alto, mais de 32 luzes na tela e a fluidez no celular.
