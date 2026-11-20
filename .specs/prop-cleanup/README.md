# prop-cleanup

Peças soltas que o dono não quer mais saem do jogo: do catálogo, das ilhas, da arte e dos scripts que as geram.

## Contexto

Em 2026-11-20, depois da [editor-ui](../editor-ui/), o dono pediu: "Agora vamos limpar algumas coisas... Quero que exclua aqueles objetos que você criou", com a lista: Casa (cidade), Casa média (cidade), Casa grande (cidade), Observatório, Prédio da Loja, Placa e Poste de luz.

Só Liora usava algumas delas: 12 Postes de luz e 2 Placas, no rascunho e na versão publicada. Perguntado, o dono escolheu apagá-las da ilha, em vez de trocá-las por peças da vila.

## Decisões

| Decisão | Quem | Motivo |
| --- | --- | --- |
| Os tipos saem do banco, e as peças postas deles saem das ilhas | Dono | "Apagar da ilha" |
| Os ids 18, 19 e 23 a 27 não voltam a ser usados | Claude | Ids do catálogo são estáveis |
| A carga inicial (`seed-data`) perde os 7 tipos, as linhas de bloqueio e as luzes deles | Claude | O teste e2e da carga confere que toda linha dos JSON está no banco |
| O `make_town.gd` fica só com o canteiro e o banco, e o `find_lights.py` sem os tipos que saíram | Claude | Um script não gera arte de peça que não existe |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-remove-town-props](01-remove-town-props.md) | Saem o Poste de luz, a Placa, o prédio da Loja, as 3 casas da cidade e o Observatório | concluída (falta o dono conferir) |
