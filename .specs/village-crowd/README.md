# village-crowd

Moradores genéricos, fora da história, que o dono põe passeando pela vila para ela parecer cheia de gente.

## Contexto

Em 2026-11-19, o dono pediu: "Crie agora varios NPCs aleatório que não serão da história, serão NPC genéricos que vão rodar a vila só para dar volume de pessoas nela". Hoje o catálogo `npcs` tem só os NPCs da história e os de teste (ids 1 a 6). A fala de um NPC mora no NPC posto na ilha (`island_npcs.dialogue`), e o F2 põe um NPC novo com a fala vazia.

## Objetivos

1. Dez moradores pessoas no catálogo, 5 de corpo masculino e 5 de feminino, cada um com nome, pele, voz e roupa próprios.
3. Três crianças, com um corpo de criança menor que o do adulto ([fase 2](02-children.md)).
2. Cada morador tem uma fala curta que já vem preenchida quando o dono o põe no F2, numa ilha ou numa sala.

## Anti-objetivos

- O rascunho de Liora não muda: o dono põe os moradores e marca o passeio na ferramenta NPC.
- Os NPCs de antes continuam nascendo no F2 com a fala vazia.
- Sem passeio automático: o passeio continua pelos hexágonos marcados.

## Decisões

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A fala padrão é uma coluna do catálogo (`npcs.default_dialogue`, vazia por padrão), copiada para o NPC posto | A fala continua sendo de cada NPC posto, e o dono a troca sem mexer no catálogo |
| Na sala, a fala padrão entra quando a caixa Fala do painel está vazia ao pôr o NPC | O painel da sala mostra a fala antes de pôr, e o texto escrito ali tem a vez |
| As roupas são escolhidas à mão entre as peças e as paletas de hoje, variando pele, cabelo e cores | Uma vila de 10 pessoas parece mais cheia com todo mundo diferente, e o dono troca no botão Aparência |
| Slugs `villager_<nome>` e a descrição "Morador da Vila Raiz." (ou "Moradora") | O F2 lista o nome e a descrição, e o prefixo separa os moradores dos NPCs da história |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-villagers](01-villagers.md) | Os 10 moradores, a fala padrão no catálogo e no F2 | concluída (falta o dono conferir) |
| 2 | [02-children](02-children.md) | Os corpos de criança Menino e Menina, só de NPC, e as crianças Juca, Nina e Bia | concluída (falta o dono conferir no F2) |
