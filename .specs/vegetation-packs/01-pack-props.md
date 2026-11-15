# 01. As peças dos pacotes

- **Status:** concluída (falta o dono usar)
- **Depende de:** [free-objects/04](../free-objects/04-objects-to-props.md) e [vegetation-brush/02](../vegetation-brush/02-vegetation-tool.md)

## Contexto

O dono quer as árvores, os arbustos e as pedras de três pacotes como peças soltas, sem mudar o bioma nem a geração ([README](README.md#contexto)).

## Escopo

- A arte recortada em `client/assets/props/`, com os créditos.
- Os 33 tipos no catálogo, por migration e no `seed-data`.
- Os 6 grupos novos do pincel Vegetação, o limite de variantes por grupo e o raio pela arte.

## Fora do escopo

- O que o [README](README.md#fora-do-escopo) deixa de fora.

## Requisitos

- **RF-01:** Cada tipo da [tabela](architecture.md#os-tipos) tem um PNG por variante em `client/assets/props/<slug>/<n>.png`, recortado pela regra da [arte](architecture.md#a-arte). O `client/assets/props/CREDITOS.md` diz de onde vem cada pasta e a licença da craftpix.net.
- **RF-02:** Uma migration cria os tipos 28 a 60 em `prop_types`, com o `slug`, o `name` e as `variants` da tabela, e acerta o contador de id. O `seed-data/prop_types.json` acompanha.
- **RF-03:** A ferramenta Peças mostra os tipos novos, com o ícone da variante 1, e põe qualquer variante deles.
- **RF-04:** O pincel Vegetação tem os 13 grupos: os 7 de hoje e depois os 6 da [tabela](architecture.md#os-grupos-do-pincel), com as variantes e os tipos desligados no começo.
- **RF-05:** Uma peça de arte própria tem o raio da [regra](architecture.md#o-espaço-no-chão), também ao contar as peças que já estão no hexágono.
- **RF-06:** Nada muda nas decorações do bioma nem no mapa sorteado.

## Critérios de aceite

- [x] Depois da migration, o catálogo tem 60 tipos de peça, e o jogo abre sem erro no `CatalogValidator`.
- [x] Todos os 33 tipos têm os PNGs de 1 até `variants`.
- [x] Sem janela, uma pincelada de "Pedras grandes (pacote)" põe só variantes 1 e 2, e uma de "Pedras pequenas (pacote)" só 4 e 5.
- [x] Sem janela, numa pincelada de "Árvores (pacote)", dois pés nunca ficam mais perto que o maior dos dois raios.
- [x] Uma prévia desenhada pelo jogo mostra os tipos novos na ilha.
- [ ] No editor (F2), as peças novas aparecem na ferramenta Peças e no pincel, e a ilha salva com elas.

## Desenho técnico

**Criar:**
- `client/assets/props/<slug>/<n>.png` (33 pastas) e `client/assets/props/CREDITOS.md`.
- `server/prisma/migrations/20261206000000_vegetation_packs/migration.sql`.

**Alterar:**
- `server/prisma/seed-data/prop_types.json` e o teste dele em `server/src/catalog/catalog-tables.spec.ts`.
- `client/tools/map_editor/vegetation_panel.gd`:
  - os grupos novos em `GROUPS`, com `variants` e `off`;
  - o sorteio da variante dentro do grupo;
  - o raio por variante (`_radius_of(slug, variant)`).

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```

À mão (F2): pintar com os grupos novos numa ilha, salvar e abrir de novo.

## Tarefas

- [x] A arte e os créditos.
- [x] A migration e o `seed-data`.
- [x] Os grupos, a variante e o raio no pincel.
- [x] A conferência sem janela e a prévia.
- [ ] O passo à mão, com o dono.

## Resultado da verificação

Em 2026-11-15:

- **Arte:** 120 PNGs em 33 pastas. O maior é a Árvore frondosa, variante 1, com 62 × 78 px.
- **Banco:** a migration `20261206000000_vegetation_packs` foi aplicada com `migrate deploy`, e o catálogo traz 60 tipos de peça.
- **Jogo sem janela:** o catálogo passou no `CatalogValidator`, e nenhum PNG faltou. Numa ilha de teste, uma pincelada de cada grupo novo deu:

  | Grupo | Peças |
  | --- | --- |
  | Árvores (pacote) | 34 |
  | Troncos (pacote) | 17 |
  | Arbustos (pacote) | 70 |
  | Pedras grandes (pacote) | 35 |
  | Pedras médias (pacote) | 41 |
  | Pedras pequenas (pacote) | 84 |

  Só os tipos ligados apareceram, e as variantes ficaram dentro do limite de cada grupo. Nenhum par de pés ficou mais perto que o maior dos dois raios. A prévia desenhada pelo jogo mostrou as peças sobre as decorações naturais, que não mudaram.
- **Servidor:** o lint, o typecheck, a suíte de unidade (888 testes) e a e2e (570) passam. Dois testes de `catalog-tables.spec.ts` contavam 27 tipos de peça: passaram a contar 60, e um teste novo confere os 33 dos pacotes.
- **Falta o dono:** pintar com os grupos novos no editor (F2), salvar e ver a ilha no jogo.
