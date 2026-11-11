# 01. A quantidade de Ecobeasts de cada área

- **Status:** concluída
- **Depende de:** [map-editor](../map-editor/) concluída, [architecture.md](architecture.md)

## Contexto

Na [map-editor/04](../map-editor/04-buildings-and-areas.md), cada área de Ecobeasts ganhou um nome, uma cor e uma lista de espécies, com peso e níveis. Ela ainda não diz **quantos** Ecobeasts nascem nela. O dono decidiu que a quantidade é definida área por área no editor, e não pelo tamanho da área. Esta fase guarda esse número no banco, nas rotas do editor e no painel da área, para a [02](02-island-exploration.md) usá-lo no sorteio.

## Escopo

- A coluna `spawn_count` em `island_areas`, com a migração.
- O campo `spawn_count` no rascunho das rotas do editor, conferido ao salvar e incluído no `content_hash`.
- O campo "Ecobeasts nesta área" no painel da área do editor.

## Fora do escopo

- Usar a quantidade para sortear os Ecobeasts (a [02](02-island-exploration.md)).
- Uma quantidade sugerida pelo tamanho da área.

## Requisitos

### Servidor

- **RF-01:** `island_areas` ganha `spawn_count`, um inteiro com `CHECK` de 1 a 200 e padrão 10 (_a revisar_). A migração dá 10 às áreas que já existem.
- **RF-02:** cada área do rascunho, em `POST /v1/editor/islands` e `PUT /v1/editor/islands/:id`, tem `spawn_count`, obrigatório. Sem ser inteiro, a rota responde `400` com "spawn_count precisa ser um número inteiro.", como os outros números do rascunho. Fora de 1 a 200, responde `400` com "Na área N, a quantidade de Ecobeasts precisa ir de 1 a 200.", com o `key` da área no lugar de N.
- **RF-03:** `GET /v1/editor/islands/:id` devolve o `spawn_count` de cada área, e publicar copia o número para a versão publicada.
- **RF-04:** o JSON canônico do `content_hash` (`canonicalDraft`) tem o `spawn_count` de cada área. Por isso, uma ilha publicada antes desta fase aparece como "Publicada, com mudanças" na primeira vez que for salva, até ser publicada de novo. As ilhas não são recalculadas na migração.

### Editor

- **RF-05:** o painel da área escolhida ganha "Ecobeasts nesta área", um `EditorNumberField` de 1 a 200 logo abaixo do nome. Um número fora da faixa fica vermelho e não muda o rascunho, como o peso e os níveis das espécies.
- **RF-06:** uma área nova começa com 10. Uma área lida do servidor mostra o número dela.
- **RF-07:** mudar o número é um passo do desfazer, juntando os passos enquanto se digita no mesmo campo, como os outros campos do painel (map-editor/04, RF-09).

## Critérios de aceite

- [x] Salvar uma área com `spawn_count` 0 ou 201 responde `400` com a mensagem da área, e com 2,5, ou sem o campo, com a mensagem de número inteiro.
- [x] Salvar e ler de volta traz o `spawn_count` de cada área; publicar copia o número.
- [x] Uma ilha publicada antes da migração fica com 10 em todas as áreas.
- [x] No editor, uma área nova mostra 10; mudar para 25, salvar, fechar o jogo e abrir a ilha mostra 25.
- [x] Desfazer volta o número anterior.
- [x] Os testes do servidor passam, e o projeto abre sem erros nem avisos de script.

## Desenho técnico

Servidor:

- `server/prisma/schema.prisma`: `IslandArea.spawnCount Int @default(10) @map("spawn_count")`. Migração nova com a coluna e o `CHECK` escrito à mão (`spawn_count BETWEEN 1 AND 200`), como os outros `CHECK` das ilhas.
- `server/src/domain/islands/island-draft.ts`: `DraftArea.spawnCount`; `MAX_AREA_SPAWNS = 200` e `MIN_AREA_SPAWNS = 1`; a conferência no `areaError`, logo depois da cor; o campo no `canonicalDraft`.
- `server/src/editor/islands-editor.dto.ts`: `DraftAreaDto.spawn_count`, com `@IsInt` e a descrição para o `/docs`. A faixa é conferida no `draftError`, que monta a mensagem com o `key`.
- `server/src/editor/islands-editor.service.ts`: o campo no `writeVersion`, no `readVersion` e na conversão do DTO.
- Testes: `island-draft.spec.ts` (a faixa e o hash), `test/islands-editor.e2e-spec.ts` (o `400`, a leitura e o publicar) e `test/database.e2e-spec.ts` (o `CHECK`).

Jogo, em `res://tools/map_editor/`:

- `area_panel.gd`: o campo "Ecobeasts nesta área" abaixo do nome.
- `area_panel.gd` também cria a área nova (`_new_area`), que passa a nascer com `spawn_count` 10.
- `island_draft.gd`: o `from_dict` e o `to_dict` já passam o dicionário da área inteiro; só muda se algum ponto montar a área campo a campo.
- `editor_history.gd`: nada novo, porque o passo de área já guarda a lista de áreas inteira antes e depois.

Documentos:

- `.specs/map-editor/architecture.md`: o campo `spawn_count` no contrato do rascunho e na linha da tabela `island_areas`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 60
```

No editor (F5, depois F2), com o servidor local: criar uma área, ver o 10, mudar para 25, desfazer e refazer, salvar, fechar o jogo, abrir de novo e conferir o 25. Pôr 0 e ver o campo vermelho.

Feita em 2026-11-11:
- **Servidor:** lint e tipos limpos; 793 testes de unidade, 453 e2e e 128 e2e legados passando. Os novos conferem a faixa e o hash no domínio, o `400` das duas mensagens, a leitura e a cópia ao publicar, e o `CHECK` do banco.
- **Migração:** aplicada no banco. As áreas da ilha que já existia (id 85), no rascunho e na publicada, ficaram com 10.
- **Projeto:** abre sem erro de script. Com `-d`, os avisos são os de antes.
- **Cena temporária, já apagada:** a área nova com 10; digitar 2 e 25 muda o rascunho num passo só; 0 e 201 deixam o campo vermelho sem mudar o rascunho; desfazer volta o 10 e refazer o 25; o `to_dict` e o `from_dict` levam o número.
- **Quadro do Movie Maker:** o painel da área com "Ecobeasts nesta área" logo abaixo do nome.
- **Para o dono:** no F5, abrir a ilha, conferir o 10 nas áreas, mudar um número, salvar e reabrir. A ilha vai aparecer como "Publicada, com mudanças" na primeira vez que for salva (RF-04).

## Tarefas

- [x] A coluna, a migração e o `CHECK`.
- [x] O campo no rascunho, na conferência, no hash e nas rotas, com os testes.
- [x] O campo no painel da área.
- [x] Rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README da iniciativa.
