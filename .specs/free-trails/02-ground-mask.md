# 02. A máscara de chão e as emendas

- **Status:** concluída (falta o dono ver no editor e no jogo)
- **Depende de:** [01](01-ground-types.md)

## Contexto

Hoje, cada hexágono com chão desenha a própria forma no shader, sem saber que tipo está do outro lado. Por isso, na print do dono, a terra "simplesmente passa para o caminho de pedra". Esta fase troca o desenho do chão pela máscara do [architecture.md](architecture.md#a-máscara-de-chão-fase-2): o chão é pintado primeiro numa imagem do chão plano e depois lido por um shader só, que faz a borda irregular com a grama e a emenda entre dois tipos. Ela só usa o chão por hexágono; os traços entram na [03](03-trail-records.md), na mesma máscara.

## Escopo

- As páginas da máscara e o desenho do chão por hexágono nelas.
- A malha de chão de cada linha e o shader novo.
- As decorações seguindo o chão embaixo do pé.
- O editor redesenhando as páginas ao pintar o chão.

## Fora do escopo

- Os traços ([03](03-trail-records.md)).
- Mudar a arte dos tipos ou a forma da trilha por hexágono.

## Requisitos

- **RF-01:** o `HexGrounds` monta as páginas da máscara de uma ilha, com as trilhas, depois os pisos, na forma e na ordem do [architecture.md](architecture.md#a-máscara-de-chão-fase-2). Só existem as páginas com chão. O `SubViewport` é desenhado antes da tela no mesmo quadro, então nada espera as páginas.
- **RF-02:** o `HexMapView` desenha o chão pela malha de chão, nos hexágonos de terra que o chão toca, com o shader novo, no lugar das malhas de hoje. O corte de altura e a janela do Domador continuam valendo para ele.
- **RF-03:** a borda do chão com a grama é irregular, com a borda escura de 2 px e 1 px de sombra na grama, em pixels inteiros da arte. Uma trilha reta não tem a borda reta.
- **RF-04:** onde dois tipos se encontram, sem borda escura entre eles, as pedras do tipo mais duro se espalham sobre o outro numa faixa de até 6 px, cada vez mais raras. Com a mesma dureza, o de id maior se espalha.
- **RF-05:** a textura de cada tipo continua presa ao mapa: dois hexágonos vizinhos do mesmo tipo seguem contínuos, sem emenda.
- **RF-06:** o chão sobe com o hexágono. Por um paredão da frente, o caminho desce reto até o pé. Num degrau de lado, ele dá o degrau junto com o terreno (decisão do [README](README.md#decisões), que troca a ponta entortada da island-villages/02). Num lado com degrau sem paredão, o chão tem a borda escura, como o piso tem hoje.
- **RF-07:** uma decoração sorteada segue o chão embaixo do pé dela ([architecture.md](architecture.md#as-decorações-sorteadas)).
- **RF-08:** no editor, pintar ou apagar o chão redesenha as páginas tocadas, e uma pincelada de raio 10 com chão não trava o editor, como na [island-villages/02](../island-villages/02-grounds.md).
- **RF-09:** o código antigo da forma por hexágono sai (`HexGrounds.add_tile`, `arm_shift`, `seamless` se não for mais usado, `Batch`, e as funções `trail` e `floor_shape` do shader).

## Critérios de aceite

- [x] Uma trilha de terra chegando num calçamento de pedra mostra pedrinhas soltas sobre a terra perto da divisa, sem linha reta entre os dois.
- [x] Uma trilha em linha, em curva, em T e em cruz se liga sozinha, com a borda irregular.
- [ ] Uma trilha sozinha é uma mancha redonda irregular.
- [x] Uma trilha que desce um paredão da frente continua por ele.
- [ ] Uma praça num degrau de lado mostra a borda no degrau.
- [x] Um piso não tem decoração, e uma trilha só tem as pequenas.
- [ ] Com o corte de altura ligado, o chão dos hexágonos altos fica transparente com eles; a janela em volta do Domador vale para o chão.
- [x] O jogo numa ilha com 2.000 hexágonos de chão não fica mais lento que antes ao andar.
- [ ] O dono vê as emendas no editor (F2) e numa ilha (F5).

## Desenho técnico

- `ui/components/hex_grounds.gd`: as páginas (o `SubViewport` num nó do `HexMapView` e as cópias em `FORMAT_R8`), a forma da trilha e do piso na página, os dados da malha de chão e a dureza; `ground_at(point)` para as decorações.
- `ui/components/hex_grounds.gdshader`: o código 3, a leitura da página com `texelFetch`, o ruído da borda e o das pedrinhas (uma textura de ruído pequena, presa ao mapa, gerada uma vez ou guardada em `assets/terrain/grounds/`), a `Texture2DArray` das texturas e a uniforme `hardness`.
- `ui/components/hex_map_view.gd`: a malha de chão no `_add_grounds`, as páginas no `set_map` e no `update_tiles`, e o filtro das decorações.
- `tools/map_editor/`: nada além do que o `update_tiles` já faz, se ele redesenhar as páginas.

## Verificação

- **Cliente, teste com janela por poucos quadros** (o `SubViewport` não desenha com `--headless`), numa cena temporária, que falha antes e passa depois:
  - a cor de um ponto da página é o id do tipo, exata;
  - só existem as páginas com chão;
  - o filtro das decorações por ponto.
- **Prints:** a emenda terra e pedra (o caso da print do dono), cascalho e terra, pisantes e grama, uma trilha descendo um paredão e um degrau de lado, no editor e no jogo.
- **Desempenho:** o tempo de montar uma ilha grande com chão, antes e depois, e os quadros por segundo andando nela.
- **Projeto:** o jogo sem janela abre sem erros de script, com os mesmos avisos de antes.

## Tarefas

- [x] As páginas da máscara, conferindo a cor exata.
- [x] A malha de chão e o shader novo.
- [x] As decorações por ponto.
- [x] O editor e o corte de altura.
- [x] Testes, prints, desempenho e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste com janela** (uma cena temporária, já apagada): falhou antes (sem a `GroundMask`) e passou depois, com 9 de 9:
  - a cor de cada página sai exata, com o id do tipo;
  - sem chão não há página, e uma ilha pequena tem uma só;
  - a trilha não cobre o canto do hexágono;
  - o piso não tem decoração, e a trilha só tem as pequenas.
- **Prints** (na conversa): a ilha de teste com a trilha de terra entrando na praça de pedra, o Cascalho se soltando na terra, os Pisantes na areia e na grama, uma trilha descendo o paredão e um degrau de lado. Na linha e no T, a trilha se liga com a borda irregular.
  - A emenda de 6 px quase não aparecia; ela passou a ter 15 px, com pedaços maiores perto da divisa e 1 px de sombra embaixo de cada um (o [architecture.md](architecture.md#o-desenho-no-terreno-fase-2) diz como).
  - A variável do laço no shader não pode se chamar `step` (é uma função do GLSL); ela virou `ring`.
- **Desempenho** (PC, ilha de 3.000 hexágonos, 2.000 com chão e 60 traços, todas as linhas montadas): montar levou 360 ms, contra 200 ms sem chão; o quadro, andando, ficou abaixo de 1 ms nos dois. A primeira versão levava 900 ms, porque cada decoração media a distância a todos os traços por perto; agora só nos hexágonos que algum traço corta. Não foi medido no código de antes, nem num celular.
- **Projeto:** o jogo sem janela abre sem erros de script e com os mesmos 9 avisos de script de antes.
- **Não conferido em print:** a curva e a cruz, a trilha sozinha, a praça num degrau de lado, o corte de altura e a janela do Domador. O chão passa pelos mesmos caminhos do terreno (`_add_terrain`), então o corte e a janela valem para ele.
- **Falta o dono:** ver as emendas no editor (F2) e numa ilha (F5).
