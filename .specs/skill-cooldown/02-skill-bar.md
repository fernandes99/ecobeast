# 02. A barra de 3 ícones e o detalhe ao segurar

- **Status:** concluída (falta o dono jogar)
- **Depende de:** [01](01-server-cooldown.md); o commit da [camera-zoom/02](../camera-zoom/02-battle-zoom.md), que também mexe no `board_battle_screen.gd`

## Contexto

Depois da [01](01-server-cooldown.md), a luta já respeita o countdown, mas as Técnicas ainda são botões retangulares com nome e PP. O dono quer a barra do print de referência ([README](README.md)): 3 ícones quadrados, e um quadro com o detalhe ao tocar e segurar.

## Escopo

- O botão de Técnica vira um ícone quadrado.
- A barra com os 3 ícones lado a lado.
- O quadro de detalhe ao segurar.

## Fora do escopo

- Mudar as regras ou o contrato da luta.
- O mesmo visual nos Detalhes do Ecobeast ou na tela de trocar Técnica.
- O som ao tocar ou segurar.

## Requisitos

- **RF-01:** As Técnicas aparecem numa linha de 3 ícones quadrados, no lugar da grade `%SkillsGrid`. Cada ícone mostra `res://assets/skills/<slug>.png` com a borda na cor do Elemento.
- **RF-02:** Embaixo de cada ícone, o PP como `atual/máximo`.
- **RF-03:** Com `cooldown_left > 0`, o ícone fica escurecido, com o número de rodadas que faltam em destaque no centro, e não pode ser escolhido.
- **RF-04:** Sem PP, o ícone fica escurecido, sem número, e não pode ser escolhido.
- **RF-05:** Uma vaga vazia aparece como um quadrado vazio, sem ícone.
- **RF-06:** Um toque rápido (soltar antes de 0,4 s) escolhe a Técnica, como hoje.
- **RF-07:** Segurar 0,4 s abre o quadro de detalhe acima da barra. Soltar fecha o quadro e não escolhe a Técnica.
- **RF-08:** Segurar também funciona num ícone bloqueado ou sem PP.
- **RF-09:** O quadro de detalhe mostra:
  - O nome e o selo do Elemento.
  - A categoria, o poder (ou "—"), a precisão (ou "—") e o alcance.
  - A descrição.
  - O PP e o countdown da Técnica (com 0, "sem countdown").
  - Com `cooldown_left > 0`, a linha "Volta em N rodada(s)" em destaque.
- **RF-10:** A Técnica escolhida fica marcada, como hoje.

## Critérios de aceite

- [ ] Na luta (F5), as 3 Técnicas aparecem como ícones com a borda na cor do Elemento e o PP embaixo.
- [ ] Um toque rápido escolhe a Técnica, e a luta segue como antes.
- [ ] Segurar abre o quadro com os dados da Técnica, e soltar fecha sem escolher.
- [ ] Depois de usar uma Técnica com countdown 2, o ícone dela mostra 2, depois 1, e então volta ao normal.
- [ ] Um Ecobeast com 2 Técnicas mostra a terceira vaga vazia.
- [x] O jogo abre sem erros nem avisos de script.

## Desenho técnico

**Alterar:**
- `res://screens/board_battle/battle_skill_button.tscn` e `battle_skill_button.gd`:
  - Um `TextureRect` com o ícone e a borda.
  - O `Label` do PP embaixo.
  - O véu escuro com o número do countdown.
  - Um `Timer` de 0,4 s iniciado em `button_down`. Se ele disparar, o botão emite `hold_started(slot)` e marca o toque como longo. Em `button_up`, ele emite `hold_ended()`, e o `pressed` é ignorado quando o toque foi longo.
- `res://screens/board_battle/board_battle_screen.gd` e a `.tscn`: a `%SkillsGrid` vira uma linha de 3 (`HBoxContainer` ou `GridContainer` de 3 colunas), e a tela liga `hold_started` e `hold_ended` ao quadro.

**Criar:**
- `res://screens/board_battle/skill_detail_card.tscn` e `skill_detail_card.gd`: um `PanelContainer` com `set_skill(slot: SkillSlot)`, posicionado acima da barra e centrado no ícone segurado, sem sair da tela.

**Reutilizar:** o `ElementBadge`; a linha de dados da `skill_learn_overlay.gd` (categoria, poder, precisão); as cores de `UiPalette`.

## Verificação

```bash
godot --headless --path client --quit-after 30
```

À mão (F5, com o servidor no ar): numa luta de selvagem, conferir os critérios de aceite. No editor, testar o segurar com o mouse; no aparelho, com o dedo, se o dono puder.

## Tarefas

- [x] O botão em ícone, com o PP, o véu e o segurar.
- [x] A barra de 3 na tela de luta.
- [x] O quadro de detalhe.
- [x] Jogo sem janela.
- [ ] Os passos à mão, com o dono.

## Resultado da verificação

Em 2026-11-15, sem janela e com uma imagem renderizada (cena temporária, já apagada):

- **Botão:** com `cooldown_left` 2, o ícone fica sob o véu com "2" e não emite `chosen`. Livre, um toque emite `chosen`.
- **Imagem:** a barra de 3 com o ícone, o PP embaixo e a borda na cor do Elemento; a escolhida com a borda branca; e o quadro acima do ícone segurado, dentro da tela.
- **Quadro:** a Erupção Solar mostrou nome, selo, "Especial · Poder 120 · Precisão 85 · Alcance 1", a descrição, "PP 4/5 · countdown de 3 rodadas" e "Volta em 2 rodadas".
- **Jogo:** abre sem erros de script.
- **Escolhas na implementação:**
  - Um ícone bloqueado ou sem PP não fica `disabled`, porque um `Button` desabilitado não emite `button_down`, e segurar precisa funcionar nele (RF-08). Ele só não emite `chosen`. Só a espera pela resposta do servidor (`_set_busy`) desabilita os botões.
  - A Técnica escolhida ganha a borda branca e mais grossa (RF-10). Antes, o botão não mudava.
  - O véu é um `Panel` com o canto arredondado do botão.
- **Falta o dono:** tocar e segurar com o mouse no F5 e, se puder, com o dedo no aparelho.
