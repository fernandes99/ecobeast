# free-trails

Os caminhos das ilhas ganham mais tipos, emendas naturais entre um tipo e outro e a liberdade de sair da grade. O dono desenha um **traço** arrastando o mouse, com um tipo e uma largura, e o caminho segue o traço em qualquer direção, subindo e descendo com a altura de cada hexágono embaixo dele. O chão por hexágono de hoje continua, para os pisos e as praças, e passa a ser desenhado do mesmo jeito que os traços.

## Contexto

Em 2026-11-14, o dono mostrou uma ilha com uma trilha de terra entrando num calçamento de pedra e pediu:

- **Mais tipos:** "mais tipos de caminhos, de cascalho, de pedra por cima, quero pelo menos mais 3 opções".
- **Emendas:** "deve ter uma junção natural deles, que não seja muito abrupto cada ligação": na print, a terra "simplesmente passa para o caminho de pedra".
- **Liberdade:** "construir os caminhos independentes do hexágono, como é feito nas decorações", para fazer caminhos "para cima por exemplo, e não só de diagonal ou de lado".

Claude mostrou dois jeitos de desenhar o caminho livre: **traços** (A), um caminho por arraste, que depois se seleciona, troca e apaga como uma peça, e **pintura** (B), um pincel redondo que pinta qualquer forma, sem um caminho para selecionar. O dono escolheu os traços. É a terceira das iniciativas que a [free-props](../free-props/README.md#contexto) listou ("trilhas contínuas").

O que existe hoje ([island-villages/02](../island-villages/02-grounds.md)):

- **4 chãos** no catálogo `ground_types`: `dirt_trail` e `stone_trail` (trilhas), `cobble_floor` e `dirt_floor` (pisos), com a arte provisória do `make_grounds.gd`.
- **O chão é do hexágono** (`HexTile.ground`). A trilha é uma faixa de 22 px do centro até o meio de cada lado com chão vizinho; o piso cobre o hexágono. O shader `hex_grounds.gdshader` desenha a forma, com a borda escura e a sombra na grama.
- **Dois tipos que se encontram** ficam lado a lado, cada um com a sua textura, sem nada entre eles.

## Objetivos

1. Quatro tipos novos de chão: cascalho, pisantes, areia batida e trilha gasta.
2. Onde dois tipos se encontram, as pedras do mais duro se soltam e se espalham sobre o outro; a borda com a grama é irregular.
3. O dono desenha traços de caminho em qualquer direção, com tipo e largura, e depois seleciona, troca o tipo ou a largura e apaga cada um, com desfazer.
4. Os traços e o chão por hexágono aparecem iguais no editor e no jogo, na altura do terreno, sem pesar.

## Anti-objetivos

- O caminho nunca muda regra: não bloqueia, não muda encontro nem a posição do Domador. Ele é só desenho, como a peça solta.
- Nada muda no mapa sorteado de Explorar zona.
- A ferramenta Chão, por hexágono, não some: os pisos e as praças continuam nela.

## Decisões

Do dono, em 2026-11-14:

| Decisão | Motivo |
| --- | --- |
| O caminho livre é um traço (opção A): uma linha de pontos com um tipo e uma largura, que se seleciona e apaga inteira | Escolhida pelo dono. Ocupa pouco no banco e se edita depois, como uma peça |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e no `architecture.md`):

| Decisão | Motivo |
| --- | --- |
| Os tipos novos: **Cascalho** (`gravel_trail`), **Pisantes** (`stepping_stones`, lajes soltas com a grama aparecendo entre elas), **Areia batida** (`sand_trail`) e **Trilha gasta** (`worn_trail`, terra com tufos de grama), todos trilhas | O dono pediu cascalho, "pedra por cima" e pelo menos 3; a areia e a trilha gasta cobrem a praia e o campo |
| Todo tipo serve para o traço e para o hexágono | O dono escolhe o tipo, não a ferramenta |
| Cada tipo tem uma dureza (`ground_types.hardness`, de 1 a 3): na emenda, o mais duro se espalha sobre o mais mole; com a mesma dureza, os dois se misturam numa faixa estreita | Terra recebe pedrinhas de um calçamento, e não o contrário |
| O chão por hexágono e os traços são desenhados juntos, por uma **máscara de chão**: uma imagem em pixels do chão plano, com o tipo em cada ponto, lida por um shader só. A trilha por hexágono vira, na máscara, a mesma faixa de hoje | Sem um desenho só, a emenda entre um traço e um piso, ou entre dois pisos, não teria como sair |
| Num degrau de lado (lados 1 e 4), o caminho dá um degrau na tela, em vez de se entortar como hoje | Na máscara, cada hexágono mostra o chão no plano dele. É o que o terreno faz no mesmo lugar, e o paredão da frente continua levando o caminho para baixo |
| As três larguras do traço: **Estreita** (14 px), **Normal** (22 px, a da trilha de hoje) e **Larga** (34 px) | Pouca escolha basta; o banco aceita de 8 a 64 |
| O traço só aparece sobre hexágonos de terra: sobre a água e fora da ilha, ele não é desenhado | A ponte é um objeto |
| Os traços ficam por cima do chão por hexágono, e o mais novo por cima do mais velho; os pisos ficam por cima das trilhas | O traço é o que o dono desenhou por último; o piso fecha a praça e a trilha chega nela |
| As decorações sorteadas seguem a regra do chão embaixo do pé, seja traço ou hexágono: na trilha, só as pequenas; no piso, nenhuma | A mesma regra de hoje, agora pelo ponto em vez do hexágono |
| Os traços não entram nos carimbos | Fica para depois; o dono desenha o caminho depois de pôr o carimbo |
| Limites: 500 traços por ilha, 256 pontos por traço | A ilha inteira vai numa resposta só, como as peças |
| Entre as lajes dos Pisantes aparece sempre o bioma, mesmo por cima de outro chão | A máscara guarda um tipo por ponto; guardar o de baixo dobraria o desenho para um caso raro |
| A máscara é desenhada pela placa de vídeo, num `SubViewport` por página, e lida direto dele (revisto na fase 2; antes, uma cópia de um canal) | O mapa nunca espera a máscara, nem ao abrir nem ao pintar; só existem as páginas com chão, de cerca de 4,7 MB cada |
| Um traço recém-desenhado fica sem escolha (revisto na fase 4) | No print do editor, escolher o tipo do próximo caminho trocava o tipo do que acabou de ser feito |

## Fora do escopo

- Mover um ponto de um traço já feito, emendar dois traços ou continuar um traço. Para mudar, o dono apaga e desenha de novo.
- Traços nos carimbos.
- O pincel que espalha peças soltas (outra iniciativa).
- A arte final dos chãos.
- Caminho no mapa sorteado de Explorar zona.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-ground-types](01-ground-types.md) | Catálogo e arte: os 4 tipos novos e a dureza de cada tipo, na ferramenta Chão como estão hoje | concluída |
| 2 | [02-ground-mask](02-ground-mask.md) | Jogo e editor: o chão por hexágono desenhado pela máscara, com a borda irregular e as emendas entre tipos | concluída |
| 3 | [03-trail-records](03-trail-records.md) | Servidor e jogo: os traços no banco, no contrato do editor e de Explorar, e desenhados na máscara | concluída |
| 4 | [04-path-tool](04-path-tool.md) | Editor: a ferramenta Caminho, para desenhar, selecionar, trocar e apagar traços, com desfazer | concluída |

O desenho compartilhado está no [architecture.md](architecture.md).
