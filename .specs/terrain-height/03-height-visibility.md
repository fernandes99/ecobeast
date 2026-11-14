# 03. Ver o que a altura esconde

- **Status:** concluída (falta o dono usar no editor e no jogo)
- **Depende de:** [02](02-eleven-heights.md) e [free-props/04](../free-props/04-stamps.md)

## Contexto

Na [02](02-eleven-heights.md), a altura passou a ir de 0 a 10, e o nível 10 sobe 80 px. Em 2026-11-14, o dono mostrou um planalto de altura 10 com buracos e disse que, no editor, não consegue escolher o hexágono que fica atrás de uma coluna alta, e que no jogo não veria o Domador dentro de um buraco.

O dono pediu duas coisas:

- **No editor**, um modo que mostra e edita só a altura de 0 a 4. Os hexágonos de 5 ou mais ficam transparentes e fora da edição. O outro modo é o de hoje, de 0 a 10.
- **No jogo**, o terreno alto que está na frente do Domador fica transparente, para ver o Domador atrás de uma montanha.

Claude propôs que, no jogo, a regra seja "o que tapa o Domador" em vez de "altura maior que 4": uma coluna de altura 3 logo na frente já esconde as pernas, e uma de altura 8 longe, de lado, não atrapalha. Como o mapa é desenhado em pedaços de linha e não hexágono por hexágono, a transparência vem de uma janela em volta do Domador. O dono aprovou.

Hoje, o `HexMapView.coord_at` escolhe a superfície mais alta sob o ponto, da altura 10 para a 0. O jogo usa essa função no toque, e o editor no ponteiro, fora da visão de cima. Cada pedaço de linha é um `HexRowView`, com o material `_terrain_material` (o shader `hex_grounds.gdshader`). As decorações e as peças soltas ficam nas 4 faixas de decoração da linha.

## Escopo

- O corte de altura no editor: os modos "Tudo" e "Até 4".
- A janela transparente em volta do Domador no mapa de Explorar zona, no sorteado e nas ilhas.

## Fora do escopo

- O tabuleiro da luta.
- Deixar transparentes os objetos, as peças soltas e as decorações na frente do Domador: eles já entram na frente ou atrás dele pelas faixas de profundidade.
- A janela em volta dos Domadores NPC e dos Ecobeasts do mapa.
- Escolher o nível do corte: ele é fixo em 4.
- Mostrar a altura na visão de cima do editor.
- Lembrar o modo do corte entre uma abertura do editor e outra.

## Requisitos

### Editor

- **RF-01:** O topo do editor ganha o botão "Altura: tudo" / "Altura: até 4", que alterna os dois modos, e a tecla H faz o mesmo. O editor abre no modo Tudo, que é o de hoje.
- **RF-02:** No modo Até 4, os hexágonos de altura 5 ou mais (acima do corte, `HexMapView.CUT_HEIGHT = 4`) são desenhados com 25% de opacidade (`GHOST_ALPHA`). Os objetos com algum hexágono acima do corte ficam com a mesma opacidade. As peças soltas e as plantas dos hexágonos acima do corte não aparecem.
- **RF-03:** No modo Até 4, o ponteiro passa pelos hexágonos acima do corte. Ele escolhe a superfície mais alta, até a altura 4, que contém o ponto. Se nenhuma contém, ele escolhe o hexágono da posição sem altura, como hoje.
- **RF-04:** No modo Até 4, nenhuma ferramenta muda um hexágono acima do corte nem o que está nele:
  - o pincel pula esses hexágonos;
  - Remover hexágono não os tira;
  - Pôr hexágono não troca o bioma nem a altura deles;
  - a Área e a Ação não os pintam;
  - o início do Domador não vai para eles;
  - um objeto com algum hexágono acima do corte não é escolhido, movido, espelhado nem apagado;
  - uma peça solta com o pé acima do corte não é escolhida, e uma peça arrastada não entra num hexágono acima do corte (ela fica no último ponto que valia);
  - o Carimbo trata os hexágonos acima do corte como se não fossem da ilha: eles ficam como estão, o contorno fica amarelo, e um objeto do carimbo que tocaria num deles não entra.

  Pintar a altura 5 ou mais num hexágono de até 4 vale: ele vira transparente na hora.
- **RF-05:** Trocar de modo é só visual: não entra no desfazer nem marca a ilha como alterada.

### Jogo

- **RF-06:** No mapa de Explorar zona, a janela é o retângulo da arte do Domador, com 4 px de folga (`REVEAL_MARGIN`), e só vale acima da linha dos pés dele. Dentro dela, o terreno das linhas da frente do Domador (as de número maior que a linha dos pés dele) é desenhado com 20% de opacidade (`REVEAL_ALPHA`). Era 40% na proposta; nos prints, o Domador ficava apagado, como um fantasma, e Claude baixou para 20%.
  - Entram as linhas que um hexágono de altura 10 ainda pode subir até cobrir o Domador (`REVEAL_ROWS`, a conta sai de `LEVEL_HEIGHTS` e da altura da arte do Domador).
  - O terreno é o paredão, o tampo, o chão e as transições, desenhados pelo material do terreno das linhas.
  - A borda da janela é reta, em pixels inteiros, sem esfumado.
- **RF-07:** A janela anda com o Domador a cada quadro, inclusive enquanto ele sobe ou desce na caminhada. Quando nada na frente o cobre, ela não muda nada na tela.
- **RF-08:** Um toque dentro da janela passa pelos hexágonos das linhas da frente que ela deixa transparentes e vai para o que aparece atrás deles. Um toque fora da janela continua como hoje.

## Critérios de aceite

