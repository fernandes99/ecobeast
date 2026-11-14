# map-editor

O editor de ilhas: uma janela só de desenvolvimento, em 16:9, para o dono criar no PC os mapas fixos do jogo e salvá-los no banco. Uma ilha é um mapa de hexágonos feito à mão, com vários biomas e com as cidades dentro dela. O editor pinta o terreno, põe as construções (Refúgio, Loja, Arena, casas) sobre os hexágonos, diz quais Ecobeasts aparecem em cada parte da ilha e marca onde o Domador chega. Cada ilha fica como rascunho até o dono publicar.

Jogar nas ilhas é a iniciativa seguinte, a `islands` (veja "Depois desta iniciativa"). Esta iniciativa entrega o editor e as ilhas guardadas no banco, sem nenhuma mudança para o jogador.

A ideia é do dono, em 2026-11-10.

## Contexto

O que já existe e esta iniciativa reaproveita:

- **O gerador de mapas** ([wild-battle](../wild-battle/architecture.md#gerador)): `generateMap(seed, config)`, em `server/src/domain/exploration/map-generator.ts`, uma função pura. Os parâmetros (`MapConfig`, em `map-config.ts`) dizem quantos hexágonos, quanta água, quanta pedra, quando a umidade vira floresta, quando a crista vira colina e montanha. Hoje eles são fixos (`DEFAULT_MAP_CONFIG`) e cada exploração gera um mapa de 10.000 hexágonos com uma seed sorteada.
- **O hexágono do mapa:** `q` e `r` axiais, `biome` (`temperate`, `boreal`, `stone`, `wshallow`, `wdeep`), `shape` (`flat`, `hill`, `mont`) e `variant`. O servidor não guarda os hexágonos de uma exploração, só os Ecobeasts, os Domadores e a posição.
- **O desenho do mapa:** `HexMapView` (`res://ui/components/hex_map_view.gd`) desenha um `ExplorationMap` com as superfícies, a elevação, as transições e as decorações, como o jogador vê em Explorar zona.
- **Uma janela só de desenvolvimento** ([content-viewer](../content-viewer/architecture.md#a-janela)): F1 abre uma janela do sistema (`Window` com `force_native`) por cima do jogo, só quando o jogo roda pelo editor do Godot (`OS.has_feature("editor")`). Ela usa os autoloads do jogo, e assim o catálogo e a sessão de quem está logado.
- **As telas das construções:** Refúgio (`heal_station`) e Loja (`shop`) já existem e abrem pelo Hub.

## Objetivos

1. O dono cria uma ilha do zero ou a partir do gerador, ajustando os parâmetros e a seed.
2. Ele pinta o terreno, põe construções e áreas de Ecobeasts e marca a chegada, e vê a ilha como o jogador vai ver.
3. A ilha fica guardada no banco como rascunho, e só passa a valer para o jogo quando ele publica.
4. Ninguém além do dono consegue gravar ilhas, mesmo chamando a API sem o jogo.

## Decisões

Do dono, em 2026-11-10:

| Decisão | Motivo |
| --- | --- |
| Os mapas feitos à mão são **ilhas**, escolhidas numa lista no Hub. Uma ilha tem vários biomas, e as cidades ficam dentro dela | Pedido do dono. O mapa-múndi começa como lista e melhora depois |
| A cidade é desenhada nos mesmos hexágonos da ilha, com as construções ocupando alguns deles | Pedido do dono |
| Chegar numa construção abre a tela dela, como o Hub faz hoje | Pedido do dono |
| O editor é só para desktop, em 16:9 | Pedido do dono: ele só cria mapas no PC |
| Uma ilha nova começa do zero ou do gerador, com os parâmetros dele (mais montanha, mais água) | Pedido do dono |
| A ilha fica como rascunho até o dono publicar | Pedido do dono |
| A geração procedural continua: o Explorar zona sorteado fica como está | Pedido do dono ("ainda vamos continuar tendo") |
| Nas ilhas, o nível dos Ecobeasts é fixo e configurado por área, com mínimo e máximo por espécie. Ele não segue a média da equipe, como no Explorar zona sorteado | Pedido do dono |

Escolhas do planejamento (corrigíveis; ao mudar uma, atualize aqui e no [architecture.md](architecture.md)):

| Decisão | Motivo |
| --- | --- |
| O editor mora no próprio jogo, em `res://tools/map_editor/`, numa janela do sistema aberta com F2, só quando o jogo roda pelo editor do Godot | É o padrão do content-viewer. Reaproveita o `HexMapView`, então a ilha aparece como no jogo, e usa o login e a API do jogo. Um editor web teria que desenhar tudo de novo, e um plugin do editor do Godot não tem o login |
| Quem gera pelo algoritmo é o servidor: o editor manda a seed e os parâmetros, e recebe os hexágonos | O gerador continua num lugar só, sem uma cópia em GDScript que se desencontre dele |
| As rotas do editor só aceitam os usuários de `MAP_EDITOR_USER_IDS`, uma variável de ambiente do servidor. Vazia, elas respondem 404 | O jogo exportado não tem o editor, mas qualquer conta logada consegue chamar a API |
| Cada ilha tem duas versões guardadas, o rascunho e a publicada. Salvar troca o rascunho; publicar copia o rascunho para a publicada | O jogador vê só a publicada, e o dono pode retocar uma ilha que já está no jogo |
| Uma construção é um tipo do catálogo (`building_types`: Refúgio, Loja, Arena, Casa) e ocupa os hexágonos que o dono pintar para ela | O dono escolhe o tamanho e a forma de cada uma. Ainda não há arte de construção: no editor ela aparece como hexágonos coloridos com o nome |
| Uma área de Ecobeasts tem um nome, uma cor e uma lista de espécies, cada uma com peso e faixa de nível, e o dono a pinta sobre os hexágonos. Hexágono sem área não tem selvagem | É o "quais Ecobeasts aparecem em cada parte da ilha", com o nível fixo que o dono pediu. Sem área, uma cidade fica sem selvagens |
| Com o zoom bem afastado (ou Tab), o editor mostra a ilha inteira em cores chapadas, onde também se pinta | O desenho do jogo monta só as linhas perto da tela; a ilha inteira de uma vez trava |
| O editor salva a ilha inteira de uma vez, e não hexágono por hexágono | Uma ilha tem até 20.000 hexágonos. Uma rota que troca tudo é simples e não deixa a ilha pela metade |
| Desfazer e refazer (Ctrl+Z, Ctrl+Y) contam cada pincelada como um passo | Pintar errado com um pincel grande sem desfazer é perder trabalho |

## Fora do escopo

- Jogar nas ilhas: o mapa-múndi, entrar numa ilha, as construções abrindo as telas e os Ecobeasts nascendo pelas áreas (a `islands`).
- A história e a ordem em que as ilhas são liberadas.
- A arte das construções e a Arena funcionando (a `arenas-league`).
- Domadores NPC fixos posicionados no mapa (a `npc-fixed-teams`).
- Decorações postas à mão: as árvores e pedras continuam saindo do `HexMapView`, como hoje.
- Editar o mapa no celular, ou em outra proporção de tela.
- Histórico de versões além do rascunho e da publicada.

## Pré-requisitos

- [wild-battle](../wild-battle/), [biome-encounters](../biome-encounters/) e [content-viewer](../content-viewer/) concluídas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-island-records](01-island-records.md) | Servidor: as tabelas das ilhas, o tipo de construção no catálogo, a regra de quem edita e as rotas do editor (listar, criar, ler, salvar, publicar, apagar e gerar) | concluída |
| 2 | [02-editor-window](02-editor-window.md) | Jogo: a janela F2, a lista de ilhas, ilha nova do zero ou pelo gerador, ver com zoom e arrastar, salvar | concluída |
| 3 | [03-terrain-tools](03-terrain-tools.md) | Jogo: os pincéis de bioma e forma, pôr e tirar hexágonos, o tamanho do pincel, a chegada, desfazer e refazer | concluída |
| 4 | [04-buildings-and-areas](04-buildings-and-areas.md) | Jogo: as construções, as áreas de Ecobeasts e o publicar | concluída |
| 5 | [05-editor-ux](05-editor-ux.md) | Jogo: topo com Ilhas, desfazer, refazer e Camadas; coluna de ferramentas; Bioma e Altura separados; prévia e barra dos objetos; foco na área | concluída |
| 6 | [06-tool-groups](06-tool-groups.md) | Jogo: as 12 ferramentas em 4 grupos (Terreno, Chão, Peças e Jogo), com abas e as teclas 1 a 4 | concluída |

O desenho compartilhado está no [architecture.md](architecture.md).

## Depois desta iniciativa

A `islands`, a seguir no [roadmap.md](../roadmap.md):

- No Hub, a lista das ilhas publicadas.
- Entrar numa ilha abre o mapa dela, como Explorar zona, com o Domador na chegada.
- Pisar numa construção abre a tela dela, e fechar volta para a ilha, no mesmo lugar.
- Os Ecobeasts nascem pelas áreas que o dono pintou.
