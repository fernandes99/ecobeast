# Hidden traits

Um Ecobeast que nasce tem 1 chance em 20 de vir com o Traço oculto da espécie.

## Contexto

Cada espécie tem 1 ou 2 Traços normais (slots 1 e 2 de `species_traits`) e pode ter 1 oculto (slot 3, `is_hidden`), como no GDD. Até 2026-11-06, o servidor só sorteava entre os normais (`server/src/player/creature-params.ts` carregava só os não ocultos), e a Evolução só mantinha o oculto de quem já o tinha. Então nenhum Ecobeast podia ter o Traço oculto: o Instinto do Ruvo, do Ruvak e do Ruvaroth estava no catálogo e funcionava na luta, mas ninguém o recebia. O dono viu isso no visualizador de conteúdo e decidiu: "pode colocar sempre uma chance de 1 em 20 de nascer com ele".

## Decisões

| Decisão | Motivo |
| --- | --- |
| 1 chance em 20 de nascer com o Traço oculto, sempre | Pedido do dono |
| Vale para todo Ecobeast que nasce: o inicial e o selvagem | "Sempre": os dois passam pela mesma fábrica de criaturas (`createCreature`) |
| A espécie sem Traço oculto não sorteia a chance | Nada muda para ela, nem a sequência dos sorteios |
| Quem ganha o oculto não sorteia o normal | O Traço é um só |

## Fora do escopo

- Outros jeitos de ganhar o oculto (item, evento, bioma).
- Mostrar na tela que o Traço do Ecobeast é o oculto.
- A Evolução, que já mantém o oculto (ver [progression/architecture.md](../progression/architecture.md)).

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01-hidden-trait-chance](01-hidden-trait-chance.md) | A chance de 1 em 20 na fábrica de criaturas do servidor | concluída |
