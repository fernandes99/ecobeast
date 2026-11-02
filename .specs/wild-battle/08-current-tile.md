# 08. Destaque do hexágono atual

- **Status:** concluída
- **Depende de:** [07-rocks](07-rocks.md)

## Contexto

O retrato do jogador fica parado no centro da tela, e nada no terreno mostra em qual hexágono ele está. Com árvores e rochas por perto, fica difícil ver o hexágono atual e, por ele, os vizinhos que dá para tocar.

O dono quer um contorno branco no hexágono atual, com uma sombra interna mais forte que o contorno comum. A referência é o contorno dos hexágonos selecionados no Sandwalkers. Geometria e ordem de desenho estão em [architecture.md](architecture.md#destaque-do-hexágono-atual).

## Escopo

- A textura do destaque, do tamanho do hexágono.
- `HexMapView.set_current(coord)`, que coloca o destaque naquele hexágono.
- A tela do mapa chamando esse método ao abrir e a cada passo.

## Fora do escopo

- Destacar os vizinhos que dá para tocar.
- Animação no destaque.
- Mudar o retrato do jogador.

## Requisitos

- **RF-01:** O hexágono atual tem um contorno branco de 2 px da arte, dentro do hexágono, e uma sombra escura que enfraquece em direção ao centro.
- **RF-02:** O destaque acompanha a altura do hexágono.
- **RF-03:** O destaque fica sobre o chão: acima da superfície e do contorno comum, e abaixo das decorações do hexágono e de tudo que está nas linhas da frente.
- **RF-04:** Só um hexágono tem destaque por vez. Ao andar, ele sai do anterior e vai para o novo no início do passo, junto com o toque.
- **RF-05:** O destaque aparece assim que o mapa abre, inclusive ao voltar da batalha.
- **RF-06:** Mudar o destaque não remonta nenhuma malha.
- **RF-07:** No modo de depuração do mapa inteiro, o destaque continua no hexágono do jogador, ainda que coberto pelo Domador.

## Critérios de aceite

- [x] O hexágono atual aparece com contorno branco em todos os níveis.
- [x] Os outros hexágonos continuam iguais às texturas.
- [x] Depois de um passo, o hexágono anterior volta ao normal.
- [x] Decorações do hexágono atual aparecem na frente do destaque.
- [x] Um hexágono mais alto na linha da frente cobre a parte do destaque que fica atrás dele.
- [x] Na tela real, contra um servidor de teste, o destaque acompanha o jogador, e andar e tocar nos vizinhos continuam funcionando.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/assets/terrain/surfaces/highlight.png`: 64×58 px, com `mipmaps/generate=true`.

**Alterar**

- `client/ui/components/hex_row_view.gd`: separa as malhas do chão das decorações, e desenha o destaque entre elas.
- `client/ui/components/hex_map_view.gd`: `set_current(coord)`.
- `client/screens/exploration/exploration_screen.gd`: chama `set_current` ao abrir o mapa e no início do passo.
- `.specs/wild-battle/architecture.md`, `README.md` e `client/CLAUDE.md`.

**Reaproveitar**

A linha de hexágonos da [06](06-vegetation.md). O destaque é desenhado dentro da linha do hexágono, então a ordem de trás para a frente já resolve quem cobre quem.

## Verificação

Uma verificação temporária confere os critérios nos quatro tamanhos, e a tela real roda contra um servidor de teste. Uma amostra das capturas é aberta e revisada.

Passos do dono no editor (F5) e no celular:

1. Abrir o mapa e conferir o destaque.
2. Andar por água, terra, colina, pedra e montanha.
3. Passar atrás de um morro e de uma árvore.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Verificação temporária; ver falhar.
- [x] Textura do destaque (RF-01).
- [x] `set_current` e o desenho na linha (RF-02 a RF-07).
- [x] Remover os arquivos temporários; atualizar `architecture.md`, o README da iniciativa e o `client/CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **Sombra escura, e não branca:** "sombra inset" serve para os dois tons, e os dois foram comparados no mapa. A escura é o sentido literal e deixa o contorno branco mais forte, inclusive sobre grama clara. Para trocar, basta pintar `highlight.png`.
- **O destaque muda no início do passo:** ele acompanha `_player_coord`, que muda no toque, e o mapa desliza depois.
- **O retrato cobre boa parte do destaque em telas pequenas:** em 405×720, um pixel da arte vale um pixel real, e o hexágono tem 64 px, quase a largura do retrato. Em 720×1061, o hexágono tem 128 px, e o destaque aparece inteiro.
- **A textura é provisória:** gerada por um script que não foi para o repositório, sem imagem de terceiros.
- **Conferência:** a verificação não compilou antes de `set_current`. Depois, passou nos quatro tamanhos: contorno em todos os níveis, um hexágono só por vez, nenhuma malha remontada, nada mudando fora do hexágono atual, a montanha da frente cobrindo o destaque, e as decorações na frente dele.
- **Tela real:** contra um servidor de teste, com o gerador de verdade, o destaque fica só no hexágono do jogador depois de andar e de voltar da luta, em 360×640 e 720×1061. Os números estão na [09](09-biome-transitions.md).
- **Falta do dono:** jogar no editor e no celular e dizer se a força da sombra está boa. Nenhum celular foi testado.
