# 02. As trilhas de pedra

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [01](01-ground-types.md)

## Contexto

Em 2026-11-22, o dono mandou uma imagem de referência com cinco trilhas de pedra (seixos azulados, terra rachada, arenito, pedra cinza chata e seixos claros) e pediu "trilhas de pedras, e também pedras por cima do ambiente", "do tipo que nem tem as pisantes só que diferentes".

Claude fez 8 trilhas: as 5 da referência, com o chão fechado, e 3 de pedras soltas, com o bioma aparecendo entre as pedras, como nos Pisantes.

## Escopo

- Os tipos 21 a 28 em `ground_types`, todos trilhas.
- As 8 texturas, geradas pelo `make_grounds.gd`.

## Fora do escopo

- Recortar a pedra inteira na borda da trilha: a máscara corta a textura na borda, então uma pedra solta pode aparecer pela metade ali, como já acontece nos Pisantes.

## Requisitos

- **RF-01:** a migration `stone_trails` põe os tipos da tabela e acerta a sequência dos ids. A foto `prisma/seed-data/ground_types.json`, o teste do banco e o teste das tabelas do catálogo levam os 28 tipos.

| id | slug | name | kind | hardness | Textura |
| --- | --- | --- | --- | --- | --- |
| 21 | `blue_cobble_trail` | Seixos azuis | trail | 3 | seixos azul-acinzentados encaixados, de cerca de 14 px, com a junta roxo-acinzentada |
| 22 | `cracked_earth_trail` | Terra rachada | trail | 2 | terra batida marrom com rachaduras escuras que se ramificam |
| 23 | `sandstone_trail` | Arenito | trail | 3 | pedras chatas de arenito em fiadas de 8 px, de 10 a 22 px de comprimento, com os cantos arredondados |
| 24 | `slate_trail` | Ardósia | trail | 3 | lajes cinza compridas em fiadas de 8 px, de 14 a 32 px de comprimento |
| 25 | `pale_cobble_trail` | Seixos claros | trail | 3 | seixos creme pequenos, de cerca de 10 px, com a junta rosada |
| 26 | `river_stones` | Pedras de rio | trail | 3 | pedras redondas de tamanhos e cores variados (cinza, marrom, azulada), soltas sobre o bioma |
| 27 | `loose_slabs` | Lajes soltas | trail | 3 | lajes chatas e arredondadas, com o claro e a sombra só na beirada, espaçadas sobre o bioma |
| 28 | `pebble_scatter` | Pedrisco | trail | 2 | pedrinhas espalhadas sobre o bioma |

- **RF-02:** o `make_grounds.gd` gera as 8 texturas no estilo das outras (poucos tons, sem degradê, 512×512, emendando nas quatro bordas), com dois geradores novos:
  - `_cobbles`: seixos num Voronoi que se repete nas bordas, cada um com contorno, o claro em cima à esquerda, a sombra embaixo à direita e um brilho, ou chato (`flat`), com a luz só na beirada. Com a junta transparente, a pedra ganha a sombra de 1 px no chão.
  - `_courses`: pedras chatas em fiadas, de comprimentos sorteados.
- **RF-03:** as ferramentas Chão e Caminho do F2 mostram os 28 tipos, sem mudança no código delas.

## Critérios de aceite

- [x] O banco e a foto do catálogo têm os 28 tipos, com a dureza.
- [x] As 8 texturas emendam nas quatro bordas.
- [x] Nas Pedras de rio, nas Lajes soltas e no Pedrisco, o bioma aparece entre as pedras.
- [x] As 8 trilhas são desenhadas pelo mapa do jogo como traço.
- [ ] O dono vê as trilhas novas no editor (F2).

## Resultado da verificação

Em 2026-11-22:

- **Arte:** na primeira folha de conferência, os seixos tinham junta demais e as Lajes soltas pareciam bolas. Os seixos passaram a encher a célula (`fill` de 1,25 a 1,45), e as lajes ficaram chatas. No mapa, as lajes eram maiores que a trilha de largura 34 e o pedrisco estava ralo: as lajes diminuíram (22 por linha) e o pedrisco ficou mais denso.
- **Servidor:** a migration `20270207000001_stone_trails` foi aplicada com `migrate deploy`. O teste das tabelas do catálogo (54 de 54) e o teste do banco que lista os tipos passaram.
- **Print** (na conversa): as 8 trilhas como traço numa ilha de teste, desenhadas pelo `HexMapView` numa cena temporária, já apagada.
- **Limite:** com os 28 tipos, a máscara de chão (`HexGrounds.MAX_TYPES`, 32) aceita só mais 3.
- **Falta o dono:** ver as trilhas novas no F2.
