# 02. As crianças da vila

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [01](01-villagers.md), [tamer-appearance](../tamer-appearance/)

## Contexto

Em 2026-11-22, o dono pediu "Crie 3 NPCs genéricos que serão crianças". Hoje uma pessoa só pode ter um dos dois corpos de adulto, Masculino e Feminino, da altura do Domador, e nada no jogo diminui um NPC. Perguntado, o dono escolheu um corpo de criança novo, menor, em vez de vestir um adulto de criança ou de encolher o boneco, que distorceria a pixel art.

## Escopo

- Dois corpos de criança, Menino e Menina, só para NPCs.
- As folhas da criança: os dois corpos e cada peça de hoje no tamanho dela, geradas pelo `make_wardrobe.gd`.
- Três crianças no catálogo `npcs`, com a fala padrão.

## Fora do escopo

- O Domador do jogador como criança: os corpos de criança não aparecem na tela Aparência dele, e o servidor os recusa.
- Peças só de criança.
- Pôr as crianças em Liora (o dono faz no F2).

## Requisitos

- **RF-01:** `body_types` ganha `adult_body_type_id` (int, opcional, FK `body_types`, `Restrict`): o corpo de adulto cujas peças a criança veste. Nulo é corpo de adulto. A migration `village_children` cria a coluna e os corpos 3 (`boy`, "Menino", adulto 1) e 4 (`girl`, "Menina", adulto 2).
- **RF-02:** Uma peça serve num corpo quando o `body_type_id` dela é nulo, é o do corpo ou é o adulto do corpo. A Saia (só do corpo 2) serve na Menina.
- **RF-03:** A arte da criança sai do mesmo template do Domador, sem 3 linhas do meio do tronco (as linhas 14 a 16 a partir do alto da cabeça): a cabeça e as pernas ficam iguais, e o tronco desce de 7 para 4 linhas. A criança tem 22 pixels de altura, contra os 25 do adulto. Na criança, a manga da camiseta tem 3 linhas, a cintura do corpo Menina não afina e o cabelo Comprido para 2 linhas mais acima. O `make_wardrobe.gd` grava `bodies/boy/` e `bodies/girl/`, e cada peça também em `parts/<slug>/child/`, com os mesmos nomes de folha (`idle.png`, `run.png`, `_back` e `_short`). As folhas de adulto não mudam, pixel a pixel.
- **RF-04:** O `TamerSprite` de um corpo com `adult_body_type_id` usa as folhas das peças de `parts/<slug>/child/`.
- **RF-05:** O `PUT /v1/me/appearance` recusa um corpo de criança com "Esse corpo é só de NPC.". O `PUT /v1/editor/npcs/:id/appearance` aceita. A tela Aparência só mostra os corpos de criança no modo NPC (o botão Aparência da ferramenta NPC do F2).
- **RF-06:** O `CatalogValidator` confere que o adulto de um corpo é um corpo de adulto e aplica a regra do RF-02 às peças dos NPCs.
- **RF-07:** As crianças (descrição "Criança da Vila Raiz."; voz Aguda; nomes, roupas e falas _a revisar_):

| id | slug | name | corpo | pele | fala |
| --- | --- | --- | --- | --- | --- |
| 17 | `villager_juca` | Juca | Menino | 5 | Aposto que eu corro mais rápido que o seu Ecobeast! |
| 18 | `villager_nina` | Nina | Menina | 7 | Quando eu crescer, vou ter um Ecobeast de cada Elemento! |
| 19 | `villager_bia` | Bia | Menina | 1 | Psiu! Tem um Puffcoo dormindo ali. Não acorda ele! |

- **RF-08:** As roupas (peça e paleta por lugar; o rosto não tem paleta):

| id | rosto | cabelo | parte de cima | parte de baixo | calçado | chapéu |
| --- | --- | --- | --- | --- | --- | --- |
| 17 | 1 | Espetado, Castanho | Camiseta, Vermelho | Bermuda, Azul | Tênis, Branco | Boné, Azul |
| 18 | 1 | Rabo de cavalo, Preto | Regata, Rosa | Saia, Roxo | Tênis, Amarelo | — |
| 19 | 2 | Comprido, Ruivo | Camiseta, Amarelo | Bermuda, Verde | Bota, Preto | — |

## Critérios de aceite

- [x] As 3 crianças estão no catálogo, e o jogo abre sem erro do `CatalogValidator`.
- [x] As folhas de adulto saem iguais do `make_wardrobe.gd`.
- [x] O `PUT /v1/me/appearance` com o corpo 3 responde 400 "Esse corpo é só de NPC.", e o do editor de NPCs aceita.
- [ ] No F2, a Nina posta em Liora aparece menor que um adulto, de saia, com a fala dela.
- [ ] A tela Aparência do jogador mostra só Masculino e Feminino.

## Desenho técnico

- `server/prisma/schema.prisma`: `BodyType.adultBodyTypeId Int? @map("adult_body_type_id")` e a relação consigo mesmo; a migration à mão e o `prisma migrate deploy`.
- O seed (`body_types.json`, `npcs.json` e `npc_appearance_parts.json`) com as mesmas linhas, como na fase 1, porque o `bundle.e2e` compara as colunas do catálogo com as do JSON; `catalog-tables.spec.ts` lista os corpos e as crianças.
- `server/src/domain/appearance/appearance.ts`: `bodies` com `adultBodyTypeId`, a regra do RF-02 e a opção `npc`, que libera o corpo de criança; `server/src/player/appearance-check.ts` passa a opção; `npcs-editor.service.ts` chama com `npc: true`.
- `client/core/data/catalog_schema.gd` e `catalog_validator.gd`; `client/ui/components/tamer_sprite.gd`, `tamer_editor.gd` (`allow_child_bodies`) e `screens/appearance/appearance_screen.gd`.
- `client/assets/tamer/make_wardrobe.gd`: as medidas do tronco e das pernas em cada `Frame`, o corte das 3 linhas e as saídas da criança.
- `.specs/game-data/architecture.md` e `.specs/tamer-appearance/architecture.md`: a coluna e a pasta `child/`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
cd client && godot --headless -s res://assets/tamer/make_wardrobe.gd
godot --headless --path client --quit-after 30
```

E uma cena temporária em `client/zz_tmp_check` (apagada no fim) que baixa o catálogo e monta as 3 crianças com `TamerAppearance.for_npc`, conferindo que cada camada achou a folha.

Manual (F2 e F5): os critérios de aceite.

## Tarefas

- [x] A arte da criança no `make_wardrobe.gd`.
- [x] Migration, schema, a regra da peça e a recusa do corpo de criança no servidor.
- [x] O catálogo, o validador, o `TamerSprite` e a tela Aparência no jogo.
- [x] As specs e o `CLAUDE.md`.
