# chimney-smoke

Cada casa com fumaça animada na chaminé pode ficar sem ela, peça por peça, escolhida no editor.

## Contexto

Em 2026-11-17, o dono pediu: "todas as casas que tem chaminés animadas, tem que ter a opção de sem animação na chaminé". Hoje a fumaça vem só do tipo da peça (`HexMapView.PROP_SMOKE`): toda Casa grande, Casa pequena, Sobrado pequeno e Casa enxaimel (tipos 95 a 98) solta fumaça, sempre.

## Objetivos

1. Uma peça posta de um tipo com fumaça pode ser marcada "sem fumaça", e aí a chaminé fica parada, só com a arte da casa.
2. A marca se escolhe no editor, pela barra da peça escolhida, e vale no jogo depois de publicar.

## Anti-objetivos

- A arte das casas e da fumaça não muda.
- O padrão continua com fumaça: as peças de antes não mudam.
- Os tipos sem fumaça não ganham a opção.

## Decisões

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A marca é da peça posta (`island_props.no_smoke`), não uma variante a mais do tipo | Assim cada casa da vila escolhe, sem dobrar as 8 cores em 16 nem copiar arte |
| A coluna diz "sem fumaça" (`no_smoke`, falso por padrão), e o contrato só manda o campo quando é verdadeiro | As peças de antes ficam com fumaça sem mexer nelas, e o JSON das ilhas não cresce, como o `action_type_id` |
| Uma peça de tipo sem fumaça pode ter a marca guardada, e ela não faz nada | Quem decide que tipo tem fumaça é o jogo (`PROP_SMOKE`), não o servidor |
| O botão fica só na barra da peça escolhida no mapa, e só nos tipos com fumaça | É onde ficam o espelho e o bloqueio da peça |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-smoke-toggle](01-smoke-toggle.md) | A marca "sem fumaça" no banco, nas rotas, no editor e no mapa | concluída (falta o dono conferir) |
