# 18. O efeito de toda Técnica com ícone, na cor do Elemento

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [09](09-hit-feedback.md), [11](11-support-skill-effects.md) e [15](15-projectile-effects.md) (o efeito, o efeito sem dano e o projétil, que entram por arquivo)

## Contexto

Até a [17](17-idle-facing.md), só quatro Técnicas têm efeito: a Arranhão, a Rugido Feroz, a Investida Veloz e a Faísca Rápida. Em 2026-11-13, o dono pediu o efeito das Técnicas que têm ícone, tirado do kit "Effect and FX Pixel All Free" (`Free/Part N/<número>.png`, fora do repositório): "A cor do efeito deve corresponder ao tipo da técnica. Por exemplo, técnica de flora deve ter a cor verde no efeito, instinto vai ser marrom, fogo vai ser vermelho, agua será azul e por ai vai. Quero que aplique todos que encaixarem naquele efeito." Ele pediu para Claude escolher e fazer tudo de uma vez, e revisar no fim.

Cada folha do kit tem 9 linhas de cor, com os mesmos quadros de 64 × 64 em cada uma. Então a cor não precisa de pintura: basta escolher a linha do Elemento.

Depois, no mesmo dia, o dono trocou a forma da Mordida Brasa: "na mordida brasa usa a 509.png" (a `Part 11/509.png`), e depois a da Presa Ígnea: "presa ignia voce vai usar a 477.png" (a `Part 10/477.png`), e a da Erupção Solar: "a erupção dolar você vai usar a 436.png" (a `Part 9/436.png`), e a da Lâmina d'Água: "lamina de agua você usa a 589.png" (a `Part 12/589.png`), e a do Maremoto: "maremoto vai ser a 654.png" (a `Part 14/654.png`).

São 26 Técnicas com ícone. Faltavam 22: 6 de Fogo, 9 de Água e 7 de Flora.

## Escopo

- A tabela que liga cada Elemento a uma linha de cor do kit.
- O efeito das 22 Técnicas com ícone que não tinham um, e o projétil da Chama Espiral, a única delas com alcance maior que 1.
- O efeito das Técnicas em si mesmo (`self`), que hoje não tocaria em todas.
- O gerador que recorta as folhas, para refazer ou trocar uma escolha.

## Fora do escopo

- Os sons: uma Técnica sem arquivo de som não toca nada, como hoje (a [09](09-hit-feedback.md), RF-09). Vieram depois, na [19](19-element-skill-sounds.md).
- Mudar os quatro efeitos de antes: foram escolhas do dono, e já estão na cor do Elemento.
- As Técnicas sem ícone: entram quando ganharem o ícone, com uma linha no gerador.
- Pintar as folhas ou mudar os pixels.

## Requisitos

- **RF-01:** A linha de cor de cada Elemento (_a revisar_). O kit tem 9 linhas e o jogo tem 15 Elementos, então alguns dividem a linha:

  | Linha | Cor no kit | Elementos |
  | --- | --- | --- |
  | 1 | laranja e amarelo | Volt, Luz |
  | 2 | roxo e rosa | Toxina, Mente |
  | 3 | azul-claro | Água, Gelo |
  | 4 | verde | Flora, Inseto |
  | 5 | marrom | Instinto |
  | 6 | cinza e branco | Vento, Metal |
  | 7 | marrom arroxeado | Terra |
  | 8 | vermelho com miolo amarelo | Fogo |
  | 9 | azul-escuro e violeta | Sombra, Arcano |

  O Fogo é a 8ª, como a Faísca Rápida ([15](15-projectile-effects.md)), e o Instinto é a 5ª, como a Arranhão, a Rugido Feroz e a Investida Veloz.

- **RF-02:** O efeito de cada Técnica, escolhido por Claude pela forma (_a revisar_). A folha é `Part/número` do kit.

  | Técnica | Elemento | Folha | Forma |
  | --- | --- | --- | --- |
  | Mordida Brasa | Fogo | 11/509 | três riscos curvos de dentes (a mesma forma da Garra de Maré, em vermelho), pedido do dono; antes era a 2/64, duas presas que se fecham |
  | Fumaça Densa | Fogo | 10/476 | nuvem de fumaça que sobe e se desfaz |
  | Presa Ígnea | Fogo | 10/477 | uma presa em meia-lua que cresce num golpe de fogo e se desfaz em brasas, pedido do dono; antes era a 13/622, duas mandíbulas que se encontram |
  | Chama Espiral | Fogo | 6/296 | espiral que gira e se fecha |
  | Couraça de Cinzas | Fogo | 14/674 | escudo de hexágono que se forma |
  | Erupção Solar | Fogo | 9/436 | um sol que estoura em raios curvos e se desfaz, pedido do dono; antes era a 11/527, uma erupção que sobe do chão em pontas |
  | Jato de Maré | Água | 12/566 | jato de lado que estoura numa nuvem |
  | Espuma Densa | Água | 11/519 | bolhas que se juntam e estouram |
  | Garra de Maré | Água | 11/509 | três riscos curvos de garra |
  | Casca Fechada | Água | 11/528 | cúpula que se fecha sobre o corpo |
  | Lâmina d'Água | Água | 12/589 | um corte em meia-lua que varre na diagonal e se desfaz, pedido do dono; antes era a 3/114, uma lâmina em meia-lua |
  | Maré Restauradora | Água | 14/673 | brilhos e bolhas que se espalham |
  | Torrente | Água | 10/484 | coluna de água que sobe e cai |
  | Muralha de Coral | Água | 15/712 | favos de hexágono que crescem |
  | Maremoto | Água | 14/654 | uma onda que cai de cima, cobre o alvo numa cúpula escorrendo e se desfaz, pedido do dono; antes era a 3/124, uma onda que se enrola e quebra |
  | Chicote de Raiz | Flora | 11/516 | chicote que sobe ondulando |
  | Esporos Sonolentos | Flora | 12/568 | nuvem de esporos |
  | Seiva Vital | Flora | 3/135 | raízes que se enroscam no alvo |
  | Folha Navalha | Flora | 6/283 | três lâminas que se cruzam no alvo |
  | Banho de Sol | Flora | 14/652 | raios de sol que se abrem |
  | Tempestade de Pétalas | Flora | 4/174 | pétalas girando |
  | Explosão Florida | Flora | 2/79 | flor que explode |

