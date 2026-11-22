# 02. O componente do rosto e o anel de HP

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-face-art](01-face-art.md)

## Contexto

As decisões estão no [README](README.md). Esta fase cria o componente que desenha o rosto com o fundo e o anel de HP, e o usa nos dois lugares que o dono apontou: as bolinhas da equipe na Home e o cartão da luta.

## Escopo

- `client/ui/components/creature_face.gd` (novo, `class_name CreatureFace`).
- `client/screens/hub/party_bubble.gd` (passa a usar o `CreatureFace`).
- `client/screens/board_battle/board_creature_card.gd` (o retrato vira o `CreatureFace`).

## Requisitos

**O componente**

- **RF-01:** O `CreatureFace` é um `Control` quadrado, do tamanho pedido (`face_size`), que desenha de dentro para fora:
  - o fundo redondo na cor do primeiro Elemento, escurecida; com dois Elementos, a metade de cima na cor do primeiro e a de baixo na do segundo, separadas na diagonal;
  - o `face.png` recortado no círculo, com o filtro suave (o rosto de 128 aparece menor, e o filtro mais próximo serrilharia);
  - o anel de HP.
- **RF-02:** O anel de HP é fino, com a espessura de 1/20 do tamanho, com o trilho escuro (`UiPalette.TRACK`) inteiro e, por cima, o arco do HP, que começa no topo e esvazia no sentido horário. A cor vai em degradê do verde (`HP_HIGH`, com a vida cheia) ao laranja (`HP_ORANGE`, na metade) e ao vermelho (`HP_LOW`, de 15% para baixo). A troca de HP anima o arco e a cor em 0,3 s.
- **RF-03:** O rosto não tem anel de selecionado: quem o usa mostra a escolha do seu jeito (na Home, o RF-06).
- **RF-04:** Os estados:
  - **desmaiado** (HP 0): o rosto e o fundo ficam acinzentados, e o anel fica só o trilho;
  - **sem HP** (`show_hp` desligado, para quem não tem HP, como uma espécie do Bestiário): o anel some, e o rosto ocupa o lugar dele;
  - **sombra** (`silhouette`, a espécie só vista no Bestiário): o `front.png` inteiro, na cor de sombra do `CreaturePortrait`, sobre o fundo cinza, porque o rosto recortado é quase todo opaco e viraria um disco;
  - **sem `face.png`**: o `front.png` inteiro, encolhido no círculo, como hoje.
- **RF-05:** A API: `set_creature(instance)` (a espécie e o HP de um Ecobeast do jogador), `set_species(id)` (só a espécie, sem HP), `set_hp(atual, máximo)` e `set_silhouette(bool)`, todas aceitas antes de entrar na árvore, como manda o `CLAUDE.md` do cliente.

**Onde entra**

- **RF-06:** A `PartyBubble` da Home desenha um `CreatureFace` com o HP do Ecobeast, e o anel na cor do Elemento sai. O Ecobeast que está na ilha fica 15% maior, crescendo para cima, com uma sombra oval no pé, e os outros ficam apagados num tom azulado; a troca anima em 0,12 s.
- **RF-07:** O `BoardCreatureCard` da luta troca o `CreaturePortrait` por um `CreatureFace` de 104 px (o retrato tinha 84; o anel come parte do círculo, e o cartão continua da mesma altura), com o anel de HP acompanhando a barra de HP que já existe no cartão. A barra continua, porque mostra os números.

## Fora do escopo

- As outras telas (a [fase 3](03-face-everywhere.md)).

## Critérios de aceite

- [x] Na Home, cada bolinha mostra o rosto grande, com o anel de HP; o Ecobeast em destaque fica maior, e os outros, apagados.
- [x] Um Ecobeast com metade do HP tem o anel pela metade, em amarelo; um desmaiado aparece cinza e sem arco.
- [ ] Na luta, o cartão mostra o rosto, e o anel esvazia quando ele leva dano.
- [ ] Um Ecobeast sem `face.png` continua aparecendo pelo corpo inteiro.
- [x] O jogo sem janela abre sem erro de script.

## Verificação

```bash
godot --headless -d --path client --quit-after 240
```

Depois, no jogo, a Home com a equipe e uma luta.

## Tarefas

- [x] O `CreatureFace`, com o fundo, o anel de HP e os estados.
- [x] As bolinhas da Home.
- [x] O cartão da luta.
- [x] Atualizar o `CLAUDE.md` do cliente.
- [x] A verificação.
