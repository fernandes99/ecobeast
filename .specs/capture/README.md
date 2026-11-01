# Capture

O jogador usa uma Esfera na luta para trazer o Ecobeast selvagem para o seu lado. O inimigo passa por um carregamento, como se entrasse na Esfera, e o servidor decide se deu certo. Se der, a luta acaba e o Ecobeast é do jogador. Se não der, a Esfera e a rodada foram gastas.

## Contexto

A [inventory-shop](../inventory-shop/) deixou as três Esferas à venda e guardadas na Mochila, com o `capture_bonus` no catálogo, mas sem uso. O painel de itens da batalha as esconde, e o motor as recusa com "Esse item não pode ser usado agora.". Hoje a equipe nunca passa de 1 Ecobeast, o inicial.

O banco já está pronto para o que vem: `creature_instances` separa a equipe (`location = party`, `party_slot` de 1 a 6) do Santuário (`location = storage`, sem `party_slot`), e `species.capture_rate` vai de 0 a 100.

## Quem usa

- O jogador, durante uma luta selvagem.
- A futura iniciativa `team-and-storage`, que mostra e organiza quem foi para o Santuário.

## Objetivos

1. O jogador usa uma Esfera na luta e pode capturar o Ecobeast selvagem.
2. O capturado entra na equipe, se houver vaga, ou vai para o Santuário.
3. A captura aparece como um carregamento, sem arremesso e sem tremidas.
4. Quem decide o resultado é sempre o servidor.

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| Sem arremesso e sem as 3 tremidas: o Ecobeast fica carregando, como se entrasse na Esfera | O dono quer evitar parecer cópia do ato de captura da referência. Substitui o que o `GDD.md` e o `TELAS.md` diziam |
| O carregamento é uma tela por cima da luta: a tela escurece, e um anel enche em volta da Esfera | Opção B, escolhida pelo dono entre 3 mockups animados |
| Se der certo, a luta acaba e o Ecobeast é do jogador | Pedido do dono |
| Se falhar, o jogador perde a Esfera e a rodada | Pedido do dono |
| A equipe principal tem 6 Ecobeasts, e só ela sai para explorar | Pedido do dono |
| Os outros ficam no Santuário, ainda sem limite | Pedido do dono |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| A chance usa a fórmula do `GDD.md`: HP do inimigo, `capture_rate`, bônus da Esfera e bônus de status | Já estava no GDD, e o `capture_bonus` foi feito para ela |
| O servidor sorteia antes da animação, e a tela só revela depois | O servidor é a autoridade: a animação não muda o resultado |
| Depois de falhar, o inimigo age sozinho, como depois de um item | Já é a regra de "gastar a rodada" |
| O capturado chega com o HP, o status e os PP que tinha na luta | É o que o jogador acabou de ver; o Refúgio cura quem está na equipe |
| Genes, Temperamento, Traço e gênero são os sorteados no começo do encontro | O inimigo já nasce completo, com a mesma regra do inicial |
| Uma espécie com `capture_rate` 0 recusa a Esfera, sem gastá-la | "0 = não captura" significa falha certa; gastar a Esfera seria só uma punição |
| O capturado ocupa a primeira vaga livre da equipe | É o caso mais simples, e funciona quando a `team-and-storage` deixar vagas no meio |
| Capturar não dá XP nem moedas | Nenhuma luta paga recompensa ainda (`progression` e a renda de moedas) |
| A chance não aparece na tela | O dono não pediu, e o carregamento perderia a expectativa |
| Os bônus de status ficam em constantes no servidor, _a revisar_ | São poucos valores, e só a fórmula os usa |
| A Esfera gasta só sai do banco no fim da luta, como os outros itens | A batalha grava tudo no fim; largar a luta no meio não gasta nada, a dúvida já está no [roadmap](../roadmap.md) |

## Fora do escopo

- Tela do Santuário, trocar Ecobeasts entre equipe e Santuário e reorganizar a equipe (`team-and-storage`).
- Mudar quais Ecobeasts aparecem (`biome-encounters`).
- XP, moedas e nível do capturado (`progression`).
- Bestiário com visto e capturado (`codex`).
- Dar apelido na hora da captura; a tela de detalhes já faz isso para quem está na equipe.
- Barrar a captura contra Domadores: eles ainda não existem, e a regra entra com a `npc-tamers`.
- Guardar a zona da captura (`caught_zone_id`), que depende de uma tabela de zonas.
- Esfera Noturna e outras Esferas do GDD.
- Sons (`audio`) e arte final.

## Pré-requisitos

- [battle-core](../battle-core/), [battle-screen](../battle-screen/) e [inventory-shop](../inventory-shop/) concluídas.

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01-capture-rules](01-capture-rules.md) | Fórmula, ação `capture` no motor e gravação do capturado | rascunho |
| [02-capture-screen](02-capture-screen.md) | Esferas no painel de itens, tela de carregamento e resultado | rascunho |
