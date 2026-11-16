# puffcoo-line

A linha de Vento de duas formas, Puffcoo e Galecrest, e as Técnicas que mexem no campo da luta: o estado Atordoado, as marcas no chão que baixam atributos, a perda de Precisão nos inimigos, o reforço de Velocidade e Evasão nos aliados e uma rajada de vários golpes de dano fixo.

## Contexto

Em 2026-11-15, o dono mandou a imagem de duas aves (`art-source/puffcoo/line.webp`): uma bolinha cinza de penas, parecida com um pombo filhote, e uma ave elegante, verde-azulada e branca, com crista, asas abertas e cauda longa. Ele pediu um nome, uma descrição, um Elemento e o resto da ficha, numa linha de uma evolução só.

Claude propôs três pares de nomes, e o dono escolheu **Puffcoo** (de *puff*, fofo, e *coo*, o arrulho) e **Galecrest** (de *gale*, ventania, e *crest*, a crista). Ele aprovou a ficha proposta e mudou a evolução de 18 para o nível 20. Depois pediu a spec, com mais Técnicas, "mas não tanta", e que elas mexam no campo da luta: um estado novo, talvez de atordoamento, a queda de Precisão e de Evasão de quem passa no campo afetado, a perda de Precisão nos inimigos e o aumento de esquiva e de Velocidade nos aliados.

O catálogo do banco tem hoje 14 espécies e 52 Técnicas: as 3 linhas iniciais, a do Hushling e a do Clod, criadas pelo painel ([game-data/04](../game-data/04-hushling-line.md) e [06](../game-data/06-clod-line.md)). Essa é a primeira linha de Vento. As 3 Técnicas de Vento que existem (Lufada Cortante, Dança do Vento e Ciclone) usam Ataque Especial, e nenhuma tem forma nem marca.

O tabuleiro ([board-battle/architecture.md](../board-battle/architecture.md)) já tem as peças de que as Técnicas novas precisam:

- a linha reta, que atravessa ou para no primeiro;
- o alvo "Meu time" (`ally`);
- os estágios de Precisão e de Evasão;
- as marcas no chão (`ground_effects`), que hoje só causam dano ou aplicam um estado.

Faltam o estado Atordoado e a marca que muda atributos. O catálogo também já tem `min_hits`, `max_hits` e o efeito `fixed_damage`, mas o motor ainda não os executa: toda Técnica dá um golpe só, e o dano fixo não tem regra.

## Objetivos

1. Puffcoo e Galecrest no catálogo: Vento, ave comum de dia, nos campos e nas colinas, com a Puffcoo evoluindo no nível 20.
2. O estado Atordoado: quem está atordoado não anda na próxima vez dele.
3. As marcas no chão que mudam atributos de quem termina a vez nelas.
4. Os vários golpes e o dano fixo no motor da luta.
5. Cinco Técnicas novas de Vento:
   - um ataque à distância que tira Precisão;
   - uma rajada de 2 a 5 golpes, de longe, com 15 de dano fixo em cada;
   - um reforço de Velocidade e Evasão num aliado;
   - uma faixa de penas que baixa Precisão e Evasão;
   - um vendaval que deixa um redemoinho, onde quem fica é atordoado.

## Anti-objetivos