- [x] No modo Até 4, a ilha do print do dono mostra o fundo dos buracos, e o pincel pinta nele.
- [x] No modo Até 4, nenhuma ferramenta muda um hexágono de altura 5 ou mais. Trocar de modo não entra no desfazer.
- [x] No jogo, o Domador atrás de uma coluna de altura 10 e dentro de um buraco aparece pela janela. Andando em campo aberto, nada muda na tela.
- [ ] O dono usa o corte no editor (F2, tecla H) e anda atrás de uma montanha com F5.

## Desenho técnico

**Alterar:**

- `ui/components/hex_map_view.gd`:
  - **O corte:** `height_cut` (−1 desligado, ou a altura máxima editável), `CUT_HEIGHT`, `GHOST_ALPHA`, e `coord_at(point)` respeitando o corte.
  - **Os pedaços acima do corte:** com o corte ligado, o `_build_row` monta os hexágonos acima do corte em malhas à parte do mesmo `HexRowView` (`ghost_meshes`), desenhadas depois das outras com a cor `GHOST_ALPHA` no `draw_mesh`. As faixas de decoração recebem só os hexágonos de até 4 e as peças com o pé neles. Ligar ou desligar o corte remonta os pedaços (`_rebuild_all`). As camadas de um mesmo hexágono somam um pouco de transparência, e nos prints isso não incomodou, então não precisou de `CanvasGroup`.
  - **Os objetos acima do corte:** o `set_objects` põe `GHOST_ALPHA` no `modulate` dos objetos com algum hexágono acima do corte.
  - **A janela do jogo:** `set_reveal(rect, feet_row)` e `clear_reveal()`. As linhas da frente, até `REVEAL_ROWS`, usam uma cópia do material do terreno com a janela ligada, e as outras usam o de sempre. Mudar a linha dos pés troca os materiais. Mudar o ponto só troca o uniforme.
  - **O toque na janela:** `coord_at` ganha a opção de pular os hexágonos das linhas da frente quando o ponto está dentro da janela.
- `ui/components/hex_grounds.gdshader`: os uniformes `reveal_rect` (em pixels da arte, que é o espaço da linha), `reveal_on` e `reveal_alpha`. Ligada a janela, o `fragment` multiplica o `COLOR.a` dentro do retângulo. As malhas que não usam a janela passam direto, como hoje.
- `screens/exploration/exploration_screen.gd`: onde ela já chama `set_actor_depth`, chama também `set_reveal` com o retângulo da arte do Domador (`TamerSprite`) e a linha dos pés. O toque usa o `coord_at` que respeita a janela.
- `tools/map_editor/map_editor.gd`: o botão no topo e a tecla H. `editor_canvas.gd` repassa o corte ao `HexMapView` e expõe `is_editable(coord)`.
- `tools/map_editor/editor_tools.gd`, `object_panel.gd` e `stamp.gd`: o filtro do RF-04. O `Stamp.place` ganha um `Callable` opcional que diz quais hexágonos da ilha valem.

O servidor e o banco não mudam.

## Verificação

- Um teste sem janela, numa cena temporária, que falha antes e passa depois:
  - o `coord_at` com e sem corte, num planalto de 10 com um buraco de 0;
  - as ferramentas no modo Até 4: pincel, Remover, Pôr hexágono, objeto, peça arrastada e carimbo na beira de um hexágono alto;
  - trocar de modo sem passo de desfazer;
  - a troca de materiais das linhas da frente quando a linha dos pés muda.
- Prints com janela:
  - do editor nos dois modos, com a ilha do print do dono refeita;
  - do jogo com o Domador atrás de uma coluna de 10, dentro de um buraco e em campo aberto.
- O jogo sem janela abre sem erros de script, com os mesmos avisos de antes.

## Tarefas

- [x] Spec.
- [x] O corte no `HexMapView` e o `coord_at`.
- [x] O modo no editor e o filtro das ferramentas.
- [x] A janela no shader e na tela de exploração.
- [x] Testes, prints e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste sem janela** (uma cena temporária, já apagada, com o catálogo do servidor local): falhou antes (sem `CUT_HEIGHT`, `REVEAL_ROWS`, `set_reveal`, `editable` e o `Stamp.place` com 5 argumentos) e passou depois, com 23 de 23.
  - **No mapa:** num planalto de 10 com um buraco de 0, sem corte o ponto do fundo do buraco dá um hexágono da frente, e com o corte dá o buraco. As linhas com hexágonos acima do corte ganham as malhas transparentes, e desligar o corte volta ao de antes.
  - **Na janela:** só as 4 linhas da frente dos pés usam o material da janela, e trocar a linha dos pés troca os materiais. O toque dentro da janela passa pelas linhas da frente, e fora dela continua igual.
  - **Nas ferramentas:** com o corte, o pincel do Bioma pula os hexágonos altos. Remover não os tira, e o início não vai para eles. Pintar a altura 7 num baixo vale. Um objeto novo não entra num alto e entra num baixo, e um objeto num alto não é escolhido. Uma peça num alto não é escolhida, e uma arrastada não entra num alto. O carimbo não muda o chão de um alto.
  - **Trocar de modo:** o `toggle_height_cut` só muda o desenho e as ferramentas, sem passar pelo `EditorHistory`, então não entra no desfazer.
- **Prints com janela**, na conversa:
  - um planalto de 10 com dois buracos, nos modos Tudo e Até 4: no Até 4, o fundo dos buracos aparece;
  - o Domador dentro de um buraco, atrás de uma coluna de 10 e em campo aberto, sem e com a janela.
- **Projeto:** o jogo sem janela abre sem erros de script e com os mesmos 9 avisos de antes. O servidor não mudou.
- **Falta o dono:**
  - usar o corte no editor (F2, botão "Altura" no topo ou tecla H);
  - andar atrás de uma montanha e dentro de um buraco com F5.
