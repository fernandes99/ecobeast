# 02. Tela do Bestiário

- **Status:** concluída (falta o teste do dono no editor)
- **Depende de:** [01-codex-records](01-codex-records.md), [architecture.md](architecture.md)

## Contexto

O servidor já guarda e devolve o Bestiário (`GET /v1/me/codex`). No jogo:

- O Hub (`res://screens/hub/hub_screen.gd`) leva o card e a aba "Bestiário" para a tela placeholder, em `DESTINATIONS`.
- O `GameData` tem as espécies (`get_all_species`, `get_species`), as evoluções (`get_evolutions`) e as tabelas `species_biomes` e `biomes` (`get_rows`, `get_row`).
- O `CreaturePortrait` (`res://ui/components/creature_portrait.gd`) mostra o `front.png` da espécie, ou uma forma na cor do Elemento quando falta a arte. O `ElementBadge` mostra um Elemento.

Godot, para quem está começando: um **`GridContainer`** arruma os filhos em colunas, e um **`ScrollContainer`** em volta deixa a grade rolar quando ela não cabe. Um **shader** é um programa pequeno que a placa de vídeo roda para cada pixel de um nó; aqui ele pinta todo pixel visível com a mesma cor, e a arte vira uma sombra com o mesmo contorno.

## Escopo

- A tela `codex`, com a contagem, a grade e o detalhe.
- O Hub abrindo a tela.
- A sombra no `CreaturePortrait`.
- O botão "Limpar Bestiário" em build de debug.

## Fora do escopo

- O aviso de registro: vem na [03](03-codex-registered.md).
- Busca, filtro e ordenação.

## Requisitos

### Dados

