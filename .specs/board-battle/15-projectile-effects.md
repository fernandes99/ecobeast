# 15. A Técnica que voa: a Faísca Rápida

- **Status:** concluída (falta o dono ver e ouvir no editor)
- **Depende de:** [09-hit-feedback](09-hit-feedback.md) (o efeito e o som da Técnica no golpe)

## Contexto

Na [09](09-hit-feedback.md), o efeito de uma Técnica aparece direto sobre o alvo, no `damage`. Numa Técnica que cruza o tabuleiro, nada liga o alvo a quem atacou, e quando ela erra ou a linha não pega ninguém, nenhum efeito aparece. Em 2026-11-07, o dono perguntou como fazer as Técnicas que cruzam o campo, como a Faísca Rápida (Fogo, linha reta de alcance 3, que para no primeiro inimigo). Claude sugeriu uma folha que voa de quem ataca até o fim da área, com o impacto no alvo, o som no lançamento e o som de dano na chegada. O dono aceitou e pediu: "Vamos fazer apenas a faisca rapida. eu tenho essa a 579 em mente para o projectile, mas você decide [...] E de efeito final eu gostei da 397."

Do kit "Effect and FX Pixel All Free":

- A `Free/Part 12/579.png` tem 896 × 576 pixels, em células de 64: 9 linhas de cor com os mesmos 14 quadros, um cometa que aponta para a direita e tremula no mesmo lugar, em loop. Claude comparou com a 578, ao lado, maior, mas que cresce e some uma vez só, sem loop: a 579 ficou.
- A `Free/Part 8/397.png` tem 576 × 576, em células de 64, com 9 quadros: um estouro que nasce embaixo à esquerda e se abre para cima e para a direita, como a continuação de um golpe que vem de baixo à esquerda.

A cor é a 8ª linha das duas folhas, vermelha com o miolo amarelo (decisão de Claude, _a revisar_): a Faísca Rápida é de Fogo, e a vermelha parece mais fogo que a laranja-clara da 1ª linha e se destaca mais no chão verde.

## Escopo

- A folha que voa (o projétil) de uma Técnica, quando ela tem o arquivo.
- O projétil, o impacto e o som da Faísca Rápida.

## Fora do escopo

- O projétil das outras Técnicas, como a Chama Espiral: cada uma chega com os arquivos dela, sem mudar código.
- O projétil no visualizador de conteúdo (F1): quase nenhuma Técnica tem, e uma linha "projétil · falta" em todas só faria barulho. Veio depois, como arquivo opcional, na [content-viewer/05](../content-viewer/05-skill-projectile.md), a pedido do dono.
- Girar o impacto na direção do golpe: ele só espelha, como na 09.

## Requisitos

- **RF-01:** `res://assets/effects/skills/faisca_rapida_projectile.png` é a 8ª linha (a vermelha) da `Part 12/579.png`, 896 × 64, com 14 quadros de 64, sem mudança nos pixels.
- **RF-02:** `res://assets/effects/skills/faisca_rapida.png` é a 8ª linha (a vermelha) da `Part 8/397.png`, 576 × 64, com 9 quadros de 64, sem mudança nos pixels.
- **RF-03:** `res://assets/sounds/skills/faisca_rapida.wav` é gerado por síntese, sem gravação de terceiros, por `art-source/sounds/faisca_rapida.py`, em 0,35 s (_a revisar_): um estalo de ignição e um chiado de faísca com crepitar, que dura o voo e some. O impacto não está nesse som: é o som de dano da 09, que toca na chegada qualquer que seja a distância.
- **RF-04:** Uma Técnica tem projétil quando existe `res://assets/effects/skills/<slug>_projectile.png` (`ContentFiles.SKILL_PROJECTILE_PATH`). A folha aponta para a direita, com a ponta a 27 de 64 pixels à direita do meio do quadro (_a revisar_ para outras folhas).
- **RF-05:** No `skill_used` de uma Técnica com projétil, depois de quem ataca tremer e com a área ainda acesa, a frase "… usou Faísca Rápida." aparece no log antes do voo, e não depois como nas outras Técnicas: assim o impacto do próximo evento vem junto da chegada, sem a frase no meio. Depois da frase, o som da Técnica toca e o projétil sai do meio do corpo de quem ataca e voa em linha reta até o último hexágono da área (`cells`), a 0,09 s por hexágono (_a revisar_), girado na direção do voo, com os quadros em loop a cada 0,05 s. Ele termina no meio do corpo de quem estiver no último hexágono, ou no meio do hexágono vazio, na altura do corpo de quem ataca, e some.
- **RF-06:** Depois do voo, cada `damage` da Técnica toca o impacto sobre o alvo, como na 09, mas sem tocar o som da Técnica de novo. O impacto espelha na horizontal quando quem ataca está à direita (como na 09) e na vertical quando quem ataca está acima do alvo, para o estouro seguir o golpe.
- **RF-07:** Quando a Técnica erra (`missed`) ou a área não tem ninguém, o projétil voa até o fim da área e some, sem impacto.
- **RF-08:** Uma Técnica sem o arquivo do projétil continua como na 09 e na 11.

