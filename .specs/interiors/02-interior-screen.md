# 02. A tela do interior

- **Status:** concluída (falta o dono conferir no F5)
- **Depende de:** [01](01-interior-data.md)

## Contexto

Com as salas no banco e o Refúgio convertido ([01](01-interior-data.md)), esta fase faz o Domador entrar. A peça com sala abre a tela `interior` por cima de Explorar, como o Refúgio abre a cura hoje. Lá dentro, ele anda por toque, fala com os NPCs e sai pela porta.

O prédio do Refúgio ainda não está posto em Liora, e ligar uma peça a uma sala só fica fácil com a [03](03-interior-editor.md). Por isso, esta fase se confere sem janela, abrindo a tela direto, e os critérios do F5 ficam para depois da 03.

## Escopo

- Entrar pela peça com sala, em Explorar.
- A tela `interior`: carregar, desenhar, a câmera, o andar, os NPCs, a conversa, a ação e a saída.
- O `ActionScreens`, com a regra sem equipe, usado pelas duas telas.

## Fora do escopo

- O editor (fase 03).
- Tudo o que o [README](README.md#fora-do-escopo) deixa de fora: cenas, seguidores, pinça, animações, luzes e passeio.

## Requisitos

### Entrar

- **RF-01:** Em Explorar, uma peça com `interior_id` responde ao toque como uma peça com ação, mesmo sem ação: o Domador anda até a linha de bloqueio dela e, ao chegar a até `TOUCH_REACH`, o jogo abre a tela `interior` com `Router.push(&"interior", {"interior_id": id})`, no lugar da tela da ação. A peça sem sala segue como hoje.
- **RF-02:** Entrar não pede equipe. A regra sem equipe de hoje (a frase do Refúgio e da Viagem) passa para o `ActionScreens.open` ([architecture](architecture.md#o-jogo)), que as duas telas usam.

### A tela

- **RF-03:** A tela pede a sala ao `Session.load_interior` e mostra "Entrando…" enquanto espera. Com erro, ela mostra a mensagem e um botão Voltar. Com `{"interior": <Interior>}` nos parâmetros, ela usa essa sala, sem pedir ao servidor; é o que os testes usam.
- **RF-04:** A sala é desenhada pelo `InteriorView` ([architecture](architecture.md#o-jogo)), com o nome da sala no topo, no estilo do nome da ilha, e uma barra de mensagem embaixo, como a de Explorar. O fundo em volta da sala é a cor de fundo do tema.
- **RF-05:** A escala é o degrau de zoom de Explorar (`ViewSettings`, de 1 a 4), sempre inteira. A câmera põe o Domador no centro, em pixels inteiros da tela. Num eixo em que a sala é maior que a tela, a câmera para na borda da sala, sem mostrar o fundo além dela. Num eixo em que a sala cabe, ela fica centrada.

### Andar

- **RF-06:** O Domador (`TamerSprite` com a aparência do jogador) nasce no centro da porta, virado para cima, parado.
- **RF-07:** Tocar no chão anda até o ponto tocado pela [regra do andar](architecture.md#o-andar-lá-dentro), com a animação de correr e virando para a direção de cada reta, e parado no fim. Um toque no meio troca o destino, a partir de onde ele está. Sem caminho, ele não sai do lugar.
- **RF-08:** Chegar ao quadrado da porta vindo de outro quadrado sai da sala na hora (`Router.back()`), e o Domador está em Liora onde estava antes de entrar. O voltar do aparelho também sai, menos com uma conversa aberta, que ele fecha.

### Os NPCs

- **RF-09:** Cada NPC da sala aparece parado no centro do quadrado dele, virado para baixo, com a arte do `NpcSprite` (um Ecobeast ou uma pessoa vestida pela aparência do NPC).
- **RF-10:** Tocar na figura de um NPC anda até o quadrado livre ao lado dele (cima, baixo, esquerda ou direita) com o caminho mais curto. Lá, o Domador vira para o NPC, o NPC vira para o Domador, e as falas abrem na caixa de fala (`TamerGreetingPanel`), um parágrafo por toque, com a voz do NPC (`GameData.npc_voice`). Sem quadrado alcançável ao lado, nada acontece.
- **RF-11:** Depois da última fala, a caixa fecha e roda a ação do NPC pelo `ActionScreens.open`. A frase que ela devolver vai para a barra de mensagem. Um NPC sem fala roda a ação ao chegar, e um sem fala nem ação só vira para o Domador.
- **RF-12:** No Refúgio, o NPC com a ação `refuge` abre a tela `heal_station`, e o Voltar dela devolve o Domador para dentro da sala.

## Critérios de aceite

- [ ] No F5, tocar no Refúgio de Liora (com a sala 1 ligada) abre a sala com o Domador na porta.
- [ ] O Domador anda pela sala sem atravessar paredes nem móveis bloqueados, e passa atrás de uma estante alta e na frente da parede.
- [ ] O NPC do balcão fala com a voz dele, e depois abre a cura; voltar da cura volta para a sala.
- [ ] Sem equipe, a mesma conversa termina com "Você ainda não tem Ecobeasts para cuidar." na barra.
- [ ] Pisar na porta volta para Liora, no mesmo lugar, com os Ecobeasts e a névoa como estavam.
- [ ] A sala aparece em pixels inteiros nos 4 degraus de zoom.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Criar:**
  - `client/core/action_screens.gd` (`ActionScreens`)
  - `client/ui/components/interior_tiles.gd` (`InteriorTiles`) e `interior_view.gd` (`InteriorView`)
  - `client/screens/interior/interior_screen.gd` e `.tscn` (`InteriorScreen`) e `interior_route.gd` (`InteriorRoute`: a busca e as retas da [architecture](architecture.md#o-andar-lá-dentro), sem `Node`, para testar sozinha)
- **Alterar:**
  - `client/core/autoload/router.gd` (o id `interior`)
  - `client/screens/exploration/exploration_screen.gd` (a peça com sala, e o `ACTION_SCREENS` saindo para o `ActionScreens`)
  - `client/domain/models/interior_npc.gd` (`to_map_npc()`: o `MapNpc` parado, que o `NpcSprite.make` já desenha sem o `HexMapView` e que já parte a fala em parágrafos)
- **Reutilizar:** o `TamerGreetingPanel`, o `TamerSprite`, o `NpcSprite` (sem mudar), o `ViewSettings` e o `WalkRoute.WALK_SPEED`.

## Verificação

- `godot --headless --path client --quit-after 30`.
- Uma cena temporária em `client/zz_tmp_check` (apagada no fim) que confere o `InteriorRoute` numa sala pequena de teste: o caminho não passa por quadrado bloqueado, a reta corta as quinas livres, e o toque num bloqueado leva ao livre mais perto.
- Uma cena temporária que abre a tela `interior` da sala 1 contra a API local por cima de outra tela, anda até a porta e confere a volta.
- Uma cena temporária que abre a tela com uma sala montada na memória, com um NPC com fala e a ação `refuge`, toca nele e confere a caminhada, a fala e a tela `heal_station` no fim.
- F5, depois da [03](03-interior-editor.md): os critérios acima.

## Tarefas

- [x] O `ActionScreens` e a peça com sala em Explorar.
- [x] O `InteriorTiles`, o `InteriorView` e a tela com a câmera.
- [x] O `InteriorRoute` e o andar.
- [x] Os NPCs, a conversa, a ação e a porta.
