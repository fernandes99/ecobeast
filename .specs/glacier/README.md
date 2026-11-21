# glacier

Um bioma novo e raro, a Geleira: chão todo de gelo, com pedras grandes de gelo e às vezes um lago no meio. Ele aparece como uma mancha pequena ou média dentro da Neve, só em alguns mapas frios do mapa sorteado, e o dono pode pintá-lo nas ilhas pelo F2. Serve de casa para uma espécie nova, que o dono vai criar depois, e o Hushling e o Echofrost também nascem nele, mais raros que na Neve.

## Contexto

Em 2026-11-21, o dono pediu: "Quero criar um novo bioma, ele será um bioma raro de se aparecer [...] Ele será um bioma de gelo (hoje só tenho de neve). A ideia é usar ele para aparecer certos ecobeasts."

O que já existia:

- **Um bioma hoje** ([desert-snow](../desert-snow/)) é:
  - uma linha em `biomes`, com quem nasce nele em `species_biomes` e a zona Comum em `biome_zones`;
  - o slug em `BIOMES` do gerador, aceito pelas rotas do mapa, das ilhas e do editor;
  - no jogo, a textura `assets/terrain/surfaces/<slug>.png`, as linhas dele em `transitions.png` e `drips.png`, o lugar em `HexTransitions.SURFACE_ORDER` e a receita em `HexDecorations.RECIPES`;
  - no F2, uma amostra no bloco Bioma.
- **O mapa sorteado** ([map-realism](../map-realism/)): cada mapa tem um clima, e o Frio sai em 20% deles. A Neve vem do ruído de calor e só encosta no Boreal, na Pedra, na Colina, na Montanha e na água.
- **Gelo no catálogo:** só o Hushling e o Echofrost são do Elemento Gelo, e os dois nascem na Neve (taxas 100 e 30). A Neve já tem a decoração `ice_shards` (cristais de gelo).
- **Pedras gigantes** ([giant-rocks](../giant-rocks/)): peças soltas desenhadas por código, que bloqueiam pelo pé, sorteadas pelo servidor nas Montanhas (`placeGiantRocks`).
- **Lagos:** redondos, com a zona Lago da água doce (33 e 34, [sea-life/07](../sea-life/07-lakes-and-trash.md)).

Na conversa, Claude sugeriu que, se a única diferença fosse quem nasce, uma zona da Neve bastaria. O dono descreveu um lugar de chão e arte próprios, então a Geleira é um bioma.

## Objetivos

1. A Geleira existe no catálogo, com quem nasce nela.
2. Ela tem a arte própria: o chão de gelo, os arremates com os vizinhos e as decorações.
3. As pedras grandes de gelo existem como peças soltas, que bloqueiam pelo pé, no F2 e no mapa sorteado.
4. No mapa sorteado, só alguns mapas frios ganham uma mancha de Geleira dentro da Neve, às vezes com um lago.
5. O F2 pinta a Geleira, e a luta aberta em cima dela usa o chão dela.

## Anti-objetivos

