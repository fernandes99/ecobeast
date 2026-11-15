# skill-cooldown

Cada Técnica ganha um **countdown**: o número de rodadas em que ela fica bloqueada depois de usada, além do PP. Cada Ecobeast passa a ter **3 Técnicas**, não 4. Na luta, as Técnicas viram uma barra de 3 ícones, e tocar e segurar num ícone mostra o detalhe dela.

## Contexto

Em 2026-11-14, o dono pediu, com um print de referência (três ícones quadrados embaixo e, por cima, um quadro com o nome, a descrição e "pode usar de novo em 3 rodadas"):

- **Countdown:** "Se uma habilidade tiver 1 de countdown ele vai poder usar outra vez a habilidade só depois de 1 rodada, se a habilidade não tiver countdown ele vai poder usar em qualquer rodada."
- **O motivo:** "com isso o player não vai ficar usando apenas uma habilidade sempre."
- **3 Técnicas:** "cada ecobeast vai poder ter 3 habilidades e não será mais 4."
- **A barra:** "deixa exibido mais ou menos dessa maneira as habilidades na batalha, ele vai poder clicar e segurar a habilidade para ver mais detalhes dela."

O que existe hoje:

- **A rodada.** Na luta de tabuleiro ([board-battle](../board-battle/README.md)), uma rodada é a fila por Velocidade: cada Ecobeast em campo age uma vez, e então começa a próxima (`startRound` em `server/src/domain/board/board-engine.ts`, `state.round`).
- **O PP** é gasto a cada uso (`learned.currentPp -= 1` em `useSkill`). Sem PP em nenhuma, sobra a Técnica de emergência (`EMERGENCY_SKILL`, `hasPp`).
- **O limite de 4** aparece em dois lugares: `MAX_SKILLS` em `server/src/domain/rules/creature-factory.ts` (as Técnicas de um Ecobeast novo) e em `server/src/domain/progression/learnset.ts` (aprender ao subir de nível ou evoluir). O banco também o confere: `creature_instance_skills_slot_check` (`slot BETWEEN 1 AND 4`).
- **A troca de Técnica** já existe (`res://screens/board_battle/skill_learn_overlay.gd`): com as vagas cheias, o jogador escolhe qual esquecer ou desiste.
- **Na luta**, as Técnicas são 4 botões retangulares com nome, Elemento e PP (`res://screens/board_battle/battle_skill_button.gd`, grade `%SkillsGrid` em `board_battle_screen.gd`).
- **Os ícones:** todas as Técnicas do catálogo já têm o ícone de 256 × 256 em `res://assets/skills/<slug>.png` (até as da [board-battle/25](../board-battle/25-shadow-metal-ice-mind-skills.md)).

## Objetivos

1. Uma Técnica com countdown N, usada na rodada R, só volta a poder ser usada na rodada R + N + 1. Com countdown 0, ela pode ser usada em toda rodada.
2. O servidor guarda e conta o countdown, para o jogador e para a IA. O cliente só mostra.
3. Todo Ecobeast tem no máximo 3 Técnicas, os novos e os que já existem.
4. Na luta, as 3 Técnicas aparecem como ícones, com o PP e o countdown à vista, e segurar um ícone mostra o detalhe.

## Anti-objetivos

- O countdown não substitui o PP: os dois valem juntos.
- Nada muda nas outras regras da luta (dano, alcance, marcas, fila).

## Decisões

Do dono, em 2026-11-14:

| Decisão | Motivo |
| --- | --- |
| Countdown por Técnica, contado em rodadas, além do PP | Para o jogador não usar sempre a mesma Técnica |
| 3 Técnicas por Ecobeast | Decisão do dono |
| Na luta, 3 ícones; tocar escolhe, segurar mostra o detalhe | O print de referência |
| O desenho abaixo, mostrado por Claude, foi aprovado pelo dono | "Aprovo" |

Escolhas de Claude, aprovadas junto com o desenho (corrigíveis; ao mudar uma, atualize aqui e no [architecture.md](architecture.md)):

| Decisão | Motivo |
| --- | --- |
| O countdown é a coluna `cooldown` da tabela `skills`, de 0 a 5, editada no painel do Supabase | Dado de design mora no banco |
| Valores iniciais pelo poder (_a revisar_): sem dano 2; poder 1 a 50, 0; 51 a 80, 1; 81 a 110, 2; acima de 110, 3 | Os golpes fracos ficam livres e os fortes, espaçados. Assim o jogador alterna entre eles |
| O countdown conta as rodadas da luta, mesmo com o Ecobeast fora de campo, e zera no fim da luta | Mais simples de entender: "volta na rodada X" |
| Os selvagens e os Domadores NPC também respeitam o countdown | A mesma regra para os dois lados |
| Com as 3 Técnicas bloqueadas por countdown, o Ecobeast só anda e espera. A Técnica de emergência continua só para quando todas estão sem PP | O countdown é uma espera curta, não falta de recurso |
| Os Ecobeasts que já têm 4 Técnicas perdem a da vaga 4 | A vaga 4 é a última aprendida. Uma migration resolve de uma vez |
| A Técnica de emergência não tem countdown | Ela já é o último recurso |

## Fora do escopo

- Arte nova de ícone (todas já têm).
- Mostrar o countdown nos Detalhes do Ecobeast. No visualizador de conteúdo (F1), ele entrou depois da 02, a pedido do dono: a linha "Countdown" na ficha da Técnica (`skills_tab.gd`).
- Escolher qual Técnica perder na mudança de 4 para 3.
- Itens ou Traços que mexam no countdown.

## Pré-requisitos

- [board-battle](../board-battle/README.md) e [progression](../progression/README.md) concluídas.
- A [02](02-skill-bar.md) mexe no `board_battle_screen.gd`, que a [camera-zoom/02](../camera-zoom/02-battle-zoom.md) também altera. A 02 foi feita depois do commit da camera-zoom.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-server-cooldown](01-server-cooldown.md) | Servidor e jogo: a coluna `cooldown`, o countdown no motor e na IA, o limite de 3 e o fim da vaga 4 | concluída (falta o dono jogar) |
| 2 | [02-skill-bar](02-skill-bar.md) | Jogo: a barra de 3 ícones na luta e o detalhe ao segurar | concluída (falta o dono jogar) |

O desenho compartilhado está no [architecture.md](architecture.md).
