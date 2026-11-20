# 01. Clima, relevo e vizinhanças

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [coast-rivers](../coast-rivers/), [desert-snow](../desert-snow/)

## Contexto

Veja os problemas no [README](README.md#contexto). Esta fase troca a escolha do bioma e da forma do terreno no `map-generator.ts`. O mar, os lagos, os rios e as zonas (`map-zones.ts`) continuam saindo dos mesmos passos.

## Escopo

- `server/src/domain/exploration/map-generator.ts`, `map-config.ts`, `map-water.ts` e os testes deles.
- Os nomes dos parâmetros novos no `new_island_panel.gd` (`PARAM_LABELS`).

## Requisitos

**Mapa sem buracos**

- **RF-01:** Depois de crescer a região, o hexágono vazio cercado pelo mapa entra nela. Para manter `tileCount`, saem os hexágonos da borda de maior nota, um por vez, só os que não partem a região.

**Relevo**

- **RF-02:** A altitude de cada hexágono de terra (`elevation`, de 0 a 1 por percentil) mistura o ruído de altitude, as cristas e a distância até o mar. O peso de cada um fica em `map-generator.ts`. O mar é decidido antes.
- **RF-03:** A Montanha é a terra acima de `mountainFrom`, e a Colina fica entre `hillFrom` e `mountainFrom`. A montanha solta continua virando Colina (`gatherMountains`, de novo depois das pontes, que podem aplainar uma margem). A forma é decidida antes da água, e a água fica sempre plana.
- **RF-04:** Os rios descem pela mesma altitude (`drainOf`), e a nascente não fica numa Montanha.

**Clima**

- **RF-05:** Cada mapa sorteia um clima, com a base de calor e de umidade dele. O parâmetro `climate` (0 sorteia, ou de 1 a 4) fixa um deles para o gerador de ilhas.

  | # | Clima | Chance | Calor | Umidade |
  | --- | --- | --- | --- | --- |
  | 1 | Temperado | 40% | 0,50 | 0,50 |
  | 2 | Frio | 20% | 0,24 | 0,50 |
  | 3 | Quente | 20% | 0,80 | 0,40 |
  | 4 | Úmido | 20% | 0,54 | 0,68 |

- **RF-06:** O calor de um hexágono é a base do clima mais três partes:
  - uma rampa numa direção sorteada, de −0,22 a +0,22 de uma ponta à outra do mapa;
  - um ruído largo, em ±0,14;
  - o frio da altitude, que tira até 0,12 no alto.

  A umidade é a base mais um ruído, em ±0,3. Os dois usam ruídos em percentil, mas não são ordenados de novo depois da soma.
- **RF-07:** O bioma da terra sai do calor `t` e da umidade `u`:
  - `t` < 0,12: Neve;
  - `t` < 0,26: Boreal;
  - `t` > 0,82 e `u` < 0,55: Deserto;
  - `u` > `wetLimit`: Boreal;
  - senão: Planície (`temperate`).

  A Pedra é a terra alta (`elevation` acima de `stoneFrom`), fora da Neve, onde um ruído de pedra passa de 0,5.

**Vizinhanças**

- **RF-08:** Depois da Praia, uma passada final:
  1. O Deserto a até 3 hexágonos da Neve vira Planície.
  2. A Planície, o Deserto e a Praia a até 2 hexágonos da Neve viram Boreal. A Praia vira Pedra.
  3. O Deserto encostado no Boreal vira Planície.
- **RF-09:** A Praia só nasce onde a terra não é Neve nem Boreal frio (`t` < 0,26). Ali, a faixa da costa vira Pedra.

**Configuração**

- **RF-10:** Saem `desertFraction`, `snowFraction` e `stoneFraction`. Entram `climate` (inteiro de 0 a 4) e `stoneFrom` (fração). Os padrões, ajustados pela prévia: `wetLimit` 0,58, `stoneFrom` 0,72, `hillFrom` 0,86 e `mountainFrom` 0,96. Como a Pedra agora fica no alto, parte dela é colina: o teste antigo de "principalmente chão plano" passou a pedir mais de 30% de chão plano.

## Critérios de aceite

- [x] Ao longo de 60 seeds, com o clima sorteado, há mapas sem Neve, mapas sem Deserto e mapas sem os dois.
- [x] Em nenhum mapa a Neve fica a até 2 hexágonos da Planície, do Deserto ou da Praia, e o Deserto não encosta no Boreal.
- [x] Nenhum mapa tem buraco, e todos têm `tileCount` hexágonos.
- [x] A Colina fica abaixo de 12% da terra, e as montanhas formam conjuntos.
- [x] Os lagos continuam redondos (o teste de antes passa sem mudar).
- [x] Os testes de unidade e os e2e do servidor passam. Em 2026-11-20: 1054 de unidade e 690 de 692 e2e; as 2 falhas (`species_day_phases` e `species_skills`) já existiam antes.
- [x] A prévia de 8 mapas, 2 de cada clima, foi mostrada ao dono.
- [ ] O dono conferiu no jogo, em Explorar zona.
