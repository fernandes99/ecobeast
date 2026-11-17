# 02. O mapa grande

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [01](01-minimap.md)

## Contexto

O minimapa da [01](01-minimap.md) mostra só a volta do Domador. O dono quer, ao tocar nele, "um mapa grande da ilha inteira" para "ver onde estou, arrastar e dar zoom pela ilha", com "O Refúgio, a Loja e os NPCs" ([README](README.md#decisões)). Esta fase abre esse mapa por cima da tela de Explorar, com a mesma imagem e os mesmos marcadores.

## Escopo

- O painel `IslandMapPanel`, aberto pelo `Minimap.tapped`.
- O zoom, o arrasto, os ícones, a legenda e o Fechar.
- Parar a caminhada ao abrir e travar o mapa por baixo enquanto o painel está aberto.

## Fora do escopo

- Andar ou marcar destino tocando no mapa grande.
- Os ícones de missão e uma porcentagem descoberta.
- Guardar o zoom ou a posição do mapa grande entre aberturas.

## Requisitos

- **RF-01:** O painel `IslandMapPanel` (`res://screens/exploration/island_map_panel.gd`, `class_name IslandMapPanel`, um `Control` que cobre a tela e monta os filhos por código) fica na cena `exploration_screen.tscn` como último filho, escondido. Ele abre por `open(image, markers, discovery, show_all, player, title)` e fecha por `close_panel()`, com o sinal `closed`. Ele tem, de cima para baixo, dentro do `SafeArea`:
  - o nome da ilha num `NamePlatePanel`; no mapa sorteado, o texto "Mapa da zona";
  - a área do mapa, na moldura dourada (`frame.png` num `NinePatchRect`), que ocupa o espaço que sobra;
  - a legenda: o pino e "Você", e os ícones e os nomes "Refúgio", "Loja" e "NPC", só dos que existem no mapa;
  - o botão "Fechar".
  
  Por trás de tudo, um fundo `UiPalette.BACKGROUND` a 92% cobre o mapa de Explorar.
- **RF-02:** Tocar no minimapa abre o painel. Se o Domador estiver andando, a caminhada para onde ele está, sem rodar a ação do fim e sem completar o destino. Com o painel aberto, o toque, a pinça e a roda do mapa de Explorar não fazem nada (`_zoom_area` vazia e `_tap` ignorado).
- **RF-03:** O botão "Fechar" e o voltar do aparelho (`handle_back`, que devolve `true` com o painel aberto) fecham o painel e devolvem o mapa de Explorar como estava.
- **RF-04:** Ao abrir, o mapa grande mostra a imagem inteira (`MinimapImage`) na maior escala inteira em que ela cabe na área (no mínimo 1), centrada. A escala mínima (`fit`) é essa; a máxima é `fit × 3`.
- **RF-05:** A pinça de dois dedos (`PinchZoom`), a roda do mouse e os botões + e − mudam a escala de 1 em 1, entre a mínima e a máxima. A pinça e a roda mantêm parado o ponto sob o centro dos dedos ou o cursor; os botões, o centro da área. Os botões + e − ficam no canto de baixo à direita da área, e o que não pode mais mudar fica desabilitado.
- **RF-06:** Um dedo (ou o mouse apertado) arrasta a imagem. Ela não sai da área: com a imagem maior que a área, a borda dela não passa da borda da área; menor, ela fica centrada no eixo em que é menor.
- **RF-07:** A posição da imagem é sempre um número inteiro de pontos, e a escala é inteira, com `TEXTURE_FILTER_NEAREST`.
- **RF-08:** O mapa grande desenha os marcadores descobertos (os mesmos do minimapa, com o NPC onde está agora) e o pino do Domador, sempre em `MinimapArt.ART_SCALE` (3), em qualquer escala da imagem. Um ícone fora da área não aparece.
- **RF-09:** Com o "Debug: ver mapa inteiro" ligado, o mapa grande também mostra tudo, porque usa a mesma imagem.
- **RF-10:** Nada no painel muda a descoberta, a posição do Domador ou o servidor.

## Critérios de aceite

- [ ] Tocar no minimapa abre o mapa grande com a ilha inteira descoberta na tela, na moldura dourada, e o resto escuro, sem contorno da ilha.
- [ ] A pinça, a roda e os botões + e − mudam o zoom em degraus nítidos, até 3 vezes o inicial, e o mapa arrasta sem sair da moldura. (As contas passaram no teste, e o zoom pelos botões, na print; falta a pinça e o arrasto no celular.)
- [x] O Refúgio, a Loja e os NPCs descobertos aparecem com o ícone do mesmo tamanho em todo zoom; os escondidos, não.
- [x] A legenda mostra só o que existe no mapa.
- [ ] Abrir no meio de uma caminhada para o Domador, e tocar no mapa grande não o anda.
- [ ] Fechar e o voltar do aparelho devolvem o mapa de Explorar como estava.
- [ ] No mapa sorteado, o título é "Mapa da zona", sem ícones além do pino.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script.

## Desenho técnico

- **Criar:** `client/screens/exploration/island_map_panel.gd`.
- **Alterar:**
  - `client/screens/exploration/exploration_screen.tscn`: o nó `IslandMap` (o painel).
  - `client/screens/exploration/exploration_screen.gd`: o `Minimap.tapped`, parar a caminhada (um pedido de parar que o laço de `_walk` lê, como o `_next_point`), o `handle_back`, o `_zoom_area` e o `_tap`.
- **Reutilizar:** a `MinimapImage`, os `MapMarker`, o `MinimapArt` e o `PinchZoom`.

## Verificação

- **Teste sem janela** numa cena temporária, que falha antes e passa depois:
  - a escala inicial de uma imagem de 650×430 numa área de 680×900 é 1, e de uma de 200×150 é 3;
  - os botões e a roda param na mínima e na máxima;
  - o arrasto não deixa a borda da imagem passar da borda da área;
  - abrir com o Domador andando para a caminhada sem rodar a ação do fim.
- **Prints** numa janela de 720×1280: o mapa grande ao abrir e com zoom, numa ilha com Refúgio, Loja e NPC.
- **Fica para o dono:** a pinça e o arrasto no celular.

## Tarefas

- [x] Spec aprovada pelo dono.
- [x] O `IslandMapPanel`, com a escala, o arrasto e os ícones, e o teste.
- [x] A tela de Explorar: abrir, parar a caminhada, travar o mapa e fechar.
- [x] Prints, `client/CLAUDE.md` e as tabelas das specs.

## Resultado da verificação

Em 2026-11-16:

- **Teste sem janela** (na mesma cena temporária da [01](01-minimap.md), já apagada): falhou antes (sem o `IslandMapPanel`) e passou depois. Conferiu:
  - a escala inicial: 1 para uma imagem de 650×430 e 3 para uma de 200×150, numa área de 680×900, e nunca abaixo de 1;
  - o zoom parando no inicial e em 3 vezes ele;
  - o arrasto parando nas bordas, com o eixo menor centrado e a posição inteira;
  - o zoom mantendo o ponto sob o cursor.
- **Prints** (na conversa): o mapa grande de uma ilha de teste ao abrir e depois de dois degraus de zoom, com a moldura dourada, os ícones, a legenda só com o que existe e o Fechar.
- **Não conferido por Claude:** parar uma caminhada ao abrir e o voltar do aparelho, porque a tela de Explorar precisa da sessão do jogo. O código segue o RF-02 e o RF-03.
- **Falta o dono:** abrir pelo minimapa numa ilha de verdade, a pinça e o arrasto no celular, abrir andando e fechar pelo voltar.
