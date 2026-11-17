# 02. Os NPCs pessoas

- **Status:** concluída
- **Depende de:** [island-npcs](../island-npcs/), [tamer-appearance](../tamer-appearance/)

## Contexto

O avô, a Mira e o responsável do Refúgio são pessoas, e um NPC hoje é sempre o desenho de um Ecobeast ([README](README.md#contexto)). Esta fase deixa um NPC ter a aparência em camadas do Domador e dá ao dono um jeito de vesti-lo no F2 ([architecture](architecture.md#os-npcs-pessoas)).

## Escopo

- O catálogo dos NPCs com a aparência de pessoa.
- O desenho no mapa, nos atores das cenas e no mapa grande.
- O botão Aparência na ferramenta NPC do F2 e a rota do editor.
- Os três NPCs da introdução no catálogo.

## Fora do escopo

- Criar ou apagar NPCs do catálogo pelo F2 (continua pelo painel do Supabase e pelo seed).
- Arte nova de pessoa: as camadas provisórias da [tamer-appearance](../tamer-appearance/).
- Um NPC pessoa andar com outra animação que não a do Domador.

## Requisitos

- **RF-01:** A migration `person_npcs` muda `npcs` e cria `npc_appearance_parts` como no [architecture](architecture.md#os-npcs-pessoas), com o CHECK `npcs_look_check`.
- **RF-02:** O seed e a migration criam os NPCs pessoas abaixo, cada um com uma roupa inicial (rosto, cabelo, parte de cima, parte de baixo e calçado, com cores), que o dono troca no F2. Os nomes, as peles e as roupas são _a revisar_:

| id | slug | name | description | corpo |
| --- | --- | --- | --- | --- |
| 3 | `grandpa` | Avô | O avô do Domador, que mora na Vila Raiz. | masculino |
| 4 | `mira` | Mira | Amiga de infância do Domador, de volta do Instituto Meridian. | feminino |
| 5 | `refuge_keeper` | Responsável do Refúgio | Cuida do Refúgio da Vila Raiz e dos Ecobeasts jovens. | masculino |

- **RF-03:** `GET /v1/catalog` inclui `npc_appearance_parts`, e os NPCs vêm com `sprite`, `body_type_id` e `skin_palette_id` (nulos quando não valem).
- **RF-04:** O `CatalogValidator` confere: um NPC com sprite ou com corpo, nunca os dois nem nenhum; as peças de NPC com as mesmas regras das do Domador (lugar da peça, corpo da peça, paleta do tipo certo); e as peças só em NPCs pessoas.
- **RF-05:** Em Explorar, o NPC pessoa aparece como um `TamerSprite` com a aparência dele, parado ou passeando como os outros NPCs, e virado para quem fala com ele. O mesmo vale para um ator de cena com esse `npc_id` e para o ícone do NPC no mapa grande.
- **RF-06:** A ferramenta NPC do F2 mostra, para o NPC escolhido que é pessoa, o botão "Aparência". Ele abre a tela Aparência no modo NPC (`setup({"npc_id": id})`) numa janela por cima do editor, já que o F2 cobre as telas do `Router`. A tela tem o título "Aparência de <nome>", a aparência do NPC e o mesmo "Salvar", que grava por `PUT /v1/editor/npcs/:id/appearance`; o Voltar e o Salvar fecham a janela pelo sinal `closed(saved)`. Na lista do F2 e nas marcas de ator da ferramenta Cenas, o NPC pessoa aparece com o ícone de pessoa (`res://ui/icons/person.svg`), já que as camadas pintadas pelo shader não viram um quadro só.
- **RF-07:** Depois de salvar, o jogo baixa o catálogo de novo (`GameData.load_catalog()`), e o NPC aparece com a roupa nova no mapa do editor e no jogo.
- **RF-08:** A rota recusa um NPC de Ecobeast (400 "Esse NPC é um Ecobeast."), um NPC que não existe (404 "NPC não encontrado.") e peças inválidas com as mensagens do `PUT /v1/me/appearance`.

## Critérios de aceite

- [x] O Avô, a Mira e o Responsável do Refúgio estão no catálogo, e o jogo abre sem erro do `CatalogValidator`.
- [ ] No F2, pôr a Mira numa ilha, tocar em Aparência, trocar o cabelo e salvar muda o desenho dela no editor.
- [ ] Em Explorar, a Mira aparece de pessoa e fala o diálogo da ilha.
- [ ] Uma cena com um ator da Mira mostra a Mira de pessoa, andando.
- [ ] Os NPCs de Ecobeast (Ruvo e Ruvak) continuam iguais.

## Desenho técnico

- `server/prisma/schema.prisma`: `Npc.sprite String?`, `bodyTypeId`, `skinPaletteId` e o modelo `NpcAppearancePart`; a migration e o seed (`npcs.json`, `npc_appearance_parts.json`).
- `server/src/catalog/`: a tabela nova na lista do catálogo e os testes da carga inicial (`catalog-tables.spec.ts`).
- `server/src/editor/npcs-editor.controller.ts`, `.service.ts`, `.dto.ts` (novos): a rota, reusando a conferência das peças do `PlayerService` (extraída para uma função comum, se for preciso).
- `client/core/data/catalog_schema.gd` e o `CatalogValidator`: a tabela e as regras.
- `client/domain/models/tamer_appearance.gd`: `for_npc`.
- `client/ui/components/npc_sprite.gd`: o `TamerSprite` para a pessoa. `client/screens/exploration/exploration_screen.gd`: não pular o NPC sem `sprite` (hoje `CreatureSprite.has_sheets` o descarta).
- `client/screens/appearance/appearance_screen.gd`: o modo NPC.
- `client/tools/map_editor/`: o botão no painel do NPC.
- O e2e de contagem de tabelas e linhas ganha `npc_appearance_parts` e os NPCs novos.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```

Manual (F2 e F5): os critérios de aceite.

## Tarefas

- [x] Migration, schema, seed e catálogo, com os testes.
- [x] A rota do editor, com os testes.
- [x] O `CatalogValidator` e o `for_npc`.
- [x] O desenho no mapa, nos atores e no mapa grande.
- [x] O botão Aparência e o modo NPC da tela.