- **A Geleira comum:** ela não pode aparecer em quase todo mapa frio, nem tomar a Neve inteira.
- **A Geleira fora do frio:** ela não pode encostar na Planície, no Deserto, na Praia nem no Boreal. Ela só fica cercada de Neve.
- **A seed mudada:** fora da mancha da Geleira, um mapa da mesma seed fica como antes, nos biomas, na altura, na água, nas pontes e nas pedras. As zonas da Neve podem mudar de lugar (ver as decisões).
- **Uma passagem cortada:** a mancha e o lago não podem deixar sem caminho uma terra que se alcançava da chegada.
- **Regras novas:** nada de escorregar no gelo, dano por frio ou outra regra. A Geleira muda só a aparência e quem nasce, como o Deserto e a Neve.
- **Arte de terceiros:** tudo é desenhado por código, como na `desert-snow` e na `giant-rocks`.

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| Um bioma de gelo, diferente da Neve, e raro | O pedido |
| Tudo feito de gelo, com pedras grandes de gelo | "vai ser tudo feito de gelo [...] eu penso em pedras grande de gelo" |
| Às vezes um lago, às vezes não | "as vezes vai ter um lago nesse bioma e as vezes não" |
| Uma região pequena ou média, só em alguns mapas frios | "uma região pequena/média, que aparece só em alguns mapas frios. Ela deve ser rara." |
| O Hushling e o Echofrost nascem nela, mais raros que na Neve | "pode nascer lá também, mas será mais dificil do que na neve" |
| A espécie própria da Geleira vem depois, em outra iniciativa | "Vou criar outro para nascer nesse bioma novo." |
| No mapa sorteado, a Geleira é uma mancha sorteada (a abordagem B) | "Pode seguir com a B" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O nome é Geleira, com o slug `glacier` e o id 12 | "Gelo" já é o nome de um Elemento. O id 11 era o Vau, que saiu ([map-realism/02](../map-realism/02-no-ford.md)), e ids não se reaproveitam |
| As taxas da Geleira: Hushling 30 e Echofrost 10 | 30% das da Neve (100 e 30), mais raros como o dono pediu |
| A Geleira tem só a zona Comum (id 35) | Ela já é pequena. A zona Lago gelado é da água, abaixo |
| 1 mapa frio em 4 ganha Geleira (`glacierChance` 0,25), perto de 1 mapa sorteado em 20 | "só em alguns mapas frios"; "rara" |
| A mancha tem de 20 a 60 hexágonos (`glacierMin` e `glacierMax`) | "pequena/média" |
| A mancha nasce num hexágono de Neve bem dentro dela, o mais longe da borda da Neve, e cresce pela Neve com a borda irregular, sem sair dela. Ela deixa pelo menos 1 hexágono de Neve entre ela e qualquer outro bioma | Assim ela fica sempre cercada de Neve. Se a Neve do mapa não comporta `glacierMin`, o mapa fica sem Geleira |
| O sorteio da Geleira (se sai, onde e o lago) vem de um sorteio à parte, a partir da seed | O resto da seed não muda, como o calor da `desert-snow` |
| Só o clima Frio ganha Geleira, mesmo que um mapa Temperado tenha Neve que caiba nela | "só em alguns mapas frios" |
| Na metade das Geleiras (`glacierLakeChance` 0,5), um lago redondo no meio da mancha, de raio 1 ou 2 (7 ou 19 hexágonos), com código próprio, sem o `placeLakes`. O de raio 2 tem a água funda no meio (`DEEP_LAKE_FROM` é 12); o de raio 1 é todo raso. A Geleira continua com pelo menos `glacierMin` hexágonos de terra além do lago | "as vezes vai ter um lago"; o dono gosta dos lagos redondos. Os lagos de hoje têm pelo menos 6 hexágonos de largura (`lakeMinWidth`), grandes demais para uma mancha de 20 a 60 |
| O lago fica só numa Geleira baixa: com o lago sorteado, a mancha nasce num ponto de Neve no patamar 1 ou abaixo. Sem um ponto assim, ela sai sem lago | Toda água fica na altura 0 (`terrain-plateaus`), e um lago no patamar 7 seria um buraco de 7 níveis. A fase 4 mede quantas Geleiras ficam com lago e avisa o dono se for bem menos que a metade |
| O lago da Geleira fica numa zona nova, Lago gelado, da Água rasa (36) e da Água profunda (37), com placas de gelo boiando | É a água de sempre, mas fria, e só o lago da Geleira cai nela |
| Os parâmetros entram no gerador do F2, ao lado dos do mar e dos lagos | Como os da `coast-rivers`: o dono testa a Geleira na ilha nova |
| A Geleira guarda a altura da Neve que ela troca | A `terrain-plateaus` já deu a altura ao terreno, e trocar só o bioma não mexe nos paredões nem nas escadarias |
| No arremate, a Geleira vem logo antes da Neve em `SURFACE_ORDER` | A neve soprada avança sobre a borda do gelo |
| O paredão da Geleira é o `cliff.png`, de rocha | O gelo é duro como a pedra, e o `side.png` é de terra |
| Decorações da Comum: rachaduras, bolhas presas no gelo, lascas soltas, montinhos de neve soprada, os `ice_shards` da Neve e, raríssimo, um peixe preso no gelo | As sugestões de Claude na conversa. O dono não corrigiu, mas também não escolheu |
| As pedras grandes de gelo, de 6 a 8 desenhos: bloco, pináculos, arco, rocha escura presa no gelo e bloco com sincelos | Como as pedras gigantes da Montanha, que também nasceram de 10 desenhos mostrados ao dono antes |
| As decorações novas da Geleira e as placas de gelo também viram tipos de peça solta, como na `nature-variety`, na `sea-life` e na `beach-life`. As pedras de gelo entram na categoria Pedras gigantes, e todas ficam num grupo Geleira do pincel Vegetação | O dono pinta as ilhas com o pincel |
| Os tipos novos começam no 165, na ordem das fases, conferidos no banco antes da migration | Os ids 154 a 164 ficaram reservados e sem uso na `beach-life`. O `seed-data` está atrasado (para no 100) |
| A arte das fases 1 e 2 é mostrada ao dono numa prévia, no chão da Geleira, e só entra depois que ele aprovar | Como as pedras gigantes, que entraram depois do "Todas as 10" |
| "A seed não muda" vale para o terreno fora da mancha: os biomas, a altura, a água, as pontes e as pedras. As zonas da Neve e as variantes podem mudar de lugar | O `assignZones` divide cada bioma por posição, e tirar hexágonos da Neve move o Campo de neve e o Pinheiral nevado. Segurar isso pede calcular as zonas como se a Geleira fosse Neve, um custo sem ganho visível |
| No mapa sorteado, as pedras de gelo nascem só na Geleira, como as da Montanha: sem encostar uma na outra, sem fechar caminho e sem Ecobeast nem Domador NPC dentro | A regra das pedras gigantes de hoje |
| A arte é desenhada pelo `make_glacier.py`, em `client/assets/terrain/` | Como o `make_desert_snow.py` e o `make_giant_rocks.py`, ele pode rodar de novo |
| A arte vem primeiro (fases 1 e 2), e o catálogo e o gerador depois (3 e 4) | A `rolling-hills` estava mudando o `map-generator.ts` em outra sessão quando a iniciativa foi escrita. Ela foi commitada (`b018e8a`) durante a fase 1, então as fases 3 e 4 não esperam mais nada |

