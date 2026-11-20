# 02. O jogo mostra os estados e as marcas novas

- **Status:** concluída (falta o dono ver no jogo)
- **Depende de:** [01](01-field-rules.md) e [board-battle/23](../board-battle/23-battle-effect-states.md) (os efeitos que duram e o F3)

## Contexto

A luta já desenha, por código, o ícone de cada estado em cima da vida (`status_icons.gd`), o efeito em loop no corpo (`creature_aura.gd`), o hexágono tingido de cada marca e o painel de depuração F3 ([board-battle/23](../board-battle/23-battle-effect-states.md)). Os estados novos e as curas da [01](01-field-rules.md) ainda não aparecem.

## Escopo

- O ícone e o efeito no corpo do Encharcado e do Brotando, e o efeito do Preso.
- A cura do Brotando e do Jardim na tela e no log.
- As falas do log dos estados novos.
- O F3 com os estados e as marcas novas.

## Fora do escopo

- Desenho próprio das marcas novas: elas são o hexágono tingido com a cor do catálogo, como a Maré Elétrica.
- Ícone, efeito e som das Técnicas novas.

## Requisitos

- **RF-01:** O `BattleStatuses` conhece `soaked` e `sprouting` como voláteis, depois do `dazed`, e passa a ler da vista os campos `trapped`, `soaked` e `sprouting` ([01](01-field-rules.md), RF-10).
- **RF-02:** Os ícones, desenhados pelo `status_icons.gd` como os outros, com as cores na `UiPalette` (_a revisar_):
  - **Encharcado:** uma gota azul `#4A90D9`;
  - **Brotando:** um broto de duas folhas verde `#7FCB6B`;
  - o **Preso** mantém o ícone de hoje.
- **RF-03:** O efeito no corpo, no `creature_aura.gd`, no estilo dos de hoje (_a revisar_):
  - **Encharcado:** gotas que pingam do corpo;
  - **Brotando:** folhinhas que sobem devagar;
  - **Preso:** raízes ou areia em volta dos pés.
- **RF-04:** Os eventos `status_heal` e `ground_heal` fazem a barra de vida subir e mostram o número da cura em verde, como a cura das Técnicas de hoje.
- **RF-05:** As falas do log (`battle_narrator.gd`), com o nome do Ecobeast (_a revisar_):
  - "… ficou Encharcado." e "… secou." (fim do Encharcado);
  - "… está Brotando." e "… recuperou HP com o broto.";
  - "… ficou Preso." e "… se soltou." (fim do Preso);
  - "… recuperou HP no Jardim.";
  - a recusa "Preso: não dá para andar nesta vez." vem do servidor.
- **RF-06:** O F3 liga e desliga o Encharcado, o Brotando e o Preso em cada Ecobeast e as marcas 6 a 11 no chão.

## Critérios de aceite

- [x] Um teste sem janela aplica os eventos de cada estado novo e confere o ícone e o efeito no corpo, e a subida da vida com o `status_heal` e o `ground_heal`.
- [x] O jogo sem janela abre sem erros de script.
- [ ] No F3, o dono liga cada estado e cada marca nova e vê o ícone, o efeito e a cor.

## Desenho técnico

- `client/screens/board_battle/`: `battle_statuses.gd`, `status_icons.gd`, `creature_aura.gd`, `battle_narrator.gd`, `board_battle_screen.gd` (os eventos de cura) e o painel F3.
- `client/domain/models/battle_creature.gd`: os campos novos da vista.
- `client/ui/theme/palette.gd`: as cores dos estados novos.

## Verificação

```bash
godot --headless -d --path client --quit-after 240
```

Manual (F5 e F3): os estados e as marcas novas numa luta.

## Resultado da verificação

Em 2026-11-19, uma cena temporária (já apagada) falhou antes do código e passou depois: a ordem dos estados novos, a leitura dos campos `trapped`, `soaked` e `sprouting` da vista, as cores, as falas do Brotando, do Jardim, do "secou" e do "se soltou", e a tela da luta compilando. O F3 lista os estados pela ordem do `BattleStatuses.ORDER` e as marcas pelo catálogo, então os novos entraram sem código no painel. O Preso já tinha ícone e efeito (o cadeado e a corrente nos pés) e ficou com eles; com ele, o tabuleiro não acende os hexágonos para andar e mostra "Preso: não dá para andar nesta vez.". Com o servidor reiniciado, o jogo sem janela abriu com o catálogo novo, sem erro de script nem do validador. O jogo com janela não foi visto.
