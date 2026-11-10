# 03. Música de explorar

- **Status:** concluída
- **Depende de:** [02-battle-music](02-battle-music.md), [architecture.md](architecture.md)

## Contexto

Pedido do dono em 2026-11-10, depois da música da luta: "Deixe uma música de fundo na tela de explorar". O `Music` e o `compose.py` já existem ([02](02-battle-music.md)). A tela de exploração (`res://screens/exploration/exploration_screen.gd`) carrega o mapa em `_begin` e percebe a volta de outra tela (a luta, a Mochila) em `_on_visibility_changed`.

Proposta aceita pelo dono ("pode seguir"): uma música calma e de aventura, que toca enquanto o jogador anda pelo mapa, dá lugar à da luta na transição e recomeça, entrando aos poucos, na volta para o mapa. O Hub continua sem música.

## Escopo

- A música `explore.ogg` no `compose.py`.
- `Music.play_explore` e a música na tela de exploração.

## Fora do escopo

- Música no Hub e nas outras telas.
- Uma música por bioma.

## Requisitos

- **RF-01:** o `compose.py` gera `explore.ogg`, original, em sol maior, a 120 batidas por minuto, com os quatro canais, percussão mais leve que a da luta e loop sem emenda de 40 a 50 s, sem abertura. O `.import` tem `loop=true`.
- **RF-02:** `Music.play_explore(fade_in := 0.0)` toca em loop a música de explorar. Se ela já toca, segue. Com `fade_in`, ela entra aos poucos nesse tempo.
- **RF-03:** a tela de exploração toca a música quando o mapa chega do servidor.
- **RF-04:** ao voltar para o mapa de outra tela, a tela chama `Music.play_explore(1.0)`: depois da luta, a música recomeça do início, entrando aos poucos; depois da Mochila, ela segue tocando.
- **RF-05:** a fala do Domador NPC não muda a música. O `BattleIntro.cover` troca para a música da luta, como hoje.
- **RF-06:** quando a tela de exploração sai da árvore (voltar ao Hub, ou o Hub depois de perder para um Domador), ela chama `Music.fade_out()`.

## Critérios de aceite

- [x] Abrir Explorar zona toca a música de explorar, em loop sem emenda.
- [x] Procurar ou tocar no log de um Domador troca para a música da luta, com a transição.
- [x] Voltar da luta para o mapa traz a música de explorar de novo, entrando aos poucos.
- [x] Abrir e fechar a Mochila não recomeça a música.
- [x] Voltar ao Hub faz a música sumir aos poucos, e o Hub fica sem música.
- [x] Rodar o `compose.py` de novo gera os mesmos arquivos.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos:

- `res://assets/music/explore.ogg` e o `.import`.

Arquivos alterados:

- `res://assets/music/compose.py`: a partitura de explorar e o padrão de percussão leve.
- `res://core/autoload/music.gd`: `play_explore` e a entrada aos poucos.
- `res://screens/exploration/exploration_screen.gd`: tocar, voltar a tocar e sumir.
- `client/CLAUDE.md`: a música de explorar na linha da música.

## Verificação

```bash
python client/assets/music/compose.py
godot --headless -d --path client --quit-after 60
```

No editor (F5), com som: abrir Explorar zona, lutar e voltar, abrir a Mochila e voltar, e voltar ao Hub.

O que foi conferido em 2026-11-10: o `compose.py` gera `explore.ogg` com 48 s (24 compassos a 120 batidas por minuto), e duas execuções seguidas deram os mesmos quatro arquivos. O projeto abre sem erro de script, e os avisos com `-d` da tela de exploração são os de antes (a variável `size`). Uma cena temporária, que roda com os autoloads e já foi apagada, conferiu: a música em loop desde o começo; tocar, e não recomeçar ao voltar da Mochila; a luta trocando a música; a volta da luta recomeçando a de explorar em silêncio e subindo aos poucos; uma segunda chamada no meio da entrada sem recomeçar; sair no meio da entrada fazendo sumir e parar; e a música da luta entrando mesmo com a de explorar sumindo. O dono ouviu no jogo e aprovou em 2026-11-10.

## Tarefas

- [x] A música no `compose.py`.
- [x] `play_explore` e a tela de exploração.
- [x] Atualizar o `client/CLAUDE.md`, rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.
