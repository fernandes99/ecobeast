# 02. Gerador do mapa

- **Status:** rascunho
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
- **RF-07:** Nenhum par proibido fica lado a lado.
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

- [ ] A mesma seed dá o mesmo mapa, e seeds diferentes dão mapas diferentes.
- [ ] Todo mapa tem `tileCount` posições únicas, conectadas, e muda de tamanho quando `tileCount` muda.
- [ ] Nenhum `wdeep` encosta em terra, e nenhum par proibido fica lado a lado.
- [ ] Menos de 5% dos tiles de terra ficam sem vizinho do mesmo bioma, e nenhum `mont` de terra fica sem vizinho `mont`.
- [ ] Todo bioma e toda forma são dos nomes de [architecture.md](architecture.md#sprites), e toda variante está na faixa da forma.
- [ ] `start` existe no mapa e é terra plana.
- [ ] Em média, a água fica perto de `waterFraction`, e a terra é a maior parte do mapa.
- [ ] Ao longo das seeds, aparecem todos os 9 biomas, e as ilhas são raras.
- [ ] Aumentar `waterFraction` aumenta a água.
- [ ] Sem token, a rota dá `401`; sem Domador, `409`; com equipe, `201`, e com a equipe a 0 HP também.
- [ ] Duas chamadas seguidas devolvem seeds diferentes.
- [ ] A rota aparece em `/docs/openapi.json`, com o cadeado.
- [ ] Mapas de seis seeds, desenhados com os sprites reais, foram abertos e revisados, e parecem regiões coerentes.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

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

Um script temporário escreve os mapas de seis seeds em JSON, e uma cena temporária do Godot os desenha com o `HexMapView`, inteiros, numa imagem por seed. Os parâmetros são ajustados olhando essas imagens, e o que mudar em relação a [architecture.md](architecture.md) é atualizado lá.

## Tarefas

- [ ] `hex`, `seededRandom` e ruído, com testes; ver falhar; implementar.
- [ ] Testes do gerador; ver falhar; `generateMap` e `DEFAULT_MAP_CONFIG` (RF-01 a RF-11).
- [ ] Testes e2e; ver falhar; módulo da rota (RF-12 a RF-16).
- [ ] Desenhar seis mapas, ajustar os parâmetros e revisar as imagens.
- [ ] Remover os arquivos temporários; marcar esta spec e a tabela do README como `concluída`; commit `feat: gerador do mapa de exploração`.