- Um estado que tira a vez inteira: isso o Amedrontado já faz.
- Uma marca que baixa atributos a cada vez da fila de qualquer Ecobeast. Numa luta de 3×3, isso daria até 6 quedas por rodada.
- Mudar o que as marcas de hoje fazem (o Chão em chamas).

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| Nomes Puffcoo e Galecrest | Escolheu entre três pares propostos |
| Uma evolução só, no nível 20 | Claude propôs 18. O dono pediu 20 |
| A ficha proposta: Vento puro, atributos, Traços, raridade, captura, biomas e só de dia | Aprovou a proposta, que fica _a revisar_ depois de jogar |
| Mais Técnicas, poucas, que mexem no campo: um estado novo de atordoamento, Precisão e Evasão baixando em quem passa pelo campo, Precisão nos inimigos e Velocidade e Evasão nos aliados | Pedido do dono |
| O ataque à distância que tira Precisão se chama Pena Afiada. A Rajada de Penas é outra Técnica, do nível 12: de 2 a 5 golpes numa linha reta de alcance 6, cada um tirando 15 de HP | Pedido do dono, depois de ler a spec |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Atordoado (`dazed`) é volátil e só tira o andar da próxima vez do Ecobeast. Ele ainda age | Tirar a vez inteira repetiria o Amedrontado. No tabuleiro, ficar parado já pesa, e o nome cabe |
| O Vento é imune a Atordoado | A ave não fica tonta com o próprio vento e pode atravessar o redemoinho que criou. Usa a tabela de imunidades que já existe |
| A marca que muda atributos age só em quem acabou de jogar, se ele terminou a vez nela | "Quem passa pelo campo" vira "quem para no campo". Com o andar de 1 hexágono, entrar num hexágono é parar nele. A queda vem uma vez por vez do próprio Ecobeast, e não a cada vez da fila |
| A marca guarda os atributos numa tabela filha, `ground_effect_stats` | Uma marca pode mudar mais de um atributo (Penas no ar baixa Precisão e Evasão), como as `skill_effects` de uma Técnica |
| As marcas novas nascem pela linha reta que atravessa, de alcance 3 | O tabuleiro tem 3 colunas, então uma linha cobre uma fileira inteira. Não é preciso criar uma forma de área |
| As Técnicas novas, com os números da [03](03-puffcoo-line.md), _a revisar_ | Foi pedido "não tanta". Somadas às 3 de Vento e à Investida Veloz, o Galecrest aprende 9 |
| A Rajada de Penas para no primeiro da linha, tem Precisão 85, sorteada uma vez para todos os golpes, e o número de golpes sai de 2 a 5 com a mesma chance | Com 15 de dano fixo, de 30 a 75 por uso logo no nível 12, a Precisão mais baixa e o cooldown 2 seguram a força. O dano fixo não cresce com o nível, então ela perde força mais tarde |
| O Ciclone sai da evolução para o nível 32, e o Vendaval fica como a Técnica que o Galecrest aprende ao evoluir | O Vendaval é a Técnica que deixa o redemoinho e combina com a forma nova |
| A captura da proposta (200 e 90, na escala antiga de 0 a 255) virou 75 e 35, na escala de hoje, de 0 a 100, _a revisar_ | A taxa de captura mudou de escala na migration `capture_rate_0_100`, e a proporção foi mantida |
| As regras primeiro, a tela depois e as espécies por último | As Técnicas das espécies usam as marcas novas. Cada fase pode ser commitada e conferida sozinha |

## Fora do escopo

- As folhas `idle.png` e `walk.png` das duas espécies (skill `creature-sprites`). Sem elas, a espécie aparece com o marcador padrão no mapa e com o `front.png` reduzido no tabuleiro.
- O ícone, o efeito e o som das Técnicas novas e o desenho animado das marcas novas. Ficam para uma fase como a [board-battle/20](../board-battle/20-instinct-wind-skills.md). Até lá, a Técnica não tem ícone, como as outras sem arte, e a marca é o hexágono tingido com a cor dela.
- Formas de área novas, empurrar e puxar.
- Marcas que só valem para um dos lados.
- Ensinar as Técnicas novas a outras espécies.

## Pré-requisitos

- [board-battle](../board-battle/): tabuleiro, marcas, linha reta, alvo `ally`, ícones de estado ([16](../board-battle/16-status-icons.md)) e o painel F3 ([23](../board-battle/23-battle-effect-states.md)).
- [day-phase-spawns](../day-phase-spawns/): `species_day_phases`.
- [hidden-traits](../hidden-traits/): o Traço oculto no slot 3.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-field-rules](01-field-rules.md) | Servidor: o estado Atordoado, as marcas que mudam atributos (`ground_effect_stats`), as marcas Penas no ar e Redemoinho, os vários golpes, o dano fixo e a IA | concluída |
| 2 | [02-field-screen](02-field-screen.md) | Jogo: o ícone do Atordoado, o andar travado na vez dele, as marcas novas no tabuleiro e no histórico e os golpes seguidos na tela | concluída (falta o dono ver no editor) |
| 3 | [03-puffcoo-line](03-puffcoo-line.md) | Dados: Puffcoo e Galecrest, as 5 Técnicas novas, os learnsets, a evolução, os biomas, as partes do dia e os `front.png` | concluída (falta o dono conferir no jogo) |
