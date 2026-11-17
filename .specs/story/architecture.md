# story: arquitetura

## Abordagens consideradas

| Abordagem | Troca | Escolha |
| --- | --- | --- |
| **Formato próprio, editado no F2**: cada cena é um `.json` com a lista de passos, escrito pela ferramenta Cenas do editor de ilhas | Tudo acontece no mapa de hexágonos, com os NPCs do catálogo e o Testar daqui; o editor de passos é trabalho nosso | **escolhida pelo dono** |
| **Dialogic** (plugin do Godot): editor pronto de diálogos, com personagens, escolhas, condições e variáveis | As falas ficam prontas quase de graça, mas o plugin é de visual novel: andar, câmera e seguir seriam comandos nossos plugados nele, a edição ficaria em dois lugares (F2 e editor do Godot), e a compatibilidade com o Godot 4.7 não foi conferida | descartada |
| **Ink ou Yarn Spinner**: o roteiro em texto, com escolhas nativas | Ótimos para histórias com escolhas, mas a integração com o Godot é em C#, e o projeto é todo em GDScript | descartada |

No progresso, um marcador único (`story_checkpoint`) foi descartado pelo dono a favor da lista de Marcos, porque a história terá missões paralelas e escolhas.

## Vocabulário

| No jogo e nas specs | No código |
| --- | --- |
| Cena | `StoryScene`, arquivo em `res://story/scenes/<slug>.json` |
| Passo | um item de `steps` |
| Marco | `story_marks` (servidor), `StoryMarks` (cliente) |
| Gatilho | `trigger` da cena |
| Ator | um NPC do catálogo posto na cena (`actors`) |

Os termos entram no [glossary.md](../glossary.md) na fase 01.

## O servidor: os Marcos

**`player_story_marks`** (schema `ecobeasts`):

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `player_id` | uuid | FK `players`, apaga junto |
| `mark` | text | `^[a-z0-9_]{1,48}$` |
| `created_at` | timestamptz | quando foi ligado |

Chave `(player_id, mark)`. O servidor não sabe o que um Marco significa e nunca dá nada por ele.

- `GET /v1/me` ganha `player.story_marks`: a lista dos Marcos, em ordem alfabética (vazia para quem não tem nenhum).
- `POST /v1/me/story/marks` com `{ "marks": ["avo_chega", "sabe_da_mira"] }` liga os Marcos e devolve a lista inteira, como no `GET`. Ligar um Marco que já existe não é erro.
- Recusa (`400`):
  - "O Marco \"Avo Chega\" tem caracteres inválidos." (fora da regra acima);
  - "Mande de 1 a 50 Marcos por vez.";
  - "O Domador pode ter até 2.000 Marcos." (contando os que já tem).
- Sem Domador, `409` com "Crie seu Domador primeiro.", como nas outras rotas de `/v1/me`.
- Apagar o progresso (`DELETE /v1/me`) apaga os Marcos pela FK.

## O cliente: o arquivo da cena

Uma cena por arquivo, `res://story/scenes/<slug>.json`, com o `slug` igual ao nome do arquivo:

```json
{
  "slug": "avo_chega",
  "name": "O avô chega",
  "island_id": 3,
  "repeatable": false,
  "priority": 0,
  "requires": ["criacao_domador"],
  "forbids": [],
  "trigger": { "type": "auto" },
  "actors": [
    { "key": "avo", "npc_id": 4, "q": 14, "r": -5, "visible": false }
  ],
  "steps": [
    { "type": "camera", "q": 12, "r": -3, "seconds": 1.5 },
    { "type": "show", "actor": "avo" },
    { "type": "move", "actor": "avo", "q": 12, "r": -3 },
    { "type": "say", "speaker": "avo", "text": "Ei! Já estava imaginando que encontraria você por aqui, {nome}!" },
    { "type": "choice", "options": [
      { "text": "Estava vendo um Ecobeast.", "steps": [
        { "type": "say", "speaker": "avo", "text": "Imaginei." }
      ]},
      { "text": "Nada demais.", "steps": [
        { "type": "say", "speaker": "avo", "text": "Sei..." },
        { "type": "set_mark", "mark": "disfarcou_pro_avo" }
      ]}
    ]},
    { "type": "set_mark", "mark": "sabe_da_mira" },
    { "type": "follow", "actor": "avo" },
    { "type": "camera_back", "seconds": 1 }
  ]
}
```

