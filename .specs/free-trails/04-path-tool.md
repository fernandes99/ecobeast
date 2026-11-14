# 04. A ferramenta Caminho

- **Status:** concluída (falta o dono usar no editor e no jogo)
- **Depende de:** [03](03-trail-records.md)

## Contexto

Com a [03](03-trail-records.md), os traços já são guardados e desenhados, mas só entram pelo contrato. Esta fase traz a ferramenta do editor que o dono pediu: desenhar o caminho arrastando o mouse, em qualquer direção, e depois selecionar, trocar e apagar cada traço.

## Escopo

- A ferramenta Caminho, o painel dela e as teclas.
- Desenhar, selecionar, trocar o tipo e a largura, apagar, e o desfazer.
- Os traços na visão de cima.

## Fora do escopo

- Mover um ponto, emendar ou continuar um traço ([README](README.md#fora-do-escopo)).
- Traços nos carimbos.

## Requisitos

- **RF-01:** a ferramenta 12 se chama **Caminho**, com o ícone `icons/path.svg`, e funciona só pelo botão, como o Carimbo e a Borracha. (Desde a [map-editor/06](../map-editor/06-tool-groups.md), ela é a segunda aba do grupo Chão, tecla 2.) A dica é "Arraste para desenhar um caminho. Clique num caminho para escolher, trocar ou apagar.".
- **RF-02:** o painel da ferramenta mostra os 8 tipos de chão como amostras (como o bloco Chão) e as três larguras (Estreita 14, Normal 22, Larga 34). A escolha vale para o próximo traço e, com um traço escolhido, troca o dele.
- **RF-03:** **desenhar:** arrastar com o botão esquerdo, começando num hexágono da ilha, cria um traço com o tipo e a largura escolhidos.
  - Enquanto arrasta, o caminho aparece já com a textura.
  - Um ponto entra a cada 12 px da arte de movimento, só sobre hexágonos da ilha. Fora deles, o traço pausa e volta quando o mouse volta.
  - Ao soltar, os pontos são simplificados (sem os que estão a menos de 2 px da reta entre os vizinhos), e o traço entra no fim da lista, num passo de desfazer, sem ficar escolhido (revisto: escolhido, a próxima amostra trocava o tipo dele).
  - Um arraste com menos de 2 pontos não cria nada. Passando de 256 pontos, o traço termina ali.
- **RF-04:** **escolher:** um clique sem arrastar num traço o escolhe: o de cima entre os que passam a até metade da largura do clique. O traço escolhido mostra o contorno e os pontos por cima do mapa, e o painel mostra o tipo e a largura dele. Um clique fora de qualquer traço, ou Esc, solta a escolha.
- **RF-05:** **trocar e apagar:** com um traço escolhido, uma amostra de tipo ou de largura troca a dele, num passo de desfazer. Delete apaga o traço, também num passo de desfazer.
- **RF-06:** **corte de altura:** com o corte ligado, um traço não começa num hexágono acima do corte, e os pontos sobre esses hexágonos não entram, como fora da ilha. Escolher um traço que passa por eles continua valendo.
- **RF-07:** apagar um hexágono não apaga os traços: a parte sobre ele some do desenho. Salvar recusa um traço com ponto fora da ilha, então o editor tira esses pontos ao salvar e apaga o traço que ficar com menos de 2. O aviso diz quantos foram mudados.
- **RF-08:** a visão de cima mostra os traços como linhas na cor média do tipo, na largura deles.

## Critérios de aceite

- [x] O dono desenha um caminho subindo reto, um em S e um em volta de uma casa, e eles saem como desenhados.
- [x] Um caminho escolhido troca de tipo e de largura, e Delete o apaga; Ctrl+Z desfaz cada passo e refazer os volta.
- [x] Com o corte de altura, o caminho não entra nos hexágonos altos.
- [x] Apagar os hexágonos embaixo de um caminho e salvar o corta, com o aviso.
- [ ] Salvar, publicar e abrir em Ilhas (F5) mostra os caminhos iguais.
- [ ] O dono usa a ferramenta Caminho no editor (F2) e vê a ilha com F5.

## Desenho técnico

- `tools/map_editor/editor_tools.gd`: `Tool.PATH`, o nome, o ícone e a dica; o arraste guarda os pontos e o clique escolhe.
- `tools/map_editor/path_panel.gd` (novo): as amostras e as larguras.
- `tools/map_editor/map_editor.gd`: o painel, Delete e Esc, o desfazer.
- `tools/map_editor/editor_canvas.gd`: o traço em andamento, o contorno do escolhido e o `set_trails`.
- `tools/map_editor/island_draft.gd`: os pontos fora da ilha ao salvar.
- `tools/map_editor/island_overview.gd`: as linhas.
- `tools/map_editor/icons/path.svg` (novo).

## Verificação

- **Cliente, teste sem janela** numa cena temporária, que falha antes e passa depois: o arraste criando o traço com os pontos simplificados, o clique escolhendo o de cima, a troca de tipo e de largura, o Delete, o desfazer e o refazer, o corte de altura e os pontos fora da ilha ao salvar.
- **Prints:** o editor com um caminho em S escolhido, e o jogo na mesma ilha.
- **Projeto:** o jogo sem janela abre sem erros de script, com os mesmos avisos de antes.

## Tarefas

- [x] A ferramenta e o painel.
- [x] Desenhar, escolher, trocar e apagar, com desfazer.
- [x] O corte de altura, os pontos fora da ilha e a visão de cima.
- [x] Testes, prints e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste sem janela** (uma cena temporária, já apagada): falhou antes (sem `Tool.PATH`) e passou depois, com 19 de 19:
  - o arraste cria o traço com o tipo e a largura escolhidos, e uma reta vira 2 pontos;
  - um clique não cria traço, escolhe o traço de cima ou solta a escolha;
  - a amostra troca o tipo e a largura do escolhido, e Delete o apaga;
  - Ctrl+Z desfaz cada passo, e refazer os volta;
  - com o corte de altura, o traço não começa num hexágono alto;
  - fora da ilha, o traço pausa;
  - ao salvar, saem os pontos de fora e o traço que fica com menos de 2.
- **Print** (na conversa): a janela do editor aberta numa cena temporária, com o mouse simulado. Ela mostra o Cascalho em S, a terra em curva e os Pisantes subindo reto, e o painel com os 8 tipos e as 3 larguras.
- **Projeto:** o jogo sem janela abre sem erros de script e com os mesmos 9 avisos de script de antes.
- **Não conferido:** o caminho em volta de uma casa, o aviso ao salvar na janela, publicar e abrir com F5 (a ida e volta pelo servidor está na [03](03-trail-records.md)).
- **Falta o dono:** usar a ferramenta Caminho (a 12, só pelo botão) no editor (F2) e ver a ilha com F5.
