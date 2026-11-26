# 03. O som de todos os Ecobeasts

- **Status:** concluída (falta o dono ouvir)
- **Depende de:** [02-ruvo-call](02-ruvo-call.md)

## Contexto

Em 2026-11-26, o dono pediu: "Crie os sons de todos os ecobeasts, veja cada um deles, eu quero um som característico de cada um, siga o exemplo dos que já existem". Só o Ruvo tinha som. Faltavam os outros 49 do catálogo (ids 2 a 50).

## Escopo

- O `call.wav` das 49 espécies sem som, gerado por `art-source/calls/make_calls.py`.

## Fora do escopo

- Tocar o som no jogo: continua sem nenhuma tela que o toque.
- Refazer o som do Ruvo, que fica no script dele.

## Requisitos

- **RF-01:** O mesmo chip do Ruvo (02, RF-01, RF-02 e RF-04): Python sem bibliotecas de fora, pulsos e triângulo de 16 degraus, ruído LFSR, calculado a 11 025 Hz, 64 degraus de volume, 44,1 kHz, mono, 16 bits, com o pico em 70%. Nada imita um bicho de verdade.
- **RF-02:** Um script para todos, com um desenho por espécie, para mudar um som sem mexer nos outros: `python -I art-source/calls/make_calls.py <slug>`.
- **RF-03:** Cada som tem:
  - sílabas que lembram o nome, como o "ru-vo";
  - um efeito do Elemento por cima: brasa (Fogo), bolhas (Água), folhas (Flora), tilintar de gelo (Gelo), cascalho e ronco (Terra), sopro e ventania (Vento), faísca e raio (Volt), voz oca e desafinada (Sombra), ondulação e eco (Psíquico), chiado (Instinto), gotas de veneno (Toxina), zumbido e cliques (Inseto), sinos e arpejos (Luz), voz dobrada e brilho girando (Arcano) e um anel de bigorna (Metal);
  - o jeito do Ecobeast, da descrição dele.
- **RF-04:** Numa linha, a Evolução fica mais grave e mais longa: perto de 0,3 a 0,5 s no filhote, 0,5 a 0,7 s no meio e 0,7 a 1 s na forma final.
- **RF-05:** Os tímidos e os silenciosos ficam mais baixos (`gain`): o Hushling (55%), a Budflit (70%), a Nilu, o Glimshell e o Owlume (85%) e o Lumoshell (90%).

## Os sons

