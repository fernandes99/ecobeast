# 03. Tela do mapa

- **Status:** concluída
- **Depende de:** [02-map-generator](02-map-generator.md)

## Contexto

Com a grade e o gerador prontos, falta o jogador chegar ao mapa. Esta fase cria a tela, o andar e o botão provisório, e troca o destino de Explorar zona. Daqui em diante, a batalha abre a partir do mapa e volta para ele.

## Escopo

- `start_exploration()` no `GameService`, no `ApiGameService` e no `Session`.
- A tela do mapa, com o marcador do jogador e o andar.
- O botão "Procurar Ecobeast".
- O destino de Explorar zona no Hub.
- A saída da batalha, que passa a dizer "Voltar".

## Fora do escopo

- Zoom, arrastar e destaque dos hexágonos vizinhos.
- Bloquear terreno, e encontros ao andar ou por bioma.
- Guardar a posição no servidor.
- Animação de andar do marcador e som.

## Requisitos

**Tela**

- **RF-01:** Tocar em "Explorar zona" no Hub abre a tela do mapa com `Router.push`.
- **RF-02:** Ao abrir, a tela mostra "Gerando mapa..." e chama `Session.start_exploration()`.
- **RF-03:** Com falha, a tela mostra o erro em `DangerLabel`, com "Voltar" disponível.
- **RF-04:** Com sucesso, o mapa aparece com o jogador em `start`.
- **RF-05:** O marcador é o retrato do primeiro Ecobeast da equipe, parado no centro da tela. Quem se move é o mapa.
- **RF-06:** Fora do mapa, o fundo é o da tela.
- **RF-07:** Não há zoom nem arrastar: gestos que não sejam um toque não mudam nada. A única exceção é o botão de depuração do RF-18.

**Andar**

- **RF-08:** Tocar em um hexágono vizinho do jogador move o jogador para lá.
- **RF-09:** O toque vale para o hexágono que contém o ponto tocado, pela geometria da grade. Se esse hexágono não for vizinho, ou não existir no mapa, nada acontece.
- **RF-10:** O passo é uma transição de `STEP_SECONDS`, de 0,18 s, _a revisar_. Toques durante o passo são ignorados.
- **RF-11:** Qualquer terreno aceita o jogador.
- **RF-12:** Ao fim do passo, o hexágono do jogador está no centro da tela, com a posição do mapa em pixels reais inteiros.

**Sair e lutar**

- **RF-13:** "Procurar Ecobeast" abre a batalha com `Router.push`, e fica desativado até o mapa aparecer.
- **RF-14:** Ao sair da batalha, a tela do mapa volta igual, com o jogador no mesmo hexágono. O Router só esconde a tela de baixo.
- **RF-15:** O botão de saída da batalha passa a dizer "Voltar".
- **RF-16:** "Voltar" e o voltar do Android levam ao Hub e descartam o mapa. Enquanto o mapa é pedido, os dois ficam parados, porque a resposta ainda vai chegar à tela.
- **RF-17:** Explorar zona de novo gera outro mapa.

**Depuração**

- **RF-18:** Só quando `OS.is_debug_build()`, depois que o mapa aparece, os controles mostram o botão "Debug: ver mapa inteiro". Na versão publicada, ele não existe para o jogador.
- **RF-19:** Tocar nele cabe o mapa inteiro acima dos botões, com o marcador sobre o hexágono do jogador, e o texto vira "Debug: voltar ao zoom normal".
- **RF-20:** Com o mapa inteiro na tela, tocar no mapa não move o jogador.
- **RF-21:** Tocar de novo volta à escala de pixels inteiros, com o jogador no centro.

## Critérios de aceite

- [x] Explorar zona abre o mapa, com o jogador em `start` e o retrato certo no centro.
- [x] Sem servidor, o erro aparece, e Voltar leva ao Hub.
- [x] Tocar em cada um dos seis vizinhos move o jogador para ele.
- [x] Tocar longe, no próprio hexágono ou fora do mapa não move o jogador.
- [x] Depois de andar, o mapa continua centrado no jogador.
- [x] Andar sobre água e montanha funciona.
- [x] Dois toques rápidos dão um passo só.
- [x] Arrastar o dedo sobre o mapa não o move.
- [x] Em 405×720 e nos tamanhos conferidos na [01](01-hex-grid.md), a arte continua em pixels inteiros depois de andar.
- [x] Procurar Ecobeast abre uma luta, e ao fim dela "Voltar" retorna ao mapa no mesmo hexágono.
- [x] Sem HP, Procurar Ecobeast mostra "Cure sua equipe no Refúgio.", e "Voltar" retorna ao mapa.
- [x] Voltar do mapa leva ao Hub, com o HP atualizado.
- [x] Explorar zona de novo devolve uma seed diferente.
- [x] Em build de debug, o botão mostra o mapa inteiro acima dos controles, com o marcador sobre o jogador.
- [x] Com o mapa inteiro, tocar não move o jogador, e voltar restaura escala, filtro e centro.
- [ ] O botão de debug não aparece na versão publicada (passo do dono, ao exportar).
- [ ] O mesmo vale em um aparelho com recorte (passo do dono).
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**, em `client/screens/exploration/`:

- `exploration_screen.tscn` e `.gd`: a tela. O mapa fica atrás, numa área que recorta o que passa das bordas e recebe os toques. Os botões ficam num `SectionPanel`, dentro de um `SafeArea`, por cima.

**Alterar**

