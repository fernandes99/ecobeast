# 14. Andar até o hexágono tocado

- **Status:** concluída
- **Depende de:** [13-debug-menu](13-debug-menu.md), [island-villages/03](../island-villages/03-map-objects.md)

## Contexto

Até aqui, o Domador anda um hexágono por toque, e só para um vizinho. Para atravessar uma ilha, o jogador toca dezenas de vezes no hexágono ao lado. O dono quer tocar num hexágono distante e ver o Domador ir sozinho até lá, pelo caminho mais curto.

A posição do jogador continua só no cliente: o servidor não confere passo a passo, só a confere ao Procurar ([biome-encounters](../biome-encounters/)). Por isso a rota também é calculada no cliente.

## Escopo

- Tocar em qualquer hexágono do mapa leva o Domador até ele, pelo caminho com menos hexágonos, desviando dos bloqueados.
- Tocar num bloqueado de longe leva o Domador para um hexágono livre ao lado dele e, se ele tiver ação, executa a ação ao chegar.
- Trocar de destino no meio do caminho.

## Fora do escopo

- Mostrar a rota no mapa antes ou durante a caminhada.
- Custo por terreno ou altura: todo hexágono livre custa 1, como no passo de um hexágono.
- Bloqueio por terreno (água, montanha): continua valendo só o bloqueio dos objetos.
- Mudar o servidor.

## Requisitos

- **RF-01:** Tocar num hexágono livre que não é o do Domador calcula o caminho com menos hexágonos até ele, sem passar por bloqueados (`ExplorationMap.path_to_any`). O Domador anda o caminho um passo por vez, com a mesma corrida, direção, plano e câmera do passo de um hexágono, sem parar entre os passos.
- **RF-02:** Tocar num bloqueado vale para os hexágonos livres ao lado dele (`ExplorationMap.free_sides`). Se ele estiver cercado, valem os livres ao lado de qualquer hexágono do mesmo objeto. O Domador vai até o mais perto deles. Se ele já estiver num deles, não anda.
- **RF-03:** Quando o bloqueado tocado tem ação, ela é executada quando o Domador chega ao lado dele, ou na hora, se ele já estiver ao lado (como antes). Um bloqueado sem ação só leva o Domador até ao lado.
- **RF-04:** O toque na arte de um objeto continua valendo para o hexágono dele ao lado do Domador, com o de ação primeiro. Longe dele, vale o hexágono do objeto mais perto do toque.
- **RF-05:** Pisar no hexágono de um Domador NPC no meio do caminho para a caminhada ali, e a fala aparece, como num passo de um hexágono.
- **RF-06:** Passar por um hexágono de ação no meio do caminho não abre nada. A tela da ação só abre se o caminho terminar nele, vindo de fora dela (como o passo de um hexágono, na [islands/03](../islands/03-island-screens.md)).
- **RF-07:** Ecobeasts selvagens no caminho não param a caminhada. Procurar continua sendo o único jeito de enfrentar um.
- **RF-08:** Um toque durante a caminhada troca o destino: o Domador termina o passo atual e segue para o novo, sem executar a ação do destino antigo.
- **RF-09:** Sem caminho até o destino, o Domador não sai do lugar, e a tela mostra "Não dá para chegar lá.".
- **RF-10:** Procurar, o mapa inteiro e o spawn do menu de depuração continuam recusando agir enquanto o Domador anda, como já faziam no passo de um hexágono.

## Critérios de aceite

- [x] Na Vila de Ventoverde, tocar num hexágono livre a 5 hexágonos leva o Domador até ele.
- [x] Tocar num objeto de 1 hexágono de longe deixa o Domador ao lado dele.
- [x] Tocar na Loja de longe leva o Domador para o lado dela e abre a tela da Loja.
- [x] Um toque no meio do caminho troca o destino; com o novo destino bloqueado, ele para ao lado.
- [x] O caminho contorna uma parede de objetos e fica vazio para um destino cercado ou bloqueado.
- [ ] Pisar num Domador NPC no meio do caminho para ali, com a fala (passo do dono).
- [x] O projeto abre sem erros nem avisos de script novos.

## Desenho técnico

**Alterar**

- `client/domain/models/exploration_map.gd`: `path_to_any(from, goals)`, uma busca em largura pelos vizinhos livres que para no primeiro hexágono de `goals` e devolve o caminho sem o `from`; e `free_sides(coord)`.
- `client/screens/exploration/exploration_screen.gd`: `_tap` escolhe o destino, `_go_to` monta os objetivos e a rota, `_walk` anda passo a passo e decide o fim (Domador NPC, novo destino, ação tocada ou ação de chegada), e `_step_to` passa a ser só o passo. O novo destino de um toque durante a caminhada fica em `_next_target`.
- `README.md`, `architecture.md` e `client/CLAUDE.md`.

**Conceito do Godot**

Uma função com `await` vira uma corrotina: chamada sem `await`, ela roda até o primeiro `await` e devolve o controle, e o resto continua quando o sinal esperado chega. `_walk` usa isso para esperar cada passo (`await _step_to(coord)`) sem travar a tela, e o toque seguinte só guarda o novo destino.

## Verificação

Uma cena temporária, já apagada, montou um mapa de 6×6 com uma parede de objetos e conferiu `path_to_any` e `free_sides`. Outra abriu o jogo de verdade contra o servidor local, entrou na Vila de Ventoverde (ilha 331), simulou os toques e salvou imagens:

- um hexágono livre a 5 de distância: o Domador chegou nele;
- o poço (objeto de 1 hexágono) a 4: ele parou ao lado;
- um toque no caminho de volta, trocado por um destino bloqueado: ele parou ao lado do novo;
- a Loja, de longe: ele parou ao lado dela e a tela `shop` abriu.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] `path_to_any` e `free_sides`, com a verificação temporária.
- [x] O toque, a caminhada e a troca de destino na tela (RF-01 a RF-10).
- [x] Conferir no jogo, na Vila de Ventoverde.
- [x] Remover os arquivos temporários; atualizar o README, `architecture.md` e o `client/CLAUDE.md`.