## Abordagens

Para fazer a Geleira nascer no mapa sorteado, Claude considerou três caminhos:

| Caminho | Como funciona | Troca |
| --- | --- | --- |
| A. Pelo frio | A parte mais fria da Neve, abaixo de um limite de calor menor, vira Geleira | É o mais simples, mas o tamanho e a raridade dependem do ruído: um mapa sai com três manchinhas, outro com uma mancha enorme. E o calor depende da altitude, que a `rolling-hills` está mudando |
| **B. Uma mancha sorteada (a escolhida)** | Um sorteio à parte decide se o mapa frio ganha a Geleira, e uma mancha de tamanho controlado cresce dentro da Neve, com o lago às vezes | Um pouco mais de código, mas garante o raro, o tamanho e o lago, e não muda o resto da seed |
| C. Só nas ilhas | A Geleira existe só para pintar no F2 | Descartada: o dono quer a Geleira em alguns mapas frios sorteados |

O dono escolheu a B.

## Fora do escopo

- A espécie própria da Geleira: é outra iniciativa, de linha evolutiva, como a [glimshell-line](../glimshell-line/).
- Neve caindo, gelo brilhando ou outra animação.
- Pintar a Geleira em Liora ou em outra ilha: o dono faz isso no F2.
- Mudar a Neve, as taxas dela ou a regra dos climas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-glacier-art](01-glacier-art.md) | O `make_glacier.py`: o chão, os arremates, o escorrido, as decorações da Comum e as placas de gelo do Lago gelado, aprovados pelo dono numa prévia, e os tipos de peça delas no grupo Geleira | concluída (falta o dono conferir no F2) |
| 2 | [02-ice-rocks](02-ice-rocks.md) | As pedras grandes de gelo, aprovadas pelo dono numa prévia, como tipos de peça solta com o bloqueio no pé, na categoria Pedras gigantes e no grupo Geleira | proposta |
| 3 | [03-glacier-records](03-glacier-records.md) | A Geleira (12) no catálogo, com a zona Comum (35), as zonas Lago gelado (36 e 37), as taxas do Hushling e do Echofrost, o slug aceito pelas rotas e a amostra no F2 | proposta |
| 4 | [04-generated-glacier](04-generated-glacier.md) | A mancha no mapa sorteado e na ilha nova pelo F2, com o lago às vezes e as pedras de gelo | proposta |
