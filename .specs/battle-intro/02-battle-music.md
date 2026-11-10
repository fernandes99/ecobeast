# 02. Música da luta

- **Status:** rascunho
- **Depende de:** [01-battle-transition](01-battle-transition.md), [architecture.md](architecture.md)

## Contexto

A transição já existe, e o `BattleIntro.cover` recebe `opponent` (`wild` ou `tamer`). O jogo não tem música nem canal de áudio separado: os sons das Técnicas e dos golpes tocam no Master, pela tela da luta.

Godot, para quem está começando: um **canal de áudio** (bus) é um caminho por onde os sons passam antes de sair. Com a música num canal próprio, dá para mudar o volume dela sem mexer nos outros sons. Os canais ficam no `default_bus_layout.tres`, e o painel "Audio", embaixo no editor, mostra todos. Um `AudioStreamPlayer` toca um som, e o `.import` de um `.ogg` diz se ele repete (loop).

## Escopo

- O script `compose.py` e as três músicas que ele gera.
- O canal `Music` e o autoload `Music`.
- A música no `cover`, o toque de vitória e o sumir aos poucos na tela da luta.

## Fora do escopo

- Música fora da luta, volume e silenciar.
- Trocar os sons de hoje de canal.

## Requisitos

### As músicas

- **RF-01:** `res://assets/music/compose.py` gera `battle_wild.ogg`, `battle_tamer.ogg` e `victory.ogg` com os quatro canais, o envelope e a saída da [arquitetura](architecture.md#o-compositor), com o Python 3 e o `ffmpeg`, sem biblioteca de fora. Rodar de novo dá os mesmos arquivos.
- **RF-02:** `battle_wild` é animada, em tom maior, e `battle_tamer` é mais rápida e tensa, em tom menor. As duas têm de 30 a 45 s e terminam no mesmo compasso em que começam, para o loop não ter emenda. `victory` tem de 3 a 5 s e termina numa nota longa.
- **RF-03:** as melodias são originais. O cabeçalho do script diz isso, e nenhuma frase copia música de jogo.
- **RF-04:** o `.import` das duas lutas tem `loop = true`, e o do `victory`, `loop = false`.

### Tocar

- **RF-05:** o `default_bus_layout.tres` tem o canal `Music`, ligado ao Master, a −6 dB.
- **RF-06:** `Music` é um autoload com os métodos da [arquitetura](architecture.md#music), tocando no canal `Music`.
- **RF-07:** `BattleIntro.cover` chama `Music.play_battle(opponent)` no começo dos clarões. O Procurar, o Domador do mapa e a luta de teste passam `&"wild"` ou `&"tamer"` conforme o adversário, e o Desafiar passa `&"tamer"`.
- **RF-08:** na tela da luta, assim que os eventos da resposta terminam com a fase `ended`, `victory` ou `captured` chama `Music.play_victory()`, e `defeat` ou `fled`, `Music.fade_out()`. Isso acontece antes do aviso de registro do Bestiário e da comemoração de XP e de nível.
- **RF-09:** quando o servidor recusa a luta, e ao sair da luta, a tela chama `Music.fade_out()`.

## Critérios de aceite

- [ ] Procurar um selvagem toca a música de selvagem desde os clarões, em loop sem emenda.
- [ ] Um Domador do mapa e o Desafiar tocam a música de Domador.
- [ ] Vencer ou capturar troca a música pelo toque de vitória.
- [ ] Perder ou fugir faz a música sumir aos poucos.
- [ ] Voltar ao mapa ou ao Hub não deixa música tocando.
- [ ] Os sons das Técnicas e dos golpes continuam tocando por cima da música.
- [ ] Rodar o `compose.py` de novo gera os mesmos três arquivos.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos:

- `res://assets/music/compose.py`: o compositor, com as partituras.
- `res://assets/music/battle_wild.ogg`, `battle_tamer.ogg` e `victory.ogg`, com os `.import`.
- `res://default_bus_layout.tres`: o canal `Music`.
- `res://core/autoload/music.gd`: `Music`.

Arquivos alterados:

- `project.godot`: o autoload `Music`.
- `res://core/autoload/battle_intro.gd`: `Music.play_battle` no `cover`.
- `res://screens/exploration/exploration_screen.gd` e `res://screens/hub/hub_screen.gd`: o `opponent` certo no `cover`.
- `res://screens/board_battle/board_battle_screen.gd`: o toque de vitória e o sumir aos poucos.
- `client/CLAUDE.md`: uma linha sobre a música e o `compose.py`.

## Verificação

```bash
python client/assets/music/compose.py
godot --headless -d --path client --quit-after 60
```

No editor (F5), em 360×640, com som:

- Lutar contra um selvagem e vencer; lutar contra um Domador e perder; fugir de um selvagem; capturar um selvagem.
- Ouvir o loop inteiro de cada música pelo menos uma vez.

## Tarefas

- [ ] O compositor e as três músicas.
- [ ] O canal `Music` e o autoload.
- [ ] A música no `cover` e no fim da luta.
- [ ] Atualizar o `client/CLAUDE.md`, rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.
