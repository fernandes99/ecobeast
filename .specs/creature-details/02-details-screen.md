# 02. Tela de detalhes

- **Status:** concluída
- **Depende de:** [01-server-contract](01-server-contract.md), [visual-theme](../visual-theme/README.md)

## Contexto

Tocar em um Ecobeast do Hub ainda abre um placeholder ([hub/01](../hub/01-hub-screen.md), RF-09). Com o XP do nível e a rota do apelido no servidor ([01](01-server-contract.md)), esta fase entrega a tela de verdade (TELAS.md #8), no layout que o dono escolheu na prancha: um topo fixo e três abas, sem rolagem.

## Escopo

- Tela `creature_details`, com topo fixo e as abas Resumo, Atributos e Técnicas.
- Componente `StatRadar`, o gráfico de hexágono.
- Painel de apelido e `set_nickname` no `GameService` e no `Session`.
- Ligação com o Hub.

## Fora do escopo

Os itens de "Fora do escopo" do [README](README.md).

## Requisitos

**Abrir e voltar**

- **RF-01:** Tocar em um slot com criatura no Hub abre `&"creature_details"` com `Router.push` e o parâmetro `{"uid": <uid>}`. Slot vazio não faz nada.
- **RF-02:** O botão de voltar no canto superior esquerdo e o voltar do Android (Esc no editor) retornam ao Hub, com a rolagem onde estava.
- **RF-03:** A tela lê a criatura em `Session.player` pelo `uid` e se redesenha a cada `Session.player_changed`. Telas não pedem dados à API.

**Topo fixo**

- **RF-04:** O retrato (`CreaturePortrait`, 360 px) fica sobre um brilho radial na cor do primeiro Elemento, desenhado por código a partir do catálogo.
- **RF-05:** O painel de identidade tem, na primeira linha, o nome de exibição (`TitleLabel`), o botão de lápis e, à direita, "Nv. <nível>". Na segunda linha, um `ElementBadge` por Elemento e, se houver apelido, o nome da espécie em `SecondaryLabel`.
- **RF-06:** Abaixo, `HpBar` com os números e a barra de XP (`XpBar`). A barra vai de `level_xp` a `next_level_xp`, e o texto diz "faltam <n> XP". Com `next_level_xp` nulo, a barra fica cheia e o texto diz "Nível máximo".

**Abas**

- **RF-07:** Três botões de largura igual: Resumo, Atributos e Técnicas. A aba atual usa o botão padrão, e as outras, `OutlineButton`. A tela abre em Resumo, e o apelido salvo não muda a aba.
- **RF-08:** Resumo: descrição da espécie; "Temperamento" com o nome; "Traço" com o nome e a descrição; "Item" com "Nenhum" quando `held_item_id` é -1; "Gênero" com "Macho", "Fêmea" ou "Sem gênero".
- **RF-09:** Atributos: o `StatRadar` com os 6 stats e, abaixo, "<Temperamento>: +10% em <stat>, −10% em <stat>", com os nomes curtos da tabela `stats`. Temperamento neutro: "<Temperamento>: sem efeito nos stats".
- **RF-10:** Técnicas: quatro linhas de altura igual. Cada Técnica mostra nome, "PP <atual>/<máximo>", `ElementBadge`, categoria, "Poder <n>" e "Prec. <n>". Poder 0 omite "Poder"; Precisão 0 mostra "Nunca erra". Uma linha sem Técnica diz "Vazio", em `TEXT_MUTED`.

**`StatRadar`**

- **RF-11:** `res://ui/components/stat_radar.gd` (`class_name StatRadar`, estende `Control`), desenhado em `_draw()`: fundo em `TRACK`, três anéis em `BORDER`, a forma da criatura em `ACCENT` com preenchimento a 35% e, em cada ponta, o nome curto e o valor. A ordem, em sentido horário a partir do topo, é HP, Atq, Def, Atq.E, Def.E, Vel.
- **RF-12:** `set_stats(stats: StatBlock, increased_slug: String, decreased_slug: String)`, com slugs vazios para Temperamento neutro. A escala é o maior dos 6 stats. O stat aumentado fica em `HP_HIGH`, com um triângulo para cima; o diminuído, em `WARNING`, com um triângulo para baixo.

**Apelido**

- **RF-13:** O lápis abre `NicknamePanel`, sobre a tela, no terço de cima, para o teclado do celular não o cobrir. Tem um `LineEdit` com o apelido atual, a dica "Deixe vazio para usar o nome da espécie.", "Salvar" e "Cancelar".
- **RF-14:** "Salvar" fica desabilitado quando o texto normalizado não é vazio nem válido (`Player.normalize_name` e `Player.is_valid_name`). Quem decide é o servidor.
- **RF-15:** Durante o envio, o botão diz "Salvando…" e o painel não fecha. Com sucesso, fecha, e a tela mostra o novo nome; com erro, mostra `result.error` e continua aberto.
- **RF-16:** Voltar do Android, toque fora e "Cancelar" fecham o painel, menos durante o envio. O voltar fecha o painel antes de sair da tela (`handle_back() -> bool`).
- **RF-17:** `GameService.set_nickname(uid: String, raw_nickname: String) -> Result` (`ApiGameService`: `PATCH /v1/me/creatures/<uid>`) e `Session.set_nickname`, que atualiza `player` como os outros métodos.

**Hub e modelo**

- **RF-18:** `CreatureInstance` ganha `level_xp` e `next_level_xp`, este com -1 quando vier nulo.
- **RF-19:** O novo apelido aparece no card do Hub ao voltar, sem chamada a mais.

## Critérios de aceite

- [x] Tocar no inicial no Hub abre a tela com o sprite, o nome e o nível dele; voltar e Esc retornam ao Hub.
- [x] Um inicial nível 5 recém-criado mostra a barra de XP vazia e "faltam 91 XP" (Fagulho, curva média).
- [x] As três abas trocam o conteúdo sem rolagem em 720×1280, e nada corta na janela 405×720.
- [x] Resumo mostra a descrição, o Temperamento, o Traço com o efeito, "Nenhum" no item e o gênero.
- [x] Os números do hexágono são iguais aos `stats` do servidor; o aumentado e o diminuído têm as marcas, e o texto de baixo nomeia os dois.
- [x] Um Temperamento neutro não mostra marcas e diz "sem efeito nos stats".
- [x] Técnicas mostra as 2 Técnicas do inicial com PP cheio e 2 linhas "Vazio".
- [x] Salvar "Chama Viva" muda o nome na tela e no Hub, e a espécie aparece em texto secundário; depois de fechar e abrir o jogo, o apelido continua lá. (A volta do apelido foi conferida relendo o jogador do servidor, sem reabrir o jogo.)
- [x] Salvar vazio volta ao nome da espécie, e o texto secundário some.
- [x] Com "A" ou "Fogo!", "Salvar" fica desabilitado; com o servidor parado, a mensagem de rede aparece, e o painel continua aberto.
- [x] Uma criatura de dois Elementos e um apelido de 16 letras não quebram o painel de identidade.
- [x] O jogo roda sem erros de script nem avisos (`godot --headless -d --path client --quit-after 60`).

## Desenho técnico

**Criar**

- `res://screens/creature_details/creature_details_screen.tscn` e `.gd`: conteúdo dentro de `SafeArea`; `setup(params)` guarda o `uid`.
- `res://screens/creature_details/nickname_panel.tscn` e `.gd` (`class_name NicknamePanel`), no molde do `StarterConfirmPanel`: sinal `save_pressed(nickname: String)`, métodos `open(current: String)`, `close()`, `set_busy(busy: bool)` e `show_error(message: String)`. Quem chama o `Session` é a tela.
- `res://ui/components/stat_radar.gd`, um script sem cena, usado como nó `Control` na cena da tela.
- `res://ui/icons/back.svg`, branco, como os outros ícones.

**Alterar**

- `res://core/autoload/router.gd`: `&"creature_details"` em `SCREENS`.
- `res://screens/hub/hub_screen.gd`: `_open_details` (RF-01).
- `res://core/services/game_service.gd`, `api_game_service.gd` e `res://core/autoload/session.gd` (RF-17).
- `res://domain/models/creature_instance.gd` (RF-18).
- `.specs/hub/01-hub-screen.md` (nota no RF-09), `.specs/foundation/architecture.md` (árvore e ids de tela), `.specs/onboarding/architecture.md` (contrato do `GameService`), `.specs/README.md`, `.specs/roadmap.md` (`creature-details` concluída) e `client/CLAUDE.md` (`StatRadar`).

**Reaproveitar**

`CreaturePortrait`, `ElementBadge`, `HpBar`, `XpBar`, `SectionPanel`, `IconButton`, `OutlineButton`. Stats, PP máximo e nomes vêm de `GameData`; categoria e nome curto, de `GameData.get_row`.

As cores vêm de `UiPalette` e do catálogo. A tela só faz a conta da barra de XP com os números que o servidor mandou, sem usar a curva.

## Verificação

Com o servidor rodando:

```bash
godot --headless -d --path client --quit-after 60
```

Uma cena temporária, nos moldes da [auth-google/05](../auth-google/05-client-player.md), abre a tela contra o servidor de teste, confere os textos, troca as abas, grava e remove o apelido e tira capturas das três abas e do painel. Ela roda com um `client/override.cfg` temporário, para não tocar na sessão do dono, e é apagada no fim. Ficam para o dono o toque de verdade, o teclado no celular e a aparência no aparelho.

## Tarefas

- [x] Cena temporária com os critérios; ver falhar.
- [x] `CreatureInstance`, `set_nickname` no serviço e no `Session` (RF-17, RF-18).
- [x] `StatRadar` (RF-11, RF-12).
- [x] Tela: topo e abas (RF-01 a RF-10), com registro no `Router` e ligação no Hub.
- [x] `NicknamePanel` (RF-13 a RF-16).
- [x] Capturas, conferência e limpeza dos arquivos temporários.
- [x] Documentos; marcar esta spec, as tabelas e o roadmap como `concluída`; commit `feat: tela de detalhes do Ecobeast`.

## Decisões da implementação

- **`SkillRow`:** a spec não listava esta cena. As quatro linhas de Técnica ficaram em `res://screens/creature_details/skill_row.tscn` e `.gd`, como os cards da escolha do inicial.
- **Linha "Vazio":** usa o `SectionPanel`, sem a borda tracejada da prancha, porque o `StyleBoxFlat` do Godot não desenha traço.
- **Nome longo:** o nome de exibição corta com reticências, para o lápis e o nível continuarem à vista.
- **Espaço livre no Resumo:** com o conteúdo de hoje, sobra cerca de 200 px embaixo da aba. Fica para os próximos dados.
- **Conferência:** 65 verificações numa cena temporária contra a API e o banco reais, sem Google, numa janela de 405×720: abrir pelo Hub, as três abas, os dois tipos de Temperamento, nível máximo, dois Elementos com apelido de 16 letras, gravar e remover o apelido, falha de rede e voltar. As capturas das telas foram conferidas uma a uma. Tudo foi apagado no fim, com o Domador de teste.
- **Para o dono:** o toque de verdade na tela, o teclado no celular e a aparência no aparelho.