- `client/core/services/game_service.gd` e `api_game_service.gd`: `start_exploration() -> Result`, com data: o `ExplorationMap`.
- `client/core/autoload/session.gd`: `start_exploration()`, sem guardar o mapa, como a batalha.
- `client/core/autoload/router.gd`: `&"exploration"` em `SCREENS`.
- `client/ui/components/hex_map_view.gd`: `coord_at(point: Vector2) -> Vector2i` e `snapped_to_pixels(value: Vector2) -> Vector2`.
- `client/screens/hub/hub_screen.gd`: o destino de "Explorar zona".
- `client/screens/battle/battle_screen.gd` e `.tscn`: `%HubButton` vira `%ExitButton`, com o texto "Voltar".
- `.specs/battle-screen/03-battle-screen.md`: uma nota dizendo que o botão mudou aqui.
- `.specs/onboarding/architecture.md`: `start_exploration` na lista de rotas.
- `TELAS.md`: a tela #4 passa a ser o mapa.
- `.specs/roadmap.md`: `wild-battle` concluída.
- `CLAUDE.md`: o Escopo atual cita a `wild-battle`.

**Reaproveitar**

`HexMapView`, `ExplorationMap`, `CreaturePortrait`, `SafeArea`, `OutlineButton`, `DangerLabel`. O movimento usa um `Tween`, o nó do Godot que muda um valor aos poucos, com `tween_method` para arredondar a posição a cada quadro.

## Verificação

Uma cena temporária, nos moldes da [heal-station/02](../heal-station/02-heal-screen.md), abre o mapa pelo Hub contra um servidor de teste, simula toques em cada vizinho, confere os critérios automáticos e salva capturas, todas abertas e revisadas. A falta de rede é simulada trocando o endereço do servidor, e o relatório diz isso.

Passos do dono no editor (F5) e no celular:

1. Tocar em Explorar zona e andar pelo mapa em várias direções.
2. Conferir se o tamanho dos hexágonos e o ritmo do passo estão bons.
3. Procurar um Ecobeast, lutar e voltar ao mapa.
4. Conferir o recorte do aparelho.

```bash
cd server && npm run start:dev
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Verificação temporária; ver falhar.
- [x] `start_exploration()`, o registro da tela e o Hub (RF-01, RF-02).
- [x] Tela, marcador e câmera (RF-03 a RF-07).
- [x] Andar (RF-08 a RF-12).
- [x] Procurar Ecobeast, a saída da batalha e o voltar (RF-13 a RF-17).
- [x] Remover os arquivos temporários; atualizar `TELAS.md`, o roadmap e o `CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`; commit `feat: mapa de exploração`.

## Decisões da implementação

- **Os botões ficam num `SectionPanel`:** a spec os punha soltos sobre o mapa, e as capturas mostraram o "Voltar", que é um botão de contorno, ilegível sobre os terrenos. O painel tem 92% de opacidade, o que basta para ler sobre qualquer terreno. O painel também recebe os toques, então tocar nele não move o jogador.
- **O toque usa a geometria da grade, não a distância em linha reta:** `coord_at` arredonda o ponto para a coordenada axial mais próxima. Na grade achatada deste sprite, isso acompanha melhor o desenho do hexágono do que medir a distância até o centro. O RF-09 foi reescrito por isso.
- **`snapped_to_pixels` no `HexMapView`:** a tela precisa arredondar a posição a cada quadro do passo, e quem conhece a escala da janela é o mapa.
- **Toque e arrasto:** o movimento acontece ao soltar, e só se o dedo tiver corrido até 24 pontos da tela lógica. Isso também impede um arrasto de virar um passo.
- **Conferência:** uma cena temporária abriu o mapa pelo Hub contra um servidor de teste, com toques entrando como cliques reais pela janela, e passou com 52 de 52 verificações em janelas de 360×640, 405×720, 412×915 e 720×1061, depois de falhar porque Explorar zona ainda abria a batalha. Ela cobre os seis vizinhos, toque longe e fora do mapa, toques rápidos, arrasto, roda do mouse, andar até água, montanha e borda, ida e volta da batalha, equipe sem HP e voltar ao Hub. Depois de andar, a tela foi comparada pixel a pixel com a arte, sem nenhuma diferença. Das 19 capturas da rodada final, 10 foram abertas e revisadas. A falta de rede foi simulada trocando o endereço do servidor. O servidor não mudou nesta fase, por isso os testes dele não foram repetidos. O jogo abriu sem erros nem avisos de script, e os arquivos temporários foram removidos.
- **Vão entre os hexágonos:** depois da entrega, o dono pediu um espaço entre os hexágonos e mandou um exemplo no Figma, com um print. O espaçamento foi medido no print, e não no Figma, que não foi aberto. Com passos de 34, 24 e 17, cada uma das 44 células do print bateu, pixel a pixel, com um sprite. A conferência acima foi repetida com esses passos: 54 de 54 verificações nos quatro tamanhos, e 3 das 19 capturas abertas e revisadas.
- **Modo debug:** o dono pediu um botão para ver o mapa inteiro, seguindo o padrão do "Apagar progresso" (`OS.is_debug_build()`). Reduzido cerca de 10 vezes, o mapa ficava granulado, por isso os sprites de terreno passaram a gerar mipmaps, que só o modo de depuração usa. A escala normal continua em pixels inteiros. Conferência: 66 de 66 verificações nos quatro tamanhos, e 2 capturas da versão final revisadas, em 405×720. A versão publicada não foi testada: as verificações rodam em build de debug.
- **Falta do dono:** jogar no editor e no celular, conferir o tamanho dos hexágonos, o ritmo do passo e o recorte do aparelho.
