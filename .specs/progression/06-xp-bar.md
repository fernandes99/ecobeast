# 06. Barra de XP na luta e no Hub

- **Status:** concluída
- **Depende de:** [03-level-up-screen](03-level-up-screen.md), [board-battle](../board-battle/)

## Contexto

A [03](03-level-up-screen.md) enchia a barra de XP no cartão da luta antiga. A luta de tabuleiro, que a substituiu, ficou sem barra, e o time do Hub mostra só o nível. O dono pediu a barra de XP sutil na luta e no Hub, crescendo toda vez que uma luta termina. Ele aprovou o esboço: uma linha fina azul-clara, sem número, embaixo do HP; e no Hub ela só aparece, sem animação.

## Escopo

- A linha de XP no cartão dos seus Ecobeasts na luta (o do inimigo não tem).
- A linha de XP em cada Ecobeast do time no Hub.
- A animação no fim da luta, antes da tela "Subiu de nível".

## Fora do escopo

- Mudar o servidor: o XP de antes da luta vem do time do jogador, e o de depois vem da `progression` do resultado.
- Animar a barra no Hub ao voltar de uma luta.
- Número de XP na linha (o detalhe do Ecobeast já mostra "faltam N XP").

## Requisitos

- **RF-01:** A linha de XP tem 4 px no cartão da luta e 3 px no Hub, em `UiPalette.XP_LINE`, sobre o trilho das barras. Ela mostra quanto do nível atual já foi feito; no nível 100, fica cheia.
- **RF-02:** Na luta, o cartão do seu Ecobeast em foco mostra a linha com o XP de quando a luta começou, guardado pelo `uid` a partir do time do jogador. Sem esse dado (a luta de teste), a linha não aparece.
- **RF-03:** No fim da luta, cada Ecobeast que ganhou XP aparece no cartão, um de cada vez, na ordem da `progression`, com o nível de antes. A linha enche do valor antigo ao novo em 0,7 s.
- **RF-04:** Se ele subiu de nível, a linha enche até o fim, pisca em branco, o selo de nível cresce um pouco e troca o número; a cada nível ganho, isso se repete. Depois vem a tela "Subiu de nível" (e a evolução e as Técnicas, como antes), e, ao fechar, a linha enche do zero até o valor novo. Se ele evoluiu, o cartão já mostra a forma nova.
- **RF-05:** Quem não ganhou XP não aparece nessa sequência.
- **RF-06:** No Hub, cada Ecobeast do time mostra a linha embaixo do HP, sem animação.

## Critérios de aceite

- [x] Na luta, o cartão do seu Ecobeast tem a linha de XP; o do inimigo não.
- [x] Vencendo, a linha enche; subindo de nível, pisca, o nível troca, abre a comemoração e a linha recomeça do zero.
- [x] No Hub, o time mostra a linha de XP.

## Desenho técnico

- `ui/components/xp_line.gd` (`XpLine`, novo): `ProgressBar` fino, com `set_ratio` e `fill_to(ratio)`, que espera o `Tween`, e `flash()`.
- `CreatureInstance.xp_ratio()`: a parte do nível já feita, como a de `CreatureProgress`.
- `BoardCreatureCard`: a linha embaixo do HP (só sem `is_enemy`), `set_xp(ratio)` (negativo esconde), `fill_xp` e `level_up_to(level)`.
- `board_battle_screen.gd`: `_xp_by_uid` guardado ao começar a luta; o cartão em foco usa o `uid` do time; `_celebrate` anima a linha de cada um antes das telas.
- `creature_slot`: a linha embaixo da barra de HP.
- `UiPalette.XP_LINE`.