- **RF-03:** `res://assets/effects/skills/<slug>.png` é a linha do Elemento da folha, de quadros de 64 da esquerda para a direita, sem mudança nos pixels. Os quadros vazios do começo e do fim são cortados: eles só atrasariam a luta, porque a sequência espera o efeito acabar (a [09](09-hit-feedback.md), RF-02).
- **RF-04:** A Chama Espiral (alcance 3) ganha o projétil `chama_espiral_projectile.png`, a 8ª linha da `Part 12/578.png`: uma bola de fogo que cresce num cometa apontado para a direita. Ela voa como a Faísca Rápida ([15](15-projectile-effects.md)), e a espiral aparece no alvo na chegada. A 578 não é em loop; o voo de até 3 hexágonos dura uns 5 quadros, e eles mostram a bola crescendo.
- **RF-05:** Uma Técnica com alvo `self` toca o efeito sobre quem a usou logo depois de ele tremer, e não espera outro evento. Antes, a Casca Fechada não tocava nada (a proteção não gera evento), e a Maré Restauradora e o Banho de Sol também não (o `healed` não toca efeito). A Couraça de Cinzas e a Muralha de Coral tocam no mesmo instante de antes, sem repetir no `stat_changed`.
- **RF-06:** O resto não muda: uma Técnica com dano toca o efeito a cada `damage`, e a sem dano toca uma vez, no primeiro `stat_changed` ou `status_applied` ([11](11-support-skill-effects.md)). A Seiva Vital toca no alvo e não de novo na cura de quem a usou.

## Critérios de aceite

- [x] As 22 Técnicas têm o efeito, e a Chama Espiral tem o projétil, cada um na linha do Elemento.
- [x] Numa luta sem janela, uma Técnica `self` toca o efeito sobre quem a usou.
- [ ] O dono vê os efeitos numa luta e troca as formas de que não gostar.

## Desenho técnico

**Criar:** `res://assets/effects/skills/cut_effects.gd`, que recorta as folhas: `ELEMENT_ROWS` (o RF-01), `EFFECTS` (o RF-02) e `PROJECTILES` (o RF-04). O kit fica fora do repositório e é passado como argumento, como no `make_objects.gd`:

```bash
godot --headless -s res://assets/effects/skills/cut_effects.gd -- "C:/Users/ferna/Downloads/Effect and FX Pixel All Free/Free" [slugs]
```

Sem slugs, ele grava só os do `EFFECTS` e do `PROJECTILES`; os quatro de antes não estão nas tabelas e ficam como estão. Para trocar uma forma, muda-se a linha e roda-se de novo.

**Alterar:** `res://screens/board_battle/board_battle_screen.gd`: no `skill_used`, depois do tremor, uma Técnica `self` chama `_play_skill_effect(key)` sobre quem a usou.

**Reutilizar:** `_play_skill_effect`, `BoardBattleView.play_effect` e `fly_projectile`, `ContentFiles.SKILL_EFFECT_PATH` e `SKILL_PROJECTILE_PATH`. O visualizador de conteúdo (F1) passa a mostrar os efeitos sem mudar nada nele.

## Verificação

- O gerador grava os 23 arquivos; uma imagem com o quadro do meio de cada um, na cor do Elemento, vai ao dono.
- Um teste sem janela, com uma luta montada, usa a Casca Fechada e confere que o efeito aparece sobre quem a usou, e usa a Mordida Brasa e confere o efeito no alvo.
- O projeto importa sem erros, e o jogo sem janela abre sem erros nem avisos de script.
- Manual, com F5: o dono vê os efeitos numa luta.

## Tarefas

- [x] Spec.
- [x] O gerador e os 23 arquivos.
- [x] O efeito das Técnicas `self`.
- [x] O teste sem janela e a imagem dos efeitos.
- [ ] O dono ver com F5.

## Resultado da verificação

Em 2026-11-13, sem janela:

- **Arquivos:** o `cut_effects.gd` gravou os 22 efeitos e o projétil da Chama Espiral, de 8 a 21 quadros de 64 depois do corte dos quadros vazios. Uma imagem com 6 quadros de cada um, na cor do Elemento, foi mandada ao dono.
- **Luta:** uma cena temporária (já apagada) abriu a tela da luta com dois Ecobeasts postos à mão, sem criar luta no servidor, e tocou as Técnicas. Sem a mudança do RF-05, a Casca Fechada e o Banho de Sol não mostravam efeito. Com ela, a Casca Fechada, o Banho de Sol (com o `healed`) e a Muralha de Coral (com o `stat_changed`) mostram o efeito uma vez sobre quem as usou. A Mordida Brasa e os Esporos Sonolentos mostram o deles uma vez no alvo. A Chama Espiral voa até o alvo, e a espiral aparece nele 0,1 s depois.
- **Projeto:** importa sem erros, e o jogo sem janela abre sem erros nem avisos de script.
- **Falta o dono:** ver os efeitos numa luta com F5 e trocar as formas de que não gostar (uma linha no `EFFECTS` do `cut_effects.gd`).
