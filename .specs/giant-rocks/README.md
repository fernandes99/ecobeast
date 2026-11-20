# giant-rocks

Pedras gigantes para a Montanha: 10 desenhos de rocha, de 1,5 a 2,5 hexágonos de largura e até 4 vezes a altura do Domador, que viram peças soltas no F2 e nascem sozinhas nas Montanhas do mapa sorteado. Elas bloqueiam o Domador pelo pé.

## Contexto

Em 2026-11-20, o dono pediu: "Agora quero criar pedras gigantes para colocar nas montanhas, hoje as montanhas não tem nada praticamente, preciso de algo que remeta o biome de montanha por lá". A receita de decoração da Montanha (`HexDecorations.RECIPES["mountain"]`) só tem pedras marrons pequenas, um pouco de musgo, lajes e galhos, numa célula de 48×64.

Claude desenhou 10 pedras em pixel art, mostrou a prévia no chão da Montanha e no da Neve, e o dono aprovou: "Todas as 10".

## Objetivos

1. As 10 pedras como tipos de peça solta, na ferramenta Peças e num grupo do pincel Vegetação.
2. Cada pedra bloqueia o Domador por uma linha fechada no pé.
3. O mapa sorteado de Explorar (e a ilha nova pelo gerador do F2) ganha pedras gigantes nas Montanhas, com as de neve onde a montanha é de Neve.

## Anti-objetivos

- Uma pedra que corta a passagem: toda terra que se alcançava da chegada continua alcançável.
- Um Ecobeast ou um Domador NPC nascendo dentro de uma pedra.
- Mudar o resto do mapa de uma seed: o terreno, a água, as pontes e as zonas ficam iguais.

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| As 10 pedras da prévia entram no jogo | "Todas as 10" |
| No F2 e no mapa sorteado | Escolheu "F2 e mapa sorteado" |
| Bloqueiam pelo pé | Escolheu "Sim, pelo pé" |

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| 8 tipos (131 a 138), o Rochedo com 3 variantes | As de neve num tipo próprio deixam o pincel e o gerador escolherem sem olhar a variante |
| A arte desenhada por código (`make_giant_rocks.py`) | Como as decorações da `nature-variety`: dá para refazer e ajustar |
| A linha de bloqueio vai em cada peça do mapa sorteado (`block`) | O servidor sabe quais hexágonos ela fecha sem ler o catálogo, e uma mudança no F2 não abre uma pedra no meio de um mapa já conferido |
| A pedra só fica num hexágono de Montanha, sem outra pedra vizinha | A Montanha é onde faltava, e as pedras não viram uma parede |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-rock-props](01-rock-props.md) | A arte, os 8 tipos com o bloqueio e o grupo do pincel | concluída (falta o dono conferir no F2) |
| 2 | [02-generated-rocks](02-generated-rocks.md) | As pedras no mapa sorteado e na ilha nova pelo gerador | concluída (falta o dono conferir no jogo) |
