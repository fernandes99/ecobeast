# 06. Vegetação no mapa

- **Status:** concluída
- **Depende de:** [05-terrain-elevation](05-terrain-elevation.md)

## Contexto

Com superfícies e relevo, o mapa ainda está vazio. O dono quer decorações em cada hexágono, como no Sandwalkers, começando só pela vegetação: árvores, arbustos, grama e flores. Pedras, construções e montanhas decorativas ficam para depois.

A vegetação é só enfeite: ela não muda terreno, encontro nem movimento. Por isso sai do cliente, a partir da seed do mapa, sem mudar o servidor. Geometria e arquivos estão em [architecture.md](architecture.md#decorações).

## Escopo

- A folha de sprites da vegetação.
- A escolha das plantas de cada hexágono, em `HexDecorations`.
- O mapa desenhado linha por linha, de trás para a frente, com as plantas de cada linha.

## Fora do escopo

- Pedras, construções, marcos e qualquer decoração que não seja planta.
- Animar as plantas com vento: veio na [12](12-plant-wind.md).
- Plantas na água.
- Esconder o marcador do jogador atrás de uma planta: veio na [11](11-depth-planes.md).

## Requisitos

**Sprites**

- **RF-01:** A vegetação fica em uma folha só, `res://assets/terrain/decorations/vegetation.png`, com células de 48×64 px e a base da planta no ponto (24, 60) da célula.
- **RF-02:** Cada tipo ocupa uma linha, com 4 variantes: `tree`, `pine`, `bush`, `dark_bush`, `tuft`, `flowers`, `fern`, `dry_shrub`, `dry_tuft` e `moss`.

**Escolha**

- **RF-03:** As plantas de um hexágono dependem só da seed do mapa, da coordenada e da superfície: a mesma seed repete as mesmas plantas.
- **RF-04:** Cada superfície tem a sua receita: `temperate` tem árvores, arbustos, flores e grama; `boreal` tem pinheiros, arbustos escuros e samambaias; `hill` tem arbustos secos e capim seco; `stone` e `mont` têm um pouco de musgo. A água não tem planta.
- **RF-05:** Parte dos hexágonos fica sem planta alguma, e a quantidade é _a revisar_.
- **RF-06:** Toda planta fica dentro do próprio hexágono, sem encostar na borda, e plantas do mesmo hexágono não se sobrepõem no ponto de apoio.
- **RF-07:** Árvores e arbustos deixam livre o centro do hexágono, onde o jogador fica.

**Desenho**

- **RF-08:** O mapa é desenhado linha por linha, de trás para a frente: cada linha desenha paredões, superfícies, contorno e, por último, as plantas dela, da mais de trás para a mais da frente.
- **RF-09:** Uma planta na frente de terreno mais alto aparece por cima dele. Uma planta atrás de terreno mais alto fica coberta por ele.
- **RF-10:** As plantas ficam na altura do hexágono, em pixels inteiros, e podem aparecer espelhadas.
- **RF-11:** Terreno, contorno, toque e câmera não mudam.
- **RF-12:** Fora da tela, uma linha não é desenhada, e as malhas dela só são montadas quando ela chega perto da tela.

## Critérios de aceite

- [x] A folha carrega, com 10 linhas e 4 colunas.
- [x] A mesma seed repete as plantas, e outra seed muda.
- [x] Cada superfície usa só os tipos da receita dela, e todos eles aparecem.
- [x] Água nunca tem planta, e parte dos hexágonos de terra fica vazia.
- [x] Toda planta fica dentro do hexágono, com folga da borda.
- [x] Árvores e arbustos não ocupam o centro do hexágono.
- [x] Uma árvore na frente de uma montanha aparece por cima do paredão.
- [x] Uma árvore atrás de uma montanha fica coberta por ela.
- [x] Sem as plantas, a tela continua igual às texturas, pixel a pixel, nos quatro tamanhos.
- [x] Na tela real, contra um servidor de teste, andar e tocar nos vizinhos continuam funcionando.
- [x] O mapa de 10.000 hexágonos abre sem travar a tela, e só parte das linhas é montada no início.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/assets/terrain/decorations/vegetation.png`, com o `.import`.
- `client/ui/components/hex_decorations.gd`: `class_name HexDecorations`, com `plants_of(tile, map_seed) -> Array[Plant]`.
- `client/ui/components/hex_row_view.gd`: `class_name HexRowView`, uma linha do mapa, que guarda as malhas e as desenha.

**Alterar**

- `client/ui/components/hex_map_view.gd`: um `HexRowView` por linha, no lugar das malhas por nível.
- `.specs/wild-battle/architecture.md` e `README.md`.
- `client/CLAUDE.md`: o caminho da folha.

Na [05](05-terrain-elevation.md), desenhar do nível mais baixo para o mais alto bastava. Com plantas, não basta: uma árvore baixa pode ficar na frente de uma montanha, e seria coberta por ela. Desenhar por linha resolve os dois casos, porque quem está mais à frente sempre vem depois. Cada linha é um nó: o Godot não desenha um nó que está fora da tela, e o mapa não paga pelas linhas que não aparecem.

As plantas de uma linha são uma malha só, com a folha inteira como textura: milhares de plantas custam um único desenho por linha.

**Reaproveitar**

As malhas da [04](04-biome-surfaces.md) e o `RandomNumberGenerator` do Godot, que repete a sequência com a mesma seed.

## Verificação

Uma cena temporária confere a escolha em milhares de hexágonos, compara a tela com as texturas sem as plantas nos quatro tamanhos e confere a ordem na frente e atrás de uma montanha. A verificação da tela real da [05](05-terrain-elevation.md) é repetida. Uma amostra das capturas é aberta e revisada.

Passos do dono no editor (F5) e no celular:

1. Andar pelo mapa e conferir a quantidade de plantas em cada bioma.
2. Conferir se dá para ler o terreno e os hexágonos com as plantas por cima.
3. Conferir se o marcador continua fácil de ver.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Folha de sprites (RF-01, RF-02).
- [x] Verificação temporária; ver falhar.
- [x] `HexDecorations` (RF-03 a RF-07).
- [x] `HexRowView` e o desenho por linha (RF-08 a RF-12).
- [x] Remover os arquivos temporários; atualizar `architecture.md`, o README da iniciativa e o `client/CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **A vegetação fica no cliente:** é só enfeite, e a seed do mapa basta para repeti-la. Se uma planta passar a importar para uma regra, como cobertura ou coleta, ela precisa ir para o servidor.
- **Uma folha só, e não um PNG por planta:** com a folha, as plantas de uma linha são um único desenho. Com um arquivo por planta, cada troca de textura quebraria o lote.
- **Uma folha de tamanho fixo:** cada tipo tem sempre 4 variantes, para a escolha não precisar de tabela por tipo.
- **Linhas sob demanda:** não estava na spec. A primeira versão montava tudo em `set_map`, e a montagem foi de 50 ms para 700 ms, por causa das centenas de malhas. Acelerar as contas por vértice quase não mudou o tempo; montar só as linhas perto da tela derrubou para cerca de 190 ms, em um mapa de 100 linhas. O `Transform2D` nas listas de vértices ficou, porque é mais simples e não custa nada.
- **Quem está no mesmo hexágono do jogador:** as árvores e os arbustos evitam o centro. O marcador ficava sempre por cima, e a [11](11-depth-planes.md) trouxe os planos.
- **As plantas são provisórias:** geradas por um script Python que não foi para o repositório, sem imagem de terceiros. Por isso não há questão de licença nelas.
- **Conferência:** a cena temporária não compilou antes do código, por faltarem as classes. Depois, passou nos quatro tamanhos: 4.000 hexágonos de cada superfície conferidos nas receitas e nos limites, a tela igual às texturas com as plantas tiradas, e, numa faixa de montanha entre florestas, 0 de 2.523 pixels aparecendo atrás dela e 3.607 de 3.899 na frente. Os que faltam são cobertos por outras plantas.
- **Tela real:** contra um servidor de teste, com o gerador de verdade, passou com 70 de 70 itens nos quatro tamanhos, com andar, toque, montanha e batalha. Das capturas, 4 foram abertas e revisadas.
- **Desempenho:** no computador de desenvolvimento, 1,3 ms por quadro, com 144 chamadas de desenho. Nenhum celular foi testado. Cada linha nova que chega perto da tela custa cerca de 7 ms aqui, o que pode pesar mais no celular.
- **Os nomes mudaram depois:** na [07](07-rocks.md), `vegetation.png` virou `decorations.png`, `plants_of` virou `decorations_of`, e `Plant` virou `Decoration`.
- **Falta do dono:** jogar no editor e no celular, conferir a quantidade de plantas em cada bioma, e decidir se as artes ficam.
