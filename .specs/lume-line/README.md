# lume-line

Uma linha nova de três formas, a coruja da noite: o **Lume**, o **Owlume** e o **Noclume**. É a primeira linha de Sombra pura (o Ruvaroth é Fogo/Sombra), e só nasce à Noite. A forma final ganha o Psíquico.

## Contexto

Em 2026-11-20, o dono pediu "um ecobeast que só aparecerá a noite, talvez um coruja". Claude propôs o conceito (penas azul-escuras com pintas claras como estrelas, olhos que refletem a lua, o rosto da forma final brilhando como a lua cheia), a ficha e três trios de nomes. O dono escolheu o trio C (Owlume, Dimwing e Lunowl), gerou a imagem da linha numa IA (`art-source/lume/line.webp`, 1536×1024, com fundo transparente) e trocou os nomes: "Vamos renomear de Owlume para Lume, e Dimwing para Owlume e o últmo se chamara Noclume. Siga para a criação desse ecobeast".

A imagem mostra:

- um filhote de coruja redondo, roxo-escuro, de peito claro, olhos dourados enormes e uma lua crescente na testa;
- uma coruja em voo, com as asas abertas de penas roxas e creme, pintas claras e a lua na testa;
- uma coruja grande, em pé, com uma crista de penas em volta de uma lua crescente dourada, asas com luas desenhadas e uma cauda longa de penas.

## Objetivos

1. As espécies 20, 21 e 22, com Elementos, atributos, Traços, evolução, learnset, biomas e só a Noite.
2. Os `front.png` recortados da imagem.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. Técnicas de Sombra especiais: Pena Sombria, Olhar da Lua, Voo Silencioso e Eclipse Lunar.

## Anti-objetivos

- Regra nova no motor da luta.
- Evolução por horário: a do GDD ("Nível 20 à noite → forma Sombra") é pós-lançamento.

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| Uma coruja que só aparece à noite | O pedido |
| Os nomes Lume, Owlume e Noclume | A troca dele sobre o trio C das sugestões |
| A arte da imagem dele | "Ok vou te mandar as imagens" |
| As 4 Técnicas de Sombra que Claude propôs | "Sim, faça a fase 2" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Sombra no Lume e no Owlume, Sombra/Psíquico no Noclume | Era a proposta de Claude, e o dono só trocou os nomes. A coruja que "vê o que está escondido" pede o Psíquico na forma final |
| As descrições do Bestiário da proposta, com os nomes novos | O dono pediu o título e a descrição de cada uma e gerou a imagem com elas |
| Incomum, crescimento Médio, captura 45 e o XP da linha do Clod (60, 140 e 230) | Só nascer à noite já a deixa mais difícil de achar; Rara seria demais para uma ave de campo |
| Evolui nos níveis 20 e 38 | O Puffcoo evolui no 20, e o Tempestide no 38 |
| Atacante especial rápido, de pouca Defesa: totais 310, 420 e 525 | Coruja caçadora, que ataca de longe e foge do contato |
| Brisa Ligeira no slot 1 e Instinto oculto no slot 3 | Os mesmos do Puffcoo e do Galecrest; não há Traço de Sombra |
| Nasce na Planície e no Boreal, e o Noclume só no Boreal | Os mesmos biomas dos vagalumes: à noite, os dois aparecem juntos |
| Só na Noite (`species_day_phases` com a 4) | O pedido do dono, sem mudar código: a `day-phase-spawns` já filtra |
| Na fase 1, o learnset usa só Técnicas que existem (as de pena de Vento, as duas de Sombra e as de Psíquico) | As de Sombra que existem são físicas; as especiais vêm na fase 2, como as de Volt na [tidebud-line](../tidebud-line/) |
| A imagem é cortada pelo `crop_line.py` da skill `creature-sprites` | O mesmo corte da [seedlet-line](../seedlet-line/) e da [tidebud-line](../tidebud-line/) |

## Fora do escopo

- O ícone do Elemento Sombra e os ícones, efeitos e sons das Técnicas novas.
- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Pôr a coruja nas áreas das ilhas: o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-lume-line](01-lume-line.md) | As três espécies, os `front.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-shadow-skills](02-shadow-skills.md) | Técnicas de Sombra especiais nos learnsets | concluída (falta o dono conferir no jogo) |
