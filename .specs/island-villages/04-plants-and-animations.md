# 04. Vegetação, objetos animados e mais casas

- **Status:** concluída
- **Depende de:** [03-map-objects](03-map-objects.md), [map-editor/05](../map-editor/05-editor-ux.md)

## Contexto

Depois da revisão dos objetos, o dono pediu:

- tirar a casa na árvore;
- poder pôr à mão, onde quiser, as árvores e o capim que balançam com o vento nos biomas, sem mudar como eles nascem com o bioma;
- animar e consertar objetos: a pá de baixo do moinho saía cortada;
- trocar a casa 7, que ficava estranha;
- mais casas de 2 e 3 hexágonos;
- mais santuários de runas, com a pedra do topo centralizada (ela ficava para a esquerda).

O pacote Sunnyside tem as pás do moinho girando (9 quadros, a 10 por segundo), as árvores e os cogumelos balançando (4 quadros, a 4 por segundo) e um brilho que pisca (4 quadros, a 5 por segundo).

## Escopo

- O tipo Vegetação (id 20, `plants`), com as plantas do terreno.
- Objetos animados: moinho, árvore e santuário.
- Casa 7 nova, 5 casas médias e 5 casas grandes novas, 3 santuários novos.
- Sai a casa na árvore (id 14).

## Fora do escopo

- Mudar as decorações que nascem com o bioma (`HexDecorations.RECIPES`).
- Fumaça nas chaminés e outros efeitos do pacote.
- Pedras do terreno como objeto: a Vegetação só traz plantas.

## Requisitos

**Vegetação**

- **RF-01:** O tipo `plants` ("Vegetação") ocupa 1 hexágono e não bloqueia por padrão. As 10 variantes são combinações das plantas do terreno (`HexDecorations.PLANT_RECIPES`):
  1. árvore e capim;
  2. duas árvores;
  3. pinheiro e samambaias;
  4. três pinheiros;
  5. arbustos e capim;
  6. arbustos escuros e samambaias;
  7. flores e capim;
  8. capim;
  9. arbusto seco e capim seco;
  10. samambaias e capim.
- **RF-02:** No mapa (jogo e editor), as plantas da Vegetação são desenhadas como as do terreno, pelo `HexMapView`: a mesma folha, o mesmo vento e a mesma ordem de desenho com o Domador. Os lugares dentro do hexágono saem de um sorteio que depende só do hexágono e da variante, então a mesma ilha mostra sempre o mesmo. Espelhada, troca os lados. No hexágono da Vegetação, as plantas do bioma não aparecem, como em qualquer objeto, e o chão (trilha) não tira plantas dela.
- **RF-03:** A Vegetação não tem sprite no mapa. O PNG dela (`plants/<variante>.png`) é só a prévia do editor, com as plantas no hexágono (0, 0).
- **RF-04:** Trocar a variante ou o espelho de uma Vegetação no editor redesenha as plantas na hora.

**Animados**

- **RF-05:** Um objeto animado tem os quadros lado a lado no PNG da variante, cada um com a largura da célula do formato. O `MapObjectSprite` conta os quadros pela largura e anda neles na velocidade do tipo (`FRAME_RATES`: moinho 10, árvore 4, santuário 5 por segundo), cada objeto começando num ponto diferente do ciclo. O toque na arte confere o quadro da vez.
- **RF-06:** Moinho: o corpo do mapa de exemplo, sem as pás, com as pás do pacote girando por cima, no mesmo eixo; a pá de baixo cabe inteira.
- **RF-07:** Árvore: as 8 variantes balançam com os quadros do pacote, cogumelos incluídos.
- **RF-08:** Santuário de runas: o pilar e o minério centrados pelos pixels desenhados, com um brilho que pisca. As 4 variantes têm minério azul, de ouro, de prata e de carvão.
- **RF-09:** A prévia e os ícones do editor mostram o primeiro quadro.
- **RF-09b:** A arte que desce da borda de baixo de um objeto (a pá do moinho) passa por cima do chão da linha da frente. Só um hexágono da frente encostado no objeto e mais alto que ele cobre essa arte, como um degrau. Para isso, o objeto entra logo depois do chão da linha seguinte, por baixo das decorações e dos atores dela; com a frente mais alta, fica onde estava, antes das decorações da frente da própria linha.

**Casas**

- **RF-10:** A casa 7 passa a ser a torre com puxadinho do mapa de exemplo, com telhado laranja.
- **RF-11:** A casa média ganha 5 variantes (7 a 11): a casa comprida laranja, a casa comprida vermelha, a casa roxa grande em verde, a torre roxa com deck e escada (a da antiga casa na árvore) e a casa verde de dois andares.
- **RF-12:** A casa grande ganha 5 variantes (6 a 10): a casa azul grande em laranja, e o casarão laranja em vermelho, azul, verde e roxo.

**Banco**

- **RF-13:** A migration `20261114000000_map_objects_plants` cria a Vegetação, apaga as casas na árvore das ilhas e o tipo 14, e muda as variantes: santuário 4, casa média 11, casa grande 10. O seed espelha. Depois dela, roda o `recompute-island-hashes.ts`.

## Critérios de aceite

- [x] A Vegetação aparece na lista do editor, com prévia, e no mapa balança com o vento.
- [x] As pás do moinho giram, e a de baixo aparece inteira, por cima do chão da frente; com o hexágono da frente mais alto, ele cobre a ponta da pá.
- [x] As árvores balançam; o santuário tem o minério centrado e o brilho.
- [x] As casas novas aparecem na prévia, e a casa na árvore saiu.
- [x] A suíte do servidor passa, com o catálogo de 15 tipos.

## Desenho técnico

- `make_objects.gd`: `_sprite` devolve o quadro `_frame`; `TYPES` ganha o número de quadros dos animados; cada variante é desenhada uma vez por quadro e montada por `_strip`; `_put_centered` centra pelos pixels desenhados; `_draw_plants` desenha a prévia com o `HexDecorations`.
- `hex_decorations.gd`: `PLANTS_SLUG`, `PLANT_RECIPES` e `decorations_of_object`.
- `hex_map_view.gd`: a Vegetação não vira sprite, e `_add_decorations` usa as plantas dela no hexágono de apoio. `_place_object` põe o objeto depois do chão da linha seguinte, a não ser que `_front_is_higher`, e a linha seguinte montada depois reposiciona os objetos da anterior.
- `map_object_sprite.gd`: `cell_width`, `frame_count`, `first_frame`, a animação em `_process` e o toque no quadro da vez.
- `editor_canvas.gd`: o que cada hexágono com objeto mostra (tipo, variante e espelho) decide quais decorações refazer.
- `object_panel.gd`: prévia e ícones pelo primeiro quadro.

## Verificação

- A arte foi conferida numa folha de contato: o moinho tinha um fio de 1 px da casa vizinha na borda (recorte com 113 px de largura, corrigido para 112), a casa média 8 trazia caixotes e a 9 a ponte da casa ao lado (recortes trocados).
- Numa cena temporária, já apagada, o editor abriu a Vila de Ventoverde, pôs uma Vegetação de cada variante, um moinho e os 4 santuários (sem salvar), e duas imagens com 0,17 s de diferença mostraram as pás em outra posição.
- O dono viu a pá cortada pelo hexágono da frente, plano. Corrigido e conferido no editor: um moinho em grama plana, com a pá por cima do chão da frente e atrás das árvores dela, e o mesmo moinho com o hexágono da frente uma altura acima, que cobre a ponta.
- Havia 2 casas na árvore nas ilhas, e a migration as apagou; o `recompute-island-hashes.ts` mudou 2 hashes.
