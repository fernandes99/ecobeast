# fog-of-war

O mapa de Explorar começa escondido: só aparecem os hexágonos perto do Domador, e o resto vai aparecendo conforme ele anda, como se estivesse descobrindo o lugar. O que já foi descoberto fica aceso. Nas ilhas, a descoberta fica guardada na conta do jogador; no mapa sorteado, recomeça a cada exploração.

## Contexto

Em 2026-11-15, o dono pediu, com o Sandwalkers como referência: "a ideia é que eu consiga aprender o mapa só o que tiver proximo de mim, o restante não vai exibir, e só vai exibir quando eu chegar proximo, como se eu tivese descobrindo o ambiente. Hoje se eu tirar o zoom eu consigo ver todo o mapa, a ideia é que eu só consiga ver os campos que estão proximo a mim."

Como funciona hoje:

- **A entrada** (`POST /v1/me/exploration`, `server/src/exploration/exploration.controller.ts`) devolve o mapa inteiro de uma vez: o sorteado, ou a versão publicada da ilha com `{island_id}`. O servidor guarda na memória os Ecobeasts, os Domadores NPC e a posição do Domador, mas só fica sabendo da posição no Procurar e nas lutas (`confirmPosition`, `server/src/battle/battle-records.service.ts`). Ele não acompanha o andar.
- **O mapa** é um `HexMapView` (`res://ui/components/hex_map_view.gd`), dentro de `MapArea` na tela `res://screens/exploration/exploration_screen.tscn`. Os hexágonos usam coordenadas axiais (`q`, `r`), e `ExplorationMap.distance` dá a distância em hexágonos. Cada hexágono é desenhado erguido pela sua altura (`LEVEL_HEIGHTS`, até 80 px da arte), com as laterais para baixo.
- **O zoom** vai de 1 a 4 pixels da tela lógica por pixel da arte ([camera-zoom](../camera-zoom/)). No 1, uma ilha cabe quase toda na tela.
- **A luz da hora** (`DayLightLayer`, `res://ui/components/day_light_layer.gd`) é um `ColorRect` com shader logo depois do `MapView`. Ela recebe a vista pelo `set_view(art_origin, art_scale)` e soma as luzes das peças e dos vagalumes ([day-night](../day-night/), [fireflies](../fireflies/)).
- **Os nomes das construções** (`BuildingNamesLayer`) ficam numa camada depois da luz.
- **O desafio de um Domador NPC** só acontece quando o Domador pisa no hexágono dele (`_map.tamer_at`). Nenhum NPC enxerga de longe.

## Objetivos

1. Ao explorar, só aparece o que o Domador já descobriu; o resto fica coberto pela cor do fundo, com a borda irregular.
2. O Domador descobre os hexágonos a até 4 de distância de onde está, ao entrar e a cada hexágono novo.
3. Nas ilhas, a descoberta fica guardada no servidor e volta na próxima entrada, inclusive em outro aparelho.

## Anti-objetivos

- Ver a ilha inteira afastando o zoom.
- Uma luz de poste ou um vagalume brilhando no meio da névoa e entregando o que tem lá.
- Uma montanha descoberta cortada pela névoa por estar erguida.
- Perder a descoberta de uma ilha ao fechar e abrir o jogo.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| Nas ilhas, o que foi descoberto fica guardado na conta; no mapa sorteado, a névoa recomeça a cada exploração | "Guardar nas ilhas": é o que faz o jogador aprender a ilha. O mapa sorteado é outro a cada vez |
| O que foi descoberto fica todo aceso, com os Ecobeasts, os Domadores NPC e os NPCs, mesmo longe do Domador | "Tudo, como Sandwalkers", no lugar de mostrar o terreno apagado e sem os seres |
| O jogo desenha a névoa e avisa o servidor do que foi descoberto, e o servidor guarda | "Caminho 1", no lugar de o servidor calcular pela posição a cada passo ou de montar o mapa só onde foi descoberto |
| A borda da névoa é um degradê em 4 degraus, ao longo de mais ou menos um hexágono | Escolheu "Em degraus" entre o liso e o pontilhado, porque o corte seco da primeira versão ficou "muito abrupto" |
| Um anel de 1 hexágono em volta do descoberto aparece pela metade, as faixas do degradê são 6, mais largas, e cada hexágono novo aparece aos poucos (0,8 s) enquanto o Domador anda | "mais um campo na frente com uma trasparencia maior", "mais espaçoso as faixas" e "aos poucos junto com o movimento" |

| Andando pela névoa, o Domador não para nem desvia ao descobrir um Domador NPC no caminho: pisar no hexágono dele começa a luta, como hoje | "Seguir como hoje": andar no escuro tem risco. Só vale no mapa sorteado, porque as ilhas não têm Domadores NPC |

