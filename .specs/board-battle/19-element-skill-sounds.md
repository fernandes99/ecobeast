# 19. O som de toda Técnica com ícone

- **Status:** concluída (falta o dono ouvir no editor)
- **Depende de:** [18-element-skill-effects](18-element-skill-effects.md) (o efeito das 22 Técnicas)

## Contexto

Na [18](18-element-skill-effects.md), as 22 Técnicas com ícone que faltavam ganharam efeito, e os sons ficaram de fora. Em 2026-11-13, o dono pediu: "agora coloca todos os sons".

Depois, no mesmo dia, o dono pediu um som mais agressivo para a Mordida Brasa, "lembrando uma mordida de lobo", junto com a forma nova do efeito (a 509, na [18](18-element-skill-effects.md)). O efeito novo dura 0,65 s, então o som também.

Os quatro sons de antes (Arranhão, Rugido Feroz, Investida Veloz e Faísca Rápida) são gerados por síntese em Python, sem gravação de terceiros, um script por som em `art-source/sounds/`. Os 22 novos seguem o mesmo caminho, num script só.

## Escopo

- O som das 22 Técnicas da [18](18-element-skill-effects.md).
- O gerador dos 22 sons.

## Fora do escopo

- Mudar os quatro sons de antes ou o som de dano.
- Mudar código do jogo: a luta já toca `res://assets/sounds/skills/<slug>.wav` quando ele existe (a [09](09-hit-feedback.md), RF-09).

## Requisitos

- **RF-01:** Cada som é gerado por síntese, sem gravação de terceiros, por `art-source/sounds/element_skills.py`: ruído em filtros, tons com a altura mudando e saturação leve. O formato é o mesmo dos outros: 44,1 kHz, mono, 16 bits, com o pico em 0,7, sem estourar. Com uma seed fixa por som, rodar de novo grava o mesmo arquivo.
- **RF-02:** O som toca no mesmo instante em que o efeito começa, então dura mais ou menos o efeito (a quantidade de quadros × 0,05 s). Os mais longos não passam de 1 s. O impacto não entra: o som de dano já toca junto com a piscada do alvo.
- **RF-03:** A Chama Espiral tem projétil, então o som dela toca no lançamento ([15](15-projectile-effects.md), RF-05), e o estouro no alvo fica com o som de dano. Ela é o lançamento de uma bola de fogo, em 0,4 s.
- **RF-04:** O som de cada Técnica (_a revisar_), pensado pela forma do efeito e pelo Elemento:

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Mordida Brasa | 0,65 s | uma mordida de lobo, pedido do dono: um rosnado áspero que sobe, o estalo dos dentes se fechando com um baque, o rosnado que volta mais baixo e a brasa chiando |
  | Fumaça Densa | 0,6 s | um sopro abafado que sobe e se espalha |
  | Presa Ígnea | 0,7 s | uma mordida mais forte, com um estalo agudo e um rugido de fogo |
  | Chama Espiral | 0,4 s | o lançamento de uma bola de fogo: um sopro que sobe, com crepitar |
  | Couraça de Cinzas | 0,9 s | um tom que sobe e brilha enquanto o escudo se forma, com brasas estalando, e um "tim" no fim |
  | Erupção Solar | 0,65 s | um estrondo grave, um ronco e um crepitar forte |
  | Jato de Maré | 0,65 s | um jato de água chiado, de ataque rápido, que termina num respingo |
  | Espuma Densa | 0,6 s | bolhas: estalinhos que sobem de altura |
  | Garra de Maré | 0,65 s | três riscos de garra mais graves que os da Arranhão, com gotas |
  | Casca Fechada | 0,65 s | um tom que sobe e um baque oco, da casca se fechando |
  | Lâmina d'Água | 0,6 s | um corte que desce do agudo para o médio, com um respingo |
  | Maré Restauradora | 0,9 s | notas suaves que sobem num acorde maior, com bolhas brilhando |
  | Torrente | 0,6 s | uma correnteza: um ruído largo e um ronco que cresce e cai |
  | Muralha de Coral | 1 s | batidas de cristal que sobem, como favos se formando |
  | Maremoto | 0,6 s | uma onda: um ronco que incha e quebra num estouro de água |
  | Chicote de Raiz | 0,6 s | um zunido que sobe e termina num estalo de chicote |
  | Esporos Sonolentos | 0,7 s | um sopro leve e um tom que desce devagar, de sono |
  | Seiva Vital | 0,6 s | um tom que desce e volta a subir, como algo sendo sugado, com brilho no fim |
  | Folha Navalha | 0,45 s | três cortes agudos e rápidos |
  | Banho de Sol | 0,8 s | notas quentes que sobem num acorde maior, com um brilho suave |
  | Tempestade de Pétalas | 0,5 s | um redemoinho de vento que gira, com sininhos leves |
  | Explosão Florida | 0,6 s | um estouro e brilhos que sobem |

