# 02. Tela da captura

- **Status:** concluída
- **Depende de:** [01-capture-rules](01-capture-rules.md)

## Contexto

O servidor já decide a captura. Falta o que o jogador vê (TELAS.md #6): as Esferas no painel de itens e o carregamento por cima da luta, a opção B que o dono escolheu entre 3 mockups animados. Não há arremesso nem tremidas.

## Escopo

- As Esferas no painel de itens da batalha.
- A cena do carregamento e o anel.
- O texto da captura no histórico e o resultado da luta.

## Fora do escopo

- Tela do Santuário.
- Mostrar a chance de captura.
- Pular a animação.
- Sons e arte final.
- Usar Esferas pela Mochila: fora da luta, elas continuam sem o botão Usar.

## Requisitos

**Painel de itens**

- **RF-01:** O painel de itens da batalha mostra as Esferas e os itens de cura, na ordem de `sort_order`, com o botão Usar.
- **RF-02:** Tocar em Usar em uma Esfera não abre a escolha do alvo: o painel fecha e a tela manda `{ "type": "capture", "item_id" }`.
- **RF-03:** Na Mochila, as Esferas continuam sem o botão Usar.
- **RF-04:** Uma recusa aparece no histórico em vermelho, sem animação, e o jogador continua podendo agir.

**Carregamento**

- **RF-05:** O evento `capture_attempted` abre a tela de carregamento por cima da luta, com o fundo escurecido.
- **RF-06:** A tela mostra a imagem da Esfera usada, com o sprite do inimigo acima dela e um anel em volta.
- **RF-07:** Durante o carregamento, o anel enche, o texto mostra "Entrando na Esfera..." e o sprite encolhe e desce até sumir na Esfera.
- **RF-08:** Com o anel cheio, o texto vira "Capturado!" ou, em vermelho, "Escapou!".
- **RF-09:** Se escapou, o sprite volta ao tamanho original.
- **RF-10:** O carregamento dura 3,5 s, e o resultado fica 1,2 s na tela, antes de a tela de cima fechar.
- **RF-11:** O voltar do Android não fecha a tela de carregamento nem interrompe o turno.
- **RF-12:** Os toques não chegam aos botões da luta enquanto a tela de carregamento está aberta.

**Depois do carregamento**

- **RF-13:** O histórico mostra "Você usou <Esfera>: <Ecobeast> foi capturado!" ou "Você usou <Esfera>: <Ecobeast> escapou!"
- **RF-14:** Com falha, os eventos do inimigo aparecem depois da linha, como em qualquer turno.
- **RF-15:** Com sucesso, o histórico mostra "<Ecobeast> entrou na equipe." ou "<Ecobeast> foi para o Santuário.", conforme `captured_to`, e o resultado da luta é "Capturado!".
- **RF-16:** Ao voltar, o jogador é relido, e o Hub mostra o novo Ecobeast quando ele entrou na equipe.

## Critérios de aceite

- [x] Com uma Esfera na Mochila, o painel de itens a mostra com a quantidade.
- [x] Sem itens, o painel continua com "Nenhum item para usar."
- [x] Com mais de um Ecobeast na equipe, a Esfera não pergunta o alvo.
- [x] O carregamento mostra a imagem da Esfera usada, não uma fixa.
- [ ] Sem sprite da espécie, o retrato com a forma provisória faz o mesmo movimento.
- [x] A resposta do servidor define o resultado: a tela não sorteia nada.
- [x] Depois de "Escapou!", o inimigo ataca, e a quantidade da Esfera diminuiu no painel.
- [x] Depois de "Capturado!", aparecem o resultado e o botão Voltar.
- [x] O novo Ecobeast aparece no Hub, e a próxima luta permite usar um Tônico nele.
- [x] Com 6 na equipe, o histórico diz que ele foi para o Santuário.
- [x] Sem resposta do servidor, a mensagem de erro aparece, e nenhuma animação começa.
- [x] O voltar do Android durante o carregamento não muda nada.
- [x] Em 360×640, 405×720, 412×915 e 720×1061, a tela de carregamento cabe, sem cortar a Esfera nem o texto.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/screens/battle/capture_overlay.tscn` e `.gd`: a tela por cima, com `CreaturePortrait`, `ItemIcon` e o anel. `play(item: Item, species_id: int, success: bool)` é aguardada com `await`, e o sprite é animado com `Tween`, a ferramenta do Godot que muda um valor aos poucos.
- `client/ui/components/capture_ring.gd`: o anel, um `Control` desenhado com `draw_arc`, nas cores de `UiPalette`, com a propriedade `value` de 0 a 1.

**Alterar**

- `client/domain/models/item.gd`: `can_capture()`, verdadeiro com `capture_bonus > 0`.
- `client/domain/models/battle_turn.gd`: `captured_to`.
- `client/screens/bag/bag_item_row.gd`: `offer_capture`, falso por padrão, mostra Usar também nas Esferas.
- `client/screens/battle/battle_items_panel.gd`: a ordem, as Esferas e o sinal `capture_chosen(item_id)`.
- `client/screens/battle/battle_narrator.gd`: `capture_attempted` e `describe_captured_to`.
- `client/screens/battle/battle_screen.gd` e `.tscn`: a tela por cima, `_show_turn` aguarda o carregamento antes de escrever a linha do evento, e `RESULT_TEXTS` ganha `captured`.
- `.specs/battle-screen/architecture.md`: o texto do evento.
- `.specs/roadmap.md`: `capture` concluída.
- `CLAUDE.md`: o Escopo atual cita a `capture`.
- `client/CLAUDE.md`: o `CaptureRing` na lista de componentes.

**Reaproveitar**

`CreaturePortrait`, `ItemIcon`, `BagItemRow`, `_act`, `_show_exit` e `UiPalette.OVERLAY`.

## Verificação

```bash
godot --headless -d --path client --quit-after 60
```

Uma cena temporária abre lutas contra um servidor de teste, com capturas certas e falhas forçadas, usa as Esferas pelos botões reais, confere os critérios automáticos e salva capturas de tela. As capturas abertas são citadas no relatório.

Passos do dono no editor (F5) e no celular:

1. Comprar Esferas na Loja.
2. Numa luta, usar uma Esfera com o inimigo de HP cheio e outra com HP baixo.
3. Conferir se o tempo do carregamento agrada.
4. Depois de capturar, conferir o novo Ecobeast no Hub e levá-lo para outra luta.

## Tarefas

- [x] Verificação temporária da tela; ver falhar.
- [x] Esferas no painel e a ação (RF-01 a RF-04).
- [x] Anel e tela de carregamento (RF-05 a RF-12).
- [x] Histórico e resultado (RF-13 a RF-16).
- [x] Remover os arquivos temporários; atualizar as specs citadas; marcar esta spec e as tabelas como `concluída`; commit `feat: tela da captura`.

## Decisões da implementação

- **O anel é desenhado, não uma imagem:** `CaptureRing` usa `draw_arc`, com as cores de `UiPalette`. A `TextureProgressBar` do Godot pediria duas imagens só para isso.
- **`CaptureOverlay.play` espera até fechar:** `_show_turn` faz `await` nela antes de escrever a linha do evento, e assim os eventos do inimigo só aparecem depois do carregamento.
- **O tempo do resultado inclui o sprite voltando:** a volta leva 0,25 s dentro de 1,2 s, para o resultado durar o mesmo com sucesso e com falha.
- **O voltar não precisou de código novo:** `handle_back` já não faz nada com o turno em andamento, e a conferência mostra isso.
- **Critério não exercitado:** as 9 espécies têm sprite, então o retrato com a forma provisória não apareceu no carregamento. O movimento é do nó `CreaturePortrait`, com ou sem sprite, mas isso não foi visto na tela.
- **Rede simulada:** a falta de servidor foi testada trocando o endereço da API por uma porta sem nada, sem cortar a rede de verdade.
- **Conferência:** uma cena temporária jogou lutas contra um servidor de teste, com capturas e fugas forçadas pela taxa da luta, e toques entrando como cliques reais pela janela. Passou com 50 de 50 verificações em janelas de 360×640, 405×720, 412×915 e 720×1061, depois de falhar porque as Esferas não apareciam e a tela de carregamento não existia. O carregamento mediu perto de 3,5 s, e o resultado, perto de 1,2 s, com folga de 0,4 s. Das 28 capturas de tela, 8 foram abertas e revisadas. Os arquivos temporários foram removidos. O teste no celular fica para o dono.