## Critérios de aceite

- [ ] Na luta, a Faísca Rápida faz quem ataca tremer, a faísca vermelha voar até o alvo com o chiado, e o estouro aparecer nele com o som de dano.
- [ ] Quando ela erra, a faísca voa e some, sem estouro.
- [ ] A Arranhão, a Investida Veloz e a Rugido Feroz continuam como antes.

## Desenho técnico

**Criar:** `art-source/sounds/faisca_rapida.py`; `faisca_rapida_projectile.png`, `faisca_rapida.png` e `faisca_rapida.wav` com os `.import`, com os mesmos parâmetros de importação da Arranhão.

**Alterar:**

- `res://tools/content_viewer/content_files.gd`: `SKILL_PROJECTILE_PATH`, ao lado de `SKILL_EFFECT_PATH`.
- `res://screens/board_battle/board_view.gd`: `fly_projectile(from_key, cells, texture)`, que pode ser esperado; `play_effect` ganha `flipped` (na vertical); o meio do corpo vira uma função só (`_body_middle`).
- `res://screens/board_battle/board_battle_screen.gd`: um `_projectile_flown` (bool) que o `skill_used` zera; no `skill_used`, com `_projectile_texture()`, a frase (`_say`, a parte do fim de `_play_event` que escreve a frase, agora uma função) e `_fly_projectile(area, texture)` depois do tremor; `_play_skill_effect` não toca o som quando o projétil já tocou e vira o impacto na vertical; o som da Técnica vira `_play_skill_sound`.

## Verificação

- Um teste sem janela, com uma luta montada, usa a Faísca Rápida numa linha de 3 hexágonos até o alvo e confere a ordem: quem ataca treme; o projétil aparece, girado na direção do alvo, e anda até ele com o som da Faísca tocando; o projétil some e o impacto aparece sobre o alvo em até 0,1 s, sem espelhar na vertical; o alvo pisca com o som de dano.
- O mesmo teste, com `missed` no lugar do dano, confere que o projétil voa e nenhum impacto aparece.
- Os testes da 09, 11, 12, 13 e 14 seguem dando 0 falhas, e o do visualizador passa a esperar 4 de 52 Técnicas com efeito e com som.
- O jogo sem janela abre sem erros nem avisos de script.
- Manual, com F5: o dono vê e ouve a Faísca Rápida numa luta.

## Tarefas

- [x] Teste da Faísca Rápida, com acerto e erro, vendo falhar.
- [x] O projétil e o impacto recortados, e o som gerado.
- [x] O voo no `board_view` e na tela.
- [x] Os testes da 09, 11, 12, 13, 14 e do visualizador.
- [ ] O dono ver e ouvir com F5.

## Resultado da verificação

Em 2026-11-07, o teste sem janela da Faísca Rápida falhou antes do código, com acerto e com erro (quem ataca tremia, e o alvo piscava sem projétil, impacto nem som da Técnica), e passou depois. Na primeira versão, o projétil voava logo depois do tremor, e a frase "Ruvo usou Faísca Rápida." vinha entre a chegada e o impacto: o impacto aparecia 0,75 s depois de o projétil sumir. O teste passou a exigir o impacto em até 0,1 s, falhou, e a frase foi para antes do voo (RF-05).

Com acerto, quem ataca treme aos 2,44 s; o projétil e o som da Faísca começam juntos aos 3,46 s, saindo do meio do corpo de quem ataca e apontando para o alvo (ângulo −0,98, o esperado); o voo de 3 hexágonos leva 0,30 s; o projétil some e o impacto aparece aos 3,76 s, sem virar na vertical; o alvo pisca aos 4,26 s. Com erro, o projétil voa os mesmos 0,30 s até o alvo e some, sem impacto nem alvo piscando. Os testes da Arranhão e do som de dano (09), da Rugido Feroz (11), dos sinais (12), do log (13), da Investida Veloz (14) e do visualizador de conteúdo (4 de 52 com efeito e com som) deram 0 falhas. O projeto importou sem erros, com os parâmetros de importação da Arranhão, e o jogo sem janela abriu sem erros nem avisos de script.

O som foi conferido pelo volume ao longo do tempo (o estalo em 0,70 no começo, o chiado em torno de 0,5 até 0,2 s, sumindo até 0,35 s), mas não foi ouvido aqui, e o voo não foi visto com janela. Falta o dono ver e ouvir com F5.
