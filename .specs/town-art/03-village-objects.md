# 03. Os objetos da vila no estilo novo

- **Status:** rascunho
- **Depende de:** [02-houses](02-houses.md)

## Contexto

Depois das casas, o resto da vila ainda vem do pacote Sunnyside. Esta fase redesenha os objetos de vila no `make_town.gd`, com os mesmos ids, formatos e variantes. A árvore, a pedra e a Vegetação são do ambiente e ficam como estão.

## Escopo

A arte nova destes tipos:

| id | slug | Formato | Variantes | Como fica (_a revisar_) |
| --- | --- | --- | --- | --- |
| 3 | `windmill` | par | 3, com 9 quadros | torre de pedra e madeira com pás girando; telhado laranja, verde e marrom |
| 7 | `garden` | um | 6 | canteiro com borda de madeira: abóbora, raízes, trigo, girassol, tubérculos e um em crescimento |
| 8 | `fence` | um | 2 | madeira e pedra, ligando-se às vizinhas, na folha de peças de hoje |
| 9 | `well` | um | 1 | poço de pedra com telhadinho de madeira e balde |
| 10 | `market_stall` | um | 3 | barraca de madeira com toldo listrado laranja, verde e roxo, com frutas |
| 11 | `cart` | um | 1 | carroça de madeira com caixotes |
| 13 | `beast_stable` | par | 2 | estábulo de madeira e de pedra, com feno |
| 16 | `trough` | um | 1 | cocho de madeira com água |
| 17 | `rune_shrine` | um | 4, com 16 quadros | pilar de pedra com o minério azul, de ouro, de prata e de carvão, com o brilho |

## Fora do escopo

- Árvore (5), pedra (6) e Vegetação (20).
- Mudar formato, bloqueio ou número de variantes.

## Requisitos

- **RF-01:** Cada tipo da tabela é desenhado pelo `make_town.gd`, seguindo o guia, com o mesmo formato, variantes e número de quadros de hoje.
- **RF-02:** O moinho e a barraca não usam vermelho nem azul no telhado e no toldo, que são do Refúgio e da Loja. As variantes 1 a 3 trocam de cor nessa ordem: o moinho de hoje vermelho, laranja e verde vira laranja, verde e marrom, e a barraca de hoje vermelha, verde e azul vira laranja, verde e roxa.
- **RF-03:** A Cerca guarda o formato da folha de peças (`fence/parts_<variante>.png`, 7 células de 96×72, com o centro em (48, 43)), e o `HexFences` não muda. A prévia `fence/<variante>.png` continua a peça reta, montada com as mesmas células.
- **RF-04:** Os animados têm os quadros lado a lado, cortados no mesmo topo e com o pé no mesmo lugar, e as velocidades de `FRAME_RATES` continuam.
- **RF-05:** O `make_objects.gd` fica só com `tree`, `rock` e `plants`.

## Critérios de aceite

- [ ] O gerador grava todos os tipos da tabela, com as variantes e os quadros de hoje.
- [ ] Numa imagem com todos lado a lado e o Domador, o traço é o mesmo das casas e das construções-chave.
- [ ] Uma fileira e um anel de cercas, de madeira e de pedra, se emendam como antes.
- [ ] As pás do moinho giram e o santuário brilha no jogo, sem pulo entre os quadros.
- [ ] Rodar o `make_objects.gd` depois não muda os PNGs da tabela.

## Desenho técnico

- `make_town.gd`: os tipos no `TYPES`, uma função `_draw_<slug>` para cada um e o `_fence_parts` com a folha de peças (as funções de hoje, `_fence_parts`, `_fence_post`, `_wood_arm` e `_stone_arm`, saem do `make_objects.gd` e são redesenhadas aqui).
- `make_objects.gd`: sobram `tree`, `rock` e `plants` e o que eles usam; o resto sai.
- `.specs/island-villages/architecture.md`: a tabela de tipos e o parágrafo da arte dizem que a cidade vem do `make_town.gd` e o ambiente do `make_objects.gd`.

## Verificação

```bash
godot --headless -s res://assets/map_objects/make_town.gd
godot --headless -s res://assets/map_objects/make_objects.gd -- <pasta do pacote>
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
```

Uma cena temporária com todos os objetos, uma fileira e um anel de cercas e o Domador, e um olhar no jogo para as animações.

## Tarefas

- [ ] Moinho, horta, poço, barraca, carroça, estábulo, bebedouro e santuário.
- [ ] A folha de peças da cerca.
- [ ] Enxugar o `make_objects.gd`.
- [ ] Conferir nas imagens e no jogo, e atualizar o `architecture.md` da island-villages e o `client/CLAUDE.md`.
