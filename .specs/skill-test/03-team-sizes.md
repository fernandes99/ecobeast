# 03. O teste de Técnica em 2×2 e 3×3

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02-test-button](02-test-button.md)

## Contexto

Em 2026-11-20, depois das fases 1 e 2, o dono pediu: "Quero testar com 2x2 e 3x3 a técnica." A luta de teste era só 1×1, e as Técnicas de área, as de linha que atravessam e as que miram no próprio time pedem mais Ecobeasts em campo.

## Requisitos

- **RF-01:** O corpo de `POST /v1/me/board-battle/skill-test` ganha `slots`, inteiro de 1 a 3, 1 sem ele. Fora da faixa, 400 com "Técnica, espécie ou nível inválidos.".
- **RF-02:** Do lado do jogador entram `slots` Ecobeasts emprestados, todos de `species_id` no `level`, cada um sorteado à parte e com a Técnica testada no 1º espaço, como no RF-02 da [01](01-test-route.md). Do outro lado entram `slots` oponentes de `enemy_species_id`. O tabuleiro é o sorteado para `slots` vagas (`rollBoard`), como numa luta de Domador do mesmo tamanho.
- **RF-03:** As regras da fase 1 valem para todos: a Técnica sem PP nem countdown do lado do jogador, o oponente parado se pedido, sem XP nem moedas, e nada gravado.
- **RF-04:** No painel do F1, a linha **Tamanho**, com 1×1, 2×2 e 3×3, vem antes de **Oponente parado**, com 1×1 por padrão. O **Testar de novo** e a troca de teste levam o mesmo tamanho.

Cada Ecobeast emprestado tem o seu `creatureUid` (`skill-test-1` a `skill-test-3`, `borrowedTeam`), para o jogo não confundir um com o outro.

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| Todos do lado do jogador são de quem usa, com a Técnica | Dá para usar a Técnica mais de uma vez por rodada e testar as que miram no próprio time |
| Todos do outro lado são da mesma espécie | O painel continua com uma escolha de oponente só |

## Fora do escopo

- Escolher uma espécie diferente para cada vaga.
- Times de tamanhos diferentes de cada lado.

## Critérios de aceite

- [x] e2e: com `slots` 2, a luta começa com 2 Ecobeasts de cada lado, os dois do jogador com a Técnica no 1º espaço, e `slots` 4 dá 400.
- [x] Testes de unidade, lint, typecheck e os e2e da luta passam.
- [x] O jogo sem janela abre sem erros de script, e o painel tem a linha **Tamanho**. Numa cena temporária com a conta do dono, o 3×3 do Golpe de Foice abriu com `skill-test-1` a `skill-test-3`, todos com a Técnica 84 no 1º espaço.
- [ ] No jogo, um teste 3×3 abre com 3 de cada lado.

## Tarefas

- [x] O `slots` na rota e no serviço, com os e2e.
- [x] A linha **Tamanho** no painel do F1.
- [x] O README da iniciativa e o `CLAUDE.md`.