| Campo | Regra |
| --- | --- |
| `slug` | `^[a-z0-9_]{1,48}$`, único entre as cenas, igual ao nome do arquivo |
| `name` | pt-BR, só para o editor |
| `island_id` | a ilha onde a cena roda |
| `repeatable` | `false`: roda uma vez e liga o Marco `slug` ao terminar. `true`: roda sempre que o gatilho disparar e não liga o próprio Marco (falas de NPC que mudam com a história) |
| `priority` | inteiro; quando duas cenas disparam juntas, roda a de maior `priority`, e no empate a de menor `slug` |
| `requires` | todos estes Marcos ligados |
| `forbids` | nenhum destes Marcos ligado |
| `trigger` | ver abaixo |
| `actors` | quem participa, cada um com uma `key` única na cena e o `npc_id` do catálogo. Com `q` e `r`, a cena põe um NPC novo ali enquanto roda (`visible: false` o põe escondido, até um `show`). Com `"island_npc": true` (sem `q` e `r`), o ator é o NPC da ilha com esse `npc_id` (o tocado, no gatilho `npc`, ou senão o primeiro da ilha), que para de passear durante a cena e volta depois |
| `steps` | os passos, em ordem |

Uma cena só pode rodar se: a ilha é a da cena, todos os `requires` estão ligados, nenhum `forbids` está ligado e, se não é repetível, o Marco `slug` não está ligado.

### Os gatilhos

| `type` | Campos | Dispara quando |
| --- | --- | --- |
| `auto` | — | o Domador está na ilha e a cena pode rodar: ao entrar na ilha e logo depois de outra cena terminar |
| `npc` | `npc_id` | o Domador toca, por perto, num NPC da ilha com esse `npc_id` do catálogo; a cena toma o lugar do diálogo dele. É o `npc_id`, e não o `id` de `map.npcs`, porque esse `id` muda quando a ilha ganha ou perde NPCs numa versão nova |
| `area` | `tiles`: lista de `{ q, r }` | o Domador termina um passo num desses hexágonos |

Com nenhuma cena para o toque, o NPC fala o diálogo da ilha, como hoje.

### Os passos

Da fase 02 (conversa):

| `type` | Campos | Faz |
| --- | --- | --- |
| `say` | `speaker` (a `key` de um ator, `"tamer"` ou `null` para narração), `text` | a caixa de fala, com o nome de quem fala; espera o toque |
| `choice` | `options`: de 2 a 4, cada uma com `text` e `steps` | os botões; roda os passos da opção tocada |
| `if_mark` | `mark`, `then`, `else` (listas de passos; `else` pode faltar) | roda um ou outro conforme o Marco (contando os ligados nesta cena) |
| `set_mark` | `mark` | liga o Marco (fica pendente até a cena terminar) |
| `wait` | `seconds` (0,1 a 10) | espera |
| `fade` | `to`: `"black"` ou `"clear"`, `seconds` | escurece ou clareia a tela |

Da fase 03 (mapa):

| `type` | Campos | Faz |
| --- | --- | --- |
| `show` / `hide` | `actor` | o ator aparece ou some |
| `move` | `actor` (ou `"tamer"`), `q`, `r`, `wait` (padrão `true`) | anda pelo caminho do mapa até o hexágono; com `wait: false`, a cena segue enquanto ele anda |
| `face` | `actor` (ou `"tamer"`), `toward`: `{ q, r }`, `"tamer"` ou a `key` de outro ator | vira para lá |
| `camera` | `q`, `r`, `seconds` | a câmera desliza até o hexágono e fica |
| `camera_back` | `seconds` | a câmera volta ao Domador |
| `follow` / `unfollow` | `actor` | o ator passa a seguir o Domador (fica depois da cena, até o `unfollow` ou sair da ilha) |
| `open_screen` | `screen`: `"appearance"`, `"heal_station"`, `"shop"`, `"team"`, `"bag"` ou `"codex"` | abre a tela por cima da cena (`Router.push`) e espera voltar. O nome e a escolha do inicial ficam de fora: numa ilha o Domador já tem os dois, e a introdução de Liora decide como eles entram numa cena |

