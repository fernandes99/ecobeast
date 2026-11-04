# Biome Encounters

Os Ecobeasts passam a nascer no mapa de Explorar zona. Cada espécie tem uma taxa por bioma, alguns ficam visíveis pelo mapa, e o botão "Procurar Ecobeast" enfrenta um dos que estão no hexágono do Domador. Depois da luta, esse Ecobeast some, e o mapa só se renova na próxima exploração.

## Contexto

Hoje, o botão "Procurar Ecobeast" chama `POST /v1/me/battle/wild`, que sorteia qualquer espécie com a mesma chance, sem olhar onde o Domador está. O nível fica perto do primeiro Ecobeast vivo do time. A posição do jogador existe só no cliente, e o mapa não fica guardado: cada entrada em Explorar gera outro.

Não existe nenhum dado de spawn. A `rarity` das espécies é só um rótulo, e os 9 Ecobeasts estão como "Raro". O `spawnWeight` e o `habitatZones` do `GDD.md` nunca chegaram ao banco.

A [wild-battle](../wild-battle/) deixou o terreno pronto: 5 biomas e 3 formas por hexágono, os 9 Ecobeasts iniciais com folhas animadas e o `CreatureSprite`, que passeia dentro de um hexágono. O catálogo também tem [Hushling e Echofrost](../game-data/04-hushling-line.md), ainda sem arte.

## Quem usa

- O jogador, ao andar pelo mapa e tocar em "Procurar Ecobeast".
- O dono do projeto, que ajusta taxas no painel do Supabase e as constantes em `spawn-config.ts`.

## Objetivos

