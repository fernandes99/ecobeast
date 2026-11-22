# 03. O Perfil com os números

- **Status:** concluída (falta o dono conferir no jogo e no celular)
- **Depende de:** [01-counters-server](01-counters-server.md) e [02-play-ping](02-play-ping.md)

## Contexto

O Perfil de hoje (`res://screens/profile/profile_screen.gd` e `.tscn`, [hub-start/02](../hub-start/02-ecobeasts-profile-settings.md)) mostra o Domador desenhado, o nome, uma grade com o nível, as moedas e as espécies do Bestiário, e o botão Aparência. Esta fase troca a grade pelo esboço A, que o dono escolheu: 3 destaques no topo e 5 abas por tema, com os números do `GET /v1/me/counters`.

## Escopo

- O modelo dos contadores no jogo, a leitura pelo `Session` e a tela Perfil refeita.

## Fora do escopo

- Barras do próximo marco, conquistas e compartilhar o Perfil.
- Mudar a tela Aparência e as Configurações.

## Requisitos

- **RF-01:** O topo do Perfil mostra o Domador desenhado (o `TamerSprite` de hoje, menor, ao lado do texto), o nome, "Nível N" e "Domador desde DD/MM/AAAA", pelo `created_at`.
- **RF-02:** Embaixo, 3 destaques lado a lado, cada um com o número grande e o nome: **Vitórias** (`wins_wild` + `wins_tamer`), **Capturas** (`captures`) e **Jogadas** (as horas de `play_seconds`).
- **RF-03:** Embaixo, as abas **Luta**, **Captura**, **Mapa**, **Ecobeasts** e **Geral**, com a Luta aberta. Cada aba é uma lista de linhas "nome … valor", com as linhas do [architecture.md](architecture.md#o-perfil):
  - **Luta:** Vitórias contra selvagens, Vitórias contra Domadores, Derrotas e Taxa de vitória;
  - **Captura:** Capturas, Esferas usadas, Na primeira Esfera, Espécies vistas, Espécies capturadas, uma linha por Elemento com captura (o nome e a cor do Elemento) e uma por parte do dia com captura;
  - **Mapa:** Hexágonos andados, Mapas explorados e Biomas pisados ("9 de 12", com `walkable_biomes`);
  - **Ecobeasts:** XP ganho e o Parceiro, com o `CreatureFace` da espécie, o nome dela e "212 lutas", ou "Ainda nenhum" sem parceiro;
  - **Geral:** Horas jogadas, Dias jogados, Dias seguidos, Moedas, Moedas ganhas, Moedas gastas e Curas no Refúgio.
- **RF-04:** A taxa de vitória é `round(100 × vitórias ÷ (vitórias + derrotas))` seguida de "%", ou "—" sem vitória nem derrota.
- **RF-05:** O tempo aparece como "37h" nos destaques e "37h 12min" na aba Geral; abaixo de 1 hora, "12min" nos dois.
- **RF-06:** Os números passam pelo `NumberFormat.thousands`. Um contador sem linha vale 0.
- **RF-07:** Enquanto os números carregam, os valores mostram "…". Se a leitura falhar, a mensagem de erro aparece no lugar das abas, e o resto do Perfil continua.
- **RF-08:** O botão Aparência e o Voltar continuam como hoje.

## Critérios de aceite

- [ ] Um Domador novo vê 0 nos destaques, "—" na taxa de vitória, "0 de N" nos biomas e "Ainda nenhum" no parceiro.
- [ ] Depois de vencer um selvagem e capturar outro, Vitórias e Capturas mostram 1, e a aba Captura mostra a linha do Elemento capturado.
- [ ] Trocar de aba não muda a altura do Perfil nem desloca os destaques.
- [ ] Com o servidor fora do ar, o Perfil abre com o Domador e a mensagem de erro no lugar das abas.
- [ ] A tela cabe em retrato a 720 × 1280 sem rolar a página inteira; uma aba mais longa que o espaço rola só a lista.

## Desenho técnico

- `res://domain/models/counter.gd` (`class_name Counter`): `id`, `slug`, `name`, `subject` e `from_row`; o `catalog.gd` lê a tabela `counters` e o `GameData` ganha `counter_id(slug: String) -> int`.
- `res://domain/models/player_counters.gd` (`class_name PlayerCounters`): `from_dict(d)`, `value(counter_id: int, subject_id := 0) -> int`, `by_subject(counter_id: int) -> Dictionary[int, int]`, `created_at: String`, `walkable_biomes: int`, `partner_species_id: int` (0 sem parceiro) e `partner_battles: int`.
- `res://core/services/game_service.gd` e `api_game_service.gd`: `load_counters() -> Result` com `PlayerCounters` em `data`; `res://core/autoload/session.gd`: `load_counters() -> Result`.
- `res://screens/profile/profile_screen.tscn` e `.gd`: o topo numa `HBoxContainer` (o `PreviewArea` menor, `PREVIEW_SCALE` 5, e a coluna do nome), os destaques numa `HBoxContainer` de 3 `SectionPanel`, e as abas pelo `DebugTabs` (`res://ui/components/debug_tabs.gd`), que ocupa o espaço que sobra, com um `ScrollContainer` em cada página (o `equal_heights` não serve: as linhas chegam depois do `_ready`); as linhas usam `SecondaryLabel` e `BoldLabel`, como a grade de hoje (`_add_stat`). O `DebugTabs` serve aqui sem mudança: o nome é só histórico.
- As espécies vistas e capturadas continuam vindo do `Session.load_codex()`.

## Verificação

- `godot --headless -d --path client --quit-after 60`, sem erro nem aviso de script.
- No jogo (F5), com o servidor no ar: abrir o Perfil com um Domador novo e com um que já lutou, trocar todas as abas, desligar o servidor e abrir de novo. Quem implementa diz o que conferiu e o que fica para o dono (no celular).

## Tarefas

- [x] O `Counter`, o `PlayerCounters`, a leitura no `catalog.gd` e no `GameData` e o `load_counters` no serviço e no `Session`; rode o jogo sem janela.
- [x] A cena e o script do Perfil, pela RF-01 à RF-08.
- [x] A conferência manual (sem janela: a tela compila, e os cálculos de data e tempo e o `PlayerCounters` conferem numa cena temporária; o layout no jogo e no celular fica para o dono), as tarefas marcadas e o status desta fase, da tabela do [README](README.md), da iniciativa no [índice](../README.md) e no [roadmap](../roadmap.md) para `concluída`; o parágrafo do Perfil no `client/CLAUDE.md` e a iniciativa no escopo do `CLAUDE.md` da raiz.
