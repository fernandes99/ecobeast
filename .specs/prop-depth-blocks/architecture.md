# prop-depth-blocks: desenho compartilhado

## A ordem de desenho

Hoje cada linha de hexágonos tem o chão e 4 faixas de decoração de 14,5 px, medidas do alto do hexágono ([free-props](../free-props/architecture.md)). Passa a ser assim:

- **A fatia.** O pé de uma peça (ou de um pedaço de cerca, ou de uma decoração natural) no chão plano tem `y`. A fatia dele é `floor(y / 42)`: a linha cujo topo plano está logo acima do pé. Um pé do hexágono da linha `r` cai na fatia `r` ou, na ponta de baixo, na `r + 1`.
- **A passagem para a linha de baixo.** O pé que cai na fatia `r + 1` é desenhado na linha `r + 1` (no mesmo pedaço de colunas), depois do chão dela, quando:
  - esse pedaço existe; e
  - os dois vizinhos de baixo do hexágono, `(-1, 1)` e `(0, 1)`, não são mais altos que ele.

  Senão, ele fica na última faixa da própria linha, como antes, e o paredão do vizinho mais alto o cobre.
- **As faixas.** Cada linha tem 6 faixas de 7 px. A faixa de um pé é `floor((y - 42 * fatia) / 7)`, de 0 a 5.
- **Os atores.** Com o pé no chão plano, o ator entra antes da faixa `round((y - 42 * fatia) / 7)` da fatia dele, ou depois da última, com a mesma regra da passagem. O erro fica em até 3,5 px.
  - O Domador já entra pelo pé (`set_actor_depth`).
  - Os Ecobeasts do mapa e os NPCs que passeiam passam a entrar pelo pé a cada passo. Hoje eles entram no meio da linha (`set_actor_row`). O nó só muda de lugar quando a fatia ou a faixa muda.
- **O que passa para a linha de baixo é montado com ela.** A linha `r + 1` monta as próprias peças e as que passam da `r`. Mudar um hexágono já refaz os pedaços das linhas vizinhas (`update_tiles`), então nada fica para trás.

## O bloqueio por variante

`prop_type_blocks` ganha a coluna `variant` (inteiro, padrão 0, de 0 a 99). A chave única passa a ser (`prop_type_id`, `variant`, `position`).

- **As linhas de uma peça** do tipo `t` e variante `v` são:
  - as próprias, quando ajustadas;
  - senão, as do tipo com `variant = v`, quando existem;
  - senão, as do tipo com `variant = 0`.

  A mesma regra vale no servidor (`blocked-hexes.ts`) e no jogo (`GameData.get_prop_blocks(t, v)`).
- **A rota** `PUT /v1/editor/prop-types/:id/blocks` recebe `variant` (0 se faltar) e troca só as linhas daquela variante. Linhas vazias numa variante maior que 0 apagam o padrão próprio dela, e ela volta a usar o de `variant = 0`.

### Os padrões dos pacotes

Calculados da arte (`client/assets/props/<slug>/<n>.png`, com o pé no meio da borda de baixo). `fundo` é a última linha de pixels opacos, contada do pé (negativa):

| Tipos | Variantes | Linha |
| --- | --- | --- |
| As 8 pedras (53 a 60) | 1 e 2 | Fechada, 8 pontos: uma elipse com a largura dos pixels opacos dos 40% de baixo da pedra, menos 2 px de cada lado, e altura de ⅓ da largura. O ponto de baixo fica em `fundo` |
| As 11 árvores (28 a 38) | 1 e 2 | Fechada, 8 pontos: uma elipse de 36 × 18 px (variante 1) ou 32 × 16 px (variante 2), com o ponto de baixo em `fundo`. Começou em 12 × 6 e 10 × 5; o dono pediu duas vezes mais o mesmo tanto e depois 32 × 16 na variante 2, para o Domador não entrar embaixo da copa |

Os números ficam na migration e no `seed-data/prop_type_blocks.json`.

## O hexágono bloqueado

O servidor (`lineBlockedKeys`) e a camada Bloqueios do editor (`IslandBlocks`) contam um hexágono como bloqueado quando o centro dele:

- está dentro de uma linha fechada (de peça ou de parede); ou
- está a até 8 px (`CENTER_REACH`) de algum trecho de linha.

Antes, bastava a linha passar por qualquer ponto do hexágono. A conta continua a mesma nos dois lados.

## A ferramenta Bloqueios

Uma ferramenta nova do grupo Peças, depois de Vegetação. Com ela:

- **as linhas** de todas as peças aparecem, como na camada Bloqueios, com os pontos à mostra;
- **apertar o botão esquerdo** a até 6 px (`EditorTools.BLOCK_PICK`) de um ponto escolhe a peça dele e o arrasta. Num trecho, põe um ponto e o arrasta. Fora de uma linha, sobre a arte de uma peça, só escolhe a peça;
- **o botão direito** num ponto o apaga;
- **o painel** mostra a peça escolhida (nome e variante) e os botões:
  - Nova linha, Fechar linha e Abrir linha;
  - Usar o padrão;
  - Salvar para esta variante e Salvar para todas;
- **Esc** larga a peça.

As regras são as do cadeado da [free-objects/02](../free-objects/02-block-editing.md): a primeira mudança copia as linhas do padrão para a peça, cada mudança é um passo do desfazer, e salvar o padrão pergunta antes. O cadeado da peça escolhida continua existindo na ferramenta Peças.
