# 35. O desenho animado de todas as marcas no chão

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [23](23-battle-effect-states.md) (as chamas do Chão em chamas)

## Contexto

Em 2026-11-20, o dono pediu: "crie os efeitos de todos os estados do chão, hoje ele só é pintado, só o de fogo que tem efeito visual, crie de todos eles." Das 11 marcas do catálogo, só o Chão em chamas tinha um desenho, as chaminhas da [23](23-battle-effect-states.md). As outras 10 só pintavam o hexágono com a cor delas. O dono aprovou a proposta de um desenho por marca ("Pode ir").

## Escopo

- Um desenho animado, feito por código como as chamas, para cada uma das 10 marcas sem desenho.
- A cor do hexágono continua por baixo, como hoje.

## Fora do escopo

- Arte nova em imagem ou shader.
- Mudar alguma regra das marcas.
- Sons das marcas.

## Requisitos

- **RF-01:** Cada marca tem um desenho próprio, por cima da cor do hexágono e por baixo dos Ecobeasts (_a revisar_):

| Marca | Desenho |
| --- | --- |
| Chão em chamas (`fire`) | As chaminhas da [23](23-battle-effect-states.md), sem mudança |
| Penas no ar (`feathers`) | Penas brancas caindo devagar e balançando |
| Redemoinho (`whirlwind`) | Três braços de espiral girando, com poeira rodando em volta |
| Espinheiro (`thorns`) | Espinhos verdes saindo do chão, balançando de leve |
| Maré Elétrica (`electric_tide`) | Ondinhas azuis, com uma faísca amarela em zigue-zague que pisca de vez em quando |
| Lamaçal (`mud`) | Manchas escuras e bolhas marrons que crescem e estouram |
| Geada (`frost`) | Cristais de gelo parados, com brilhos que piscam |
| Poça Tóxica (`toxic_pool`) | Bolhas roxas que sobem e estouram, com um vapor fraco |
| Areia Movediça (`quicksand`) | Anéis que encolhem até o buraco do meio, com grãos girando para dentro |
| Jardim (`garden`) | Florzinhas balançando e brilhos verdes subindo |
| Poça d'Água (`puddle`) | Anéis de gota se abrindo em pontos sorteados, como chuva na poça |

- **RF-02:** Hexágonos com a mesma marca não se mexem juntos: cada um começa a animação num ponto sorteado pela coordenada.
- **RF-03:** Uma marca nova no catálogo, sem desenho, continua só com a cor.

## Critérios de aceite

- [x] Numa cena temporária, as 11 marcas aparecem cada uma num hexágono, com o desenho dela, num print com janela.
- [x] O jogo abre sem erros de script.
- [ ] No jogo, pelo F3 de uma luta, cada marca liga o desenho dela.

## Desenho técnico

O `GroundFlames` (`res://screens/board_battle/ground_flames.gd`) vira o `GroundEffects` (`ground_effects.gd`), na mesma camada do `BoardView`, entre o chão e os Ecobeasts. Ele recebe `kinds` (o `slug` de cada hexágono marcado), anda enquanto houver marca e desenha cada uma pelo `slug`, com as cores em `UiPalette` (`GROUND_*`).

## Verificação

Numa cena temporária (já apagada), um tabuleiro de 4 × 3 com as 11 marcas, em três prints com janela. Na primeira rodada, os espinhos verdes sumiam no gramado e os anéis da Areia Movediça e da Poça d'Água estavam fracos: os espinhos ficaram marrons, e os anéis, mais fortes. O jogo sem janela, com os avisos ligados, não mostra aviso dos arquivos mexidos.
