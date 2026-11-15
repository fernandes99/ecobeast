# vegetation-packs

As árvores, os arbustos e as pedras de três pacotes de pixel art viram tipos novos de peça solta, que o dono põe pela ferramenta Peças e pelo pincel Vegetação. As decorações sorteadas pelo bioma e o mapa sorteado não mudam.

## Contexto

Em 2026-11-15, o dono pediu: "crie novas vegetações utilizando esse pacote", e mandou três pacotes gratuitos da craftpix.net:

- **Árvores:** `craftpix-net-385863-free-top-down-trees-pixel-art`.
- **Arbustos:** `craftpix-net-141354-free-top-down-bushes-pixel-art`.
- **Pedras:** `craftpix-net-974061-free-rocks-and-stones-top-down-pixel-art`.

Antes de decidir, ele viu uma prévia desenhada pelo próprio jogo, com o Domador e quatro Ecobeasts. De um lado do rio estavam as plantas de hoje e do outro as dos pacotes. O que a prévia mostrou:

- **Árvores:** as grandes dos pacotes têm o dobro do tamanho das de hoje. A maior tem 62 × 78 px; a Árvore de hoje, uns 30 × 40.
- **Arbustos:** têm o tamanho dos de hoje.
- **Pedras:** cada uma vem em 5 tamanhos, e a maior tem quase um hexágono.

Na mesma conversa, Claude fez pisos mais lisos para comparar. O dono os deixou de lado ("não vamos usar"), guardados em `backup testes/pisos/`, fora do jogo.

Decisão do dono: "vamos colocar as vegetações do pacote como peças soltas, mas vamos manter do jeito que está nos biomas e nas gerações procedurais".

## Objetivos

1. Os 33 tipos da [tabela](architecture.md#os-tipos) entram no catálogo, com a arte em `client/assets/props/`.
2. A ferramenta Peças os mostra e põe, como qualquer peça solta.
3. O pincel Vegetação ganha 6 grupos com eles. As pedras se dividem por tamanho, pela variante.

## Anti-objetivos

- As decorações naturais do bioma (`HexDecorations`) e as receitas delas não mudam.
- O mapa sorteado de Explorar zona não muda.
- O piso dos biomas não muda.
- Nenhuma peça nova bloqueia. O dono pode dar um bloqueio a um tipo depois, pelo editor ([free-objects/02](../free-objects/02-block-editing.md)).

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| A arte dos pacotes vira peça solta | "vamos colocar as vegetações do pacote como peças soltas" |
| O bioma e a geração não mudam | "vamos manter do jeito que está nos biomas e nas gerações procedurais" |
| A arte fica no tamanho original | Pixel art reduzida perde o desenho; o dono viu a prévia nesse tamanho |
| Os pisos de teste ficam guardados, sem uso | "deixa em uma pasta de 'backup testes'" |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e no `architecture.md`):

| Decisão | Motivo |
| --- | --- |
| Um tipo por desenho do pacote, e os tamanhos dele viram as variantes, da maior para a menor | O pacote desenha cada planta em 3 tamanhos (as pedras em 5), e a ferramenta Peças já troca a variante |
| Os tocos e troncos caídos são um tipo só, com 7 variantes de formato | São pedaços de árvore sem tamanhos próprios |
| Usa a versão "com sombra" de cada pacote (`Trees_shadow`, `Assets_shadow` e `RockN_K.png`) | A sombra cinza combina com a das decorações de hoje. As versões de grama, neve e água das pedras ficam de fora |
| No pincel, os tipos novos ficam em 6 grupos próprios, depois dos 7 de hoje. Os de clima (neve, cacto, outono, seco) e os cristais começam desligados | Pintar Árvores continua dando as árvores de hoje, e a mistura de estilos só acontece quando o dono escolher |
| O espaço no chão de uma peça sem raio fixo é ¼ da largura da arte da variante, de 4 a 15 px | Com o raio fixo de 8 px, duas árvores grandes nasceriam uma dentro da outra. 15 px é o raio da Árvore de hoje |

## Fora do escopo

- Os pisos de teste.
- Usar as plantas novas no sorteio do bioma ou do mapa sorteado.
- Bloqueio e ação para os tipos novos.
- Vento nas peças novas: as peças de arte própria ficam paradas, como o banco e o poste.

## Pré-requisitos

- [free-props](../free-props/): as peças soltas e a ferramenta Peças.
- [vegetation-brush](../vegetation-brush/): o pincel Vegetação.
- [free-objects](../free-objects/): os tipos 22 a 27, que vêm antes dos novos.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-pack-props](01-pack-props.md) | A arte, os 33 tipos no catálogo e os 6 grupos do pincel | concluída (falta o dono usar) |

O desenho compartilhado está no [architecture.md](architecture.md).
