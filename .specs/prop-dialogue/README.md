# prop-dialogue

Uma peça solta pode ter fala: tocar nela mostra o texto na caixa de fala, como a conversa de um NPC, e depois roda a ação ou abre a sala dela, se tiver.

## Contexto

Em 2026-11-22, o dono pediu: "eu tenho uma placa eu quero colocar uma diálogo nela para quando o player clicar nela, sem ter que colocar via a aba de 'ações'". Hoje a peça tem só o **Ação** (uma tela: Refúgio, Loja, Arena, Casa ou Viagem) e a **Sala** (um interior). Só os NPCs falam (`island_npcs.dialogue`).

## Objetivos

1. No F2, a peça escolhida ganha a caixa **Fala**, embaixo do Ação e da Sala.
2. Em Explorar numa ilha, tocar numa peça com fala leva o Domador até ela e mostra as falas, uma por toque; depois da última, a ação ou a sala acontece.

## Anti-objetivos

- Não vira uma opção da lista Ação: ela é o catálogo das telas que abrem.
- Sem nome nem rosto na caixa: a peça não é um personagem.
- As cenas da história não mudam; a peça não dispara cena.

## Decisões

O dono aprovou a caixa Fala separada do Ação, com a narração e a ação depois. Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A coluna `island_props.dialogue` (texto, vazio por padrão, até 2.000 caracteres), e o contrato só manda o campo quando há texto | Como o `island_npcs.dialogue`, e o JSON das ilhas não cresce nas 20.000 peças |
| Cada parágrafo é uma fala, como no NPC | O dono já escreve assim nos NPCs |
| A voz é a da narração (`voices.slug = narration`) | A peça não tem voz própria; a narração já é a voz fixa do que não é personagem |
| No F2, a fala entra no desfazer meio segundo depois de parar de digitar, e não a cada letra | Copiar as 20.000 peças a cada letra travaria o editor numa ilha cheia (editor-performance) |
| O carimbo guarda a fala junto com a peça | Como a ação e a sala |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-prop-dialogue](01-prop-dialogue.md) | A fala no banco, nas rotas, no F2 e em Explorar | concluída |
