# 01. Os tipos novos de chão

- **Status:** concluída (falta o dono ver no editor e no jogo)
- **Depende de:** [island-villages/02](../island-villages/02-grounds.md)

## Contexto

O dono pediu mais tipos de caminho, entre eles cascalho e "pedra por cima" ([README](README.md#contexto)). Hoje há 4 chãos no catálogo, com arte provisória gerada pelo `make_grounds.gd`. Esta fase traz os 4 tipos novos e a dureza de cada tipo, que a [02](02-ground-mask.md) usa nas emendas. Eles já aparecem na ferramenta Chão, desenhados como os de hoje.

## Escopo

- A coluna `hardness` e os 4 tipos novos em `ground_types`.
- A arte provisória dos 4 tipos.
- O catálogo do cliente e a ferramenta Chão com os tipos novos.

## Fora do escopo

- As emendas e a borda irregular ([02](02-ground-mask.md)).
- Os traços ([03](03-trail-records.md) e [04](04-path-tool.md)).

## Requisitos

- **RF-01:** a migration `free_trails_ground_types`, escrita à mão e aplicada com `migrate deploy`, cria a coluna `ground_types.hardness` (`smallint NOT NULL`, `CHECK BETWEEN 1 AND 3`), preenche os 4 tipos de hoje e põe os tipos 5 a 8, com os valores da tabela do [architecture.md](architecture.md#o-catálogo-ground_types). O `schema.prisma`, o `catalog_schema.gd`, o `.specs/game-data/architecture.md` e a resposta do catálogo levam a coluna.
- **RF-02:** o `make_grounds.gd` gera também `gravel_trail.png`, `stepping_stones.png`, `sand_trail.png` e `worn_trail.png`, em pixel art no estilo dos de hoje (poucos tons, sem degradê, 512×512, emendando nas quatro bordas):
  - **Cascalho:** pedrinhas pequenas e soltas, claras e escuras, sobre terra cinza.
  - **Pisantes:** lajes chatas e irregulares, com brilho em cima e sombra embaixo, e o espaço entre elas transparente.
  - **Areia batida:** areia clara com pouca variação e alguns grãos escuros.
  - **Trilha gasta:** terra como a da trilha de terra, com tufos de grama verde espalhados.
  As texturas de hoje não mudam.
- **RF-03:** no desenho de hoje, o shader do chão trata a parte transparente da textura como sem chão (o pixel some e aparece o bioma), para os Pisantes aparecerem certos.
- **RF-04:** a ferramenta Chão mostra os 8 tipos, na ordem do id, mais o Sem chão. A visão de cima mostra a cor média deles, como hoje.

## Critérios de aceite

- [x] O catálogo baixado tem os 8 tipos, com a dureza, e o `CatalogValidator` aceita.
- [x] As 4 texturas novas emendam nas quatro bordas, sem linha visível numa trilha longa.
- [x] Os Pisantes mostram a grama do bioma entre as lajes.
- [x] A ferramenta Chão pinta os 8 tipos, e salvar e abrir de novo os mantém.
- [ ] O dono vê os 4 tipos novos no editor (F2) e numa ilha (F5).

## Desenho técnico

- **Servidor:** a migration, o `schema.prisma`, a foto `prisma/seed-data/ground_types.json` (o e2e do catálogo compara as colunas com ela) e os testes do banco e do catálogo.
- **Cliente:** `assets/terrain/grounds/make_grounds.gd` (os 4 geradores novos, reaproveitando os de hoje: as pedras do `_stones` para os Pisantes e o Cascalho, a terra do `_dirt` para a areia e a trilha gasta, com os tufos por cima), `core/data/catalog_schema.gd`, e o `discard` do alfa em `ui/components/hex_grounds.gdshader`.

## Verificação

- **Servidor:** os testes de unidade e a suíte e2e inteira antes do commit, porque o servidor muda.
- **Cliente:** um teste sem janela, numa cena temporária, que confere os 8 tipos e a dureza no catálogo e que as 4 texturas existem, em 512×512.
- **Prints:** uma ilha no editor com uma trilha de cada tipo novo, ao lado da de terra.
- **Projeto:** o jogo sem janela abre sem erros de script, com os mesmos avisos de antes.

## Tarefas

- [x] Servidor: a migration, a coluna e os tipos.
- [x] Arte: os 4 geradores e as texturas.
- [x] Cliente: o catálogo, o alfa no shader e a ferramenta Chão.
- [x] Testes, prints e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Servidor:**
  - **Banco:** a migration `20261123000000_free_trails_ground_types` foi aplicada com `migrate deploy`, e o `migrate diff` saiu vazio. Os testes novos do banco (a dureza 4 recusada e os 8 tipos com dureza) falharam antes e passaram depois.
  - **Suítes:** o lint, o typecheck e os testes de unidade passaram (807 de 807). Na primeira volta da suíte e2e, 498 de 499 passaram. O que falhou foi o do catálogo, que compara as colunas com a foto do `seed-data`; com a foto atualizada, o e2e do catálogo passou (81 de 81).
- **Cliente, teste sem janela** (uma cena temporária, já apagada): falhou antes (4 tipos, sem dureza nem texturas) e passou depois, com 14 de 14. Ele confere os 8 tipos com a dureza no catálogo do servidor local, as 4 texturas em 512×512 e a grama entre as lajes dos Pisantes.
- **A ferramenta Chão** lê os tipos do catálogo, então os 8 aparecem sem mudança no editor, e o servidor aceita no salvar qualquer `slug` da tabela. Isso foi conferido no código, não num salvar de verdade.
- **As texturas** emendam por construção: o ruído é o `get_seamless_image` e as pedras e pedrinhas dão a volta nas bordas (`posmod`).
- **Print** (na conversa): uma ilha de teste com a trilha de terra, o Cascalho, os Pisantes, a Areia batida e a Trilha gasta, cada uma chegando numa praça de pedra.
- **Projeto:** o jogo sem janela abre sem erros de script e com os mesmos 9 avisos de script de antes.
- **Falta o dono:** ver os 4 tipos novos no editor (F2, ferramenta Chão) e numa ilha (F5).
