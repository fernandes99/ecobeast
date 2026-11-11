# 02. Trilhas e pisos

- **Status:** concluída
- **Depende de:** [01-village-records](01-village-records.md)

## Contexto

Com a [01](01-village-records.md), cada hexágono de uma ilha pode guardar um chão, mas nada o desenha e o editor não o pinta. Esta fase traz a arte provisória dos 4 tipos de chão, o desenho no `HexMapView` e a ferramenta Chão no editor. O desenho está no [architecture.md](architecture.md#o-desenho-no-jogo).

## Escopo

- As texturas provisórias e o script que as gera.
- A trilha e o piso no `HexMapView`, com as ligações, a altura e o filtro de decorações.
- A ferramenta Chão no editor.

## Fora do escopo

- Objetos ([03](03-map-objects.md)).
- Chão no mapa sorteado.
- Trilha com mais de uma largura, ou cruzando água como ponte (a ponte é um objeto).

## Requisitos

### Arte

- **RF-01:** `res://assets/terrain/grounds/make_grounds.gd` gera `dirt_trail.png`, `stone_trail.png`, `cobble_floor.png` e `dirt_floor.png`. São texturas que emendam nas quatro bordas, no tamanho e na paleta das superfícies de hoje: terra batida com pedrinhas, lajes de pedra irregulares, paralelepípedos e terra lisa. Elas são provisórias.

### Desenho

- **RF-02:** um hexágono com trilha mostra uma faixa da textura do tipo. A faixa vai do centro até o meio de cada lado em que o vizinho tem qualquer chão, com 22 px de largura e a borda suavizada. Sem vizinho ligado, ela é um círculo de 22 px no centro.
- **RF-03:** um hexágono com piso mostra a textura do tipo no hexágono inteiro. Nos lados em que o vizinho não tem chão, há uma borda de 2 px mais escura. Num lado com trilha ligada, não há borda.
- **RF-04:** a textura do chão fica presa à posição no mapa: trilhas e pisos vizinhos seguem contínuos, como as superfícies.
- **RF-05:** o chão sobe com a superfície do hexágono. Dois hexágonos com chão se ligam na mesma altura, ou por um dos dois lados de baixo do mais alto, e aí a faixa continua pelo paredão até o pé dele. Nos outros lados com alturas diferentes, não há ligação, e a faixa termina arredondada.
- **RF-06:** num hexágono de piso, não nasce nenhuma decoração sorteada. Num de trilha, só `tuft`, `dry_tuft`, `flowers`, `pebbles` e `moss`.
- **RF-07:** trocar o chão de um hexágono no editor refaz ele e os vizinhos (`update_tiles`), porque as ligações dependem dos vizinhos.

### Editor

- **RF-08:** a ferramenta **Chão** entra logo depois de Altura, e as teclas passam a ir até 8. O bloco Chão mostra os 4 tipos como amostras em hexágono, como os biomas, e uma amostra **Sem chão**, que apaga. A frase da ferramenta é "Pinta trilhas e pisos sobre o terreno. Sem chão apaga.".
- **RF-09:** pintar com o pincel põe o chão escolhido nos hexágonos que existem. Desfazer e refazer guardam o chão.
- **RF-10:** a visão de cima mostra o chão como a cor média da textura dele, por cima da cor do bioma.

### Jogo

- **RF-11:** em Ilhas, as trilhas e os pisos aparecem como no editor.

## Critérios de aceite

- [x] Uma trilha pintada em linha, em curva, em T e em cruz se liga sozinha, sem emenda entre os hexágonos.
- [x] Uma trilha que chega numa praça entra nela.
- [x] Uma trilha sozinha é um círculo.
- [x] Uma trilha que desce um degrau continua pelo paredão.
- [x] Um piso não tem decoração, e uma trilha só tem as pequenas.
- [x] Apagar o chão de um hexágono refaz as ligações dos vizinhos.
- [x] Salvar, publicar e abrir a ilha em Ilhas mostra o mesmo chão.
- [x] Uma pincelada de raio 10 com chão não trava o editor, como na [map-editor/03](../map-editor/03-terrain-tools.md).
- [x] O projeto abre sem erros nem avisos de script novos.

## Desenho técnico

**Criar**

- `res://assets/terrain/grounds/make_grounds.gd` e as 4 texturas, com o `.import` (com `mipmaps/generate=true`, como as superfícies).
- `res://ui/components/hex_grounds.gd`: `HexGrounds`, que diz os lados ligados de um hexágono e monta os pontos da faixa e do piso. É o mesmo papel do `HexTransitions` para os arremates.

**Alterar**

- `res://ui/components/hex_map_view.gd`: a passada do chão no `_build_row`, depois dos arremates e antes do contorno; a faixa no paredão; o filtro de decorações do chão junto com o `allows_decoration` de quem usa o mapa.
- `res://tools/map_editor/editor_tools.gd`, `island_draft.gd` (o chão no estado do desfazer), `island_overview.gd` e `map_editor.gd` (a linha do ponteiro mostra o chão).
- `.specs/wild-battle/architecture.md`: o chão no desenho.

## Verificação

```bash
godot --headless -d --path client --quit-after 60
```

Uma cena temporária monta um mapa à mão com trilhas em linha, curva, T, cruz, sozinha e descendo um degrau, e uma praça com uma trilha chegando. Ela salva uma captura, que é aberta e revisada, e confere os lados ligados de cada hexágono. Depois, a pasta é apagada.

Passos no editor (F2):

1. Pintar uma vila com trilhas e uma praça.
2. Apagar trechos.
3. Desfazer e refazer.
4. Salvar, publicar e andar pela ilha em Ilhas.

## Tarefas

- [x] Script e texturas provisórias.
- [x] `HexGrounds` e a passada do chão no `HexMapView`, com o paredão e as decorações.
- [x] Ferramenta Chão, desfazer e visão de cima.
- [x] Verificação; atualizar a arquitetura; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **As texturas são geradas pelo Godot, e não por Python:** a versão em Python só com a biblioteca padrão levou mais de 10 minutos e foi abandonada. `make_grounds.gd` usa o ruído contínuo nas bordas do Godot (`FastNoiseLite.get_seamless_image`) para a terra. Para as pedras, usa um Voronoi próprio que repete nas bordas, porque o celular do Godot emendado deixava uma mancha no meio da textura. Gera as 4 em menos de 3 segundos.
- **Borda suavizada:** a faixa tem um miolo de 16 px e 3 px de cada lado que vão ficando transparentes, pela cor dos vértices. O círculo do centro faz a junta entre as faixas.
- **Três hexágonos com trilha, vizinhos entre si,** formam um triângulo de faixas com um pouco de grama no meio. É o resultado de ligar cada par, e ficou assim.
- **Piso num degrau:** um piso ligado ao vizinho de baixo cobre o paredão inteiro com a textura dele, como uma escada.
- **Verificação:**
  - Uma cena temporária, já apagada, conferiu:
    - o lado sem paredão sem ligar;
    - o degrau da frente ligando;
    - as decorações do piso e da trilha;
    - pintar e apagar o chão com o desfazer;
    - a cor na visão de cima.
  - Uma captura mostrou:
    - a trilha em linha, curva, T e cruz;
    - a trilha sozinha;
    - a praça com a borda e a trilha entrando;
    - a trilha descendo o paredão de um planalto.
  - A captura foi aberta e revisada.

**Falta do dono:** pintar uma vila no F2 e andar por ela em Ilhas.
