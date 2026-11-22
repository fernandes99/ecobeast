# volcano

Um bioma épico e raro, o Vulcão: um cone grande de rocha escura, íngreme e em patamares, com a borda no alto e a cratera no meio, onde a lava rasa (mais clara) e a funda (mais escura) se mexem e brilham à noite. Ele aparece de duas formas no mapa sorteado: um cone no meio da terra de um mapa comum, ou um mapa inteiro que é uma ilha vulcânica no meio do oceano, com só um pouco de floresta e praia no pé. Quem pega essa seed tem que pensar "tirei a sorte" e "nossa, que diferente!". No futuro, o Vulcão terá itens e Ecobeasts próprios.

## Contexto

Em 2026-11-21, o dono pediu: "vamos criar mais um bioma, vai ser outro bioma raro, dessa vez será um bioma épico. Quero criar um bioma de vulcão [...] A ideia é ter um relevo muito alto em volta e ter lava no centro, deve ser um bioma grande e raramente será criado no mundo." Ele mandou de inspiração a imagem de um vulcão com picos pontudos em volta, lava alaranjada escorrendo no meio e floresta no pé.

O que já existia:

- **Um bioma hoje** ([desert-snow](../desert-snow/), [glacier](../glacier/)) é:
  - uma linha em `biomes`, com quem nasce nele em `species_biomes` e a zona Comum em `biome_zones`;
  - o slug em `BIOMES` e `SHAPED_BIOMES` do gerador (`server/src/domain/exploration/map-generator.ts`), aceito pelas rotas do mapa, das ilhas e do editor;
  - no jogo, a textura `client/assets/terrain/surfaces/<slug>.png`, a linha dele em `transitions.png` e `drips.png`, o lugar em `HexTransitions.SURFACE_ORDER`, a cor do minimapa (`minimap_palette.gd`) e a receita em `HexDecorations.RECIPES`;
  - no F2, uma amostra no bloco Bioma (`editor_tools.gd`).
- **A altura** ([terrain-plateaus](../terrain-plateaus/), [rolling-hills](../rolling-hills/)): vai de 0 a 10. A terra fica nos patamares 1, 4 e 7, a Montanha de 8 a 10 e toda água no 0. O Domador sobe ou desce no máximo 2 níveis por passo (`MAX_CLIMB`). Um paredão de 3 ou mais bloqueia, e as escadarias (`openRamps`) e a garantia de alcance (`openSlopes`, em `map-slopes.ts`) abrem degraus de 1 e 2.
- **A água** ([water-motion](../water-motion/)): a Água rasa e a funda bloqueiam o andar (`blocksWalking` no servidor, `HexTile.blocks_walking` no jogo). A superfície ondula pelo `hex_grounds.gdshader` (o código 4 é a superfície, com a funda no z), e toda lateral de água vira cachoeira.
- **A noite** ([day-night](../day-night/), [fireflies](../fireflies/)): o `day_light.gdshader` escurece o mapa e acende as luzes das peças (`prop_type_lights`, até `MAX_LIGHTS`) e os vagalumes, desenhados no próprio shader.
- **A raridade de hoje:** a Geleira ([glacier/04](../glacier/04-generated-glacier.md)) sai em 1 mapa frio a cada 4, uns 5% dos mapas, com 20 a 60 hexágonos, por um sorteio próprio a partir da seed (`map-glacier.ts`), depois do `openSlopes`. O mapa tem 10.000 hexágonos (`tileCount`).
- **Pedras gigantes** ([giant-rocks](../giant-rocks/), [glacier/02](../glacier/02-ice-rocks.md)): peças soltas desenhadas pelo `make_giant_rocks.py`, com o bloqueio no pé, sorteadas pelo servidor (`placeRocks` em `map-rocks.ts`).
- **Fogo no catálogo:** só a linha do Ruvo (Ruvo 1, Ruvak 2 e Ruvaroth 3), que nasce em vários biomas, a Montanha entre eles (taxas 20, 40 e 20).