Os Ecobeasts das ilhas continuam sorteados a cada entrada: a névoa guarda só quais hexágonos foram descobertos, nunca os seres.

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O raio de descoberta é de 4 hexágonos, contado por `ExplorationMap.distance`, sem olhar paredes, altura ou linha de visão. _A revisar_ | É o mais simples de entender; ver mais longe do alto de uma montanha fica para depois |
| A névoa é uma camada nova com shader (`FogLayer`) em `MapArea`, entre o `MapView` e o `DayLight`, coberta pela luz da hora | É o mesmo esquema do `DayLightLayer`, não mexe na montagem do mapa e escurece junto com o fundo à noite |
| A máscara é uma imagem com um pixel por hexágono (descoberto e altura), e o shader acha o dono de cada pixel pela regra do `HexMapView.coord_at`, com o topo e as laterais de cada hexágono | Uma máscara plana, só pela grade, cortaria os hexágonos altos; a regra do toque no shader dispensa pintar formas |
| O que passa para cima da forma de um hexágono descoberto (a copa de uma árvore, o telhado de uma casa) fica coberto se cair sobre um escondido. _A revisar_ | Mostrar o que sobe sem mostrar o chão escondido atrás pede uma máscara por peça; fica para quando o dono vir |
| A cor da névoa é a mesma do fundo atrás do mapa hoje, e a borda é irregular, por ruído, em pixels inteiros da arte | Parece a borda do mapa no Sandwalkers e não borra a pixel art |
| As luzes das peças, os vagalumes e os nomes das construções em hexágonos escondidos não aparecem | Senão a névoa entregaria o que tem atrás dela |
| Um hexágono escondido mais para baixo na tela cobre com névoa o que ele já cobria | Não mostra pedaços de uma montanha escondida, e o que fica coberto já não aparecia sem a névoa |
| Tocar na névoa leva o Domador até lá, pelo caminho do mapa de verdade; um NPC ou uma peça com ação escondidos não respondem ao toque | Andar no escuro é como se explora, e um toque às cegas não deve abrir a tela de algo que não aparece |
| Uma tabela de estado do jogador, `island_discoveries` (`player_id`, `island_id`, `q`, `r`), com uma linha por hexágono | É o formato do resto do estado do jogador, como `codex_entries`, e fica legível no painel do Supabase |
| A entrada numa ilha devolve os hexágonos descobertos junto com o mapa | Evita uma chamada a mais antes de mostrar a ilha |
| O jogo manda os hexágonos novos em lotes, a cada 5 s, ao esconder a tela e ao sair dela, por uma fila no `Session` | Poucas chamadas enquanto anda, quase nada se perde se o jogo fechar, e o autoload termina o envio depois que a tela some |
| O servidor aceita só hexágonos que existem na versão publicada da ilha e ignora os repetidos | Não confere a posição: a descoberta não muda nenhuma regra (dano, captura, recompensa), então confiar no jogo é suficiente |
| O botão de debug "ver mapa inteiro" apaga a névoa enquanto estiver ligado, e um botão de debug novo, "Esquecer ilha", apaga a descoberta da ilha | Testar sem andar a ilha toda e recomeçar do zero |

## Fora do escopo

- Esconder os dados de verdade: o servidor continua mandando o mapa inteiro, e um jogo modificado poderia ver tudo.
- Ver mais longe do alto (Colina, Montanha) ou ter a visão cortada por paredes e construções.
- A névoa no tabuleiro da luta, no editor de ilhas (F2) e no Desafiar do Hub.
- Um minimapa ou uma porcentagem da ilha descoberta.
- Guardar a descoberta do mapa sorteado.
- Recompensa por descobrir.

## Pré-requisitos

- [islands](../islands/): as ilhas publicadas e a entrada com `{island_id}`.
- [camera-zoom](../camera-zoom/): o zoom que hoje mostra o mapa inteiro.
- [day-night](../day-night/) e [fireflies](../fireflies/): a camada da luz, onde as luzes escondidas precisam sair.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-discovery-store](01-discovery-store.md) | A tabela `island_discoveries`, os descobertos na entrada da ilha e as rotas para guardar e esquecer | concluída |
| 2 | [02-fog-layer](02-fog-layer.md) | A névoa no mapa de Explorar, com o raio de 4 hexágonos, a borda irregular e as luzes escondidas | concluída (falta o dono conferir no celular) |
| 3 | [03-island-memory](03-island-memory.md) | A ilha começando do que já foi descoberto, os lotes para o servidor e o "Esquecer ilha" | concluída (falta o dono conferir) |