| Ecobeast | Som |
| --- | --- |
| Ruvak | "ru-vak", mais grave que o Ruvo; o "vak" cai depressa e estala no "k" |
| Ruvaroth | "ru-va-roth", o "roth" oco e desafinado (a chama escura), brasa e ronco |
| Nilu | "ni-lu" agudo e macio, tímido, com duas bolhas |
| Nilgar | "nil-gar", a garra estalando e as bolhas subindo |
| Nilgorr | "nil-gorrr", o "r" rolado, o casco de metal soando e a água no fundo |
| Seedlet | "see-dlet" contente, e a cauda abrindo como broto num arpejo |
| Grovequill | "grove-quill", o "quill" num trinado, com vento nas folhas |
| Arbornix | "ar-bor-nix", um chamado solene que sobe, com a ventania das asas |
| Hushling | "hush-ling" quase sem som: um sopro e dois flocos tilintando |
| Echofrost | "e-cho-frost" que ecoa três vezes, como a palavra guardada no cristal |
| Clod | "clo-d" abafado, com duas pedrinhas batendo |
| Crag | "crag" de cascalho, áspero, com um baque no "g" |
| Ingot | "in-got" pesado batendo como numa bigorna |
| Puffcoo | "puff-coo-oo", um sopro de penas e um arrulho macio em dois tempos |
| Galecrest | "gale-crest", uma subida em rasante e o "crest" caindo na ventania |
| Tidebud | "tide-bud" de bolha e a faísca azul da crista |
| Kelpcoil | "kelp-coil", o "coil" enrolando num vibrato largo, com faíscas |
| Tempestide | "tem-pes-tide", um raio, o trovão e o mar revolto |
| Lume | "lu-me" oco e baixo, no escuro |
| Owlume | "ow-lu-me" mais grave, com o sopro das asas silenciosas |
| Noclume | "noc-lu-me" ondulando devagar, o brilho da lua e o eco |
| Snekit | "sne-kit-kit", o chiado e um "ki-ki-ki" de deboche |
| Venomaw | "ve-no-maw", chiado longo, o "maw" rouco e o veneno pingando |
| Prayling | "pray... ling!": um quase nada parado e, de repente, o bote |
| Mantorn | "man-torn", duas lâminas e um corte que desce frio |
| Solantis | "so-lan-tis" subindo em maior, com sinos de luz e o zumbido |
| Umbrantis | "um-bran-tis" descendo em menor, seco, e a foice raspando |
| Sandlurk | "sand-luuurk", um suspiro de tédio, areia e uma pinça |
| Dunestrike | "duuune... strike!": a espera lenta e o bote do ferrão |
| Hopling | "hop-ling, hmph": um pulinho, a cara amarrada e um bufo |
| Pouchmend | "pouch-mend" resmungado e o filhote respondendo animado |
| Glimshell | "glim-shell" sonolento, num bocejo, com a pedrinha brilhando |
| Lumoshell | "lu-mo-shell" mais lento, com a luz escapando pelas frestas |
| Prismback | "prism-back" muito grave e um arco-íris de notas por cima |
| Veilmoth | "veil-moth" dobrado, como a irmã respondendo, com pó cintilando |
| Gatemoth | "gate-moth" e um portal abrindo, com o brilho girando |
| Snelt | "snelt", o "tim" da concha polida e a fumaça de raiva |
| Smeltrudge | "smelt-rudge" moendo devagar e uma batida de metal |
| Magmollusk | "mag-mol-lusk" grave, a bigorna, a lava borbulhando e as brasas |
| Fuzzap | "fuz-zap... eep!": o pelo chiando, o choque e o susto com ele |
| Blizzvolt | "bliz-volt" de alerta, gelado, estalando em raio |
| Nectoad | "nec-toad" de bolha, cheio de si, num ta-dá |
| Toxbloom | "tox-bloom" inchando de orgulho, a flor e o néctar pingando |
| Budflit | "bud-flit" pequenino, as asas tremendo e uma faísca |
| Cheerwing | "cheer-wing!" e uma vinheta de torcida |
| Galafly | "ga-la-fly" e uma fanfarra de maestro com confete |
| Bumbit | "bum-bit-bit-bit", zumbido baixinho e nervoso |
| Buzzwork | "buzz-work" mandão e uma contagem: um, dois, três, pronto |
| Bloomarch | "bloom-arch" solene sobre um zumbido grave, com pétalas e mel |

## Critérios de aceite

- [x] O script escreve os 49 `call.wav`, e o Godot os importa com as opções do Ruvo.
- [x] No visualizador (F1), todos os Ecobeasts mostram "▶ Ouvir" na linha "call".
- [ ] O dono ouve e aprova cada som.

## Verificação

Em 2026-11-26, o script escreveu os 49 sons. A conferência de cada arquivo deu o pico em 70% (menos nos mais baixos), sem estalo no começo nem no fim, e o fim do eco do Noclume coube no arquivo; os que sobravam silêncio no fim ficaram mais curtos. A imagem do espectro dos 50 mostrou as sílabas e os efeitos separados e nenhum som igual a outro. O `--import` do Godot gerou os `.import` iguais ao do Ruvo, e uma cena sem janela carregou os 50 pelo `ContentFiles.CREATURE_CALL_PATH` como `AudioStreamWAV`. Falta o dono ouvir no F1.
