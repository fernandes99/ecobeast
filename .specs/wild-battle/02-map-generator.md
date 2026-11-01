# 02. Gerador do mapa

- **Status:** concluída
- **Depende de:** [01-hex-grid](01-hex-grid.md)

## Contexto

Com a grade validada, falta quem decide o que vai em cada hexágono. Esta fase cria o gerador, como regra pura do servidor, e a rota que o entrega. O algoritmo, o contrato e os parâmetros estão em [architecture.md](architecture.md).

## Escopo

- A geração com seed.
- A rota `POST /v1/me/exploration`.

## Fora do escopo

- Qualquer mudança no cliente.
- Guardar o mapa no banco.
- Receber uma seed do cliente. O jogador não pode escolher um mapa; reproduzir um mapa é coisa de teste, pela função.
- Terrenos bloqueados e encontros por bioma.

## Requisitos

**Gerador**

- **RF-01:** `generateMap(seed, config)` devolve `{ seed, start, tiles }`, e `config` tem `DEFAULT_MAP_CONFIG` como padrão.
- **RF-02:** A mesma seed e a mesma configuração dão exatamente o mesmo mapa.
- **RF-03:** O mapa tem `tileCount` posições, sem repetir, todas conectadas.
- **RF-04:** A borda do mapa é irregular.
- **RF-05:** Os biomas seguem as regras de [architecture.md](architecture.md#gerador).
- **RF-06:** `wdeep` só encosta em água.
- **RF-07:** Removido: os pares proibidos saíram junto com `warm`, `swamp`, `desert` e `snow`.
- **RF-08:** Biomas de terra formam grupos, e `mont` forma conjuntos.
- **RF-09:** Só existem biomas, formas e variantes que têm sprite.
- **RF-10:** `start` é terra plana.
- **RF-11:** Todos os parâmetros ficam em `DEFAULT_MAP_CONFIG`, e mudar a frequência de um terreno não exige mudar o gerador.

**Rota**

- **RF-12:** `POST /v1/me/exploration`, sem corpo, exige a sessão e responde `201 { "map" }`, no formato de [architecture.md](architecture.md#contrato).
- **RF-13:** A seed vem de `secureRandom`, e cada chamada gera um mapa novo.
- **RF-14:** Sem Domador ou sem criaturas na equipe: `409` "Crie seu Domador primeiro."
- **RF-15:** A rota funciona com a equipe a 0 HP. Quem barra a luta é a rota da batalha.
- **RF-16:** A rota está no OpenAPI, em pt-BR, sob a tag "Exploração".

## Critérios de aceite

Os testes de unidade rodam cada critério do gerador em 200 seeds.

- [x] A mesma seed dá o mesmo mapa, e seeds diferentes dão mapas diferentes.
- [x] Todo mapa tem `tileCount` posições únicas, conectadas, e muda de tamanho quando `tileCount` muda.
- [x] Nenhum `wdeep` encosta em terra.
- [x] Menos de 5% dos tiles de terra ficam sem vizinho do mesmo bioma, e nenhum `mont` de terra fica sem vizinho `mont`.
- [x] Todo bioma e toda forma são dos nomes de [architecture.md](architecture.md#sprites), e toda variante está na faixa da forma.
- [x] `start` existe no mapa e é terra plana.
- [x] Em média, a água fica perto de `waterFraction`, e a terra é a maior parte do mapa.
- [x] Ao longo das seeds, aparecem todos os biomas, e as ilhas são raras.
- [x] Aumentar `waterFraction` aumenta a água.
- [x] Sem token, a rota dá `401`; sem Domador, `409`; com equipe, `201`, e com a equipe a 0 HP também.
- [x] Duas chamadas seguidas devolvem seeds diferentes.
- [x] A rota aparece em `/docs/openapi.json`, com o cadeado.
- [x] Mapas de seis seeds, desenhados com os sprites reais, foram abertos e revisados, e parecem regiões coerentes.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**, em `server/src/domain/exploration/`, cada um com seu `.spec.ts`:

- `hex.ts`: `HexCoord`, `hexKey`, `hexNeighbors`, `hexDistance`.
- `seeded-random.ts`: `seededRandom(seed: number): Random`.
- `noise.ts`: ruído suave com oitavas.
- `map-config.ts`: `MapConfig` e `DEFAULT_MAP_CONFIG`.
- `map-generator.ts`: `generateMap`, com os tipos `Biome`, `TerrainShape`, `MapTile` e `GeneratedMap`.

Em `server/src/exploration/`: `exploration.module.ts`, `exploration.controller.ts`, `exploration.service.ts` e `exploration.dto.ts`. Em `server/test/`: `exploration.e2e-spec.ts`.

**Alterar**

- `server/src/app.module.ts`: o módulo novo.
- `server/CLAUDE.md`: a pasta `src/exploration/` na estrutura.
- `.specs/auth-google/architecture.md`: a rota na tabela da API.

**Reaproveitar**

`Random` de `src/domain/battle/types.ts`, `secureRandom`, `AuthGuard`, `@CurrentUser()`.

Os e2e não conferem valores de balanceamento: só o formato do mapa e os códigos de resposta.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Um script temporário escreve os mapas de seis seeds em JSON, e um script temporário do Godot os monta com os sprites reais, inteiros, numa folha só. Os parâmetros são ajustados olhando essas imagens, e o que mudar em relação a [architecture.md](architecture.md) é atualizado lá.

## Tarefas

- [x] `hex`, `seededRandom` e ruído, com testes; ver falhar; implementar.
- [x] Testes do gerador; ver falhar; `generateMap` e `DEFAULT_MAP_CONFIG` (RF-01 a RF-11).
- [x] Testes e2e; ver falhar; módulo da rota (RF-12 a RF-16).
- [x] Desenhar seis mapas, ajustar os parâmetros e revisar as imagens.
- [x] Remover os arquivos temporários; marcar esta spec e a tabela do README como `concluída`; commit `feat: gerador do mapa de exploração`.

## Decisões da implementação

- **Um quarto ruído, a crista:** na primeira versão, forma e pedra vinham da mesma elevação. Por isso 76% das montanhas eram de pedra, em blocos maciços, e as montanhas de grama e deserto quase não existiam. Os testes passavam, e o problema só apareceu olhando os mapas. Agora a forma vem da crista, que desenha cadeias, e `stone` fica só no miolo delas. A [arquitetura](architecture.md#gerador) foi atualizada.
- **Parâmetros ajustados olhando os mapas:** `edgeRoughness` de 3 para 7, porque a borda ainda lembrava um hexágono; `coldLimit` de 0,18 para 0,12 e `climateShift` de 0,2 para 0,12, porque a neve dominava; `swampBand` de 0,06 para 0,12 e `wetLimit` de 0,62 para 0,6, porque o pântano ficava em 1% dos tiles; `stoneFrom` de 0,86 para 0,96; `hillFrom` de 0,78 para 0,8. `noiseScale`, que a spec não previa, é 0,14.
- **Testes a mais:** nenhum bioma de terra aparece em menos de 25% dos mapas, nenhum bioma passa de 35% dos tiles, e há montanhas em pelo menos 5 biomas de terra. O limite de 35% começou em 30% e subiu porque `temperate`, com 30,6%, é a base da região, como o dono pediu.
- **Os mapas foram montados por script, sem o `HexMapView`:** o script usa os mesmos passos de 32 e 21 px, e a [01](01-hex-grid.md) já provou que o `HexMapView` desenha exatamente isso.
- **Distribuição em 200 seeds:** `temperate` 30,6%, `boreal` 15,7%, `wshallow` 14,6%, `warm` 9,5%, `snow` 9,4%, `desert` 8,2%, `wdeep` 7,4%, `swamp` 3,3% e `stone` 1,2%. Por forma: `flat` 83,5%, `hill` 9,8% e `mont` 6,7%.
- **Cinco regiões:** depois da entrega, o dono reduziu o mapa a `temperate`, `boreal`, `stone`, `wshallow` e `wdeep`. Saíram a temperatura, `climateShift`, `coldLimit`, `hotLimit`, `dryLimit`, `swampBand` e os pares proibidos, que só existiam para os biomas removidos. Os valores e a distribuição acima são os da versão com 9 biomas; os atuais estão na [arquitetura](architecture.md#gerador).
- **Pedra como região:** `stoneFrom`, que recortava o miolo das cadeias, deu lugar a um ruído próprio e a `stoneFraction`, a parte da terra que é pedra. Agora ela tem chão plano, colinas e montanhas, e em campo e floresta as montanhas têm base verde. O dono pediu a mudança ao ver montanhas de base cinza coladas nesses biomas.
- **Testes com configuração própria:** o dono passou a ajustar `DEFAULT_MAP_CONFIG` direto, e os testes dependiam desses valores. Agora eles usam uma configuração fixa, e um teste só confere que a do jogo gera um mapa válido.
- **Conferência:** `npm run lint` e `npm run typecheck` sem avisos; `npm test` com 401 testes e `npm run test:e2e` com 273, já com as cinco regiões e a pedra como região. Os testes novos falharam antes do código. Os mapas de seis seeds foram desenhados e revisados em duas rodadas.
