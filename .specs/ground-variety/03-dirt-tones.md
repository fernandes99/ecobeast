# 03. As terras clara e escura

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [02](02-stone-trails.md)

## Contexto

Em 2026-11-22, o dono pediu "3 versões da trilha de terra, uma mais clara e outra mais escura (praticamente com a mesma tonalidade que a lama)". A Trilha de terra (tipo 1) é a do meio; as duas novas usam o mesmo desenho dela, com outra paleta e outro sorteio.

## Escopo

- Os tipos 29 e 30 em `ground_types`, as duas trilhas.
- As 2 texturas, geradas pelo `make_grounds.gd`.

## Requisitos

- **RF-01:** a migration `20270210000000_dirt_tones` põe os tipos da tabela e acerta a sequência dos ids. A foto `prisma/seed-data/ground_types.json`, o teste do banco e o teste das tabelas do catálogo levam os 30 tipos.

| id | slug | name | kind | hardness | Textura |
| --- | --- | --- | --- | --- | --- |
| 29 | `light_dirt_trail` | Trilha de terra clara | trail | 1 | a Trilha de terra num marrom-areia mais claro (`LIGHT_DIRT_TRAIL`) |
| 30 | `dark_dirt_trail` | Trilha de terra escura | trail | 1 | a Trilha de terra no marrom-escuro da Lama (`DARK_DIRT_TRAIL`, quase a paleta `MUD`), sem as poças nem as pegadas |

- **RF-02:** as duas saem do `_dirt` com os números da Trilha de terra (frequência 0,006, 420 pedrinhas e 300 grãos), com as sementes 199 e 211. Rodar o `make_grounds.gd` de novo não muda as outras texturas.
- **RF-03:** as ferramentas Chão e Caminho do F2 mostram os 30 tipos, sem mudança no código delas.

## Critérios de aceite

- [x] O banco e a foto do catálogo têm os 30 tipos, com a dureza.
- [x] As 2 texturas emendam nas quatro bordas, como as outras do `_dirt`.
- [ ] O dono vê as duas trilhas novas no editor (F2).

## Resultado da verificação

Em 2026-11-22:

- **Arte:** lado a lado com a Trilha de terra e a Lama, a clara fica num marrom-areia e a escura no tom da Lama, com as mesmas pedrinhas.
- **Limite:** com os 30 tipos, a máscara de chão (`HexGrounds.MAX_TYPES`, 32) aceita só mais 1.
