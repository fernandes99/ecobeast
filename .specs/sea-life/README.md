# sea-life

A Água rasa e a Água profunda ganham decorações, como as plantas e as pedras da terra: algas, pedras que furam a superfície, pedras submersas e lixo boiando. Cada bioma de água ganha 3 zonas, uma delas de lixo.

## Contexto

Em 2026-11-20, o dono pediu: "Crie vegetações e pedras para o bioma do mar/oceano (água profunda) e também para a água rasa, coloque algas, pedras, lixo (lixo vai ser raro aparecer normalmente, ele será uma zona do mar que pode aparecer lixo) e etc... Separe zonas para isso e também pode aparecer no bioma normalmente, como as outras vegetações..."

Como é hoje:

- **As decorações:** a receita de `wshallow` e de `wdeep` em `HexDecorations.RECIPES` não existe, então a água não tem nada. O `HexMapView` já desenha decorações num hexágono de água, se houver receita.
- **As zonas:** a Água rasa (bioma 6) e a Água profunda (7) só têm a Comum (`biome_zones` 6 e 7, `share` 100).
- **Quem nasce na água:** a linha da Nilu (espécies 4 a 6) e a do Tidebud (17 a 19).
- **A água bloqueia o andar** (`bridges/04`), então as decorações da água não precisam bloquear nada.

Claude propôs o desenho, e o dono aprovou: "Aprovado, pode seguir".

## Objetivos

1. 13 tipos novos de decoração da água (o lixo refeito na [04](04-trash-and-density.md)), desenhados por código, com a parte de baixo d'água meio transparente.
2. A Comum da Água rasa e a da Água profunda com algas e pedras; o lixo, raríssimo nelas.
3. 6 zonas novas: Algal, Pedras rasas e Lixo na Água rasa; Floresta de algas, Rochedo e Lixo na Água profunda. Elas valem no mapa sorteado e se pintam nas ilhas pela ferramenta Zona do F2.
4. Os Ecobeasts da água nascendo mais nas algas e menos no lixo.
5. Os 13 tipos como peças soltas no F2, na categoria Mar e num grupo "Mar" do pincel Vegetação.

## Anti-objetivos

- O lixo virar a cara do mar: fora da zona Lixo, ele é raríssimo.
- Mudar o terreno, a terra ou as zonas de terra de uma seed.
- Coral ou qualquer coisa que só caiba no mar: os lagos e os rios também são Água rasa e Água profunda.

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| Algas, pedras e lixo na Água rasa e na profunda, na Comum e em zonas | O pedido |
| O lixo, raro na Comum e com uma zona própria | "lixo vai ser raro aparecer normalmente, ele será uma zona do mar que pode aparecer lixo" |
| As 6 zonas, os Ecobeasts da água mais nas algas e menos no lixo, e as peças no F2 | Aprovou a proposta |

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| Sem coral nem vitória-régia | Os dois biomas também são os lagos e os rios |
| A parte submersa com alfa de 45% a 70%, e a parte acima da água com um anel de espuma clara | Lê como embaixo d'água sobre as duas cores de água, sem mexer no shader do terreno |
| O que boia e as algas balançam pelo `KIND_SWAY` | O vento das plantas já faz o balanço, sem código novo |
| As zonas com os slugs `wshallow_*` e `wdeep_*`, ids 25 a 30 | O teste da carga das zonas pede o slug do bioma como prefixo |
| A parte das zonas: Comum 50, as duas de algas e de pedras 21 cada, e o Lixo 8 | O lixo aparece como uma mancha pequena, e o resto fica variado |
| Os tipos de peça 139 a 151 e a categoria 14 `sea` "Mar" | Os 131 a 138 são da [giant-rocks](../giant-rocks/), feita junto |
| As ilhas de hoje ganham as decorações da Comum na água | São as decorações naturais do bioma, como as da terra; a Borracha as tira |
| As linhas da carga inicial (`seed-data`) não mudam | São a foto da carga inicial |

## Fora do escopo

- Coral, peixes, animação própria da água em volta da decoração e reflexo.
- O lixo mudar alguma regra (Toxina, itens, recompensa).
- Arte nova do chão da água.

## Pré-requisitos

- [nature-variety](../nature-variety/): o traço das decorações e o `make_nature.py`.
- [biome-zones](../biome-zones/): as zonas, `assignZones`, a ferramenta Zona.
- [coast-rivers](../coast-rivers/): o mar, os lagos e os rios.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-sea-art](01-sea-art.md) | A arte dos 13 tipos e a prévia | concluída (falta o dono aprovar a prévia) |
| 2 | [02-sea-zones](02-sea-zones.md) | As receitas, as zonas e quem nasce nelas | concluída (falta o dono conferir no jogo) |
| 3 | [03-sea-props](03-sea-props.md) | Os tipos de peça, a categoria Mar e o grupo do pincel | concluída (falta o dono conferir no F2) |
| 4 | [04-trash-and-density](04-trash-and-density.md) | O lixo reconhecível (garrafa PET, lata, sacola, bota, pneu e galão) e a água com bem menos decoração | concluída (falta o dono conferir no jogo) |

## Resultado da verificação

Em 2026-11-20:

- **A arte:** o `make_sea.py` rodado duas vezes dá a mesma folha (192×4096). A prévia das 8 receitas sobre a água e a cena num `HexMapView` de verdade, numa cena temporária (apagada), foram mandadas ao dono.
- **As receitas:** numa cena temporária com o catálogo do servidor, todo tipo das receitas está em `KIND_ROWS` e `KIND_RADIUS`, toda zona do catálogo tem receita, e 400 hexágonos de cada receita dão a mistura da tabela (o lixo da Comum rasa: 14 peças em 400 hexágonos).
- **O banco:** as migrations `sea_zones` e `sea_props` foram aplicadas; os 13 tipos estão na categoria 14.
- **O servidor:** `npm run lint`, `npm run typecheck` e `npm test` (1.069 testes) passam, com o teste novo de `assignZones` para as zonas da água, que confere a parte de cada zona e que a terra não muda. A suíte e2e deu 694 de 696: as 2 falhas do `seed.e2e` de antes (`species_day_phases` e `species_skills`, linhas do JSON que não estão no banco).
- **O jogo:** `godot --headless --path client --quit-after 60` sobe sem erro de script.
- **Falta o dono:** ver o mar num mapa sorteado e usar o grupo Mar e a ferramenta Zona no F2.
