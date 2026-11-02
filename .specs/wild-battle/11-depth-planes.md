# 11. Planos de profundidade

- **Status:** concluída
- **Depende de:** [10-tamer-sprite](10-tamer-sprite.md)

## Contexto

O Domador fica por cima de tudo no mapa. Parado no meio de um hexágono, ele aparece na frente de uma árvore que está, no chão, mais perto da câmera do que ele.

O dono quer planos: o Domador fica na frente do que está atrás dele e atrás do que está na frente, com a metade de baixo do hexágono como divisa. O desenho está em [architecture.md](architecture.md#planos-de-profundidade).

## Escopo

- Dividir as decorações de cada linha em duas partes, pela metade do hexágono.
- O Domador como filho do mapa, entre as duas partes da linha dele.
- Trocar de plano ao andar.

## Fora do escopo

- Plano por decoração, comparando a posição a cada quadro.
- Mostrar o Domador quando ele estiver coberto, com silhueta ou transparência.
- Mudar a quantidade de árvores.
- Planos para outros personagens: ainda não há nenhum no mapa.

## Requisitos

- **RF-01:** Uma decoração com ponto de apoio acima do centro do hexágono fica atrás do Domador; do centro para baixo, fica na frente.
- **RF-02:** Decorações e terreno das linhas da frente cobrem o Domador. As das linhas de trás ficam atrás dele.
- **RF-03:** Em um passo para a frente, o Domador muda de plano no início do passo. Em um passo para trás, ao chegar. Na mesma linha, não muda.
- **RF-04:** Mudar de plano não remonta nenhuma malha.
- **RF-05:** O Domador continua parado na tela, em pixels reais inteiros, com a mesma densidade do mapa.
- **RF-06:** Quem usa o plano é qualquer nó filho do mapa: `set_actor_row(actor, row)`.
- **RF-07:** O modo de depuração do mapa inteiro continua com o Domador sobre o jogador, sem encolher.

## Critérios de aceite

- [x] Cada linha tem as decorações de cima em um nó e as de baixo em outro, sem perder nenhuma.
- [x] O Domador fica entre as duas partes da linha, indo para a frente ou para trás.
- [x] Na tela, a planta da metade de baixo e a da linha da frente cobrem o Domador.
- [x] Na tela, a planta da metade de cima e a da linha de trás ficam atrás dele.
- [x] Nos seis vizinhos, o plano no passo e ao chegar está certo.
- [x] Andar, tocar, voltar da luta e o modo de depuração continuam funcionando.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Alterar**

- `client/ui/components/hex_map_view.gd`: `_front_rows`, um segundo `HexRowView` por linha; `set_actor_row`; `art_scale`; `_add_decorations` dividindo pela metade do hexágono.
- `client/screens/exploration/exploration_screen.tscn`: `PlayerMarker` passa a ser filho de `MapView`.
- `client/screens/exploration/exploration_screen.gd`: plano no início e na chegada do passo, posição do Domador em `_move_map` e escala em `_fit_view`.
- [06-vegetation](06-vegetation.md), [10-tamer-sprite](10-tamer-sprite.md), `architecture.md` e `README.md`.

**Conceito do Godot**

Em 2D, os nós são desenhados na ordem da árvore de cenas: quem vem depois fica por cima. `move_child` muda essa ordem sem recriar nada. O `z_index` faria o mesmo, mas é global na camada: com um valor alto, o mapa passaria por cima dos botões.

## Verificação

Uma verificação temporária compara os pixels onde o Domador e uma planta se cruzam, com cada caso em um hexágono cercado de água, e confere as fases anteriores. A tela real roda nos quatro tamanhos, contra um servidor de teste, com o gerador de verdade.

Passos do dono no editor (F5) e no celular:

1. Andar em volta de uma árvore no campo.
2. Entrar em uma floresta densa e ver se dá para achar o Domador.
3. Andar para a frente e para trás perto de plantas.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Verificação temporária; ver falhar.
- [x] Dividir as decorações (RF-01, RF-02, RF-04, RF-06).
- [x] Tela do mapa (RF-03, RF-05, RF-07).
- [x] Remover os arquivos temporários; atualizar `architecture.md` e o README da iniciativa; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **Duas partes por linha, e não um plano por decoração:** o centro do hexágono é onde o Domador para, então a metade do hexágono já é a divisa certa. Comparar cada decoração a cada quadro exigiria remontar ou desenhar uma por uma.
- **Filho do mapa, e não uma camada por cima:** copiar as decorações da frente para uma camada acima do Domador desenharia o tronco de uma árvore por cima do morro que está na frente dela. Dentro do mapa, a ordem das linhas resolve tudo sozinha, inclusive o terreno.
- **Mudança de plano no passo:** indo para a frente, a linha nova cobriria os pés dele, então ele muda antes de sair. Voltando, é a linha de onde ele veio que cobriria, então ele muda ao chegar. Por 0,36 s, uma planta perto do caminho pode trocar de lado de uma vez, sem transição.
- **Centro da tela em tela de tamanho ímpar:** em 405×720, o centro cai em 202,5 pixels reais. O mapa e o Domador arredondavam separados, e, em uma simulação de 73.205 posições, cerca de metade dos hexágonos deixava os pés 1 pixel real fora do centro. A falha apareceu uma vez na tela real, mudando com o mapa sorteado. Agora a posição do mapa parte do centro já arredondado, e a simulação deu 0 fora, nos seis tamanhos.
- **Conferência:** a verificação quebrou antes de `_front_rows`. Depois, nos quatro tamanhos: quem devia cobrir cobriu em 100% dos pixels onde o Domador e a planta se cruzam, nos quatro casos; 349 plantas divididas sem perder nenhuma; e a tela real passou com 93 de 93, contra um servidor de teste, com o gerador de verdade. A verificação das fases 04 a 09 continua passando, e o projeto abre sem erros nem avisos.
- **Desempenho:** em um mapa de 10.000 hexágonos, a linha mais lenta levou de 10 a 12 ms, e a média ficou em 7,4 ms. O quadro custa 0,7 ms, com 202 chamadas contra 187 antes. A montagem total ficou em 220 ms.
- **Em floresta densa, ele some bastante:** em 21 hexágonos de `boreal`, medidos no centro, em média 75% do Domador aparece, e o pior caso mostra 6%. Em 5 dos 21, aparece menos da metade. É o efeito pedido, mas pode atrapalhar. Se atrapalhar, o caminho é uma silhueta dele por cima das árvores, ou menos pinheiros no `boreal`. O dono decide depois de jogar.
- **Mudou depois:** na [12](12-plant-wind.md), as decorações de cima saíram de `_rows` para `_back_rows`, porque o vento é um material e vale para o nó inteiro. O ator continua entre as duas partes das decorações.
- **Falta do dono:** jogar no editor e no celular. Nenhum celular foi testado.
