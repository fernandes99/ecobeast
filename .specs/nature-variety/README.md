# nature-variety

Mais variedade de natureza dentro de cada bioma: 24 tipos novos de decoração, com árvores, galhos soltos, troncos, mato, flores, cogumelos e pedras, no mesmo estilo das de hoje, sorteados no mapa e nas ilhas e postos à mão no editor.

## Contexto

Em 2026-11-15, o dono pediu: "Agora eu quero aumentar a diversidade de natureza dentro dos biomas, colocando mais tipos de arvores, galhos soltos, mais tipos de mato, planta, flores, pedras e etc."

Hoje cada bioma sorteia de 4 a 6 dos 23 tipos de `HexDecorations` (a folha `decorations.png`, feita por script). A mesma receita vale no mapa sorteado de Explorar zona, nas ilhas e no tabuleiro da luta. Os 17 primeiros tipos também são tipos de peça solta (ids 1 a 17), desenhados pela mesma folha.

Duas formas de trazer a arte foram mostradas: arte nova no estilo de hoje, gerada por script, ou as peças dos pacotes da craftpix.net no sorteio. O dono escolheu "Arte nova, estilo atual". Depois de ver a proposta de tipos por bioma, disse "Pode seguir".

## Objetivos

1. Cada bioma ganha tipos novos de decoração no sorteio, sem lotar o hexágono.
2. As decorações de hoje continuam no mesmo lugar, em toda seed.
3. O editor põe os tipos novos, e os 6 do Deserto e da Neve, pela ferramenta Peças e pelo pincel Vegetação.

## Anti-objetivos

- Arte de terceiros nas decorações do bioma.
- Uma decoração nova nascendo em cima de uma peça posta à mão numa ilha.
- Um hexágono tão cheio que o Domador some no meio das plantas.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| A arte nova é desenhada no estilo de hoje, por script | "Arte nova, estilo atual" |
| Os tipos por bioma, o sorteio no fim da receita, o filtro das peças e os tipos de peça novos | Aprovou a proposta: "Pode seguir" |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Os tipos novos entram no fim de cada receita | O sorteio de um hexágono segue em ordem, então os primeiros sorteios, e as decorações de hoje, não mudam |
| As chances dos tipos novos são baixas, de 0,04 a 0,3 | Cada hexágono ganha um ou dois tipos a mais, não todos |
| Uma decoração que cai a menos do raio de uma peça do mesmo hexágono não aparece | O pincel já evita as decorações; assim a peça posta à mão nunca fica embolada com uma planta. Vale para todos os tipos, e os de hoje só somem onde o dono pôs uma peça por cima de propósito |
| A arte sai de um script versionado, `assets/terrain/make_nature.py`, que acrescenta as linhas 23 a 46 | Como o `make_desert_snow.py`: rodar de novo regrava só essas linhas |
| Os galhos, troncos, tocos, cogumelos e pedras ficam parados; árvores, arbustos, mato e flores balançam | A mesma regra do vento de hoje |
| Os tipos novos entram nos grupos do pincel que já existem, e os do Deserto e da Neve começam desligados; os galhos e troncos ganham o grupo "Galhos e troncos" | Pintar Árvores passa a dar a variedade nova, sem cacto nem neve no meio da Planície |
| Os galhos, os cogumelos, o trevo e as flores novas ficam na luta perto dos Ecobeasts, como o capim e as flores de hoje | São baixos e não escondem o Ecobeast |

## Fora do escopo

- Mudar a arte ou as chances dos 23 tipos de hoje.
- Bloqueio ou ação para os tipos novos.
- Os pacotes da craftpix.net no sorteio.

## Pré-requisitos

- [desert-snow](../desert-snow/): as linhas 17 a 22 da folha.
- [vegetation-brush](../vegetation-brush/): o pincel Vegetação e o raio das peças.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-nature-art](01-nature-art.md) | A arte, os tipos e as receitas | concluída (falta o dono conferir no jogo) |
| 2 | [02-nature-props](02-nature-props.md) | Os tipos de peça no catálogo e os grupos do pincel | concluída (falta o dono usar) |
