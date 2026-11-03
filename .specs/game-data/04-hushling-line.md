# 04. Linha do Hushling

- **Status:** concluída
- **Depende de:** [03-starter-content](03-starter-content.md)

## Contexto

Depois das 3 linhas iniciais, esta é a primeira espécie nova do catálogo. Ela estreia os Elementos Gelo e Mente, que ainda não tinham nenhum Ecobeast nem Técnica.

Conceito: um arminho das neves que nunca faz barulho e guarda em gelo cada som que ouve. Ele só ascende quando confia no Domador, e leva no peito a primeira palavra que ouviu dele.

O dono aprovou o conceito, os nomes, os Elementos, a altura, o peso, a raridade, a taxa de captura, as descrições e o gatilho de Vínculo. Atributos, XP, Traço, Técnicas e learnsets são _a revisar_.

## Escopo

Linhas novas no banco (schema `ecobeasts`), nas tabelas `species`, `species_elements`, `species_stats`, `species_traits`, `skills`, `skill_effects`, `species_skills` e `evolutions`.

## Fora do escopo

- A Ascensão acontecer no jogo: XP, subir de nível e Ascensão por nível são da iniciativa `progression`, e os demais gatilhos vêm depois dela (ver [roadmap.md](../roadmap.md)).
- As folhas `idle.png` e `walk.png` entrarem em outras telas além do spawn de depuração: as duas espécies já têm `front.png` e as duas folhas.
- Encontros por bioma (`biome-encounters`).
- `server/prisma/seed-data/`: é só a foto da carga inicial. Um banco recriado do zero não terá esta linha.

## Requisitos

**Espécies**

- **RF-01:** Duas espécies novas, ambas com `growth_rate_id` = Médio, `rarity_id` = Incomum, `capture_rate` = 55 e `gender_ratio` = 0.5. Echofrost tem `evolves_from_species_id` = Hushling.

| id  | name      | Elementos    | XP  | Altura (m) | Peso (kg) | Descrição (Bestiário)                                                                                     |
| --- | --------- | ------------ | --- | ---------- | --------- | --------------------------------------------------------------------------------------------------------- |
| 10  | Hushling  | Gelo         | 58  | 0.3        | 1.2       | Arminho das neves de orelhas enormes. Nunca faz barulho: guarda cada som que ouve em flocos presos ao pelo. |
| 11  | Echofrost | Gelo / Mente | 205 | 1.7        | 46.0      | Leva no peito um cristal com a primeira palavra que ouviu de seu Domador. Esse gelo nunca derrete.        |

- **RF-02:** Atributos (entre parênteses, o Treino que a espécie dá ao ser derrotada; o resto é 0):

| Espécie   | HP | Atq | Def | Atq.E   | Def.E | Vel    | Total |
| --------- | -- | --- | --- | ------- | ----- | ------ | ----- |
| Hushling  | 45 | 35  | 40  | 65      | 55    | 70 (1) | 310   |
| Echofrost | 75 | 50  | 70  | 110 (2) | 95    | 100    | 500   |

- **RF-03:** As duas espécies têm no slot 1 o Traço Brisa Ligeira, que o motor de batalha já aplica. Não há Traço oculto.
- **RF-04:** Hushling ascende para Echofrost pelo gatilho `bond`, com `min_bond` = 220 (`GDD.md`, "Evoluções").

**Técnicas novas**

- **RF-05:** Oito Técnicas, usando só efeitos que o motor já executa. Nenhuma faz contato, e todas têm prioridade 0 e um golpe.

| slug               | name             | Elemento | Categoria | Poder | Prec | PP | Efeito                       |
| ------------------ | ---------------- | -------- | --------- | ----- | ---- | -- | ---------------------------- |
| `floco_cortante`   | Floco Cortante   | Gelo     | Especial  | 40    | 100  | 30 | 10% Congelado                |
| `geada_silenciosa` | Geada Silenciosa | Gelo     | Suporte   | 0     | 100  | 30 | −1 Vel do inimigo            |
| `manto_de_neve`    | Manto de Neve    | Gelo     | Suporte   | 0     | 0    | 20 | Si mesmo; +1 Def.E           |
| `lanca_de_cristal` | Lança de Cristal | Gelo     | Especial  | 80    | 100  | 15 | 10% Congelado                |
| `inverno_mudo`     | Inverno Mudo     | Gelo     | Especial  | 110   | 80   | 5  | 20% Congelado                |
| `eco_mental`       | Eco Mental       | Mente    | Especial  | 65    | 100  | 20 | 10% Confuso                  |
| `grito_congelado`  | Grito Congelado  | Mente    | Especial  | 90    | 100  | 10 | 20% Amedrontado              |
| `palavra_guardada` | Palavra Guardada | Mente    | Suporte   | 0     | 0    | 10 | Si mesmo; cura 50% do HP máx |

**Learnsets**

- **RF-06:** Tudo por nível (`level_up`). A Palavra Guardada é por nível, e não `evolution`, porque um Echofrost selvagem também precisa poder usá-la.

| Nível | Hushling         | Echofrost        |
| ----- | ---------------- | ---------------- |
| 1     | Arranhão         | Arranhão         |
| 1     | Geada Silenciosa | Geada Silenciosa |
| 6     | Floco Cortante   | Floco Cortante   |
| 11    | Manto de Neve    | Manto de Neve    |
| 17    | Eco Mental       | Eco Mental       |
| 24    | Lança de Cristal | Lança de Cristal |
| 28    | —                | Palavra Guardada |
| 34    | —                | Grito Congelado  |
| 42    | —                | Inverno Mudo     |

## Critérios de aceite

- [x] `GET /v1/species/hushling` e `GET /v1/species/echofrost` respondem 200, e `/v1/species/hushling/evolutions` mostra a linha com o gatilho de Vínculo.
- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` não aponta erro.
- [x] Uma batalha contra cada espécie, em nível baixo e alto, começa e aplica as Técnicas novas.
- [x] Lint, typecheck, testes de unidade e e2e do servidor passam.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```

Sem rota de escolha de espécie fora dos testes, ver as duas no mapa depende do sorteio: `startWild` escolhe entre todas as espécies do banco, com a mesma chance para cada uma.
