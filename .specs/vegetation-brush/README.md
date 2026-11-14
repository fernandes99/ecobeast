# vegetation-brush

O editor ganha um pincel que espalha vegetação e pedras como peças soltas, por grupo (árvores, arbustos, gramas, flores e pedras pequenas, médias e grandes), para o dono encher uma ilha em poucas pinceladas. Antes disso, os objetos de grade que não vão mais ser usados saem do catálogo, das ilhas e do jogo. Ficam só as casas da cidade, os prédios do Refúgio e da Loja e a cerca da cidade.

## Contexto

Em 2026-11-14, depois da [free-trails](../free-trails/README.md), o dono pediu:

- **A limpeza:** "quero que seja removido todos os mapas e as props que bloqueiam. Mantendo apenas a Casa (cidade), Casa média (cidade), Casa grande (cidade), Prédio de Refúgio, Prédio de Loja e a Cerca (cidade). Pode deletar tudo que não será mais usado além deles, quero limpar os maps objects (as soltas que é só enfeite pode manter)".
- **O pincel:** "uma maneira para criar vegetações de maneira mais rapida, um pincel que vai criar vegetações de acordo com um grupo de vegetações (arvores, arbustros, gramas, flores, pedras pequenas, pedras médias, pedras grandes)".

Claude perguntou três coisas, e o dono respondeu:

- **Os tipos do grupo:** o pincel não escolhe pelo bioma; o dono marca quais tipos do grupo entram.
- **Apagar:** o botão direito do pincel apaga todas as peças soltas dentro dele, de qualquer grupo.
- **Os carimbos:** "Apague todos os carimbos".

O que existe hoje:

- **31 objetos de grade** no catálogo `map_object_types`, que ocupam e podem bloquear hexágonos ([island-villages](../island-villages/README.md)). As duas versões da ilha do dono, o rascunho e a publicada, usam 11 deles.
- **21 tipos de peça solta** no catálogo `prop_types`, que são só enfeite, num ponto em pixels ([free-props](../free-props/README.md)). Os 17 primeiros usam a arte das decorações naturais; os outros 4 (poste, placa, canteiro e banco) têm arte própria.
- **A ferramenta Peças** põe uma peça por clique. A Borracha apaga as peças e as decorações sorteadas de um pincel de hexágonos.
- **O limite** é de 6.000 peças por ilha.

## Objetivos

1. O catálogo, as ilhas, a arte e o código ficam só com os 6 objetos que o dono escolheu.
2. Com o pincel, o dono espalha os tipos marcados de um grupo pelos hexágonos do pincel, com a densidade que escolher, e apaga com o botão direito.
3. Uma ilha grande cabe com muita vegetação.

## Anti-objetivos

- O pincel nunca bloqueia nem muda regra: ele só põe peças soltas, que são enfeite.
- As decorações naturais sorteadas do bioma não mudam.
- Nada muda no mapa sorteado de Explorar zona.

## Decisões

Do dono, em 2026-11-14:

| Decisão | Motivo |
| --- | --- |
| Ficam só 6 objetos de grade: Casa (cidade), Casa média (cidade), Casa grande (cidade), Prédio do Refúgio, Prédio da Loja e Cerca (cidade). Os outros 25 saem do banco, das ilhas, da arte e do código | Pedido do dono |
| As peças soltas ficam todas | "as soltas que é só enfeite pode manter" |
| O dono marca quais tipos do grupo o pincel usa | Escolhido pelo dono, em vez de escolher pelo bioma |
| O botão direito do pincel apaga todas as peças soltas dos hexágonos do pincel, de qualquer grupo | Escolhido pelo dono |
| Todos os carimbos são apagados | "Apague todos os carimbos" |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e no `architecture.md`):

| Decisão | Motivo |
| --- | --- |
| Os grupos e os tipos de cada um estão na tabela do [architecture.md](architecture.md#os-grupos). As Flores e as Pedras pequenas têm um tipo só; o Canteiro, o Poste, a Placa e o Banco ficam fora dos grupos | O canteiro é de cidade, não planta solta; o resto não é vegetação |
| O pincel é uma ferramenta nova, **Vegetação**, no grupo Peças, logo depois de Peças | Fica perto das peças que ele põe |
| O pincel usa o tamanho em hexágonos que as outras ferramentas já usam, e a densidade tem 3 escolhas: Pouca, Média e Muita | O dono já conhece o tamanho; 3 escolhas bastam |
| As peças novas guardam distância entre si, das peças que já estão lá e das decorações naturais do hexágono, pela mesma regra das decorações | Sem isso, a árvore nasceria em cima da pedra |
| O limite sobe de 6.000 para 20.000 peças por ilha | Com o pincel, uma ilha de 2.000 hexágonos com grama passa de 6.000. Cada peça tem uns 90 bytes, e uma ilha cheia continua abaixo dos 5 MB que o editor manda |
| O editor redesenha, a cada passo do pincel, só os hexágonos que ele tocou (revisto na fase 2) | Numa ilha com 15.000 peças, refazer a lista toda levava 130 ms por passo; só os tocados, 17 ms |
| As ilhas perdem os objetos apagados, no rascunho e na publicada | O banco não deixa um objeto sem tipo. Os 5 tipos usados que saem são a Arena, o Moinho, o Poço, a Barraca de feira e a Fonte, todos da cidade |

## Fora do escopo

- Arte nova de vegetação ou de pedra.
- Escolher a vegetação pelo bioma embaixo do pincel.
- Pincel de objetos de grade.
- Carimbos novos.
- As ações das ilhas, que não são objetos: a ação da Arena continua nos hexágonos dela, sem o prédio.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-object-cleanup](01-object-cleanup.md) | Servidor e jogo: os 25 objetos saem do banco, das ilhas, da arte e do código; os carimbos saem | concluída |
| 2 | [02-vegetation-tool](02-vegetation-tool.md) | Editor e servidor: a ferramenta Vegetação, com os grupos, os tipos marcados, a densidade e o apagar, e o limite de 20.000 peças | concluída |

O desenho compartilhado está no [architecture.md](architecture.md).
