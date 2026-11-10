# 03. Aviso de registro

- **Status:** rascunho
- **Depende de:** [01-codex-records](01-codex-records.md), [02-codex-screen](02-codex-screen.md), [architecture.md](architecture.md)

## Contexto

As respostas da luta e da Evolução já trazem `registered_species_ids`. No jogo:

- A tela da luta no tabuleiro (`res://screens/board_battle/board_battle_screen.gd`) mostra a captura no `CaptureOverlay`, escreve no histórico para onde o capturado foi (`describe_captured_to`) e, no fim, chama `_celebrate`, que mostra a subida de nível e a Evolução (`EvolutionOverlay.play`, que devolve um `ProgressChoice`).
- Os avisos da luta (`LevelUpOverlay`, `EvolutionOverlay`) são cenas postas na cena da luta, escondidas até tocarem.

## Escopo

- O `CodexRegisteredOverlay` e a ordem em que ele aparece na luta.
- `registered_species_ids` no `BoardTurn` e no `ProgressChoice`.

## Fora do escopo

- O aviso fora da luta: hoje, captura e Evolução só acontecem nela.
- O aviso de espécie vista.
- O aviso na luta antiga (`res://screens/battle/battle_screen.gd`), que também usa o `EvolutionOverlay`, mas nenhuma tela abre.
- Uma resposta da Evolução perdida na rede: o registro fica gravado, mas o aviso não aparece, porque a nova tentativa já não acha a Evolução.

## Requisitos

- **RF-01:** o `BoardTurn` e o `ProgressChoice` leem `registered_species_ids` (lista vazia quando falta).
- **RF-02:** o `CodexRegisteredOverlay` cobre a tela com um fundo escuro e mostra "Novo registro no Bestiário!", a arte colorida da espécie com um brilho atrás, "#{número} {nome}", os Elementos, a descrição e o botão "Continuar". `play(species_id)` espera o toque em "Continuar" e fecha.
- **RF-03:** na luta, depois da linha de para onde o capturado foi, o aviso aparece para cada espécie de `registered_species_ids` do turno, antes da subida de nível e da Evolução.
- **RF-04:** depois de uma Evolução aceita, o aviso aparece para cada espécie de `registered_species_ids` do `ProgressChoice`, antes das Técnicas que ficaram para escolher.
- **RF-05:** com o aviso na tela, o voltar do aparelho faz o mesmo que "Continuar".

## Critérios de aceite

- [ ] Capturar um Ecobeast de uma espécie que nunca foi capturada mostra o aviso com ele, depois da linha da Esfera.
- [ ] Capturar outro da mesma espécie não mostra o aviso.
- [ ] Aceitar uma Evolução para uma espécie nova mostra o aviso com ela, e cancelar não mostra.
- [ ] Depois do aviso, a luta segue como antes, com XP, níveis e a saída.
- [ ] O voltar do aparelho fecha o aviso.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos:

- `res://screens/codex/codex_registered_overlay.gd` e `.tscn`: `CodexRegisteredOverlay`.

Arquivos alterados:

- `res://domain/models/board_turn.gd` e `progress_choice.gd`: `registered_species_ids`.
- `res://screens/board_battle/board_battle_screen.gd` e `.tscn`: o aviso depois da captura e da Evolução, e o `handle_back`.
- `res://screens/battle/evolution_overlay.gd`, se o `ProgressChoice` precisar sair dele com a lista.

## Verificação

```bash
cd server && npm run start:dev
godot --headless -d --path client --quit-after 60
```

No editor (F5), em 360×640, com `ENABLE_TEST_BATTLE` ligada no servidor:

- Limpar o Bestiário no Debug, capturar um selvagem e conferir o aviso.
- Capturar outro da mesma espécie e conferir que o aviso não aparece.
- Com um Ecobeast a um nível da Evolução (o "Quase subir de nível" do menu Debug do mapa leva ao último XP), vencer uma luta, aceitar a Evolução e conferir o aviso.

## Tarefas

- [ ] Os modelos.
- [ ] O `CodexRegisteredOverlay`.
- [ ] O aviso depois da captura e da Evolução.
- [ ] Rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.