O texto aceita `{nome}`, o nome do Domador.

### Durante a cena

- O Domador não anda pelo toque, e a UI de Explorar (minimapa, Mochila, Procurar) fica escondida.
- Um ator que não acha caminho até o destino aparece lá (sem travar a cena), e o console avisa.
- Ao fim, o jogo manda num `POST /v1/me/story/marks` o Marco `slug` (se não é repetível) e os `set_mark` que rodaram. Só depois disso a cena conta como terminada, e o jogo procura uma cena `auto` que possa rodar. Se o `POST` falhar, o jogo mostra o erro com "Tentar de novo".
- Fechar o app no meio: nada foi gravado, e a cena roda de novo quando o gatilho disparar.
- As cenas só rodam em Explorar numa ilha, e Explorar já exige um Domador; por isso sempre há onde gravar.

## O cliente: o código

- `domain/models/story_scene.gd` (`StoryScene`): a cena lida do arquivo.
- `core/story/story_library.gd` (`StoryLibrary`): lê todos os arquivos de `res://story/scenes/` ao abrir o jogo e os confere pelo `StoryValidator` (`core/story/story_validator.gd`): campo faltando, tipo de passo desconhecido, `slug` repetido ou diferente do arquivo, Marco fora da regra, NPC que não existe no catálogo, `key` de ator repetida ou usada sem estar em `actors`. Um erro aparece na tela "Erro nos dados do jogo", como os do catálogo. A ilha não é conferida aqui, porque as ilhas não vêm no catálogo; quem confere é o editor, que lista as cenas pela ilha aberta.
- `core/autoload/story.gd` (autoload `Story`): os Marcos do jogador (de `Session`), a escolha da cena por gatilho (`scene_for_auto`, `scene_for_npc`, `scene_for_tile`) e a gravação dos Marcos.
- `screens/exploration/story_player.gd` (`StoryPlayer`): o nó que toca uma cena dentro da tela de Explorar, passo por passo, com a caixa de fala do `TamerGreetingPanel`.

## O editor: a ferramenta Cenas

Na barra de ferramentas do F2, ao lado da NPC. O painel mostra as cenas da ilha aberta, com Nova cena, e, na cena escolhida:

- os campos (`name`, `repeatable`, `priority`, `requires`, `forbids`);
- o gatilho, com "Escolher no mapa" para o NPC ou os hexágonos da área;
- os atores, cada um com o NPC do catálogo e o hexágono escolhido no mapa;
- os passos numa lista com recuo para os blocos (opções da escolha, `then` e `else`), com adicionar, apagar, subir e descer, e os campos do passo escolhido; os campos de hexágono têm "Escolher no mapa";
- **Salvar** grava o arquivo em `res://story/scenes/<slug>.json`. Gravar em `res://` só funciona com o jogo aberto pelo editor do Godot; fora dele, Salvar fica desligado com o aviso "Abra o jogo pelo Godot para salvar cenas.";
- **Testar daqui** abre Explorar na versão publicada da ilha (o rascunho não, porque o mapa de Explorar vem do servidor, e hoje ele só monta a versão publicada) e toca a cena com os Marcos de teste: a lista dos `requires` da cena, que o dono pode mudar no painel. Nada é gravado no servidor, e as outras cenas não disparam durante o teste. Uma ilha nunca publicada mostra Testar daqui desligado, com o aviso "Publique a ilha para testar a cena.".

As cenas apontam para hexágonos da ilha. Ao salvar a ilha ou a cena, o editor avisa da cena que usa um hexágono que não é mais da ilha.

## O editor: a Linha da história

Uma vista do F2 com todas as cenas como caixas, em colunas pela profundidade (as sem `requires` à esquerda), e uma seta de cada cena que liga um Marco para cada cena que o exige. Tocar numa caixa abre a cena na ferramenta Cenas. Os avisos:

- "Ninguém liga o Marco X, que a cena Y exige.";
- "A cena Y exige e proíbe o Marco X.";
- "As cenas Y e Z esperam uma pela outra em ciclo.";
- "A cena Y proíbe o próprio Marco.".
