# 03. A barra de abas e o palco do campo

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-hub](01-hub.md) e [02-ecobeasts-profile-settings](02-ecobeasts-profile-settings.md)

## Contexto

Em 2026-11-21, depois da fase 2, o dono pediu: "os botões que ficam embaixo serão tipo uma tabbar, como se fosse a navegação do clash royale. E acrescente mais uma opção no centro para 'Home'. Que vai ser essa tela com o botão de explorar", e também "a criatura ficou com muito destaque na tela. Deixe mais bonito, explore outras interfaces". Claude mostrou três desenhos (A, o palco no campo; B, o cartão e a grade; C, a arena com pedestal), e ele escolheu o **A**: o Domador e o Ecobeast em destaque pequenos, em pixel art, de pé na grama da arte do Hub, com a equipe em bolinhas.

## Escopo

- `client/screens/hub/` (`hub_screen.gd` e `hub_screen.tscn`).
- `client/ui/components/safe_area.gd` (a margem de baixo das páginas das abas).
- As telas das abas: `shop`, `heal_station`, `team` e `bag` (o `setup` com `in_tab`).

## Requisitos

**A barra de abas**

- **RF-01:** O Hub tem, embaixo, de ponta a ponta da tela, a barra com 5 abas, nesta ordem: **Loja**, **Refúgio**, **Home** (no meio), **Ecobeasts** e **Mochila**. O Hub abre na Home.
- **RF-02:** A aba escolhida fica mais larga, mais alta que a barra (saltada para cima), com o fundo mais claro, a borda de cima na cor de destaque, o ícone maior e o nome embaixo. As outras mostram só o ícone, apagado. A troca anima em menos de 0,2 s. O Refúgio ganha um ícone próprio (`refuge.svg`, o coração com a cruz), porque a casa com a cruz de hoje se confundia com a casa da Home.
- **RF-03:** Trocar de aba troca a página **dentro do Hub**, com a barra sempre embaixo, como no Clash Royale. A Loja, o Refúgio, a tela Ecobeasts e a Mochila são as telas de hoje, criadas na primeira vez que a aba abre e guardadas até sair do Hub.
  - Dentro de uma aba, a tela não mostra o Voltar dela. Aberta de outro lugar (a Mochila e a Loja pelo mapa, o Refúgio pela sala), ela continua com o Voltar de hoje.
  - O que a tela abre por cima (o detalhe, o Santuário, o Bestiário) abre com `Router.push`, por cima do Hub inteiro, e o Voltar volta à aba.
- **RF-04:** O Voltar do aparelho numa aba que não é a Home primeiro deixa a tela fechar o que tem aberto (o `handle_back` dela) e, se ela não tiver nada, volta para a Home. Na Home, não faz nada.
- **RF-05:** A barra respeita a área segura de baixo do aparelho, e as páginas das abas não somam essa margem de novo: a margem de baixo delas é só a folga da aba levantada (`SafeArea.bottom_override`), para ela não cobrir os botões do fim da tela.

**A Home**

- **RF-06:** O topo continua o da fase 1 (o Domador, o nível e a barra, as moedas e a engrenagem), só na Home. O indicador da parte do dia fica embaixo dele, à direita.
- **RF-07:** No meio, o **palco**: a arte do Hub, posta para que a grama do primeiro plano fique sob os pés, e nela, lado a lado, o Domador (o `TamerSprite` com a aparência dele) e o Ecobeast em destaque (o `CreatureSprite` com as folhas do mapa), em pixel art, com o mesmo aumento inteiro (4 vezes), de frente, virados um para o outro.
  - Sem as folhas do mapa, o Ecobeast aparece pelo `front.png`, pequeno, no mesmo lugar.
  - Acima do Ecobeast, uma etiqueta com o nome, o nível e uma barra fina de HP.
  - Tocar no Ecobeast ou na etiqueta abre o detalhe dele.
- **RF-08:** Embaixo do palco, a equipe em 6 bolinhas com o retrato de cada um. Tocar numa põe aquele Ecobeast no palco, e a bolinha dele ganha o anel claro. Como na fase 1, o destaque não é gravado e não muda o líder, e um espaço vazio não faz nada.
- **RF-09:** Embaixo das bolinhas, o botão **Explorar**, como na fase 1. Os 4 atalhos da fase 1 saem, porque as abas fazem o papel deles.
- **RF-10:** A arte escurece da fileira para baixo, para as bolinhas e o Explorar ficarem legíveis, e cabe em retrato de 720×1280 a 1080×2400 sem rolar e sem faixa vazia em cima.

## Fora do escopo

- Arrastar o dedo para o lado para trocar de aba.
- Arte nova para o palco, as bolinhas ou a barra.
- O topo nas outras abas: cada tela já tem o seu título.

## Critérios de aceite

- [x] O Hub abre na Home, com a barra de 5 abas e a do meio saltada.
- [x] Tocar em cada aba mostra a tela dela dentro do Hub, sem o Voltar, com a barra embaixo; o Voltar do aparelho volta para a Home.
- [x] Na Home, o Domador e o Ecobeast em destaque aparecem pequenos, de pé na grama; tocar noutra bolinha troca o Ecobeast; tocar nele abre o detalhe.
- [x] O detalhe, o Santuário e o Bestiário, abertos de uma aba, voltam para ela.
- [x] A Mochila pelo mapa e o Refúgio pela sala continuam com o Voltar.
- [x] O jogo sem janela abre sem erro de script.

## Verificação

```bash
godot --headless -d --path client --quit-after 240
```

Depois, no jogo, cada aba, o Voltar e a troca do destaque.

## Tarefas

- [x] A barra de abas e as páginas dentro do Hub.
- [x] O `in_tab` nas 4 telas e a margem de baixo do `SafeArea`.
- [x] A Home: o palco, a etiqueta, as bolinhas e o Explorar.
- [x] Atualizar o `CLAUDE.md`, o `TELAS.md` e o README da iniciativa.
- [x] A verificação.
