# 02. As pedras no mapa sorteado

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-rock-props](01-rock-props.md), [map-realism](../map-realism/)

## Escopo

- `server/src/domain/exploration/map-rocks.ts` (novo) e o `map-generator.ts`, que devolve as pedras em `props`.
- `server/src/exploration/exploration.service.ts`: manda as pedras e não sorteia Ecobeast nem Domador NPC num hexágono fechado por elas.
- `server/src/editor/map-generator.controller.ts` e o DTO: a resposta do gerador do F2 traz `props`.
- `client/tools/map_editor/island_draft.gd`: a ilha nova pelo gerador começa com as pedras.

## Requisitos

- **RF-01:** Depois do resto do mapa, `placeGiantRocks` passa pelos hexágonos de Montanha (`shape` `mont`) numa ordem sorteada por um sorteio próprio (`seed ^ ROCKS_SALT`), sem mudar nenhum outro sorteio do mapa. Cada um ganha uma pedra com a chance `ROCK_CHANCE` (0,35, _a revisar_).
- **RF-02:** O tipo vem do bioma do hexágono:

  | Bioma | Tipos |
  | --- | --- |
  | Neve | 136, 137, 138 |
  | Deserto | 131 (marrom ou granito), 132, 133, 135 |
  | os outros | 131 (as 3 variantes), 132, 133, 134, 135 |

  A Crista (135) só entra quando o vizinho da direita (q + 1) também é Montanha e livre, com o pé entre os dois; senão, sorteia outro tipo.
- **RF-03:** O pé fica no centro do hexágono, ajustado para que a linha de bloqueio do RF-02 da fase 1 fique centrada nele, e a peça sai com essa linha em `block`. A arte pode sair espelhada.
- **RF-04:** Uma pedra só entra se:
  - nenhum hexágono que ela fecha já está fechado ou encosta num hexágono fechado por outra pedra;
  - nenhum é a chegada;
  - toda terra que se alcançava da chegada, andando e pelas pontes, continua alcançável sem os hexágonos fechados.
- **RF-05:** No mapa sorteado de Explorar, a resposta traz as pedras em `props`, e os Ecobeasts e os Domadores NPC só nascem fora dos hexágonos fechados.
- **RF-06:** O gerador do F2 devolve as pedras em `props`, e a ilha nova começa com elas como peças comuns, que o dono pode mover ou apagar.

## Critérios de aceite

- [x] Em 24 seeds com a configuração do jogo (`map-rocks.spec.ts`): toda pedra fecha só hexágonos de Montanha, sem pedra vizinha de outra; a chegada nunca é fechada; a terra alcançável é a de antes menos os hexágonos fechados.
- [x] As de neve só ficam na Montanha de Neve, e as outras fora dela; há mapas com pedras de cada tipo.
- [x] Os hexágonos e as pontes de uma seed não mudam: as pedras usam um sorteio próprio e não mexem nos hexágonos (os testes do gerador passam sem mudar).
- [x] Os testes de unidade e os e2e do servidor passam. Em 2026-11-20: 1068 de unidade e 693 de 696 e2e. Duas falhas (`species_day_phases` e `species_skills`) já existiam antes, e a terceira era o e2e do mapa sorteado sem peças, que agora confere as pedras e passa.
- [ ] O dono conferiu no jogo, em Explorar zona.

## Resultado da verificação

Em 2026-11-20:

- Cada mapa do jogo (10.000 hexágonos, de 260 a 280 de Montanha) teve de 43 a 52 pedras. As pedras levam uns 30 ms dos cerca de 250 ms do gerador.
- Pelo próprio jogo, as seeds 13 (Temperado) e 31689 (Frio) foram desenhadas com o `HexMapView`. As pedras ficam em cima da Montanha, na altura dela, e no mapa Frio só aparecem as de neve.