## Critérios de aceite

- [x] Os 22 arquivos existem, no formato dos outros, cada um com a duração da tabela.
- [x] Numa luta sem janela, a Técnica toca o som dela quando o efeito começa.
- [ ] O dono ouve os sons numa luta e pede para mudar os de que não gostar.

## Desenho técnico

**Criar:** `art-source/sounds/element_skills.py`. Ele tem as peças de síntese (ruído, filtro passa-banda e passa-baixa com o centro mudando, tom com a altura mudando, envelope e mistura) e uma função por Técnica, numa tabela `SOUNDS`. Os 22 `.wav` vão em `client/assets/sounds/skills/`, com os `.import`.

```bash
python -I art-source/sounds/element_skills.py [slugs]
```

Sem slugs, ele grava os 22. Para mudar um som, muda-se a função dele e roda-se de novo.

**Reutilizar:** `_play_skill_sound` e `ContentFiles.SKILL_SOUND_PATH`. O visualizador de conteúdo (F1) passa a mostrar os sons sem mudar nada nele.

## Verificação

- O gerador grava os 22 arquivos. Um resumo do volume de cada um, em pedaços de 0,05 s, confere a forma (o ataque, o pico e o fim) e que nenhum estoura.
- Uma cena sem janela carrega os 22 como áudio e confere que a luta toca o som da Técnica junto com o efeito.
- O jogo sem janela abre sem erros nem avisos de script.
- Manual, com F5: o dono ouve os sons numa luta.

## Tarefas

- [x] Spec.
- [x] O gerador e os 22 sons.
- [x] O resumo do volume e o teste sem janela.
- [ ] O dono ouvir com F5.

## Resultado da verificação

Em 2026-11-13, sem janela:

- **Arquivos:** o `element_skills.py` gravou os 22 sons em 2 s, cada um com a duração da tabela, a 44,1 kHz, mono, 16 bits, com o pico em 0,7. Rodar de novo grava os mesmos arquivos.
- **Volume:** o resumo em pedaços de 0,05 s mostrou o ataque e o fim esperados em cada um. Os sons curtos e secos (Mordida Brasa, Garra de Maré, Chicote de Raiz e Folha Navalha) ficavam baixos perto dos outros, como a Arranhão. Eles ganharam mais saturação e ficaram mais perto do resto.
- **Luta:** uma cena temporária (já apagada) carregou os 22 como áudio e tocou a Garra de Maré, a Casca Fechada e a Chama Espiral numa luta montada à mão. O som de cada uma estava tocando no quadro em que o efeito (ou o projétil, na Chama Espiral) apareceu.
- **Mordida Brasa, refeita:** o resumo em pedaços de 0,025 s mostra o rosnado crescendo até 0,2 s, o pico no estalo dos dentes entre 0,22 e 0,27 s e o rosnado e a brasa sumindo até 0,6 s.
- **Projeto:** importa sem erros, e o jogo sem janela abre sem erros de script.
- **Falta o dono:** os sons não foram ouvidos aqui. O dono ouve numa luta com F5 e pede para mudar os de que não gostar.