1. Cada Ecobeast nasce só nos biomas em que tem taxa, e tanto a taxa quanto o bioma estão no banco.
2. O jogador vê alguns Ecobeasts pelo mapa, sem nome nem nível.
3. Procurar enfrenta um Ecobeast do hexágono do Domador, e ele some depois da luta.
4. As evoluções são raras para um time abaixo do nível delas e comuns para um time no nível.
5. O nível do Ecobeast selvagem parte do nível natural da espécie e sofre influência da média do time.
6. Quem decide tudo é o servidor: o cliente não consegue escolher o Ecobeast nem pular para longe.

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| Alguns Ecobeasts ficam visíveis no mapa, e cada um fica em um hexágono | Pedido do dono |
| O encontro escondido, sem ver o Ecobeast antes, fica para depois | Pedido do dono |
| Procurar enfrenta um Ecobeast do hexágono do Domador; com mais de um, a escolha é aleatória | Pedido do dono |
| Depois da luta, o Ecobeast some, com vitória, derrota, fuga ou captura | Pedido do dono |
| Em um hexágono vazio, Procurar só avisa que não há nada ali | Pedido do dono |
| O mapa só se renova ao sair e entrar de novo: nenhum Ecobeast novo nasce durante a exploração | Pedido do dono |
| Biomas e taxas moram no banco, e a tabela `biomes` tem nome e descrição | Pedido do dono: os dados do bioma serão usados mais para frente |
| Colina e montanha contam como biomas nas taxas | Pedido do dono, ainda na [wild-battle/04](../wild-battle/04-biome-surfaces.md) |
| A taxa vai de 0 a 100 e é um peso na disputa: 0 nunca aparece, e 100 é a maior chance possível, sem garantia de aparecer | Decisão do dono, na mesma escala da captura |
| Uma evolução é muito mais rara para um time abaixo do nível dela, mas não é impossível | Pedido do dono, com o exemplo do Ruvak: raro com média 10 e comum com média 20 |
| O nível do selvagem fica perto do nível natural, com sorteio e influência da média do time | Pedido do dono, que também pediu um centro mais alto do que a primeira proposta |
| No mapa não aparece nenhuma informação: nome e nível só na luta | Pedido do dono |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| Uma montanha ou colina conta só como montanha ou colina, em qualquer bioma, inclusive em ilhas | Sete biomas cabem em uma tabela que dá para editar à mão. A combinação de bioma e forma daria 15 |
| O número de Ecobeasts por mapa é fixo: 500, _a revisar_ | "Só alguns": dá cerca de 3 por tela, e uma espécie nova divide as vagas em vez de encher o mapa |
| Não existe atributo novo de raridade de spawn; a `rarity` segue como rótulo | A taxa por bioma já faz esse papel. Dois controles para a mesma coisa se confundiriam |
| O nível natural vem da tabela `evolutions`, e a base de uma linha tem nível natural 1 | Evita uma coluna nova que repetiria o `min_level` |
| Uma evolução sem `min_level`, como a por Vínculo, tem o nível natural da espécie anterior mais 20, _a revisar_ | Com 1, o Echofrost apareceria para quem acabou de começar. O 20 é o salto entre o Ruvak (16) e o Ruvaroth (36) |
| Hushling e Echofrost ficam sem taxas até terem folhas. Com as folhas prontas, o dono deu as taxas por resolvidas | Sem elas, o Ecobeast seria invisível no mapa |
| A taxa cai pela metade a cada nível que falta para o nível natural | Uma regra só cobre o Ruvak (16) e o Ruvaroth (36) |
| A média do time usa toda a equipe principal, inclusive quem está sem HP, e vale no momento em que a exploração começa | É o mais simples de explicar, e o mapa nasce pronto |
| Variar o nível de 5 para cada lado, com pesos ¼ e ¾ | Dá de 10 a 20 no exemplo do dono, e mantém o fim do jogo perto do time |
| O Ecobeast sai do mapa quando a luta começa, não quando termina | Quem fecha o app no meio não ganha uma segunda chance, e a regra cobre os quatro resultados de uma vez |
| O cliente informa a própria posição ao Procurar, e o servidor confere pela distância e pelo tempo | Não precisa de uma chamada por passo. Quem mente na posição não chega mais rápido do que andando |
| A exploração fica na memória do servidor, como a batalha | É o mesmo padrão de `BattleStore`. Reiniciar o servidor perde a exploração, e o jogador só precisa entrar de novo |
| Só os Ecobeasts perto do Domador existem como nós do Godot | Um nó com animação para cada um dos 500 gastaria o celular à toa |
| No botão de depuração de mapa inteiro, todos aparecem | É como o dono confere as taxas a olho, igual ao spawn de depuração |

## Fora do escopo

- Encontro escondido ao andar: fica para uma iniciativa própria.
- Nascer Ecobeast durante a exploração.
- Guardar o mapa entre sessões ou entre reinícios do servidor.
- O Campo decidido pelo bioma (o roadmap citava isso aqui, e passa a ser uma linha própria).
- Regiões fundas só para quem voa ou nada: hoje o Domador anda em qualquer hexágono.
- Mostrar biomas para o jogador. A tabela já tem nome e descrição, mas nenhuma tela os usa ainda.
- Ecobeast que muda de hexágono ou persegue o Domador.
- Velocidade de passeio por tamanho, e rever a variação de nível depois de jogar.

## Pré-requisitos

- [wild-battle](../wild-battle/), [battle-screen](../battle-screen/) e [capture](../capture/) concluídas.
- As 9 folhas de `client/assets/creatures/` no repositório. Hoje elas e o spawn de depuração estão sem commit, e a fase 04 usa tudo isso.

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01-biome-tables](01-biome-tables.md) | Tabelas `biomes` e `species_biomes`, com as taxas dos 9 | concluída |
| [02-spawn-rules](02-spawn-rules.md) | Regras puras: sorteio do mapa, peso por nível e nível do selvagem | concluída |
| [03-exploration-session](03-exploration-session.md) | Exploração guardada no servidor e o encontro saindo do hexágono | concluída |
| [04-map-creatures](04-map-creatures.md) | Ecobeasts no mapa, Procurar e o sumiço depois da luta | concluída |

O desenho compartilhado está em [architecture.md](architecture.md).
