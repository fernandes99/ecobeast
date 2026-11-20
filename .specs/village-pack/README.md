# village-pack

As casas, os objetos de vila e as cercas do tileset **Village** do pacote **Fantasy Dreamland Reborn** (ElvGames) entram nas ilhas: as casas em vários tamanhos, montadas pelos tiles, em 8 cores; os objetos como peças soltas; e a cerca de madeira e o muro de pedra como tipos novos de parede.

## Contexto

Em 2026-11-20, o dono pediu: "Crie casas e objetos que existem nesse tileset", apontando a pasta `Tilesets/Village/Sprites` do pacote, e completou: "Eu quero ter mais variedade de objetos padronizados com esse tileset, tente pegar o maximo de objetos que conseguir, o maximo de variantes de casas que conseguir (pequenas, medias, grandes e etc)".

O tileset é uma imagem só, `FDR_Village.png` (512×512, tiles de 16×16, com transparência). Ele tem:

- **Casas em partes:** os telhados em 3 cores (vermelho, azul e ardósia), cada uma em 3 formatos (a casa larga de frontão no meio e duas alas, a mesma com as alas mais compridas, e a casinha de um frontão só); os corpos de reboco creme com postes de madeira, sem porta nem janela; as frentes de frontão com janela (3 linhas, com janela de madeira, de vidro e redonda); as portas num batente de madeira (4 quadros, da fechada à aberta); as janelas soltas; e 2 chaminés de pedra.
- **Objetos:** placas de direção, placas de madeira, placas de loja penduradas num braço (8 ícones), lanternas penduradas (amarela e roxa), fontes (grande e pequena, com e sem estátua), poços de pedra, tanques de tábuas, cochos, caixotes, bancos, mesas, cadeiras e banquinhos, escadas, lenha, trigo, canteiros de terra e flores.
- **Cercas:** a cerca de madeira e o muro de pedra, em peças de 16 px deitadas e em pé.
- **Chão:** grama, terra, areia, pedras de caminho e deques de madeira.

Na escolha das abordagens, o dono escolheu as casas montadas por tamanho com 8 cores (contra só as 3 cores do pacote e contra recortar só as casas prontas) e pediu as cercas também.

## Objetivos

1. Todas as casas que os tiles permitem montar, em tamanhos diferentes (pequena, média, grande, comprida, sobrado), cada uma como um tipo de peça solta, com as 8 cores como variantes, espelháveis, com bloqueio no pé, janelas acesas à noite e fumaça na chaminé.
2. Os objetos do pacote viram peças soltas, agrupados por parecença, cada forma como uma variante.
3. A cerca de madeira e o muro de pedra do pacote viram tipos de parede, desenhados pela ferramenta Cerca, bonitos em qualquer ângulo.
4. A arte sai de scripts que recortam e montam os tiles do pacote, sem desenhar pixel novo (fora a troca de cor das variantes).

## Anti-objetivos

- As peças, as paredes, as luzes e a fumaça de antes não mudam.
- Nenhuma regra nova do jogo: as peças são enfeite com bloqueio, e o editor dá uma ação a qualquer uma pela lista Ação.
- Nada no mapa sorteado.

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| As casas são montadas pelos tiles, por tamanho, cada tamanho um tipo de peça, com 8 cores como variantes | Máximo de variedade, combinando com as outras casas |
| As cercas do pacote entram como tipos de parede | Pedido do dono |
| Pegar o máximo de objetos do pacote | Pedido do dono |
| Os 10 formatos da prévia entram, da Casinha à Casa de três frontões (peças 102 a 111) | Escolha do dono pela prévia, em 2026-11-20 |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Os tipos de peça começam no 102, e os de parede no 5 | O 101 (Altar-portal) e a parede 4 (Cerca de estacas) são os últimos |
| As cores seguem a numeração das outras casas ([home-pack/03](../home-pack/03-house-shapes.md)): 1 vermelho, 2 azul, 3 verde, 4 telha de madeira, 5 ardósia, 6 roxo, 7 verde-água, 8 laranja. As cores 1, 2 e 5 são os telhados do próprio pacote; as outras são o vermelho repintado | Uma cor tem o mesmo número em todas as casas, e 3 das 8 ficam fiéis ao pacote |
| Os formatos das casas passam por uma prévia, e o dono escolhe quais entram antes do cadastro | Na home-pack, o dono descartou 4 dos 6 formatos da prévia |
| O chão do pacote (grama, terra, areia, pedras de caminho e deques) fica fora | O chão do jogo é a máscara de chão (`GroundMask`), com tipos próprios; um deque como peça solta cobriria o Domador pela ordem do pé |
| As portas, as janelas e as chaminés não viram peças: só entram nas casas | Soltas, não têm parede onde ficar |
| A fumaça é a da Casa grande (`big_house/smoke.png`) | O pacote não tem fumaça, e as outras casas já usam essa |
| Os slugs começam com `village_` | Os nomes `bench`, `sign`, `lamp_post` e `small_house` já são de outras peças |
| A prévia ganhou 3 formatos além dos 7 da primeira versão da spec: a Casa de ala comprida, o Sobrado comprido e a Casa de três frontões | As emendas por colunas permitiam mais tamanhos, e o dono pediu o máximo de casas |
| O cocho tem 2 variantes (vazio e com água), a placa de loja 10 (a lisa, os 8 ícones e o braço vazio) e a lanterna é acesa ou apagada, não amarela ou roxa | É o que a folha tem: a terceira peça da fileira dos cochos é uma pilha de caixotes, e a lanterna roxa é a mesma apagada |
| As migrações não dão o `id` das linhas de bloqueio e de luz: o `setval` acerta a sequência antes do `INSERT` | O editor cria linhas de bloqueio pelo cadeado, e um id fixo poderia já estar em uso |
| A carga inicial (`seed-data`) não muda; os tipos entram só pelas migrações | Como o Altar-portal |
| A arte do pacote fica fora do [guia de estilo da cidade](../town-art/style-guide.md) | O dono pediu o pacote, como nas casas da home-pack e da timber-house |

## Fora do escopo

- O chão, os deques e as pedras de caminho (ver as decisões).
- A porta abrindo (os 4 quadros do batente) e qualquer animação além da fumaça e da luz da noite.
- As salas por dentro das casas novas ([interiors](../interiors/)); o editor pode ligar uma sala a qualquer peça pela lista Sala.
- Os outros tilesets do pacote (Castle, City, Winter Village e os outros).

## Pendências do dono

- A licença do pacote: os créditos citam o pacote e o autor, e o dono confirma que pode usá-lo no jogo.

## Pré-requisitos

- [home-pack](../home-pack/): as 8 cores e a fumaça das casas.
- [day-night](../day-night/): as luzes da noite (`prop_type_lights`) e o `find_lights.py`.
- [fence-art](../fence-art/): a folha de 3 células das paredes e o `make_walls.py`.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-village-houses](01-village-houses.md) | A prévia dos formatos e as 10 casas, em 8 cores, com luzes, fumaça e bloqueio | concluída (falta o dono conferir) |
| 2 | [02-village-objects](02-village-objects.md) | Os 17 objetos do pacote como peças soltas, com bloqueio e a lanterna acesa | concluída (falta o dono conferir) |
| 3 | [03-village-fences](03-village-fences.md) | A cerca de madeira e o muro de pedra como paredes 5 e 6 | concluída (falta o dono conferir) |
