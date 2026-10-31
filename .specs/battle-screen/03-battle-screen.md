# 03. Tela de batalha

- **Status:** concluída
- **Depende de:** [02-battle-client](02-battle-client.md), [visual-theme](../visual-theme/README.md)

## Contexto

Com a rota do encontro e a batalha no cliente prontas, falta o que o jogador vê (TELAS.md #5). O layout é a opção A que o dono escolheu no canvas: o inimigo em um cartão no topo, seu Ecobeast em outro cartão, o histórico do turno entre eles e quatro botões embaixo.

## Escopo

- Tela `battle`, com os dois cartões, o histórico e os botões.
- Escolha da Técnica, golpe de emergência e Correr.
- Painel do próximo Ecobeast e fim da luta.
- Ligação de "Explorar zona" no Hub.

## Fora do escopo

Os itens de "Fora do escopo" do [README](README.md).

## Requisitos

**Abrir**

- **RF-01:** "Explorar zona" no Hub abre `&"battle"` com `Router.push`, sem parâmetros.
- **RF-02:** A tela chama `Session.start_wild_battle()` no `_ready` e mostra "Procurando um Ecobeast..." enquanto espera. Os eventos do começo seguem a mesma sequência de um turno, e só depois deles a tela chama `BattleNarrator.begin_turns()` e reativa os botões.
- **RF-03:** Com falha, a tela mostra o erro e um botão "Voltar ao Hub". É assim que aparece "Cure sua equipe no Refúgio."

**Cartões**

- **RF-04:** O cartão do inimigo tem nome da espécie, "Nv. <nível>", um `ElementBadge` por Elemento, os selos de condição, `HpBar` sem números e, à direita, o retrato espelhado.
- **RF-05:** O cartão do jogador tem, à esquerda, o retrato sem espelhar; ao lado, o nome de exibição, "Nv. <nível>", os selos de condição, `HpBar` com números e a barra de XP (`XpBar`), lida de `Session.player`.
- **RF-06:** Os selos mostram o status (o nome do catálogo), "Confuso" e cada estágio diferente de 0, como "Atq −1" ou "Vel +2", com os nomes curtos da tabela `stats`.
- **RF-07:** `CreaturePortrait` ganha `@export var flipped: bool`, que espelha o sprite. O placeholder desenhado não muda.

**Histórico**

- **RF-08:** O histórico fica entre os cartões, ocupa o espaço que sobrar e rola até a linha mais nova a cada linha nova.
- **RF-09:** A última linha fica em `TEXT` e as anteriores, em `TEXT_SECONDARY`. O histórico guarda as 50 últimas linhas.
- **RF-10:** A tela mostra um selo "Turno <n>" no topo.

**Ações**

- **RF-11:** Quatro botões de tamanho igual, em duas linhas: Atacar, Itens, Equipe e Correr.
- **RF-12:** Itens e Equipe ficam desativados, com "Em breve" abaixo do nome.
- **RF-13:** Correr envia `{"type": "flee"}`. Com `can_flee` falso, fica desativado.
- **RF-14:** Atacar troca os botões pelas quatro Técnicas e por "Voltar", que volta às ações sem chamar o servidor.
- **RF-15:** Cada Técnica mostra nome, `ElementBadge` e "PP <atual>/<máximo>", com a borda na cor do Elemento, e envia `{"type": "skill", "slot": <1 a 4>}`. Sem PP, fica desativada. Um slot sem Técnica diz "Vazio".
- **RF-16:** Sem PP em nenhuma Técnica, a lista vira um botão "Golpe de Esforço", com "Sem PP: ele também machuca quem usa.", que envia `{"type": "emergency"}`.

**Turno**

- **RF-17:** Ao agir, a tela volta às ações, com todos os botões desativados, e segue [Mostrar um turno](architecture.md#mostrar-um-turno). `LINE_DELAY` é uma constante da tela.
- **RF-18:** Com `ok` falso, a tela escreve o erro no histórico, em `DANGER`, e reativa os botões. Nada mais muda.
- **RF-19:** Com `data` nulo, a tela escreve "Essa batalha não existe mais." e mostra só "Voltar ao Hub".
- **RF-20:** Um toque durante a sequência não envia nada. Só existe uma chamada por vez.
- **RF-21:** O voltar do Android (Esc no editor) fecha as Técnicas, se estiverem abertas. Fora disso, não sai da luta. Com a luta encerrada ou com o erro de RF-03, faz o mesmo que "Voltar ao Hub".

**Próximo Ecobeast**

- **RF-22:** Em `choose_next`, um painel sobre a tela pede "Escolha o próximo Ecobeast" e lista a equipe, com retrato, nome, "Nv. <nível>" e `HpBar` com números.
- **RF-23:** Uma criatura com 0 HP fica desativada. Tocar em outra envia `{"type": "switch", "team_index": <posição>}`, fecha o painel e mostra os eventos.
- **RF-24:** O painel não se fecha sem uma escolha, e o voltar do Android não faz nada nele. Com falha, o erro aparece no painel, que continua aberto.

**Fim**

- **RF-25:** Em `ended`, os botões dão lugar ao resultado ("Você venceu!", "Você perdeu." ou "Você fugiu.") e a "Voltar ao Hub".
- **RF-26:** "Voltar ao Hub" chama `Session.load_player()` e volta com `Router.back`. O Hub se redesenha com o HP novo por `Session.player_changed`.
- **RF-27:** Se `load_player` falhar, a tela mostra o erro e continua aberta, e o botão tenta de novo.

## Critérios de aceite

- [x] Tocar em Explorar zona abre a batalha, e o Hub volta com a rolagem onde estava.
- [x] Os cartões, o histórico e os botões cabem em 720×1280, sem rolagem na tela.
- [ ] O mesmo vale em um aparelho com recorte (passo do dono).
- [x] Atacar abre as Técnicas com o PP certo, e Voltar não chama o servidor.
- [x] Uma Técnica mostra as linhas uma a uma, com o HP caindo junto, e os botões voltam no fim.
- [x] Depois do turno, os cartões batem com o JSON da resposta.
- [x] Um estágio alterado aparece como selo, e um status também.
- [x] Itens e Equipe não respondem ao toque.
- [x] Correr termina em "Você fugiu."; uma falha mostra "Não conseguiu fugir!", e o inimigo age.
- [x] Vencer mostra "Você venceu!", e o Hub volta com o HP e o PP gravados.
- [x] Com duas criaturas, um desmaio abre o painel, quem caiu fica desativado, e a escolhida entra sem o inimigo agir.
- [x] Perder mostra "Você perdeu.", e Explorar zona passa a mostrar "Cure sua equipe no Refúgio." com a saída para o Hub.
- [x] Sem PP, Atacar oferece só o Golpe de Esforço.
- [x] Com o servidor fora do ar no meio da luta, o erro aparece no histórico, e a luta continua quando ele volta.
- [x] Reiniciar o servidor no meio da luta mostra "Essa batalha não existe mais." e a saída.
- [x] Durante a luta, o voltar do Android não sai da tela.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**, em `client/screens/battle/`:

- `battle_screen.tscn` e `.gd`: a tela, com um `SafeArea`.
- `battle_side_card.tscn` e `.gd`: um cartão. `set_creature(creature: BattleCreature, display_name: String)`.
- `battle_skill_button.tscn` e `.gd`: uma Técnica ou "Vazio".
- `next_creature_panel.tscn` e `.gd`: o painel do próximo.
- `next_creature_row.tscn` e `.gd`: uma criatura desse painel.

**Alterar**

- `client/core/autoload/router.gd`: `&"battle"` em `SCREENS`.
- `client/screens/hub/hub_screen.gd`: o destino de "Explorar zona".
- `client/ui/components/creature_portrait.gd`: `flipped`.
- `TELAS.md`: a tela #5 com Atacar no lugar de Lutar e "Correr" no lugar de "Fugir".
- `.specs/roadmap.md`: `battle-screen` concluída.

**Reaproveitar**

`HpBar`, `XpBar`, `ElementBadge`, `CreaturePortrait`, `SectionPanel`, `OutlineButton`, `DangerButton`, `UiPalette` e a referência visual em `BatalhaCartoes.dc.html` no canvas. Sem cor fixa nas cenas: a borda de cada Técnica copia o estilo do tema antes de pintar, como o `ElementBadge`.

## Verificação

Uma cena temporária, nos moldes da [02](02-battle-client.md), joga uma luta contra o servidor de teste, confere os critérios automáticos e salva capturas em 405×720. As capturas são revisadas uma a uma: ações, Técnicas, turno em andamento, painel do próximo, vitória e erro.

Passos do dono no editor (F5) e no celular:

1. Jogar uma luta até vencer e outra até fugir.
2. Conferir se o ritmo das linhas está bom.
3. Conferir o Hub depois da luta.

```bash
cd server && npm run start:dev
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Registrar a tela e ligar o Hub (RF-01 a RF-03).
- [x] `flipped`, cartões e selos (RF-04 a RF-07).
- [x] Histórico e sequência do turno (RF-08 a RF-10, RF-17 a RF-20).
- [x] Botões, Técnicas e golpe de emergência (RF-11 a RF-16).
- [x] Voltar, próximo Ecobeast e fim (RF-21 a RF-27).
- [x] Remover os arquivos temporários; atualizar `TELAS.md`; marcar esta spec, a tabela do README e o roadmap como `concluída`; commit `feat: tela de batalha`.

## Decisões da implementação

- **`next_creature_row` é um arquivo próprio:** cada linha do painel tem retrato, nome, nível e HP, e a spec não previa uma cena para ela.
- **O erro de abertura não relê o jogador:** "Voltar ao Hub" só chama `load_player` depois que a luta existiu. Sem isso, sem rede, o jogador ficaria preso na tela da falha.
- **`Router.back` depois de "Voltar ao Hub":** como o voltar não sai da luta, a tela guarda que já pode fechar, senão o próprio `handle_back` a seguraria.
- **Itens e Equipe usam `OutlineButton`:** o estilo desativado do tema já mostra que não respondem, e "Em breve" fica na segunda linha do texto do botão.
- **Um espaço no topo e na base da coluna:** sem recorte, o `SafeArea` não dá margem vertical, e o selo de turno e os botões encostavam nas bordas.
- **Conferência:** uma cena temporária jogou lutas pelo Hub contra um servidor de teste, com 89 de 89 verificações, depois de falhar pela falta da tela: abertura, Técnicas, turno, selos, voltar, queda de rede, batalha perdida no servidor, fuga, próximo Ecobeast, sem PP, vitória, derrota e equipe sem HP. A queda de rede foi simulada trocando o endereço do servidor, e a batalha perdida, apagando-a da memória dele; o servidor não chegou a ser desligado nem reiniciado de verdade. As 12 capturas em 405×720 foram revisadas. O jogo abriu sem erros nem avisos de script, e os arquivos temporários foram removidos.
- **Falta do dono:** jogar no editor e no celular, conferir o ritmo das linhas e o recorte do aparelho.
