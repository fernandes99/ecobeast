# 14. Efeito e som da Investida Veloz

- **Status:** concluída (falta o dono ver e ouvir no editor)
- **Depende de:** [09-hit-feedback](09-hit-feedback.md) (o efeito e o som da Técnica no golpe)

## Contexto

Na [09](09-hit-feedback.md), o efeito e o som de uma Técnica tocam a cada `damage` dela, se os arquivos existirem: só a Arranhão os tinha, e a Rugido Feroz ganhou os dela na [11](11-support-skill-effects.md). A Investida Veloz é a Técnica corpo a corpo de Elemento Instinto, com 40 de poder e prioridade, e batia sem efeito nem som. Em 2026-11-07, o dono pediu: "quero usar o 333 de C:\Users\ferna\Downloads\Effect and FX Pixel All Free\Free\Part 7. e como ela é do tipo instinto, precisa usar a cor marrom. crie para mim o som também".

A folha 333 tem 576 × 576 pixels, em células de 64: 9 linhas de cor com os mesmos 9 quadros, um risco rápido que cresce na diagonal e some. A marrom é a 5ª linha, a mesma cor da Arranhão e da Rugido Feroz.

## Escopo

- O efeito e o som da Investida Veloz.

## Fora do escopo

- O atacante avançar até o alvo e voltar.
- Mudar código: a Investida Veloz causa dano, e a 09 já toca o efeito e o som de qualquer Técnica que tenha os arquivos.

## Requisitos

- **RF-01:** `res://assets/effects/skills/investida_veloz.png` é a 5ª linha (a marrom) da `Part 7/333.png`, 576 × 64, com 9 quadros de 64, sem mudança nos pixels. Marrom porque a Investida Veloz é de Instinto, pedido do dono.
- **RF-02:** `res://assets/sounds/skills/investida_veloz.wav` é gerado por síntese, sem gravação de terceiros, por `art-source/sounds/investida_veloz.py`, em 0,42 s (_a revisar_): um zunido de vento que sobe do médio para o agudo enquanto o risco cresce, e um baque grave com um estalo aos 0,16 s, quando o risco está maior (quadros 3 e 4).
- **RF-03:** Na luta, a Investida Veloz faz o que a Arranhão faz, com os arquivos dela: o atacante treme, o efeito e o som tocam juntos sobre o alvo, o alvo pisca com o som de dano e o número sobe.

## Critérios de aceite

- [ ] Na luta, a Investida Veloz mostra o risco marrom sobre o alvo, com o zunido e o baque.

## Desenho técnico

**Criar:** `art-source/sounds/investida_veloz.py`, `investida_veloz.png` e `investida_veloz.wav` com os `.import`, com os mesmos parâmetros de importação da Arranhão.

**Reutilizar:** `_play_skill_effect`, `ContentFiles.SKILL_EFFECT_PATH` e `SKILL_SOUND_PATH`. O visualizador de conteúdo passa a mostrar a Investida Veloz com efeito e som, sem mudar nada nele.

## Verificação

- Um teste sem janela, com uma luta montada, usa a Investida Veloz e confere a ordem: o atacante treme, o efeito `investida_veloz.png` e o som `investida_veloz.wav` começam juntos, e depois o alvo pisca e o número sobe.
- Os testes da 09, 11, 12 e 13 seguem dando 0 falhas, e o do visualizador passa a esperar 3 de 52 Técnicas com efeito e com som.
- Manual, com F5: o dono vê e ouve a Investida Veloz numa luta.

## Tarefas

- [x] Teste da Investida Veloz, vendo falhar.
- [x] O efeito recortado e o som gerado.
- [x] Os testes da 09, 11, 12, 13 e do visualizador.
- [ ] O dono ver e ouvir com F5.

## Resultado da verificação

Em 2026-11-07, o teste sem janela da Investida Veloz falhou antes dos arquivos (o atacante tremia e o alvo piscava, sem efeito nem som da Técnica) e passou depois: o atacante treme aos 2,45 s, o efeito `investida_veloz.png` e o som começam juntos aos 3,51 s, o alvo pisca com o som de dano aos 4,00 s e o número sobe aos 4,38 s. Os testes da Arranhão e do som de dano (09), da Rugido Feroz (11), dos sinais (12), do log (13) e do visualizador de conteúdo (3 de 52 com efeito e com som) deram 0 falhas. O projeto importou sem erros, e o jogo sem janela abriu sem erros nem avisos de script.

O som foi conferido pelo volume ao longo do tempo (sobe até 0,67 aos 0,14 s, chega ao pico no baque aos 0,16 s e some até 0,42 s), mas não foi ouvido aqui. Falta o dono ver e ouvir com F5.
