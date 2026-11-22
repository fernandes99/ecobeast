# creature-faces

Cada Ecobeast ganha um **rosto**: o recorte do rosto do `front.png`, centrado, para os lugares pequenos, onde o corpo inteiro encolhido fica ilegível. O rosto aparece num círculo com o fundo na cor do Elemento e, em volta, o **anel de HP**, que esvazia conforme o Ecobeast perde vida.

- **Status:** em andamento (fases 1 e 2 concluídas)
- **Depende de:** [creature-fronts](../creature-fronts/), [hub-start](../hub-start/) e [board-battle](../board-battle/)

## Contexto

Em 2026-11-21, olhando as bolinhas da equipe na Home do Hub ([hub-start/03](../hub-start/03-tab-bar.md)), o dono escreveu: "nas imagens do ecobeasts é muito pequeno a parte de seleção deles lá, estou pensando em criar imagens para cada ecobeast do rosto deles centralizados com um fundo com alguma cor deles, para usarmos em alguns casos". Ele mandou de exemplo um cartão com o retrato redondo do Ruvo e o HP como borda do círculo, e pediu: "repare que na print que eu enviei tem o hp dele em borda da imagem, consegue deixar nessa pegada ai também?".

Claude conferiu o jogo de hoje:

- Os `front.png` têm 512×512, com a figura em até 480 px, do `crop_line.py` da skill `creature-sprites` ([creature-fronts](../creature-fronts/)).
- O `CreaturePortrait` desenha o `front.png` inteiro no tamanho pedido. Ele aparece pequeno nas bolinhas da Home (`PartyBubble`), na fila de vez da luta (`TurnQueueBar`), no cartão da luta (`BoardCreatureCard`, 84 px), nas linhas da tela Ecobeasts (`TeamRow`), do Refúgio (`HealCreatureRow`), da Mochila (`BagTargetRow`) e da troca na luta (`NextCreatureRow`) e na grade do Santuário (`StorageCell`) e do Bestiário (`CodexCell`).
- O `HpBar` pinta o HP em 3 faixas: verde acima de 50%, amarelo de 50% a 20% e vermelho abaixo (`UiPalette.HP_HIGH`, `HP_MID` e `HP_LOW`).

## Objetivos

1. Reconhecer cada Ecobeast pelo rosto nos lugares pequenos.
2. Ver o HP de cada um num relance, pelo anel, sem uma barra ao lado.
3. Um Ecobeast novo ganhar o rosto sem desenhar nada, só marcando onde o rosto fica.

## Não objetivos

- Arte nova à mão para os rostos.
- Trocar o corpo inteiro onde há espaço: o detalhe do Ecobeast, a escolha do inicial, o registro no Bestiário, a captura, a Evolução e a subida de nível continuam com o `front.png`.

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| Um rosto centrado para cada Ecobeast, com um fundo na cor dele, nos lugares pequenos | O pedido dele |
| O HP como a borda do círculo do rosto | "tem o hp dele em borda da imagem, consegue deixar nessa pegada ai também?" |
| O rosto menos aproximado e o anel de HP fino, indo do verde ao laranja e ao vermelho conforme a vida cai | Depois da fase 2: "Queria que ficasse com menos zoom na cara, ta muito exagerado em alguns" e "a barra de vida tem que ser mais sutil [...] A ideia é ela ir ficando laranja e vermelha conforme a vida abaixa" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O rosto é recortado do `front.png` por um script, pelo quadrado do rosto de cada espécie, e não desenhado | Sai igual ao Ecobeast, no mesmo pixel art e contorno, e uma linha nova ganha o rosto na hora; se o front mudar, basta rodar de novo |
| O script acha um quadrado inicial sozinho, pela parte de cima da figura, e os tortos são corrigidos olhando uma folha com todos os rostos | Na prática, o cálculo errou a maioria (pegou orelhas, cristais e asas), e os 37 quadrados de hoje foram marcados à mão; para uma espécie nova, ele ainda serve de ponto de partida |
| O `face.png` sai com o fundo transparente, e o jogo pinta o fundo | O fundo muda com o Elemento (as duas cores de quem tem dois), com a sombra do Bestiário e com o desmaiado, sem refazer a imagem |
| O anel de HP esvazia no sentido horário a partir do topo, sobre um trilho escuro | O topo é onde o olho começa |
| O anel de selecionado fica por fora do anel de HP, fino e branco | O anel de HP passa a ocupar o lugar do anel na cor do Elemento das bolinhas de hoje |

## Fora do escopo

- Os rostos dos NPCs e dos Domadores.
- Animar o rosto.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-face-art](01-face-art.md) | O script dos rostos, o quadrado de cada espécie e os `face.png` | concluída |
| 2 | [02-face-component](02-face-component.md) | O componente `CreatureFace`, com o fundo, o anel de HP e os estados, nas bolinhas da Home e no cartão da luta | concluída |
| 3 | [03-face-everywhere](03-face-everywhere.md) | O rosto nas outras listas e grades pequenas | proposta |
