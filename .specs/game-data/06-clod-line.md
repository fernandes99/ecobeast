# 06. Linha do Clod

- **Status:** concluída
- **Depende de:** [04-hushling-line](04-hushling-line.md)

## Contexto

O dono quis um Ecobeast de Terra com três formas, que termina Terra/Metal. É o primeiro Ecobeast de Terra do catálogo, e estreia as Técnicas de Terra.

Conceito: uma toupeira que come pedras com minério. O minério se junta no corpo a cada forma: terra no filhote, pedra no meio e placas de aço na forma final, com as garras virando picaretas. Para não lembrar a toupeira de Terra/Metal da referência, nenhuma forma tem broca na cabeça nem nome com "Burr" e "Drill" juntos.

O dono escolheu o conceito e os nomes, e trouxe as três imagens. Aprovou a proposta de Elementos, altura, peso, raridade, taxa de captura, descrições, atributos, Traço, Técnicas, learnsets, níveis de evolução e taxas de bioma, que são _a revisar_ depois de jogar.

## Escopo

- Linhas novas no banco (schema `ecobeasts`), nas tabelas `species`, `species_elements`, `species_stats`, `species_traits`, `skills`, `skill_effects`, `species_skills`, `evolutions` e `species_biomes`.
- Os `front.png` de 512×512, com fundo transparente, em `client/assets/creatures/<slug>/`, cortados da imagem que o dono trouxe. Seguem o enquadramento dos outros: o lado maior com 480 px, centralizado.

## Fora do escopo

- As folhas `idle.png` e `walk.png`: saem da skill `creature-sprites`, numa entrega própria. Sem elas, a espécie aparece no mapa com o marcador padrão.
- `server/prisma/seed-data/`: é só a foto da carga inicial. Um banco recriado do zero não terá esta linha.

## Requisitos

**Espécies**

- **RF-01:** Três espécies novas, todas com `growth_rate_id` = Médio, `rarity_id` = Incomum, `capture_rate` = 45 e `gender_ratio` = 0.5. Crag evolui do Clod, e Ingot do Crag.

| id  | name  | Elementos     | XP  | Altura (m) | Peso (kg) | Descrição (Bestiário)                                                                                    |
| --- | ----- | ------------- | --- | ---------- | --------- | -------------------------------------------------------------------------------------------------------- |
| 12  | Clod  | Terra         | 60  | 0.4        | 9.0       | Filhote de toupeira coberto de terra. Come pedrinhas com minério e guarda as mais bonitas nas patas.     |
| 13  | Crag  | Terra         | 140 | 1.0        | 55.0      | As pedras que comeu cresceram nas costas e nas garras como armadura. Abre túneis em rocha maciça.        |
| 14  | Ingot | Terra / Metal | 230 | 1.6        | 180.0     | O minério de uma vida inteira virou placas de aço. Os túneis que ele deixa têm paredes lisas como espelho. |

- **RF-02:** Atributos de tanque. Os totais são os dos iniciais. Entre parênteses fica o Treino que a espécie dá ao ser derrotada; o resto é 0:

| Espécie | HP | Atq | Def     | Atq.E | Def.E | Vel | Total |
| ------- | -- | --- | ------- | ----- | ----- | --- | ----- |
| Clod    | 55 | 60  | 70 (1)  | 30    | 50    | 45  | 310   |
| Crag    | 70 | 85  | 100 (2) | 40    | 65    | 60  | 420   |
| Ingot   | 90 | 120 | 135 (3) | 45    | 85    | 60  | 535   |

- **RF-03:** As três espécies têm no slot 1 o Traço Casca Dura, que o motor de batalha já aplica. Não há Traço oculto.
- **RF-04:** Clod evolui para Crag no nível 16, e Crag para Ingot no nível 36, pelo gatilho `level`.

**Técnicas novas**

- **RF-05:** Seis Técnicas, usando só efeitos que o motor já executa. Todas têm prioridade 0 e um golpe.

| id | slug                  | name                | Elemento | Categoria | Poder | Prec | PP | Contato | Efeito                   |
| -- | --------------------- | ------------------- | -------- | --------- | ----- | ---- | -- | ------- | ------------------------ |
| 47 | `nuvem_de_poeira`     | Nuvem de Poeira     | Terra    | Suporte   | 0     | 100  | 30 | não     | −1 Precisão do inimigo   |
| 48 | `arremesso_de_torrao` | Arremesso de Torrão | Terra    | Física    | 40    | 100  | 30 | não     | —                        |
| 49 | `garra_de_pedra`      | Garra de Pedra      | Terra    | Física    | 65    | 100  | 20 | sim     | —                        |
| 50 | `desabamento`         | Desabamento         | Terra    | Física    | 90    | 90   | 10 | não     | 20% Amedrontar           |
| 51 | `abalo_profundo`      | Abalo Profundo      | Terra    | Física    | 120   | 85   | 5  | não     | Recuo de 33%             |
| 52 | `garra_de_picareta`   | Garra de Picareta   | Metal    | Física    | 70    | 95   | 15 | sim     | 10% −1 Def do inimigo    |

**Learnsets**

- **RF-06:** Tudo por nível (`level_up`), menos a Garra de Picareta, que o Ingot aprende ao evoluir (`evolution`, nível 0). Couraça, Arranhão e Martelo de Ferro já existem.

| Nível | Clod                | Crag                | Ingot               |
| ----- | ------------------- | ------------------- | ------------------- |
| 1     | Arranhão            | Arranhão            | Arranhão            |
| 1     | Nuvem de Poeira     | Nuvem de Poeira     | Nuvem de Poeira     |
| 0     | —                   | —                   | Garra de Picareta   |
| 6     | Arremesso de Torrão | Arremesso de Torrão | Arremesso de Torrão |
| 12    | Couraça             | Couraça             | Couraça             |
| 18    | Garra de Pedra      | Garra de Pedra      | Garra de Pedra      |
| 28    | Desabamento         | Desabamento         | Desabamento         |
| 40    | —                   | —                   | Martelo de Ferro    |
| 50    | —                   | Abalo Profundo      | Abalo Profundo      |

**Biomas**

- **RF-07:** Taxas em `species_biomes`. Sem linha, a taxa é 0:

| Espécie | Planície | Pedra | Colina | Montanha |
| ------- | -------- | ----- | ------ | -------- |
| Clod    | 10       | 40    | 35     | 20       |
| Crag    | —        | 25    | 20     | 25       |
| Ingot   | —        | 5     | —      | 10       |

## Critérios de aceite

- [x] `GET /v1/species/clod`, `/crag` e `/ingot` respondem 200, e `/v1/species/clod/evolutions` mostra a linha com os níveis 16 e 36.
- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` não aponta erro.
- [x] Lint, typecheck, testes de unidade e e2e do servidor passam.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```