## Objetivos

1. O Vulcão, a Lava rasa e a Lava funda existem no catálogo, e a linha do Ruvo nasce no Vulcão.
2. Eles têm arte própria: o chão de rocha vulcânica, a lava que se mexe e brilha à noite, os arremates, as decorações e os picos de basalto.
3. O Vulcão é alcançável: escadarias em degraus sobem a encosta íngreme até a borda e descem até o piso da cratera.
4. No mapa sorteado, um mapa raro ganha um vulcão grande no meio da terra, e um mapa mais raro ainda é uma ilha vulcânica no meio do oceano.
5. O F2 pinta o Vulcão e a lava, e o gerador da ilha nova pode forçar cada forma, para o dono testar sem depender da sorte.

## Anti-objetivos

- **O vulcão comum:** ele não pode aparecer em muitos mapas. O "tirei a sorte" acaba se o jogador o vê toda semana.
- **O vulcão pequeno ou sem graça:** ele não pode sair como uma montanha qualquer com uma poça de lava. O cone, a borda alta e a cratera têm que ser reconhecíveis de longe e no minimapa.
- **A cratera fechada:** o piso da cratera não pode ficar sem caminho a pé desde a chegada, nem ter um pedaço de chão preso entre a lava e os paredões.
- **A encosta fácil:** ela não pode ser uma rampa suave. Subir é pelas escadarias, e o resto da encosta é de paredões.
- **O mapa mudado sem vulcão:** com as chances do vulcão em 0, o mapa de uma seed é igual ao de antes, hexágono por hexágono.
- **Regras novas:** nada de dano por lava, calor, erupção ou outra regra. Por enquanto o Vulcão muda só a aparência e quem nasce. A lava só bloqueia o andar, como a água.
- **Arte de terceiros:** tudo é desenhado por código, como na `glacier` e na `giant-rocks`.
- **Vocabulário do Pokémon:** nada de nomes, termos ou visuais dele ([glossary](../glossary.md)).

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| Um bioma de vulcão, épico e raro | O pedido |
| Relevo muito alto em volta e lava no centro | "ter um relevo muito alto em volta e ter lava no centro" |
| Grande e raro | "deve ser um bioma grande e raramente será criado no mundo" |
| No futuro, itens e Ecobeasts próprios do Vulcão | "A ideia é que no futuro tenha itens e ecobeasts especificos lá." |
| A cratera é alcançável, por degraus, mas a encosta é íngreme | "Deve ser alcancabel sim, a crateria deve ter maneiras de conseguir subir e em degraus, mas ao mesmo tempo ser ingrime." |
| O cone carimbado por um sorteio próprio (a abordagem A) | "pode seguir com a A" |
| Às vezes no meio do oceano, como o centro do mapa, com só um pouco de floresta do lado | "pode ter chance de ser no meio do oceano, ele deve ser bem grande, pode ter gerações onde ele será o centro e terá apenas algumas floresta do lado" |
| O efeito no jogador: sorte e surpresa | "Eu quero que o usuário que pegou essa seed já pense: 'tirei a sorte aqui', 'nossa, que diferente!'" |
| Lava rasa, mais clara, e lava funda, mais escura | "pode ter lavas mais claras e mais escuras, também simbolizando lava rasa e funda" |
| O resto da proposta de Claude (as duas formas, as chances, o tamanho, a lava se mexendo e brilhando, as decorações, quem nasce, o F2 e o fora do escopo) | "pode seguir, está certo" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Os nomes são Vulcão (`volcano`), Lava rasa (`lshallow`) e Lava funda (`ldeep`), nos ids 13, 14 e 15 | Os slugs da lava seguem os da água (`wshallow`, `wdeep`). Os ids continuam a lista: a Geleira é a 12 |
| Duas formas: o **vulcão em terra**, em perto de 1 mapa a cada 15 (`volcanoChance` 0,07), e a **ilha vulcânica**, em perto de 1 mapa a cada 50 (`volcanoIslandChance` 0,02). A ilha é sorteada primeiro, e um mapa nunca tem as duas | O dono aprovou as duas formas e a raridade proposta. A ilha é a mais rara porque é a mais diferente |
| Nenhum vulcão sai no clima Frio, nem a ilha vulcânica com o `climate` fixado em `cold` | Assim ele não divide o mapa com a Geleira, e cada mapa raro tem uma surpresa só |
| Os dois sorteios (a ilha e o vulcão em terra) rodam sempre, cada um com o sal dele, e a ilha vence quando os dois saem | Assim ligar um não muda os mapas do outro |
| As raridades são a parte dos mapas, não a chance do sorteio: o vulcão em terra em 5% a 8% dos mapas fora do Frio. O construtor ajusta o `volcanoChance` se faltar lugar | O que o dono sente é quantos mapas têm vulcão |
| O vulcão em terra só nasce em chão dos patamares 1 e 4, sem Colina nem Montanha no disco, e tenta raios menores antes de desistir. Ele nunca passa por cima de água, ponte ou Montanha | Num chão de 7 não cabe o paredão do pé abaixo da borda no 10. Cobrir rios e lagos quebraria a água em volta |
| A borda fica no 10, e o 9 só onde não encosta na encosta de fora | Um 9 ao lado do patamar 7 se subiria sem escadaria |
| O vulcão em terra tem raio de 10 a 14 hexágonos (uns 300 a 600), e o da ilha ocupa de 40% a 60% da terra | "bem grande". O da ilha é "o centro" do mapa |
| O perfil do cone, de fora para dentro: o pé no chão em volta, a encosta subindo em patamares com paredões de 3 ou mais níveis até a borda, a borda de 9 e 10 com picos, e o piso da cratera no 6, com a lava no mesmo nível | A altura vai só até 10. O piso no 6 deixa 4 níveis de paredão por dentro, íngreme dos dois lados |
| A lava fica no piso da cratera: a funda no meio e a rasa em volta dela, com um anel de chão de Vulcão andável entre a lava e o paredão de dentro. Às vezes saem braços de lava rasa do lago até o pé do paredão, como as rachaduras da imagem | O dono quer a lava no centro, e o piso precisa ter onde andar |
| 2 ou 3 escadarias por vulcão em terra e 3 ou 4 na ilha, espalhadas em volta do cone. Cada uma sobe a encosta de fora em degraus de 1 e 2 e desce por dentro até o anel do piso | "maneiras de conseguir subir e em degraus" |
| Os picos da borda são peças soltas, os picos de basalto, desenhados pelo `make_giant_rocks.py` com o material basalto e sorteados na borda e na encosta | A altura não passa de 10, então os espetos da imagem só aparecem como peças altas. É o mesmo caminho das pedras de gelo |
| A lava se mexe pelo mesmo caminho da água no `hex_grounds.gdshader`, mais devagar e com um brilho que pulsa. A lava funda é mais escura e vermelha, e a rasa mais clara e amarela | "lavas mais claras e mais escuras" |
| À noite, a lava fica clara (o filtro da noite não a escurece) e solta uma luz fraca e alaranjada em volta, no `day_light.gdshader`, como os vagalumes | O vulcão aceso na noite é o momento mais marcante dele |
| A lateral de um hexágono de lava (se houver) é o paredão de rocha, sem cachoeira de lava | Cachoeira de lava é animação nova. Pelo perfil do cone, a lava fica no piso e quase não tem lateral |
| A linha do Ruvo nasce no Vulcão: Ruvo 20, Ruvak 30 e Ruvaroth 15. Ninguém nasce na lava | Assim o Vulcão não fica vazio até as espécies próprias. O Ruvaroth um pouco mais comum que na Montanha, por ser a casa dele |
| Só a zona Comum em cada um dos 3 biomas (38 a 40, conferidos no banco) | Zonas e plantas próprias vêm com as espécies próprias |
| Decorações da Comum do Vulcão: pedrinhas de basalto, rachadura com brilho de lava, fumarola (uma boca soltando fumaça), árvore queimada, cinza no chão e obsidiana. Na lava rasa, placas de crosta escura boiando | A proposta aprovada pelo dono |
| As decorações e os picos também viram peças soltas, numa categoria Vulcão, e entram no pincel Vegetação nos grupos Vulcão e Picos de basalto | Como a `glacier`: o dono pinta as ilhas com o pincel |
| A ilha vulcânica tem o clima Úmido. O pé dela é a Praia na costa e um cinto de Planície e Boreal entre a praia e o cone, sem Neve, Deserto, rios grandes nem montanhas fora do vulcão | "terá apenas algumas floresta do lado". Um bioma novo de selva ficou fora do escopo |
| A arte das fases 1 e 2 é mostrada ao dono numa prévia e só entra depois que ele aprovar | Como na `glacier` e na `giant-rocks` |
| Os ids das peças começam no 177, as linhas da folha de decorações na 72, e a categoria nova é a próxima livre. Tudo conferido no banco antes de cada migration | A Geleira parou na peça 176 e na linha 71. O `seed-data` está atrasado |

