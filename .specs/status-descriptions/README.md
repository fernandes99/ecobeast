# status-descriptions

Cada estado da luta ganha uma descrição curta do que faz, vista no F1.

## Contexto

Em 2026-11-20, o dono pediu: "insira descrições nos estados, principalmente para vermos no f1", com o exemplo do Queimado ("Dá dano em cada rodada no ecobeast").

Os 11 estados (`status_conditions`) tinham só o nome e se duram depois da luta; a regra de cada um ficava no código do servidor (`src/domain/battle/status.ts`, `damage.ts`, `stages.ts`, `capture.ts` e o `board-engine.ts`) e na tabela do `GDD.md`.

## Decisões

| Decisão | Quem | Motivo |
| --- | --- | --- |
| A descrição é uma coluna do catálogo (`status_conditions.description`), como a dos itens e dos traços | Claude | Dado de design mora no banco, editável pelo painel do Supabase |
| O texto diz o efeito com os números das regras de hoje, em uma ou duas frases, sem repetir os Elementos imunes nem se o estado dura, que o F1 já mostra | Claude | O F1 já tem esses dados ao lado; a descrição explica o que o código faz |
| As marcas no chão (`ground_effects`) ficam sem descrição | Claude | O pedido foi dos estados; o F1 já mostra o dano, a cura e o estado de cada marca |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-status-text](01-status-text.md) | A coluna `description`, os 11 textos e a descrição no F1 | concluída (falta o dono conferir) |