- **RF-01:** `Codex` (`res://domain/models/codex.gd`) lê o `entries` em `from_dict` e tem `status(species_id)`, `seen_count()` e `caught_count()`, como na [arquitetura](architecture.md#jogo). Uma entrada sem `species_id` válido é ignorada.
- **RF-02:** `Session.load_codex()` devolve um `Result` com o `Codex`. `Session.debug_clear_codex()` chama o `DELETE` e só existe para a build de debug.

### Grade

- **RF-03:** a tela `codex` lê o Bestiário ao abrir. Enquanto ele não chega, mostra "Carregando..."; com erro, mostra o erro e o botão de voltar, como as outras telas.
- **RF-04:** no topo, o título "Bestiário" e dois chips, "Vistos" e "Capturados", com as contagens do `Codex`.
- **RF-05:** a grade tem 3 colunas e uma célula por espécie do catálogo, na ordem do `id`, e rola na vertical. Cada célula mostra o número `#%03d` no canto.
  - **Capturado:** a arte colorida, o nome e uma marca de capturado no canto.
  - **Visto:** a arte como sombra e o nome.
  - **Nunca visto:** "???" no lugar da arte, sem nome.
- **RF-06:** tocar num capturado ou num visto abre o detalhe. Tocar num "???" não faz nada.

### Detalhe

- **RF-07:** o detalhe abre por cima da grade, com o número no título, e fecha no voltar da tela e no do aparelho (`handle_back`).
- **RF-08:** o detalhe de um **capturado** mostra, de cima para baixo: a arte, o nome, os Elementos (`ElementBadge`), a descrição, a altura e o peso, o habitat e a linha evolutiva. Ele rola se não couber.
- **RF-09:** o habitat lista os nomes dos biomas de `species_biomes` com taxa acima de 0, do mais comum para o mais raro, separados por vírgula. Sem nenhum, mostra "Desconhecido".
- **RF-10:** a linha evolutiva tem todas as espécies da família, da primeira forma até as últimas, ligadas por setas, com "nv. {min_level}" embaixo da seta de quem evolui por nível. Cada uma segue a regra da grade (colorida, sombra ou "???"). Tocar numa que não seja "???" troca o detalhe pelo dela. Quem não evolui nem vem de outra mostra só ela mesma.
- **RF-11:** o detalhe de um **visto** mostra só a arte como sombra, o nome e "Capture um {nome} para ver os dados dele."

### Hub e depuração

- **RF-12:** o card e a aba "Bestiário" do Hub abrem a tela `codex`.
- **RF-13:** só em build de debug, a grade tem o botão "Limpar Bestiário" no fim. Tocar nele chama `Session.debug_clear_codex()` e relê o Bestiário.

## Critérios de aceite

- [ ] O card e a aba Bestiário do Hub abrem a tela, com as contagens certas.
- [ ] A grade mostra todas as espécies do catálogo, coloridas, em sombra ou "???", na ordem do número.
- [ ] Um capturado abre o detalhe completo, e um visto, o detalhe só com a sombra.
- [ ] A linha evolutiva do Ruvo mostra as três formas, com "???" para quem nunca foi visto, e tocar numa forma conhecida troca o detalhe.
- [ ] Uma espécie sem arte aparece com a forma do Elemento, colorida ou em sombra.
- [ ] Voltar fecha o detalhe e, depois, a tela.
- [ ] "Limpar Bestiário" deixa tudo "???" na build de debug.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos:

- `res://domain/models/codex.gd`: `Codex`.
- `res://ui/components/silhouette.gdshader`: a sombra, com a cor recebida como parâmetro.
- `res://screens/codex/codex_screen.gd` e `.tscn`: a tela, com a grade e o detalhe.
- `res://screens/codex/codex_cell.gd` e `.tscn`: a célula da grade, um `TapPanel`.
- `res://screens/codex/codex_detail.gd` e `.tscn`: o detalhe, com a linha evolutiva.

Arquivos alterados:

- `res://core/services/game_service.gd` e `api_game_service.gd`: `load_codex` e `debug_clear_codex`.
- `res://core/autoload/session.gd`: `load_codex` e `debug_clear_codex`.
- `res://core/autoload/router.gd`: o id `codex` em `SCREENS`.
- `res://core/autoload/game_data.gd` e `res://core/data/catalog.gd`: os biomas de uma espécie, do mais comum para o mais raro, e a família evolutiva de uma espécie.
- `res://ui/components/creature_portrait.gd`: `set_silhouette`, com o shader na arte e a forma de quando falta a arte desenhada em `SILHOUETTE`.
- `res://ui/theme/palette.gd`: `SILHOUETTE`.
- `res://screens/hub/hub_screen.gd`: o destino "Bestiário".
- `client/CLAUDE.md` e `TELAS.md`: uma linha sobre o Bestiário.

## Verificação

```bash
cd server && npm run start:dev
godot --headless -d --path client --quit-after 60
```

No editor (F5), em 360×640:

- Abrir o Bestiário pelo card e pela aba, e conferir as contagens.
- Abrir o detalhe de um capturado e de um visto, e andar pela linha evolutiva.
- Na build de debug, limpar o Bestiário, lutar contra um selvagem e conferir que ele aparece como sombra.

O que foi conferido em 2026-11-10: o projeto abre sem erro de script, e os avisos com `-d` são de arquivos que esta fase não tocou (o "resources still in use" no fim já aparecia antes). Uma cena temporária, que roda com os autoloads e o catálogo do servidor e já foi apagada, compilou os scripts da tela e conferiu: o `Codex` lê as entradas e ignora as inválidas, com as contagens; a linha do Ruvak é Ruvo, Ruvak e Ruvaroth, com "nv. 16" na primeira seta; o habitat do Ruvak tem 5 biomas, do mais comum para o mais raro; a célula colorida tem a marca da Esfera, a vista tem a sombra e a nunca vista não tem nome; o detalhe de um capturado mostra "1,0 m", o Ruvaroth nunca visto como "???", e tocar no Ruvo troca o detalhe; o detalhe de um visto mostra só a dica. Os passos no editor ficam para o dono.

## Tarefas

- [x] Modelo e serviços.
- [x] A sombra no `CreaturePortrait`.
- [x] A grade e a contagem.
- [x] O detalhe e a linha evolutiva.
- [x] O Hub e o botão de depuração.
- [x] Atualizar o `client/CLAUDE.md` e o `TELAS.md`, rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.