## Abordagens

Para fazer o vulcão nascer no mapa sorteado, Claude considerou três caminhos:

| Caminho | Como funciona | Troca |
| --- | --- | --- |
| **A. Um cone carimbado (a escolhida)** | Um sorteio à parte decide se o mapa ganha vulcão e onde. O gerador desenha o cone com o perfil fixo (encosta em paredões, borda, cratera e lava) e abre as escadarias | O formato, o tamanho e a raridade ficam sob controle, e o mapa sem vulcão não muda. Pede mais código |
| B. Virar um maciço que já existe | O maior maciço de Montanha vira vulcão, com o miolo rebaixado | Os maciços têm formas tortas e tamanhos variados, então o vulcão nem sempre parece um cone. E só sai em mapa com montanha grande |
| C. Só nas ilhas, pintado no F2 | O bioma existe, e o gerador não o cria | Não atende o "raramente criado no mundo" |

O dono escolheu a A e pediu, além dela, a forma da ilha vulcânica.

## Fora do escopo

- As espécies e os itens próprios do Vulcão: outras iniciativas, depois desta.
- Dano por lava, calor, erupções, rios de lava descendo a encosta, cachoeira de lava e fumaça animada nas fumarolas.
- Um bioma de selva tropical para o pé da ilha vulcânica.
- Pintar um vulcão em Liora ou em outra ilha: o dono faz isso no F2.
- Mudar a Montanha, os climas ou a Geleira.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-volcano-art](01-volcano-art.md) | O `make_volcano.py`: o chão do Vulcão, a lava rasa e a funda, os arremates e as decorações, aprovados pelo dono numa prévia; a lava se mexendo e brilhando à noite; os tipos de peça das decorações no grupo Vulcão | pendente |
| 2 | [02-basalt-spires](02-basalt-spires.md) | Os picos de basalto, aprovados pelo dono numa prévia, como tipos de peça solta com o bloqueio no pé, no grupo Picos de basalto | pendente |
| 3 | [03-volcano-records](03-volcano-records.md) | O Vulcão e a lava (13 a 15) no catálogo, com as zonas Comum, as taxas da linha do Ruvo, a lava bloqueando o andar, o slug aceito pelas rotas e as amostras no F2 | pendente |
| 4 | [04-land-volcano](04-land-volcano.md) | O vulcão em terra no mapa sorteado e na ilha nova pelo F2: o cone, a cratera, a lava, as escadarias e os picos | pendente |
| 5 | [05-volcanic-island](05-volcanic-island.md) | A ilha vulcânica: o mapa inteiro como o vulcão no meio do oceano, com a praia e a floresta no pé | pendente |
