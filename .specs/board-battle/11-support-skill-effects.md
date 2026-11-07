# 11. Efeito e som das Técnicas sem dano: a Rugido Feroz

- **Status:** concluída (falta o dono ver e ouvir no editor)
- **Depende de:** [09-hit-feedback](09-hit-feedback.md) (o efeito e o som da Técnica no golpe)

## Contexto

Na [09](09-hit-feedback.md), o efeito e o som de uma Técnica tocam a cada `damage` dela. A Rugido Feroz, a Técnica de nível 1 do Ruvo, do Ruvak e do Ruvaroth, não causa dano: ela só baixa o Ataque do alvo em 1 nível (`stat_changed`). Então nenhum arquivo dela tocaria. Em 2026-11-06, o dono perguntou como a Rugido Feroz deveria ser, e Claude indicou um efeito, um som de rugido e um sinal de "Ataque caiu" sobre o alvo. O dono escolheu o efeito e o som: "use o vfx 398 com a cor marrom" (`Free/Part 8/398.png` do kit "Effect and FX Pixel All Free") "e crie o som".

A folha 398 tem 576 × 576 pixels, em células de 64: 9 linhas de cor com os mesmos 9 quadros, uma explosão de pontas que nasce do chão, cresce e se desfaz. A marrom é a 5ª linha, a mesma cor da Arranhão.

## Escopo

- O efeito e o som da Rugido Feroz.
- Uma Técnica sem dano toca o efeito e o som dela uma vez, no primeiro evento que ela causa em alguém.

## Fora do escopo

- O sinal de stat sobre o alvo ("Ataque ↓"): oferecido, o dono não pediu.
- O alvo encolher de susto.
- O efeito e o som das outras Técnicas de apoio: cada uma chega com os arquivos dela, sem mudar código.

## Requisitos

- **RF-01:** `res://assets/effects/skills/rugido_feroz.png` é a 5ª linha (a marrom) da `Part 8/398.png`, 576 × 64, com 9 quadros de 64, sem mudança nos pixels.
- **RF-02:** `res://assets/sounds/skills/rugido_feroz.wav` é um rugido gerado por síntese, sem gravação de terceiros, por `art-source/sounds/rugido_feroz.py`: um grave áspero que sobe e desce de altura, com um ruído rouco por cima, em 0,6 s (_a revisar_).
- **RF-03:** Depois do `skill_used`, se a Técnica ainda não tocou o efeito nesse uso, o primeiro `stat_changed` ou `status_applied` toca o som e o efeito dela sobre a criatura do evento, como o `damage` faz (a 09, RF-02 e RF-09), antes da frase. A Rugido Feroz mostra o efeito sobre o alvo e depois escreve "Ataque de … caiu.".
- **RF-04:** Uma Técnica com dano continua tocando o efeito a cada `damage`, e não toca de novo no `stat_changed` ou `status_applied` que vier depois no mesmo uso.
- **RF-05:** Sem `skill_used` antes (o chão em chamas, um estado no começo da vez), o `stat_changed` e o `status_applied` não tocam nada, como hoje.

## Critérios de aceite

- [ ] Na luta, a Rugido Feroz faz o atacante tremer, o rugido tocar com a explosão marrom sobre o alvo, e depois a frase da queda do Ataque.
- [ ] A Arranhão continua com o efeito e o som de antes, uma vez por golpe.

## Desenho técnico

**Alterar:** `res://screens/board_battle/board_battle_screen.gd`: um `_effect_played` (bool) que o `skill_used` zera e o `_play_skill_effect` liga; no `match`, `stat_changed` e `status_applied` chamam `_play_skill_effect(key)` quando ele está desligado.

**Criar:** `art-source/sounds/rugido_feroz.py`, `rugido_feroz.png` e `rugido_feroz.wav` com os `.import`.

**Reutilizar:** `_play_skill_effect`, `BoardBattleView.play_effect`, `ContentFiles.SKILL_EFFECT_PATH` e `SKILL_SOUND_PATH`. O visualizador de conteúdo passa a mostrar a Rugido Feroz com ícone, efeito e som, sem mudar nada nele.

## Verificação

- Um teste sem janela, com uma luta montada, usa a Rugido Feroz e confere a ordem: o atacante treme, o efeito `rugido_feroz.png` aparece sobre o alvo com o som tocando, e a frase da queda vem depois.
- O teste da Arranhão (09) segue dando 0 falhas.
- O projeto importa sem erros.
- Manual, com F5: o dono vê e ouve a Rugido Feroz numa luta.

## Tarefas

- [x] Teste da Rugido Feroz, vendo falhar.
- [x] O efeito recortado e o som gerado.
- [x] O efeito nas Técnicas sem dano.
- [x] Os testes da 09 e desta.
- [ ] O dono ver e ouvir com F5.

## Resultado da verificação

Em 2026-11-06, o teste sem janela da Rugido Feroz falhou antes do código (o atacante tremia e a frase vinha, sem efeito nem som) e passou depois: o atacante treme aos 2,44 s, o efeito `rugido_feroz.png` e o som começam juntos aos 3,45 s, a frase "Ataque de Ruvak caiu." vem aos 3,95 s, e nenhum número de dano aparece. Os testes da Arranhão e do som de dano (09) seguiram com 0 falhas, com o efeito uma vez por golpe. O projeto importou sem erros, e o jogo sem janela abriu sem erros nem avisos de script. O script do visualizador de conteúdo passou a esperar 2 de 52 Técnicas com efeito e com som, e a Rugido Feroz com os dois; deu 0 falhas.

O som foi conferido pelo volume ao longo do tempo (sobe em 0,05 s, fica até 0,3 s e some até 0,6 s), mas não foi ouvido aqui. Falta o dono ver e ouvir com F5.
