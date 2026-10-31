# 02. Tela do Refúgio

- **Status:** rascunho
- **Depende de:** [01-heal-api](01-heal-api.md)

## Contexto

Com a rota da [01](01-heal-api.md), falta o jogador alcançá-la. O card "Refúgio" do Hub ainda abre um placeholder. Esta fase cria a tela (TELAS.md #14) e a liga ao Hub.

## Escopo

- `heal_team()` no `GameService`, no `ApiGameService` e no `Session`.
- A tela do Refúgio, com a lista da equipe.
- O destino de "Refúgio" no Hub.

## Fora do escopo

- Sons e animações. A barra muda de uma vez.
- Preço em moedas.
- Mudar a tela de batalha.

## Requisitos

**Tela**

- **RF-01:** Tocar em "Refúgio" no Hub abre a tela com `Router.push`.
- **RF-02:** A tela tem, de cima para baixo: o título "Refúgio", a lista da equipe, uma linha de mensagem, o botão "Curar todos" e o botão "Voltar". O conteúdo fica dentro de um `SafeArea`.
- **RF-03:** A lista fica numa rolagem, e os dois botões ficam sempre visíveis.
- **RF-04:** Cada linha mostra retrato, nome, nível, barra de HP com números e, abaixo, o PP somado das Técnicas ("PP 30/35"), seguido do nome do status, se houver.
- **RF-05:** O nome da linha é o apelido, ou o nome da espécie, como no Hub.

**Curar**

- **RF-06:** Se alguma criatura tem HP abaixo do máximo, status ou PP abaixo do máximo, o botão fica ativo. Senão, fica desativado, com o texto "Equipe já curada".
- **RF-07:** Tocar em "Curar todos" chama `Session.heal_team()`. Enquanto o pedido dura, o botão fica desativado, com o texto "Curando...", e Voltar também.
- **RF-08:** Enquanto o pedido dura, o voltar do Android não sai da tela (`handle_back` devolve `true`).
- **RF-09:** Com sucesso, a lista mostra a equipe curada, a mensagem diz "Equipe curada!", e o botão fica como no RF-06.
- **RF-10:** Com falha, a equipe continua como estava, a mensagem mostra o erro em `DangerLabel`, e o botão volta a "Curar todos", ativo.
- **RF-11:** A mensagem de um resultado anterior some ao tocar em "Curar todos" de novo.

**Hub**

- **RF-12:** Voltar leva ao Hub, que já mostra o HP curado, porque `Session.heal_team()` emite `player_changed`.

## Critérios de aceite

- [ ] Tocar em Refúgio no Hub abre a tela com a equipe do jogador.
- [ ] Com a equipe ferida, cada linha mostra HP, PP e status de verdade.
- [ ] Curar enche as barras, zera os status e mostra "Equipe curada!".
- [ ] Depois de curar, o botão fica desativado com "Equipe já curada".
- [ ] Abrir a tela com a equipe bem mostra o botão desativado, sem mensagem.
- [ ] Com o servidor fora do ar, o erro aparece, a equipe não muda, e o botão volta a funcionar.
- [ ] Enquanto cura, nem Voltar nem o voltar do Android saem da tela.
- [ ] Depois de uma derrota total, curar no Refúgio faz Explorar zona abrir uma luta.
- [ ] O Hub mostra o HP curado.
- [ ] A tela cabe em 405×720 com 6 criaturas.
- [ ] O mesmo vale em um aparelho com recorte (passo do dono).
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**, em `client/screens/heal_station/`:

- `heal_station_screen.tscn` e `.gd`: a tela.
- `heal_creature_row.tscn` e `.gd`: uma linha. `set_creature(creature: CreatureInstance)`. Painel `SectionPanel`, sem toque.

**Alterar**

- `client/core/services/game_service.gd`: `@abstract func heal_team() -> Result`, com data: o Player curado.
- `client/core/services/api_game_service.gd`: `HEAL_PATH := "/v1/me/heal"` e `heal_team()`, com `_player_result`.
- `client/core/autoload/session.gd`: `heal_team()`, que chama `_set_player`, como `set_nickname`.
- `client/core/autoload/router.gd`: `&"heal_station"` em `SCREENS`.
- `client/screens/hub/hub_screen.gd`: o destino de "Refúgio".
- `.specs/onboarding/architecture.md`: `heal_team` = `POST /v1/me/heal` na lista de rotas do `GameService`.
- `TELAS.md`: a tela #14 com "Curar todos".
- `.specs/roadmap.md`: `heal-station` concluída.
- `CLAUDE.md`: o Escopo atual cita o `heal-station`.

**Reaproveitar**

`SafeArea`, `CreaturePortrait`, `HpBar`, `OutlineButton`, `DangerLabel`, `CreatureInstance.display_name`. O `max_pp` vem de `GameData.get_skill`, o HP máximo de `creature.stats`, e o nome do status de `GameData.catalog.get_row("status_conditions", id)`.

Comparar os valores atuais com os máximos no RF-06 não é uma regra: a tela só decide se vale mostrar o botão. Quem cura é o servidor.

## Verificação

Uma cena temporária, nos moldes da [battle-screen/03](../battle-screen/03-battle-screen.md), abre a tela pelo Hub contra um servidor de teste, confere os critérios automáticos e salva capturas em 405×720, com todas elas abertas e revisadas. A falta de rede é simulada trocando o endereço do servidor, e o relatório diz isso.

Passos do dono no editor (F5) e no celular:

1. Perder uma luta até a equipe ficar a 0 HP.
2. Abrir o Refúgio, tocar em "Curar todos" e conferir a tela.
3. Voltar ao Hub e abrir uma luta em Explorar zona.

```bash
cd server && npm run start:dev
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [ ] Registrar a tela, ligar o Hub e criar `heal_team()` (RF-01, RF-12).
- [ ] Tela e linha da equipe (RF-02 a RF-05).
- [ ] Curar, estados do botão e voltar (RF-06 a RF-11).
- [ ] Remover os arquivos temporários; atualizar `TELAS.md`, o roadmap e o `CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`; commit `feat: tela do Refúgio`.
