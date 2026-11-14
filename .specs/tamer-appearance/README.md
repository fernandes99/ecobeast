# tamer-appearance

A aparência do Domador: escolher o corpo (masculino ou feminino), a cor da pele, o rosto, o cabelo, um chapéu ou capacete e as roupas, cada peça com a sua cor. Hoje o Domador é uma folha só (`res://assets/tamer/idle.png` e `run.png`, do template da Eris Esra), igual para todo mundo.

A técnica é a **boneca de papel** (paper doll): um corpo base só com roupa íntima e cada peça como uma folha à parte, no mesmo formato do corpo, desenhada por cima dele no jogo.

## Objetivos

- No catálogo, os corpos, os lugares do corpo (rosto, cabelo, chapéu, partes de cima e de baixo, calçado), as peças e as paletas de cor, editados pelo painel do Supabase.
- No servidor, a aparência de cada jogador, conferida e guardada só com ids do catálogo.
- No jogo, o Domador montado em camadas, com a cor de cada peça trocada por shader, e a tela Aparência, aberta depois do nome na entrada e pelo avatar do Hub.

## Decisões

| Decisão | Motivo |
| --- | --- |
| A arte é desenhada no formato do Domador de hoje (16×32 em quadros de 32×32, 5 direções), sobre o corpo do template da Eris Esra | Decisão do dono. Os pacotes gratuitos em camadas (Mana Seed, LPC, o de Tiago Patricio) usam outro tamanho e 4 direções, e trocariam o formato que o jogo já lê |
| Dois corpos, masculino e feminino, com a **mesma silhueta e a mesma pose**, pixel por pixel, nas mesmas folhas | Assim uma roupa serve nos dois e o trabalho de arte não dobra. Em 16×32 a diferença de corpo é pequena. _A revisar_ |
| Uma peça pode servir só num corpo (`body_type_id`); sem ele, serve nos dois | Para a peça que não fica bem num dos corpos, sem obrigar todas a ter duas versões |
| Toda folha de peça tem o formato exato da folha do corpo: quadros de 32×32, as mesmas 5 linhas de direção e as mesmas colunas de `idle` e `run` | É o que deixa o jogo empilhar as camadas no mesmo quadro. É o formato que o `SheetSprite` já lê |
| A peça que fica atrás do corpo numa direção (cabelo comprido, capa) tem uma segunda folha, `_back`, desenhada atrás | Mais simples do que trocar a ordem das camadas por direção |
| A cor sai de uma rampa de 4 cores-chave na arte, trocada pela paleta escolhida num shader | Um desenho vira todas as cores da paleta. O tom de pele usa o mesmo caminho |
| O chapéu diz o que esconde do cabelo: nada, o topo ou tudo. Com o topo, o cabelo usa a folha `_short`, se tiver | Para o cabelo não vazar pelos lados do chapéu |
| Toda peça está liberada para todo jogador | Ganhar, comprar ou desbloquear peça fica para depois |
| A tela Aparência abre depois do nome, antes da escolha do inicial, e pelo avatar do Hub | Decisão do planejamento, _a revisar_. O Perfil ainda é um placeholder |
| Quem já tem Domador recebe a aparência padrão: corpo 1, a primeira pele e o primeiro rosto | Ninguém fica sem aparência depois da migration |

## Fora do escopo

- Ganhar, comprar ou desbloquear peças (Loja de roupas, recompensas, passe cosmético).
- Duas cores na mesma peça (uma camisa com a barra de outra cor) e a cor dos olhos.
- Animações novas do Domador (atacar, comemorar). Cada uma multiplica a arte de todas as peças.
- A aparência nos Domadores NPC e no avatar redondo do Hub, que continua com a inicial do nome.
- Ver a aparência de outros jogadores.

## Pré-requisitos

- [auth-google](../auth-google/): o jogador no servidor e as rotas `/v1/me`.
- [wild-battle](../wild-battle/) e [islands](../islands/): o `TamerSprite` andando no mapa de Explorar.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-appearance-records](01-appearance-records.md) | Servidor: o catálogo de aparência, a aparência do jogador e a rota que a troca | concluída |
| 2 | [02-layered-tamer](02-layered-tamer.md) | Jogo: a pasta da arte, o shader de paleta e o Domador montado em camadas no mapa | concluída |
| 3 | [03-appearance-screen](03-appearance-screen.md) | Jogo: a tela Aparência, na entrada e pelo avatar do Hub | concluída |
| 4 | [04-starter-wardrobe](04-starter-wardrobe.md) | Arte: os 2 corpos e o primeiro guarda-roupa, e as folhas que faltam no visualizador (F1) | concluída |

O desenho compartilhado está no [architecture.md](architecture.md).
