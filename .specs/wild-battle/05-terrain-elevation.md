# 05. Elevação do terreno

- **Status:** concluída
- **Depende de:** [04-biome-surfaces](04-biome-surfaces.md)

## Contexto

Com as superfícies contínuas, o mapa ainda é plano. O dono quer o relevo do Sandwalkers: o terreno mais alto sobe de verdade, mostra um paredão na frente e esconde parte do que está atrás dele. Por enquanto são cinco níveis, de 0 a 4, com a água sempre embaixo e a montanha sempre em cima.

Esta fase muda só o desenho e o toque, que precisa acompanhar o que o jogador vê. O gerador e o contrato não mudam: o nível sai do bioma e da forma que o servidor já manda. Geometria e arquivos estão em [architecture.md](architecture.md#elevação).

## Escopo

- O nível de cada hexágono no `HexTile`.
- Superfícies, contorno e marcador na altura do nível.
- O paredão onde o vizinho da frente é mais baixo.
- O toque e o centro de cada hexágono na altura certa.
- `cliff.png` e a nova `side.png`.

## Fora do escopo

- Bloquear terreno: qualquer nível continua aceitando o jogador.
- Mudanças no gerador. A quantidade e o formato das montanhas continuam nos parâmetros de `map-config.ts`.
- Decorações, rampas, sombras projetadas e mais de cinco níveis.
- Animar o marcador ao subir ou descer.

## Requisitos

**Níveis**

- **RF-01:** `HexTile.level()` devolve 4 para a forma `mont`, 3 para o bioma `stone`, 2 para a forma `hill`, 1 para terra plana e 0 para água plana. Ilhas seguem a forma. Quem ocupa os níveis 2 e 3 é _a revisar_.
- **RF-02:** Cada nível tem uma altura fixa, múltipla de 8: 0, 8, 16, 24 e 32 px da arte.

**Desenho**

- **RF-03:** A superfície e o contorno de um hexágono sobem a altura do nível dele.
- **RF-04:** Dentro de um nível, a textura continua presa às coordenadas do mapa, sem a altura: hexágonos vizinhos do mesmo nível seguem contínuos.
- **RF-05:** Sob cada uma das duas bordas de baixo, aparece um paredão se o vizinho daquele lado for mais baixo. A altura dele é a diferença entre os dois níveis.
- **RF-06:** Onde não há vizinho, na borda do mapa, o paredão vai até a altura do nível mais a lateral de 26 px.
- **RF-07:** Vizinhos da mesma altura não têm paredão entre eles.
- **RF-08:** O terreno mais alto cobre o que está atrás dele, e nenhum fundo aparece entre hexágonos do mapa.
- **RF-09:** O paredão da pedra e da montanha usa `cliff.png`. Os outros usam `side.png`. A face da direita é mais escura que a da esquerda.

**Toque e câmera**

- **RF-10:** `surface_center(coord)` devolve o centro já na altura do hexágono, e o jogador fica sobre ele.
- **RF-11:** O toque vale para a superfície que está visível no ponto tocado, da mais alta para a mais baixa. Um toque em um paredão vale para o hexágono dele.
- **RF-12:** O toque em um vizinho visível move o jogador para ele. Um vizinho coberto em parte é tocado pela parte que aparece.
- **RF-13:** O modo de depuração continua cabendo o mapa inteiro, com o marcador sobre o jogador.

## Critérios de aceite

- [x] `HexTile.level()` devolve o esperado para água, terra, colina, pedra, colina na pedra, montanha e ilhas.
- [x] Hexágonos de cada nível aparecem na altura certa, e a textura deles bate com as coordenadas do mapa.
- [x] Há paredão entre níveis diferentes, inclusive de 8 px, com a altura da diferença.
- [x] Não há paredão entre vizinhos do mesmo nível, nem nas bordas de cima.
- [x] A face direita do paredão é mais escura que a esquerda.
- [x] A borda de baixo do mapa mostra a lateral.
- [x] Nenhum fundo aparece entre os hexágonos, em nenhuma combinação de níveis.
- [x] Toques caem na superfície visível, e um toque no paredão vale para o dono dele.
- [x] Na tela real, contra um servidor de teste, o jogador sobe e desce a montanha, fica no centro da tela e anda para todos os vizinhos.
- [x] Em janelas de 360×640, 405×720, 412×915 e 720×1061, o mapa continua em pixels inteiros.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/assets/terrain/surfaces/cliff.png`, com o `.import`.

**Alterar**

- `client/assets/terrain/surfaces/side.png`: passa a ter 512×64 px, como a `cliff.png`.
- `client/domain/models/hex_tile.gd`: `level() -> int`.
- `client/ui/components/hex_map_view.gd`: desenha nível por nível, do mais baixo para o mais alto, e `surface_center` e `coord_at` passam a usar a altura.
- `.specs/wild-battle/architecture.md`, `README.md` e `04-biome-surfaces.md`.

Desenhar do nível mais baixo para o mais alto basta para a ordem: um hexágono mais alto só pode cobrir um mais baixo, e o paredão termina exatamente na borda de cima do vizinho da frente, sem invadi-lo. Dentro de um nível, nada se sobrepõe.

**Reaproveitar**

As malhas da [04](04-biome-surfaces.md), com a textura presa à posição antes da altura. A tela do mapa não muda: ela já pergunta tudo ao `HexMapView`.

## Verificação

Uma cena temporária monta mapas à mão, com todas as combinações de níveis, e compara a tela com as texturas, pixel a pixel, nos quatro tamanhos. A verificação da tela real da [04](04-biome-surfaces.md) é adaptada para subir e descer a montanha. Uma amostra das capturas é aberta e revisada.

Passos do dono no editor (F5) e no celular:

1. Andar até uma montanha e conferir a altura dos paredões.
2. Conferir se dá para tocar nos vizinhos atrás da montanha.
3. Conferir a quantidade e o formato das montanhas.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Texturas do paredão.
- [x] Verificação temporária; ver falhar.
- [x] `HexTile.level()` (RF-01).
- [x] `HexMapView`: desenho (RF-02 a RF-09).
- [x] `HexMapView`: toque e câmera (RF-10 a RF-13).
- [x] Remover os arquivos temporários; atualizar `architecture.md`, o README da iniciativa e a [04](04-biome-surfaces.md); marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **Cinco níveis, múltiplos de 8:** a fase foi entregue com três níveis (0, 8 e 34), e o dono pediu 0, 8, 16, 24 e 32, com a montanha no último.
- **Quem ocupa os níveis do meio:** o dono definiu a água e a montanha. A colina ficou no 16 e a pedra no 24 por decisão do planejamento: a pedra forma regiões largas, e isso cria planaltos, como na referência. A colina de uma região de pedra fica no 24, para a região não ter buracos. É uma função só para trocar.
- **`level()` fica no cliente:** é só desenho e toque por enquanto, e o servidor já manda o bioma e a forma. Quando o nível decidir uma regra, como bloquear terreno, ele precisa passar para o servidor.
- **`coord_at` trocou o arredondamento pelo hexágono exato:** a conta antiga usava um hexágono 1 px menor que o desenhado, e a diferença aparecia na borda dos hexágonos elevados. A nova conta é menor e não precisa arredondar.
- **Um vizinho atrás da montanha é tocado pela parte que aparece:** o centro dele fica coberto. Foi conferido subindo em montanhas e andando para os seis vizinhos.
- **A `side.png` mudou de formato:** de 512×512 para 512×64, como a `cliff.png`.
- **Conferência:** a cena temporária falhou antes do código, com 17 falhas, e depois passou nos quatro tamanhos, sem pixel errado nas superfícies de todos os níveis, em dois mapas e num palco com montanha sobre terra, montanha sobre água e terra sobre água. A primeira rodada achou 54 pixels errados em 360×640, e a causa era a conta do `coord_at`, corrigida. Ficaram fora da comparação os pixels do contorno e uma faixa junto da borda de cada hexágono.
- **Tela real:** contra um servidor de teste, com o gerador de verdade, passou com 70 de 70 itens em cada tamanho, incluindo subir na montanha e andar para todos os vizinhos. A rodada de 405×720 usou a arte anterior do paredão; as outras três usaram a final. Das capturas, 5 foram abertas e revisadas.
- **Formato das montanhas:** com o gerador atual, as montanhas saem em cadeias finas, de um hexágono de largura, e cerca de 2,5% da água vira um pilar de montanha sozinho. Mudar isso é decisão do dono, em `map-config.ts` ou no gerador, e ficou fora desta fase.
- **Conferência dos cinco níveis:** a verificação falhou com 14 falhas antes da mudança, e depois passou nos quatro tamanhos, com superfícies comparadas nos cinco níveis e paredões de 8 e 16 px. A tela real passou com 70 de 70 itens em 405×720 e 720×1061; 360×640 e 412×915 só rodaram na versão de três níveis. Das capturas desta rodada, 3 foram abertas e revisadas.
- **A ordem de desenho mudou depois:** a [06](06-vegetation.md) trocou o desenho por nível pelo desenho por linha, porque uma planta baixa pode ficar na frente de um terreno alto.
- **Falta do dono:** jogar no editor e no celular, e conferir as alturas e a quantidade de montanhas. Nenhum celular foi testado.
- **Depois:** a [terrain-height](../terrain-height/README.md) trocou `HexTile.level()` pelo `height` que o servidor manda, e o paredão passou a sair do bioma.
