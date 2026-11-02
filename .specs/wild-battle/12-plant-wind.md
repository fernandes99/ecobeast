# 12. Vento nas plantas

- **Status:** concluída
- **Depende de:** [11-depth-planes](11-depth-planes.md)

## Contexto

O Domador já anda, mas o mapa em volta dele está parado. O dono quer animar as decorações: as plantas balançam com o vento, em uma onda que atravessa o mapa, e as rochas ficam paradas. O balanço é feito por código, sem arte nova. O desenho está em [architecture.md](architecture.md#vento).

## Escopo

- Um shader que desloca cada linha de pixels das plantas.
- Quanto cada tipo de planta balança.
- Um terceiro nó por linha do mapa, só para as decorações de cima.

## Fora do escopo

- Quadros desenhados para as plantas.
- Plantas reagindo ao Domador.
- Folhas, borboletas ou qualquer outro detalhe solto no mapa.
- Vento diferente por bioma, por horário ou com controle do jogador.
- Animar água, terreno ou rochas.

## Requisitos

- **RF-01:** `tree`, `pine`, `bush`, `dark_bush`, `tuft`, `flowers`, `fern`, `dry_shrub` e `dry_tuft` balançam. Rochas, `pebbles` e `moss` ficam parados.
- **RF-02:** O ponto de apoio e a sombra ficam parados, e o topo da planta é o que mais anda.
- **RF-03:** Cada linha de pixels anda um número inteiro de pixels da arte: a planta nunca borra.
- **RF-04:** O balanço fica dentro da folga da célula: a planta nunca é cortada nem mostra a célula vizinha.
- **RF-05:** O vento é uma onda: plantas próximas balançam quase juntas, e a onda anda pelo mapa, com a força mudando devagar.
- **RF-06:** Todas as plantas no mesmo ponto da onda vão para o mesmo lado, mesmo as espelhadas.
- **RF-07:** O balanço não remonta nenhuma malha e não roda GDScript a cada quadro.
- **RF-08:** Os planos da [11](11-depth-planes.md), o destaque da [08](08-current-tile.md), andar, tocar e o modo de depuração do mapa inteiro continuam iguais.
- **RF-09:** Uma arte nova na mesma folha balança sem mudar o shader, e um tipo novo só precisa de uma linha em `KIND_SWAY`.

## Critérios de aceite

- [x] Em um conjunto de quadros, o topo de uma árvore anda, e a base não.
- [x] Toda linha da planta na tela é a linha da folha deslocada por um número inteiro, nunca maior que o máximo do tipo.
- [x] Uma rocha e um musgo não mudam em nenhum quadro.
- [x] Uma planta e a mesma planta espelhada, no mesmo ponto da onda, andam igual em todos os quadros.
- [x] Plantas a 20 px na direção do vento, como duas do mesmo hexágono, andam quase sempre para o mesmo lado, e plantas a meia onda de distância quase sempre para lados opostos.
- [x] Em todas as variantes de cada tipo, a folga da célula é maior que o máximo do tipo.
- [x] O número de malhas não muda enquanto as plantas balançam.
- [x] A verificação das fases 04 a 11 continua passando.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/ui/components/plant_wind.gdshader`: o vento.

**Alterar**

- `client/ui/components/hex_decorations.gd`: `WIND_SHADER_PATH` e `KIND_SWAY`.
- `client/ui/components/hex_map_view.gd`: `_back_rows`, o terceiro `HexRowView` por linha; `_wind_material`, um material só para os nós de decorações; os dados de cada planta na malha.
- `client/ui/components/hex_row_view.gd`: sem decorações na linha do chão, o destaque é desenhado por último, e `ground_meshes` sai.
- `client/CLAUDE.md`, `architecture.md`, `README.md`, [06-vegetation](06-vegetation.md) e [11-depth-planes](11-depth-planes.md).

**Conceito do Godot**

Um shader é um programa curto que roda na placa de vídeo, uma vez para cada pixel desenhado. Um `ShaderMaterial` liga esse programa a um nó. A hora vem de `TIME`, dentro do próprio shader, então o GDScript não faz nada a cada quadro. Parâmetros com `uniform` podem ser mudados de fora, sem tocar no shader.

O material vale para o nó inteiro, e não para cada malha. Por isso as decorações saem do nó do chão e ganham um nó só delas.

## Verificação

Uma verificação temporária monta plantas escolhidas em um mapa de água, tira quadros durante alguns segundos e compara cada linha da tela com a folha. A verificação das fases anteriores roda com o vento desligado, para continuar comparando pixels. A tela real roda nos quatro tamanhos, contra um servidor de teste, com o gerador de verdade.

Passos do dono no editor (F5) e no celular:

1. Parar no campo e na floresta e olhar o vento por alguns segundos.
2. Conferir se o balanço está forte ou fraco demais, e se distrai.
3. Andar perto das plantas e conferir os planos.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Verificação temporária; ver falhar.
- [x] Separar as decorações de cima em um nó próprio (RF-07, RF-08).
- [x] Shader e dados das plantas (RF-01 a RF-06, RF-09).
- [x] Tela real e desempenho.
- [x] Remover os arquivos temporários; atualizar `architecture.md`, o README da iniciativa, o `client/CLAUDE.md` e as specs afetadas; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **Por código, e não por quadros:** o shader não exige arte nova e vale para qualquer folha que entrar depois. Quadros desenhados fariam as folhas mexerem de verdade, mas multiplicariam a folha por 3 ou 4, e a arte final também precisaria deles. A troca é que a copa anda em bloco: o movimento fica um pouco rígido.
- **Um nó a mais por linha:** o material vale para o nó inteiro, e as decorações de cima dividiam o nó com o chão. Com um nó próprio para elas, o chão não passa pelo shader, e `ground_meshes` deixou de ser necessário.
- **`CUSTOM0`, e não a cor dos vértices:** quatro números reais por vértice, sem a perda de precisão de guardar posição em uma cor de 8 bits. Com isso, os comprimentos das ondas mudam no shader, sem remontar a malha.
- **A fase vem do ponto de apoio, e não do pixel:** a planta inteira fica no mesmo ponto da onda.
- **`z` negativo na planta espelhada:** a textura dela corre ao contrário, e sem isso ela balançaria contra o vento.
- **O shader ignora `modulate`:** ele troca a cor final pela da folha. Nada no mapa usa `modulate` hoje. Quem quiser escurecer as plantas precisa multiplicar no shader.
- **O balanço é a revisar:** `KIND_SWAY` e os parâmetros do shader são um primeiro chute. O teste confere a medida, não a sensação: só jogando dá para saber se está forte, fraco ou se distrai.
- **Conferência:** a verificação quebrou antes de `KIND_SWAY`. Depois, nos quatro tamanhos, com 40 quadros em 6 s: o topo da árvore e o capim passaram pelas 5 posições, de -2 a 2 pixels, a base não andou, nenhuma linha fugiu de um deslocamento inteiro, a rocha e o musgo não mudaram, a planta espelhada andou igual nos 40 quadros, plantas a 20 px concordaram em 102 de 103 quadros, e plantas a meia onda em 0 de 119. A folga mínima das plantas é de 6 px, contra 2 px de balanço. A verificação das fases 04 a 11 continua passando, com 149 itens por tamanho, e o projeto abre sem erros nem avisos. Das capturas, as do vento, do mapa inteiro e uma comparação ampliada de dois quadros foram abertas e revisadas.
- **Tela real:** contra um servidor de teste, com o gerador de verdade, passou com 93 de 93 em seis rodadas: três em 405×720 e uma em cada outro tamanho.
- **Uma falha na tela real, que era do teste:** em uma rodada de 405×720, o Domador não andou para 2 dos 6 vizinhos de uma montanha. O ponto que a verificação tocava caía exatamente em um canto de hexágono, onde um arredondamento de 0,00001 pixel decide o dono. Em uma simulação, 82 de 28.000 toques erraram assim, todos em alvos de nível 0, e com o toque no meio do pixel o número foi a 0 nos quatro tamanhos. A simulação não repetiu os 2 vizinhos da mesma rodada, só 1 por montanha, e o mapa daquela rodada não ficou guardado. O vento não mexe no toque. Um dedo que acerte esse canto no jogo pode ir para o vizinho, o que é aceitável.
- **Desempenho:** em um mapa de 10.000 hexágonos, a linha mais lenta levou de 9 a 10 ms, com média de 6 ms, a montagem total ficou entre 176 e 192 ms, e o quadro custa 0,4 ms, com 180 chamadas. Não piorou em relação à [11](11-depth-planes.md), mas o shader roda em cada pixel de planta, e isso pesa mais em celular. Nenhum celular foi testado.
- **Falta do dono:** jogar no editor e no celular, e ajustar a força do vento.
