# field-effects

Mais estados e mais marcas no chão da luta, com Técnicas que os usam: o Preso que não anda, o Encharcado que combina Água com Volt, o Brotando que cura aos poucos, a marca Jardim que cura quem para nela e cinco marcas novas que usam regras que já existem. A luta ganha combos e disputa por posição no tabuleiro.

## Contexto

Em 2026-11-19, o dono pediu: "reveja as skills, e tente implementar mais status tanto de ecobeast quanto de terreno, e também se puder criar mais ténicas que afetam mais status e campo, pode criar."

Claude revisou o catálogo e o motor da luta:

- **Estados:** Queimado, Envenenado, Paralisado, Adormecido, Congelado, Confuso, Amedrontado, Preso e Atordoado. O Envenenado já tira 1/8 do HP no fim de cada vez, mas nenhuma Técnica o aplica, e o Elemento Toxina não tem nenhuma Técnica. O Preso só impede a fuga, e nenhuma Técnica o aplica.
- **Marcas:** Chão em chamas, Penas no ar, Redemoinho, Espinheiro e Maré Elétrica. Uma marca tira uma porcentagem do HP ou tenta pôr um estado em todos que estão nela, depois de cada vez da fila, e muda os atributos de quem acabou de jogar nela ([puffcoo-line/01](../puffcoo-line/01-field-rules.md)).
- **Efeitos:** o clima, o carregar e o trocar existem no catálogo, mas sem regra no motor.

Claude propôs três caminhos: só dados (A), dados e algumas regras novas que combinam com o tabuleiro (B) e, além disso, o clima (C). O dono escolheu o **B**.

## Objetivos

1. O Preso passa a valer no tabuleiro: quem está preso não anda, por 2 vezes dele.
2. O estado Encharcado: o dano de Volt sobe e o de Fogo cai em quem está encharcado.
3. O estado Brotando: quem está brotando recupera um pouco do HP no fim de cada vez dele.
4. A marca que cura, o Jardim.
5. Seis marcas novas no catálogo, cinco delas com as regras que já existem.
6. Dez Técnicas novas que usam os estados e as marcas, com as primeiras de Toxina, nos learnsets dos Ecobeasts que já existem.
7. O jogo mostra os estados novos, a cura das marcas e do Brotando, e o F3 liga e desliga cada um.

## Anti-objetivos

- Clima, que muda a luta inteira: fica para outra iniciativa.
- Mudar as Técnicas, os estados e as marcas que já existem, fora o Preso.
- Um estado que só um Ecobeast consegue tirar, ou que trava a luta para sempre: todo estado novo acaba sozinho.

## Decisões

Do dono, em 2026-11-19:

| Decisão | Motivo |
| --- | --- |
| O caminho B: dados e algumas regras novas que combinam com o tabuleiro, sem clima | Escolha entre os três caminhos de Claude |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase). Todos os números são _a revisar_ depois de jogar:

| Decisão | Motivo |
| --- | --- |
| Os estados novos são voláteis e contam as vezes de quem os tem, como o Atordoado | Acabam sozinhos, saem na troca e no fim da luta, e não brigam com o estado principal (o Queimado e os outros) |
| Encharcado: Volt ×1,5 e Fogo ×0,5 no dano recebido, por 3 vezes | Cria o combo da linha do Tidebud (molhar e eletrocutar) e uma defesa contra o Fogo |
| Brotando: cura 1/16 do HP máximo no fim de cada vez, por 5 vezes | A mesma fração do Queimado, ao contrário |
| Preso: não anda por 2 vezes; o Vento é imune | Quem voa não fica preso no chão; é a mesma imunidade do Atordoado |
| A marca Jardim cura 6% do HP de todos que estão nela, depois de cada vez, aliados e inimigos | É o Chão em chamas ao contrário: a disputa é por quem fica no jardim |
| Toxina sem Ecobeast novo: as Técnicas dela vão para a linha do Seedlet (espinho venenoso) e para o Nilgorr e o Ingot (de Metal, imunes ao Envenenado, que ficam na própria poça) | Toxina estreia sem esperar uma linha nova |
| Ícone, efeito e som das Técnicas novas ficam para quando o dono mandar os ícones, como nas [board-battle/26](../board-battle/26-feather-wind-skills.md) a [28](../board-battle/28-skill-projectiles.md) | É o caminho de sempre |

## Fora do escopo

- O clima e os efeitos `set_weather`, `multi_turn` e `switch`.
- Ícone, efeito e som das dez Técnicas novas.
- Desenho próprio das marcas novas no tabuleiro: o hexágono tingido com a cor da marca, como a Maré Elétrica.
- Uma linha de Ecobeast de Toxina.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-field-rules](01-field-rules.md) | No servidor: o Preso no tabuleiro, o Encharcado, o Brotando, a marca que cura e as seis marcas | concluída |
| 2 | [02-field-screen](02-field-screen.md) | No jogo: os ícones e os efeitos dos estados novos, a cura das marcas e do Brotando, as falas do log e o F3 | concluída (falta o dono ver no jogo) |
| 3 | [03-field-skills](03-field-skills.md) | As dez Técnicas novas e os learnsets | concluída (falta o dono ver no jogo) |
