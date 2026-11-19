# 01. Os moradores da vila

- **Status:** concluída (falta o dono conferir no F2 e no F5)
- **Depende de:** [island-npcs](../island-npcs/), [liora-intro/02](../liora-intro/02-person-npcs.md), [dialogue-voices](../dialogue-voices/), [interiors/03](../interiors/03-interior-editor.md)

## Contexto

Ver o [README](README.md#contexto).

## Escopo

- A coluna `npcs.default_dialogue` e os 10 moradores, na migration e no seed.
- A coluna no catálogo do jogo.
- A fala padrão ao pôr o NPC na ferramenta NPC do F2 e no modo Interiores.

## Fora do escopo

- Pôr os moradores em Liora (o dono faz no F2).
- Arte nova de pessoa.

## Requisitos

- **RF-01:** A migration `village_crowd` cria `npcs.default_dialogue` (`TEXT NOT NULL DEFAULT ''`, CHECK `npcs_default_dialogue_check` de até 2.000 caracteres, como `island_npcs.dialogue`) e os 10 moradores abaixo, com as peças em `npc_appearance_parts`. O seed (`npcs.json`, `npc_appearance_parts.json`) tem as mesmas linhas, e os NPCs de antes ganham `"default_dialogue": ""`.
- **RF-02:** Os moradores (descrição "Morador da Vila Raiz." ou "Moradora da Vila Raiz."; a pele é o id da paleta; os nomes, as roupas e as falas são _a revisar_):

| id | slug | name | corpo | pele | voz | fala |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | `villager_tome` | Tomé | masculino | 4 | Média | Bom dia! A colheita está boa este ano. |
| 8 | `villager_baltazar` | Baltazar | masculino | 6 | Grave | Na minha época, os Ecobeasts selvagens chegavam até a praça. |
| 9 | `villager_caio` | Caio | masculino | 5 | Média | Um dia eu ainda vou ser Domador também! |
| 10 | `villager_severino` | Severino | masculino | 7 | Grave | Cuidado com o mato alto. Sempre tem Ecobeast escondido lá. |
| 11 | `villager_joaquim` | Joaquim | masculino | 1 | Média | O vento está forte hoje. Bom dia para soltar pipa. |
| 12 | `villager_lucia` | Lúcia | feminino | 4 | Aguda | Que bom te ver por aqui! A vila anda movimentada. |
| 13 | `villager_benedita` | Benedita | feminino | 5 | Média | Já passou no Refúgio? Eles cuidam muito bem dos Ecobeasts. |
| 14 | `villager_clara` | Clara | feminino | 1 | Aguda | Estou procurando flores para a minha horta. |
| 15 | `villager_rosa` | Rosa | feminino | 8 | Média | Dizem que à noite aparecem vagalumes perto do campo. |
| 16 | `villager_dalia` | Dália | feminino | 6 | Aguda | A Loja recebeu Esferas novas. Vale a pena dar uma olhada. |

- **RF-03:** As roupas (peça e paleta por lugar; o rosto não tem paleta):

| id | rosto | cabelo | parte de cima | parte de baixo | calçado | chapéu |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | 1 | Curto, Castanho | Camiseta, Verde | Calça, Cinza | Bota, Preto | Chapéu de palha, Amarelo |
| 8 | 2 | Curto, Branco | Jaqueta, Roxo | Calça, Preto | Bota, Cinza | — |
| 9 | 1 | Espetado, Preto | Regata, Laranja | Bermuda, Azul | Tênis, Branco | Boné, Vermelho |
| 10 | 2 | Curto, Preto | Camiseta, Branco | Calça, Azul | Bota, Preto | — |
| 11 | 1 | Espetado, Ruivo | Jaqueta, Verde | Bermuda, Cinza | Tênis, Vermelho | — |
| 12 | 2 | Comprido, Loiro | Camiseta, Rosa | Saia, Roxo | Tênis, Branco | — |
| 13 | 1 | Rabo de cavalo, Branco | Jaqueta, Vermelho | Saia, Cinza | Bota, Preto | — |
| 14 | 2 | Rabo de cavalo, Rosa | Regata, Amarelo | Bermuda, Verde | Tênis, Azul | Boné, Branco |
| 15 | 1 | Comprido, Preto | Camiseta, Laranja | Calça, Azul | Bota, Cinza | — |
| 16 | 2 | Comprido, Castanho | Jaqueta, Azul | Saia, Preto | Tênis, Rosa | Chapéu de palha, Amarelo |

- **RF-04:** `GET /v1/catalog` leva `default_dialogue` em cada NPC, e o `catalog_schema.gd` aceita a coluna (texto).
- **RF-05:** Na ferramenta NPC do F2, pôr um NPC numa ilha já preenche o diálogo com o `default_dialogue` dele. No modo Interiores, pôr um NPC com a caixa Fala vazia usa o `default_dialogue`; com texto, usa o texto. Nos dois, a fala continua editável e entra no desfazer como antes.

## Critérios de aceite

- [x] Os 10 moradores estão no catálogo, e o jogo abre sem erro do `CatalogValidator`.
- [ ] No F2, pôr a Lúcia em Liora mostra a fala dela na caixa de diálogo, e ela aparece de pessoa, com a roupa da tabela.
- [ ] Em Explorar, um morador passeia pelos hexágonos marcados e fala ao ser tocado.
- [ ] Pôr o Avô no F2 continua com o diálogo vazio.

## Desenho técnico

- `server/prisma/schema.prisma`: `Npc.defaultDialogue String @default("") @map("default_dialogue")`; a migration à mão e o `prisma migrate deploy`.
- `server/prisma/seed-data/npcs.json` e `npc_appearance_parts.json`.
- `server/test/database.e2e-spec.ts`: o CHECK da fala padrão. `server/src/catalog/catalog-tables.spec.ts`: os moradores no seed, com a pele e as cores do tipo certo e a fala padrão.
- `client/core/data/catalog_schema.gd`: a coluna.
- `client/tools/map_editor/npc_panel.gd` (`place`) e `client/tools/interior_editor/interior_editor.gd` (o pôr NPC).
- `.specs/game-data/architecture.md`: a coluna no parágrafo de `npcs`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```

E uma cena temporária em `client/zz_tmp_check` (apagada no fim) que baixa o catálogo, confere os 10 moradores com `TamerAppearance.for_npc` e chama o `place` do `NpcPanel` num `IslandDraft` de memória, sem salvar ilha nenhuma.

Manual (F2 e F5): os critérios de aceite.

## Tarefas

- [x] Migration, schema, seed e o teste do CHECK.
- [x] O catálogo do jogo e a fala padrão no F2.
- [x] O `game-data/architecture.md`, o `README.md` e o `roadmap.md` das specs, e o `CLAUDE.md` da raiz.
