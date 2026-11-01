# 03. Tela do mapa

- **Status:** rascunho
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
- **RF-07:** Não há zoom nem arrastar: gestos que não sejam um toque não mudam nada.

**Andar**

- **RF-08:** Tocar em um hexágono vizinho do jogador move o jogador para lá.
- **RF-09:** O toque vale para o hexágono cuja superfície tem o centro mais perto do ponto tocado. Se esse hexágono não for vizinho, ou não existir no mapa, nada acontece.
- **RF-10:** O passo é uma transição de `STEP_SECONDS`, de 0,18 s, _a revisar_. Toques durante o passo são ignorados.
- **RF-11:** Qualquer terreno aceita o jogador.
- **RF-12:** Ao fim do passo, o hexágono do jogador está no centro da tela, com a posição do mapa em pixels reais inteiros.

**Sair e lutar**

- **RF-13:** "Procurar Ecobeast" abre a batalha com `Router.push`, e fica desativado até o mapa aparecer.
- **RF-14:** Ao sair da batalha, a tela do mapa volta igual, com o jogador no mesmo hexágono. O Router só esconde a tela de baixo.
- **RF-15:** O botão de saída da batalha passa a dizer "Voltar".
- **RF-16:** "Voltar" e o voltar do Android levam ao Hub e descartam o mapa. Enquanto o mapa é pedido, os dois ficam parados, porque a resposta ainda vai chegar à tela.
- **RF-17:** Explorar zona de novo gera outro mapa.

## Critérios de aceite

- [ ] Explorar zona abre o mapa, com o jogador em `start` e o retrato certo no centro.
- [ ] Sem servidor, o erro aparece, e Voltar leva ao Hub.
- [ ] Tocar em cada um dos seis vizinhos move o jogador para ele.
- [ ] Tocar longe, no próprio hexágono ou fora do mapa não move o jogador.
- [ ] Depois de andar, o mapa continua centrado no jogador.
- [ ] Andar sobre água e montanha funciona.
- [ ] Dois toques rápidos dão um passo só.
- [ ] Arrastar o dedo sobre o mapa não o move.
- [ ] Em 405×720, 720×1280 e 1080×1920, a arte continua em pixels inteiros depois de andar.
- [ ] Procurar Ecobeast abre uma luta, e ao fim dela "Voltar" retorna ao mapa no mesmo hexágono.
- [ ] Sem HP, Procurar Ecobeast mostra "Cure sua equipe no Refúgio.", e "Voltar" retorna ao mapa.
- [ ] Voltar do mapa leva ao Hub, com o HP atualizado.
- [ ] Explorar zona de novo devolve uma seed diferente.
- [ ] O mesmo vale em um aparelho com recorte (passo do dono).
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**, em `client/screens/exploration/`:

- `exploration_screen.tscn` e `.gd`: a tela. O mapa fica atrás, numa área que recorta o que passa das bordas e recebe os toques. Os botões ficam dentro de um `SafeArea`, por cima.

**Alterar**

- `client/core/services/game_service.gd` e `api_game_service.gd`: `start_exploration() -> Result`, com data: o `ExplorationMap`.
- `client/core/autoload/session.gd`: `start_exploration()`, sem guardar o mapa, como a batalha.
- `client/core/autoload/router.gd`: `&"exploration"` em `SCREENS`.
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

Uma cena temporária, nos moldes da [heal-station/02](../heal-station/02-heal-screen.md), abre o mapa pelo Hub contra um servidor de teste, simula toques em cada vizinho, confere os critérios automáticos e salva capturas nos três tamanhos, todas abertas e revisadas. A falta de rede é simulada trocando o endereço do servidor, e o relatório diz isso.

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

- [ ] Verificação temporária; ver falhar.
- [ ] `start_exploration()`, o registro da tela e o Hub (RF-01, RF-02).
- [ ] Tela, marcador e câmera (RF-03 a RF-07).
- [ ] Andar (RF-08 a RF-12).
- [ ] Procurar Ecobeast, a saída da batalha e o voltar (RF-13 a RF-17).
- [ ] Remover os arquivos temporários; atualizar `TELAS.md`, o roadmap e o `CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`; commit `feat: mapa de exploração`.
