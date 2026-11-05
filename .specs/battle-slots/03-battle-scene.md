# 03. Cena da batalha

- **Status:** cancelada (a iniciativa foi substituída pela luta no tabuleiro, ver o [README](README.md))
- **Depende de:** [02-client-slots](02-client-slots.md), [battle-screen/03](../battle-screen/03-battle-screen.md), [inventory-shop](../inventory-shop/README.md), [team-and-storage](../team-and-storage/README.md), [progression](../progression/README.md)

## Contexto

A tela de batalha da [battle-screen/03](../battle-screen/03-battle-screen.md) é uma coluna: o cartão do inimigo, o histórico com várias linhas, o cartão do jogador e os botões. O dono quer outra tela, a partir de dois mockups que mandou em 2026-11-03:

- **A cena:** um cenário de fundo, o selvagem de frente no círculo de pedra do fundo e o Ecobeast do jogador de costas no círculo da frente. Há um painel de HP para cada um, uma caixa com uma mensagem só e quatro botões grandes e coloridos: Lutar, Equipe, Mochila e Fugir.
- **Lutar:** abre o painel "Escolha uma técnica", com quatro botões na cor do Elemento e "Voltar" embaixo.

As regras não mudam. É a mesma tela, com o mesmo caminho de uma ação e os mesmos eventos, mostrada de outro jeito. A cena foi desenhada para 1 contra 1, a luta de verdade. Depois, o dono pediu lutas de até 3 contra 3 ([README](README.md)): com mais de uma vaga, a mesma cena ganha um painel pequeno por Ecobeast, a escolha de quem age e a do alvo ([Mais de uma vaga](#mais-de-uma-vaga)).

## Escopo

- O fundo da Planície, um só por enquanto.
- O selvagem e o Ecobeast do jogador sobre o fundo, com a imagem de costas quando existir.
- Os painéis de HP no lugar dos cartões.
- A caixa de mensagem, letra por letra e com o toque para avançar, e o histórico que abre ao tocar na caixa.
- Os quatro botões novos e o painel de Técnicas.
- O fim da luta no lugar dos botões.
- Com 2 ou 3 vagas: os Ecobeasts lado a lado, um painel pequeno por Ecobeast, a ação de cada um e o alvo.
- A luta 2 contra 2 de teste no menu de depuração do mapa.

## Fora do escopo

- **Animações:** golpe, piscar ao apanhar, desmaio, entrada e respiração. Decisão do dono: "sem animação ainda, pode manter estático por enquanto". A barra de XP que enche na vitória ([progression/03](../progression/03-level-up-screen.md)) e o carregamento da Esfera ([capture](../capture/README.md)) continuam como estão.
- **Um fundo por bioma:** a escolha pelo bioma do hexágono vem com a `biome-terrain` do [roadmap](../roadmap.md).
- **As imagens de costas:** o dono vai gerá-las, uma por Ecobeast. Esta fase só as lê quando existirem.
- **O visual novo dos painéis por cima da tela:** Mochila, Equipe e troca, próximo Ecobeast, captura, comemoração, evolução e Técnica nova continuam como estão e funcionando.
- **Ícones que faltam:** os ícones de Técnica que faltam (15 das 38) e os de Elemento que faltam (11 dos 14).
- **Sons.**
- **Servidor:** nenhuma mudança.

## Requisitos

**Cena**

- **RF-01:** A tela inteira, inclusive atrás do recorte do aparelho, mostra `res://assets/backgrounds/battle/temperate.png`. A imagem cobre a tela sem distorcer, cortando as laterais em telas mais estreitas que 9:16.
- **RF-02:** O selvagem fica em pé no círculo do fundo, e o Ecobeast do jogador no círculo da frente, maior. As duas posições acompanham a imagem quando ela é cortada.
- **RF-03:** O selvagem usa `front.png` espelhado, olhando para a esquerda, para o jogador, como hoje.
- **RF-04:** O Ecobeast do jogador usa `res://assets/creatures/<slug>/back.png`, quando existe. Sem ela, usa `front.png` sem espelhar, olhando para a direita, para o selvagem. Sem nenhuma das duas, usa o placeholder do `CreaturePortrait`.
- **RF-05:** Quem entra na luta, na abertura ou numa troca, troca a imagem do seu lado junto com o painel. Quem desmaia continua na cena até o próximo entrar ou a luta acabar.

**Painéis**

- **RF-06:** O painel do selvagem fica no topo, à esquerda. Ele tem:
  - um círculo com o ícone do 1º Elemento;
  - "<espécie> Selvagem" e uma etiqueta vermelha "Nv. <nível>";
  - a barra de HP e "<HP> / <máximo>";
  - uma etiqueta por Elemento, na cor dele.
- **RF-07:** O painel do jogador fica à direita, logo acima da caixa de mensagem. Ele tem:
  - o círculo com o ícone do 1º Elemento;
  - o nome de exibição e uma etiqueta verde "Nv. <nível>";
  - "HP" com a barra e "<HP> / <máximo>";
  - "EXP" com a barra de XP e "Próximo nível: <n>".

  `<n>` é o XP que falta para o próximo nível. No nível 100, aparece "Nível máximo", com a barra cheia.
- **RF-08:** Um Elemento sem `res://assets/ui/elements/<slug>/icon.png` mostra o círculo na cor do Elemento, sem ícone.
- **RF-09:** Os selos de status, "Confuso" e estágios da [battle-screen/03](../battle-screen/03-battle-screen.md) (RF-06) continuam, como etiquetas pequenas dentro do painel de cada lado.
- **RF-10:** O selo "Turno <n>" sai da tela.

**Caixa de mensagem**

- **RF-11:** Uma caixa escura, logo acima dos botões, mostra uma frase por vez.
- **RF-12:** Cada frase aparece letra por letra, a `CHARS_PER_SECOND` (60, _a revisar_). A linha de moedas da [progression/05](../progression/05-wild-coins.md) mostra o ícone da moeda inteiro, que conta como uma letra.
- **RF-13:** Enquanto o turno é mostrado, um toque em qualquer lugar da tela, inclusive na caixa:
  - com a frase ainda sendo escrita, completa a frase;
  - com a frase completa, passa para o próximo evento.

  Um evento sem frase não espera toque.
- **RF-14:** A última frase de um turno que volta para `choose_action` não espera toque: quando termina de ser escrita, os botões voltam, e ela fica na caixa. Nas outras fases (`choose_next` e `ended`), a última frase espera o toque antes do painel do próximo, da comemoração ou do resultado.
- **RF-15:** O painel de cada lado muda quando o evento é aplicado, antes da frase dele, como hoje. Os números trocam de uma vez, sem animação.
- **RF-16:** Um erro de ação aparece na caixa, em `DANGER`, e os botões voltam. "Procurando um Ecobeast..." aparece na caixa durante a abertura.

**Histórico**

- **RF-17:** Com os botões à vista, tocar na caixa abre o histórico. É um painel por cima da cena, do painel do selvagem até os botões, com as 50 últimas frases da luta, a mais nova embaixo e à vista, e rolagem.
- **RF-18:** O histórico guarda todas as frases mostradas na caixa, inclusive erros e a de moedas, com o ícone. A mais nova fica em `TEXT`, e as outras em `TEXT_SECONDARY`.
- **RF-19:** Tocar no histórico ou no voltar do Android fecha o histórico. Enquanto ele está aberto, os botões não respondem.

**Botões**

- **RF-20:** Quatro botões grandes, em duas linhas, cada um com ícone e nome:
  - Lutar, vermelho;
  - Equipe, azul;
  - Mochila, verde;
  - Fugir, roxo.

  Eles fazem o que Atacar, Equipe, Itens e Correr fazem hoje, e desativam nas mesmas condições.
- **RF-21:** Lutar troca a caixa e os botões pelo painel "Escolha uma técnica", com as quatro Técnicas em duas linhas e "Voltar" embaixo, à esquerda. "Voltar" e o voltar do Android trazem os botões de volta, sem chamar o servidor.
- **RF-22:** Cada botão de Técnica tem:
  - fundo na cor do Elemento;
  - à esquerda, um círculo com `res://assets/skills/<slug>.png`, ou, sem ele, o ícone do Elemento, como no RF-08;
  - uma etiqueta com o nome do Elemento;
  - o nome da Técnica;
  - "PP <atual> / <máximo>".

  Ele envia `{"type": "skill", "slot": <1 a 4>}`, como hoje.
- **RF-23:** Uma Técnica sem PP fica desativada e apagada. Uma vaga sem Técnica aparece apagada, com "Vazio".
- **RF-24:** Sem PP em nenhuma Técnica, o painel mostra só o botão "Golpe de Esforço" e "Sem PP: ele também machuca quem usa.", como na [battle-screen/03](../battle-screen/03-battle-screen.md) (RF-16).

**Fim**

- **RF-25:** No fim da luta, o resultado ("Você venceu!", "Você perdeu.", "Você fugiu." ou "Capturado!") e "Voltar" ficam no lugar dos quatro botões. A última frase continua na caixa, e tocar nela abre o histórico. O resto do fim segue a [battle-screen/03](../battle-screen/03-battle-screen.md) (RF-26 e RF-27).
- **RF-26:** Os erros de abertura (RF-03 da [battle-screen/03](../battle-screen/03-battle-screen.md)), como "Cure sua equipe no Refúgio.", e "Essa batalha não existe mais." aparecem na caixa, com "Voltar" no lugar dos botões. Sem luta, a cena mostra só o fundo.

**Voltar do Android**

- **RF-27:** O voltar do Android fecha, nesta ordem, o que estiver aberto: os painéis de hoje, o histórico e as Técnicas. No fim da luta, faz o mesmo que "Voltar". Fora disso, não sai da luta.

**Mais de uma vaga**

Os requisitos acima descrevem 1 vaga por lado. Com 2 ou 3, mudam assim:

- **RF-28:** Os Ecobeasts de cada lado ficam lado a lado em volta do círculo daquele lado, menores, por posição da esquerda para a direita. As posições e a escala de cada número de vagas são constantes do `BattleStage`, _a revisar_.
- **RF-29:** Cada Ecobeast em campo tem um painel compacto: nome, "Nv. <nível>", a barra de HP e os selos. O do jogador mostra também "<HP> / <máximo>" e a barra de XP, sem "Próximo nível". Os do selvagem ficam em uma linha no topo, e os do jogador em uma linha acima da caixa, na ordem das posições. Uma vaga vazia não mostra painel nem Ecobeast.
- **RF-30:** No `choose_action`, a tela pede a ação de cada Ecobeast do jogador de pé em campo, da esquerda para a direita. O painel de quem escolhe fica com a borda em `ACCENT`, e a caixa diz "O que <nome> vai fazer?".
- **RF-31:** Escolhida a ação, a tela passa para o próximo. Do segundo em diante, um botão "Voltar" desfaz a escolha anterior. Com a ação do último, a tela manda a lista inteira.
- **RF-32:** Fugir só fica ativo na vez do primeiro e manda `[{"type": "flee"}]` na hora.
- **RF-33:** Uma Técnica ou uma Esfera contra o adversário, com mais de um adversário de pé, abre "Escolha o alvo". É um painel no lugar das Técnicas, com um botão por adversário de pé: nome, "Nv. <nível>" e a barra de HP. "Voltar" volta às Técnicas ou à Mochila. Com um adversário só, o alvo vai direto.
- **RF-34:** Equipe e Mochila, na vez de um Ecobeast, gastam a ação dele. A Equipe não deixa escolher quem já está em campo ou já vai entrar.
- **RF-35:** No `choose_next`, o painel do próximo abre uma vez por posição de `pending_positions`, em ordem, com o título "Quem entra no lugar de <nome>?". A tela manda as trocas juntas no fim.
- **RF-36:** Só com `OS.is_debug_build()`, o menu de depuração do mapa ([wild-battle/13](../wild-battle/13-debug-menu.md)) ganha "Debug: luta 2×2". Ele abre a batalha pela rota de teste, com `slots: 2` e dois Ecobeasts sorteados do catálogo, no nível do Ecobeast da frente da equipe.

## Critérios de aceite

- [ ] A tela mostra o fundo da Planície cobrindo a tela, sem faixas, em 360×640, 405×720 e 412×915.
- [ ] Nos três tamanhos, o selvagem fica no círculo do fundo e o Ecobeast do jogador no da frente, e nenhum painel cobre o rosto de um deles.
- [ ] Um Ecobeast com `back.png` aparece de costas, e um sem ela aparece de frente, olhando para o selvagem.
- [ ] Os painéis mostram nome, nível, HP, Elementos e, no do jogador, EXP e "Próximo nível", e batem com o JSON da resposta no fim do turno.
- [ ] Um turno mostra uma frase por vez, letra por letra. O primeiro toque completa a frase, e o seguinte passa para a próxima.
- [ ] O HP do painel muda junto com a frase do dano.
- [ ] Depois da última frase de um turno comum, os botões voltam sem toque, e a frase fica na caixa.
- [ ] Com os botões à vista, tocar na caixa abre o histórico com as frases da luta, e tocar de novo o fecha.
- [ ] Lutar abre "Escolha uma técnica":
  - as cores e o PP estão certos;
  - uma Técnica sem ícone mostra o do Elemento ou a cor;
  - "Voltar" não chama o servidor.
- [ ] Sem PP, Lutar mostra só o Golpe de Esforço.
- [ ] Equipe, Mochila, captura, troca, próximo Ecobeast, comemoração, evolução e Técnica nova funcionam como antes.
- [ ] Vencer, perder, fugir e capturar mostram o resultado no lugar dos botões, e "Voltar" volta ao mapa.
- [ ] A linha de moedas aparece na caixa e no histórico com o ícone.
- [ ] O voltar do Android fecha o histórico e as Técnicas, e não sai da luta no meio dela.
- [ ] A luta 2×2 de depuração mostra dois Ecobeasts e dois painéis por lado, sem cobrir os rostos, nos três tamanhos.
- [ ] Num 2×2, a tela pede a ação de cada um, com a borda e "O que <nome> vai fazer?". "Voltar" desfaz a anterior, e o turno só roda depois do último.
- [ ] Uma Técnica com dois adversários de pé pede o alvo, e o dano cai em quem foi escolhido.
- [ ] Fugir só responde na vez do primeiro.
- [ ] Um desmaio com reserva pede quem entra naquela vaga, e uma vaga sem reserva fica vazia.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**, em `client/`:

- `assets/backgrounds/battle/temperate.png`: a imagem que o dono mandou, sem mudança, com o `.import`.
- `screens/battle/battle_stage.tscn` e `.gd`: o fundo e os dois Ecobeasts. É um `AspectRatioContainer` com a proporção da imagem e `stretch_mode` em cobrir, para as posições dos Ecobeasts, em fração da imagem, acompanharem o corte. Ele tem `set_creatures(player_species_id: int, enemy_species_id: int)`, e um id negativo esconde aquele lado.
- `screens/battle/battle_hud.tscn` e `.gd`: o painel de um lado, no lugar do `BattleSideCard`. Mantém `set_creature`, `set_xp` e `animate_xp`, e tem `@export var is_enemy`.
- `screens/battle/battle_message_box.tscn` e `.gd`: a caixa. Ela tem:
  - `show_line(text: String, color: Color)`, que escreve letra por letra;
  - `wait_advance()`, que espera o toque, com um primeiro toque que completa;
  - o sinal `opened`, para o toque com os botões à vista.

  A linha de moedas usa `RichTextLabel` com `visible_characters`, como a [progression/05](../progression/05-wild-coins.md) já faz no log.
- `screens/battle/battle_history.tscn` e `.gd`: o histórico, com a rolagem e as cores da [battle-screen/03](../battle-screen/03-battle-screen.md) (RF-09).
- `screens/battle/battle_target_panel.tscn` e `.gd`: o "Escolha o alvo" do RF-33.
- `screens/battle/battle_turn_plan.gd`: a lista de ações do turno, com quem escolhe agora, avançar e desfazer. É uma classe sem nó, para a tela só mostrar.

**Alterar**

- `screens/battle/battle_screen.tscn` e `.gd`:
  - o novo layout: o `BattleStage` fora do `SafeArea`, ocupando a tela toda, e, dentro dele, o painel do selvagem no topo e, no rodapé, o painel do jogador, a caixa e os botões;
  - `_show_turn` trocando a espera de `LINE_DELAY` pelo toque;
  - os textos Lutar, Mochila e Fugir;
  - o `handle_back` com o histórico.
- `screens/battle/battle_skill_button.tscn` e `.gd`: o visual do RF-22.
- `screens/battle/next_creature_panel.gd`: a lista de quem está em campo ou vai entrar, e o título do RF-35.
- `screens/exploration/`: o botão do RF-36.
- `core/autoload/session.gd` e os serviços: `start_test_battle(slots: int, enemies: Array[Dictionary])`, pela rota de teste.
- `ui/components/creature_portrait.gd`: o Ecobeast do jogador precisa de `back.png`. Pode ser uma propriedade `@export var view: StringName` (`&"front"` ou `&"back"`), com a regra de queda do RF-04.
- `TELAS.md`: a tela #5 com a cena, a caixa de mensagem e Lutar, Equipe, Mochila e Fugir.
- `.specs/battle-screen/README.md`: um aviso de que a tela mudou nesta fase.
- `.specs/battle-screen/architecture.md`: "Mostrar um turno" com o toque no lugar de `LINE_DELAY`.

**Remover**

- `battle_side_card.tscn` e `.gd`, que viram o `BattleHud`.

**Reaproveitar**

- `HpBar`, `XpBar`, `ElementBadge` (o ícone e a cor do Elemento) e `UiPalette`.
- Os painéis de hoje (`BattleItemsPanel`, `NextCreaturePanel` e os overlays), sem mudança.
- Os ícones `res://ui/icons/team.svg` (Equipe) e `res://assets/ui/actions/bag.webp` (Mochila).
- Lutar e Fugir não têm ícone no projeto. Quem implementa desenha dois SVGs simples em `res://ui/icons/`, no estilo dos que já existem (`swords.svg` e `run.svg`), marcados como _a revisar_.

As cores dos botões e dos painéis vão para `UiPalette`, sem cor fixa nas cenas. A posição e o tamanho de cada peça seguem os dois mockups do dono, e quem implementa ajusta pelos critérios de aceite nos três tamanhos.

## Verificação

Uma cena temporária, nos moldes da [battle-screen/03](../battle-screen/03-battle-screen.md), abre a tela contra o servidor de teste e salva capturas em 360×640, 405×720 e 412×915 de:

- a abertura;
- uma frase pela metade e completa;
- os botões;
- as Técnicas;
- o histórico aberto;
- o painel do próximo;
- a luta 2×2: a escolha de cada um, o alvo e uma vaga vazia;
- a vitória com moedas;
- um erro.

As capturas são revisadas uma a uma, e os arquivos temporários são removidos.

```bash
cd server && npm run start:dev
godot --headless -d --path client --quit-after 60
```

Passos do dono no editor (F5) e no celular:

1. Jogar uma luta até vencer, outra até perder e uma captura.
2. Conferir se a velocidade das letras está boa.
3. Conferir o histórico e o voltar do Android.
4. Colocar um `back.png` em um Ecobeast e ver que ele aparece de costas.
5. Jogar a luta 2×2 de depuração até o fim.

## Tarefas

- [ ] Fundo e `BattleStage`, com o `back.png` e as quedas (RF-01 a RF-05).
- [ ] `BattleHud` no lugar dos cartões (RF-06 a RF-10).
- [ ] Caixa de mensagem e o turno pelo toque (RF-11 a RF-16).
- [ ] Histórico (RF-17 a RF-19).
- [ ] Botões, ícones e painel de Técnicas (RF-20 a RF-24).
- [ ] Fim, erros e voltar (RF-25 a RF-27).
- [ ] Mais de uma vaga, o alvo e a luta 2×2 de depuração (RF-28 a RF-36).
- [ ] Remover os arquivos temporários. Atualizar `TELAS.md`, o README e o `architecture.md`. Marcar esta spec, o README e o roadmap como `concluída` e fazer o commit `feat: cena da batalha`.
