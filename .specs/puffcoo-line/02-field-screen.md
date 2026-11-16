# 02. O campo na tela: o Atordoado, as marcas novas e os golpes seguidos

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [01-field-rules](01-field-rules.md)

## Contexto

A [01](01-field-rules.md) criou o estado Atordoado (`dazed`), a tabela `ground_effect_stats` e as marcas Penas no ar (id 2) e Redemoinho (id 3) no servidor. Esta fase leva isso ao jogo:

- o ícone e o efeito do estado;
- o andar travado na vez de quem está atordoado;
- o texto no histórico;
- a tabela nova no catálogo do jogo.

As marcas novas já aparecem como o hexágono tingido com a cor de `ground_effects.color_hex`, pelo `_refresh_marks` de `res://screens/board_battle/board_battle_screen.gd`. Só o Chão em chamas tem desenho próprio (`GroundFlames`).

## Escopo

- `ground_effect_stats` no esquema do catálogo do jogo.
- O Atordoado no acompanhamento dos estados, no ícone, no efeito no corpo, no sinal e no painel F3.
- O andar travado na vez de um Ecobeast do jogador que está atordoado.
- Os textos do histórico.
- Os golpes seguidos de uma Técnica de vários golpes e o detalhe dela.

## Fora do escopo

- O desenho animado das marcas novas (penas voando, redemoinho girando), que fica com o ícone, o efeito e o som das Técnicas novas, numa fase própria ([README](README.md#fora-do-escopo)).
- Mostrar na tela o que uma marca faz antes de alguém parar nela.

## Requisitos

- **RF-01:** `res://core/data/catalog_schema.gd` ganha a tabela `ground_effect_stats`, com `ground_effect_id` (FK `ground_effects`), `stat_id` (FK `stats`) e `stages` (int). O `CatalogValidator` confere as FKs e o par único (`ground_effect_id`, `stat_id`), e `stages` precisa ser diferente de 0.
- **RF-02:** O `BattleStatuses` (`res://screens/board_battle/battle_statuses.gd`) acompanha o `dazed` como estado volátil, depois de "preso" na ordem:
  - entra com o `status_applied`;
  - sai com o `status_ended` do `dazed`, ao desmaiar e no fim da luta;
  - no fim de cada resposta do servidor, fica igual ao `dazed` da vista (o `sync` ganha esse campo).
- **RF-03:** As peças do estado, _a revisar_:
  - a cor é `UiPalette.STATUS_COLORS["dazed"]` = `#F2B84B` (âmbar);
  - o ícone, em `res://screens/board_battle/status_icons.gd`, é o círculo do RF-02 da [board-battle/16](../board-battle/16-status-icons.md), com três estrelinhas escuras;
  - o efeito no corpo, em `res://screens/board_battle/creature_aura.gd`, são três estrelinhas âmbar girando em volta da cabeça;
  - o sinal da [board-battle/12](../board-battle/12-battle-signs.md) diz "Atordoado", na cor do estado;
  - o painel F3 ([board-battle/23](../board-battle/23-battle-effect-states.md)) ganha o botão do estado, para conferir o desenho.
- **RF-04:** Na vez de um Ecobeast do jogador que está atordoado:
  - o tabuleiro não acende os hexágonos para andar;
  - tocar num hexágono vazio não manda `move`;
  - a mensagem da vez diz "Atordoado: não dá para andar nesta vez.";
  - as Técnicas, a Mochila, a Esfera, a fuga e o Passar continuam como sempre.
- **RF-05:** O `BattleNarrator` (`res://screens/board_battle/battle_narrator.gd`) escreve no histórico, _a revisar_:
  - "`<nome>` ficou atordoado." no `status_applied` do `dazed`;
  - "`<nome>` não está mais atordoado." no `status_ended` do `dazed`.

  São os textos de hoje para qualquer estado, com o nome do catálogo em minúsculas.

  O `stat_changed` que vem de uma marca usa o texto de hoje.
- **RF-06:** Os eventos `damage` seguidos de uma Técnica de vários golpes ([01](01-field-rules.md), RF-12) tocam, cada um, o tremor e o pisca do alvo e o número de dano da [board-battle/09](../board-battle/09-hit-feedback.md), com 0,15 s entre um golpe e o próximo (_a revisar_). O efeito e o som da Técnica tocam uma vez, no primeiro golpe.
- **RF-07:** O `multi_hit` escreve "Acertou `<hits>` vezes!" no log e no histórico.
- **RF-08:** O detalhe da Técnica, que aparece ao segurar o ícone ([skill-cooldown](../skill-cooldown/)), mostra:
  - "Golpes `<min>` a `<max>`" no fim da linha de informações, quando `max_hits` é maior que 1;
  - "Dano fixo `<value>`" no lugar do "Poder", numa Técnica com `fixed_damage`.

  Sem dois-pontos, como o "Poder 40" e o "Precisão 100" da mesma linha.

## Critérios de aceite

- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` não aponta erro.
- [ ] No painel F3, o Redemoinho embaixo do Ecobeast do jogador pinta o hexágono de verde-água. No fim da vez de qualquer um, o Ecobeast fica com o ícone e as estrelinhas do Atordoado.
- [ ] Na vez dele, nenhum hexágono acende para andar, a mensagem avisa, e uma Técnica funciona.
- [ ] As Penas no ar embaixo do Ecobeast do jogador baixam a Precisão e a Evasão dele no fim da vez dele, com as plaquinhas dos atributos.
- [ ] Uma Técnica de vários golpes mostra um número de dano por golpe, um depois do outro, e o "Acertou N vezes!". Dá para conferir com a Rajada de Penas, depois da [03](03-puffcoo-line.md), ou com uma Técnica de teste no F1.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script.

## Desenho técnico

- **Alterar:**
  - `res://core/data/catalog_schema.gd` (RF-01);
  - em `res://screens/board_battle/`: `battle_statuses.gd` (`ORDER`, `VOLATILE`, `sync`), `status_icons.gd`, `creature_aura.gd`, `battle_effects_debug.gd`, `battle_narrator.gd` e `board_battle_screen.gd` (o `dazed` da vista no `sync`, e o andar travado no cálculo do `_reach`, que fica vazio quando quem joga está atordoado);
  - `res://ui/theme/palette.gd` (`STATUS_COLORS`);
  - o modelo da vista em `res://domain/models/` que lê `status` e `confused`, que passa a ler `dazed`;
  - a fila de efeitos dos golpes em `board_battle_screen.gd` (RF-06) e o detalhe da Técnica (RF-08), onde ele é montado.
- **Reutilizar:** o círculo dos ícones, o desenho das estrelinhas do `CreatureAura`, se já houver um parecido, e o `_refresh_marks`, que já pinta as marcas novas.

## Verificação

- F5 no Godot, com o servidor no ar: abrir uma luta, usar o painel F3 para pôr o Redemoinho e as Penas no ar embaixo dos Ecobeasts, passar algumas vezes e ler o histórico.
- `godot --headless --path client --quit-after 60`.

## Tarefas

- [x] `ground_effect_stats` no esquema e no validador.
- [x] O Atordoado no `BattleStatuses`, na cor, no ícone, no efeito no corpo, no sinal e no F3.
- [x] O andar travado e a mensagem.
- [x] Os textos do histórico.
- [x] Os golpes seguidos, o `multi_hit` e o detalhe da Técnica.
- [x] `client/CLAUDE.md`, o README da iniciativa e as tabelas das specs.

Conferido por Claude:
- o jogo abre sem janela com o servidor no ar, e o validador aceita o catálogo com `ground_effect_stats`;
- numa cena temporária, a tela da luta e os scripts mexidos compilam, o `BattleStatuses` põe e tira o `dazed` (pelo `sync`, pelo `status_ended` e no fim da luta), o narrador escreve "Acertou 4 vezes!" e o validador recusa `stages` 0;
- numa captura, o ícone âmbar tem as três estrelinhas, e as estrelinhas de 4 pontas do Atordoado se distinguem das estrelas da confusão.

Fica para o dono: a luta de verdade no editor, com o F3 (Redemoinho, Penas no ar e o andar travado), e os golpes seguidos, que só dá para ver com a Rajada de Penas da [03](03-puffcoo-line.md) ou com uma Técnica de teste no F1. O `client/CLAUDE.md` não ganhou linha: os estados da luta não são descritos lá.
