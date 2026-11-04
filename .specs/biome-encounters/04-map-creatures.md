# 04. Ecobeasts no mapa

- **Status:** concluída
- **Depende de:** [03-exploration-session](03-exploration-session.md) e de [wild-battle/13](../wild-battle/13-debug-menu.md), que criou o `CreatureSprite`

## Contexto

O servidor já manda os Ecobeasts do mapa e já confere o encontro. Falta o jogador vê-los, tocar em Procurar e não encontrar mais quem já enfrentou.

## Escopo

- Mostrar os Ecobeasts perto do Domador.
- Procurar em hexágono vazio e em hexágono com Ecobeast.
- Tirar do mapa o Ecobeast enfrentado.
- Todos os Ecobeasts no mapa inteiro de depuração.

## Fora do escopo

- Qualquer texto sobre o Ecobeast no mapa: nome, nível ou destaque no hexágono.
- Mudar o spawn de depuração, que continua sendo só enfeite.
- Ajustar a velocidade de passeio por tamanho.

## Requisitos

- **RF-01:** Cada Ecobeast aparece no hexágono dele, com a folha da espécie, passeando como no spawn de depuração.
- **RF-02:** Nenhuma informação do Ecobeast aparece no mapa, e tocar nele não abre nada.
- **RF-03:** Só existem nós para os Ecobeasts a até `CREATURE_RADIUS` hexágonos do Domador, e eles nascem e saem conforme ele anda, fora da tela.
- **RF-04:** Um Ecobeast que volta para perto do Domador aparece no mesmo hexágono de antes.
- **RF-05:** Procurar em um hexágono sem Ecobeast mostra "Nada por aqui." no painel, sem chamar o servidor, e o texto some no próximo passo.
- **RF-06:** Procurar em um hexágono com Ecobeast abre a batalha, enviando a posição do Domador.
- **RF-07:** Ao voltar da luta, seja qual for o resultado, o Ecobeast enfrentado não está mais no mapa, e os outros continuam onde estavam.
- **RF-08:** Uma falha ao abrir a luta mostra a mensagem do servidor, e nenhum Ecobeast sai do mapa.
- **RF-09:** Um Ecobeast com folhas que faltam não aparece, sem erro no jogo.
- **RF-10:** No mapa inteiro de depuração, em build de debug, todos os Ecobeasts ainda no mapa aparecem.
- **RF-11:** Enquanto o Domador anda, tocar em Procurar não faz nada. O cliente já conta o hexágono de destino no começo do passo, e o servidor recusaria quem chegou há menos de 300 ms.

## Critérios de aceite

- [x] Em um mapa, aparecem alguns Ecobeasts, e nenhum Elu em água.
- [x] Os Ecobeasts respeitam os planos de decoração, como o Domador.
- [x] Procurar em um hexágono vazio mostra "Nada por aqui.", e o texto some ao andar.
- [x] Procurar em um hexágono com um Ecobeast abre a luta contra a mesma espécie do desenho.
- [x] Depois de vencer, perder, fugir ou capturar, ele não está mais no mapa.
- [x] Em um hexágono com dois, Procurar enfrenta um, e o outro continua lá.
- [x] Com os Ecobeasts por perto, os quadros por segundo não caem em relação ao mapa sem eles, medidos no monitor de FPS do Godot.
- [x] Sair e entrar traz um mapa novo, cheio.
- [x] Reiniciar o servidor no meio mostra "Essa exploração acabou. Saia e entre de novo." ao Procurar.

## Desenho técnico

### Arquivos alterados

- `client/domain/models/exploration_map.gd`: lê `creatures` em `from_dict`, guarda os Ecobeasts por id e ganha `has_creature(coord)` e `distance(from, to)`. Procurar é um toque, então percorrer 500 Ecobeasts basta, sem um índice por hexágono. Uma classe `MapCreature` (`id`, `species_id`, `coord`), em `client/domain/models/map_creature.gd`, segue o padrão dos outros modelos.
- `client/screens/exploration/exploration_screen.gd`:
  - `CREATURE_RADIUS := 16`, _a revisar_: o canto da tela chega a 12 hexágonos do Domador em 412×915, e o limite precisa passar disso para nenhum nó nascer à vista. Na prática, são de 13 a 35 nós.
  - `_wild_sprites`, de id para `CreatureSprite`, atualizado depois de cada passo.
  - O botão Procurar passa por `_search()`, em vez de ligar direto no `Router.push`. Com Ecobeast, faz `Router.push(&"battle", {"coord": _player_coord})`.
  - Ao voltar, com `visibility_changed`, lê e limpa `Session.take_fought_spawn()` e tira esse Ecobeast do mapa.
  - `_toggle_whole_map` cria os sprites que faltam e, ao voltar, remove os longe do Domador. O `_fit_view` passa a ajustar a escala dos dois grupos de sprites.
- `client/screens/battle/battle_screen.gd`: ganha `setup(params)`, o método que o Router chama com os parâmetros de `push`, guarda `coord` e chama `Session.start_wild_battle(coord)`.
- `client/core/services/game_service.gd` e `api_game_service.gd`: `start_wild_battle(coord)` manda `{ "q", "r" }`.
- `client/core/autoload/session.gd`: guarda o `spawn_id` da resposta, e `take_fought_spawn()` o devolve e limpa.
- `client/ui/components/creature_sprite.gd`: o comentário deixa de dizer que é só enfeite, e cada espécie reaproveita um único `SpriteFrames`, em um cache estático. Hoje cada Ecobeast monta o próprio, com 50 quadros, o que pesaria com vários na tela. O `SheetSprite` e o Domador não mudam.

A espécie vira slug com `GameData.get_species(species_id)`, e `CreatureSprite.has_sheets` cobre o RF-09. O Ecobeast é filho do `HexMapView`, com `set_actor_row` pela linha do hexágono, como já faz o spawn de depuração.

### Documentação

- `.specs/wild-battle/README.md` e `architecture.md`: a posição do jogador deixa de ser só do cliente.
- `client/CLAUDE.md`: Ecobeasts do mapa.
- `CLAUDE.md`, `.specs/README.md` e `.specs/roadmap.md`: iniciativa concluída.

## Verificação

O dono testou no editor e aprovou. A tela real passou nos quatro tamanhos. O dono deu por concluídos o teste no celular e os Ecobeasts pequenos atrás das plantas em 2026-11-03.

```bash
cd server && npm run start:dev
godot --headless -d --path client --quit-after 60
```

Na tela real, em 720×1061, 405×720, 360×640 e 412×915: entrar em Explorar, andar até um Ecobeast, Procurar, voltar e conferir que ele sumiu. No celular, o mesmo caminho.

## Tarefas

- [x] Ler `creatures` no modelo.
- [x] Compartilhar o `SpriteFrames` por espécie e conferir que o Domador não mudou.
- [x] Mostrar os Ecobeasts perto do Domador.
- [x] Ligar o Procurar à posição, com a mensagem de hexágono vazio.
- [x] Tirar do mapa quem foi enfrentado.
- [x] Mostrar todos no mapa inteiro de depuração.
- [x] Atualizar a documentação.
- [x] Rodar a verificação e dizer o que ficou para o dono.
