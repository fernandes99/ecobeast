# 01. Linha do Browt

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [puffcoo-line](../puffcoo-line/) (o Vento a Favor e as marcas pela linha reta)

## Contexto

O dono trocou a lebre com broto (Elu, Eluvin e Eluvara) por uma ave de penas-folha e escolheu os nomes ([README](README.md#decisões)). A imagem fica em `art-source/browt/line.webp`, com fundo transparente:

- **Browt** é a da esquerda;
- **Eagrow** é a do meio;
- **Sowingle** é a da direita.

Os números são _a revisar_ depois de jogar.

## Escopo

- As linhas no banco (schema `ecobeasts`), gravadas por SQL, sem arquivo no repositório, como na [puffcoo-line/03](../puffcoo-line/03-puffcoo-line.md):
  - as linhas 7, 8 e 9 de `species`, trocadas no lugar;
  - as dessas espécies em `species_elements`, `species_stats`, `species_skills` e `species_day_phases`, refeitas;
  - linhas novas em `skills` e `ground_effects`.
- A arte:
  - as pastas `client/assets/creatures/elu`, `eluvin` e `eluvara` saem;
  - entram `browt/front.png`, `eagrow/front.png` e `sowingle/front.png`.

## Fora do escopo

- `board.png`, as folhas da luta e `call.wav` das três formas. As folhas `idle.png` e `walk.png` do mapa vieram depois, pela skill `creature-sprites` (`<slug>/explore/sprites.py`).
- Os ícones, os efeitos e os sons das Técnicas novas.

## Requisitos

**Espécies**

- **RF-01:** As três espécies trocam nome, slug, descrição, altura e peso. Continuam iguais o crescimento Médio (2), a raridade (3), a captura 45, o XP, o `gender_ratio` 0.5, as evoluções (`evolutions` 5 e 6, nos níveis 16 e 36) e `starter_options`.

  | id | slug | name | Elementos | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- |
  | 7 | `browt` | Browt | Flora | 0.3 | 2.6 |
  | 8 | `eagrow` | Eagrow | Flora / Vento | 1.0 | 15.0 |
  | 9 | `sowingle` | Sowingle | Flora / Vento | 1.8 | 36.0 |

  Descrições (Bestiário):
  - **Browt:** "Filhote de coruja coberto de penas-folha. Quando encara alguém, franze as sobrancelhas de folha e nunca pisca primeiro."
  - **Eagrow:** "As penas da cauda cresceram como folhas longas. Plana em silêncio sobre as copas e mergulha de uma vez na presa."
  - **Sowingle:** "Cada batida das asas solta sementes no vento. Por onde ele passa, um bosque novo brota na estação seguinte."

- **RF-02:** Os atributos puxam para Ataque e Velocidade, com o Ataque Especial logo atrás. Entre parênteses fica o Treino que a espécie dá ao ser derrotada, e o resto é 0:

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Browt | 46 | 60 (1) | 46 | 52 | 50 | 64 | 318 |
  | Eagrow | 60 | 80 (2) | 60 | 68 | 64 | 88 | 420 |
  | Sowingle | 78 | 104 (3) | 74 | 88 | 82 | 106 | 532 |

- **RF-03:** Os Traços não mudam: Raiz Furiosa (5) no slot 1 e Brisa Ligeira (6) no slot 3, oculto.
- **RF-04:** Os biomas (`species_biomes`) não mudam. As partes do dia (`species_day_phases`) mudam:
  - **Browt:** Final de tarde (3) e Noite (4);
  - **Eagrow** e **Sowingle:** Manhã (1), Tarde (2) e Final de tarde (3).

**A marca nova**

- **RF-05:** `ground_effects` 4: `thorns`, "Espinheiro", `damage_percent` 6, sem estado, cor `#5E9B3A`. Quem termina a vez nela perde 6% do HP máximo, pela mesma regra do Chão em chamas.

**Técnicas novas**

- **RF-06:** Quatro Técnicas físicas, todas com prioridade 0 e um golpe só. Nenhuma tem `skill_effects`. A coluna "Forma" segue o [board-battle/architecture.md](../board-battle/architecture.md):

  | id | slug | name | Elemento | Poder | Prec | PP | Crítico | Contato | Forma | Marca | Cooldown |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 58 | `bicada_de_folha` | Bicada de Folha | Flora | 40 | 100 | 30 | 0 | sim | um alvo, alcance 1 | — | 0 |
  | 59 | `garra_de_espinho` | Garra de Espinho | Flora | 70 | 100 | 15 | 1 | sim | um alvo, alcance 1 | — | 1 |
  | 60 | `rasante` | Rasante | Vento | 80 | 95 | 15 | 0 | sim | linha reta, alcance 3, para no primeiro | — | 2 |
  | 61 | `asa_semeadora` | Asa Semeadora | Flora | 75 | 95 | 10 | 0 | não | linha reta, alcance 3, atravessa | Espinheiro (4), por 4 vezes | 3 |

  Descrições:
  - **Bicada de Folha:** "Bica o alvo com o bico coberto de folhas."
  - **Garra de Espinho:** "Agarra o alvo com garras cheias de espinhos. Acerta um ponto fraco com mais facilidade."
  - **Rasante:** "Mergulha em linha reta até o primeiro da fileira, a até 3 hexágonos, e bate com as asas abertas."
  - **Asa Semeadora:** "Uma batida de asa corta a fileira inteira e semeia espinhos no chão. Quem para no espinheiro se machuca."

**Learnsets**

- **RF-07:** As linhas antigas de `species_skills` das três espécies saem, e entram estas. Tudo é por nível (`level_up`), menos o Rasante no Eagrow e a Asa Semeadora no Sowingle, aprendidos ao evoluir (`evolution`, nível 0):

  | Nível | Browt | Eagrow | Sowingle |
  | --- | --- | --- | --- |
  | 0 | — | Rasante | Asa Semeadora |
  | 1 | Bicada de Folha | Bicada de Folha | Bicada de Folha |
  | 1 | Olhar Manhoso | Olhar Manhoso | Olhar Manhoso |
  | 1 | — | — | Rasante |
  | 7 | Folha Navalha | Folha Navalha | Folha Navalha |
  | 10 | Investida Veloz | Investida Veloz | Investida Veloz |
  | 13 | Garra de Espinho | Garra de Espinho | Garra de Espinho |
  | 19 | Seiva Vital | Seiva Vital | Seiva Vital |
  | 22 | — | Lufada Cortante | Lufada Cortante |
  | 25 | Banho de Sol | Banho de Sol | Banho de Sol |
  | 28 | — | Vento a Favor | Vento a Favor |
  | 31 | Tempestade de Pétalas | — | — |
  | 34 | — | Tempestade de Pétalas | Tempestade de Pétalas |
  | 48 | — | — | Ciclone |
  | 55 | — | Explosão Florida | Explosão Florida |

- **RF-08:** A Patada (27), o Chicote de Raiz (29), os Esporos Sonolentos (30) e a Dança do Vento (36) saem da linha e continuam no catálogo. A Dança do Vento continua com a Puffcoo e a Galecrest, e as outras três ficam sem quem aprenda.
- **RF-09:** Os Ecobeasts já capturados não mudam de Técnicas. Um Browt que veio de um Elu continua sabendo a Patada até trocá-la.

**Arte**

- **RF-10:** Os `front.png` são de 512×512, com fundo transparente. Cada ave é recortada da imagem pelo retângulo do alfa da coluna dela e enquadrada como as outras: o lado maior com 480 px, centralizado, sem reamostrar com suavização. Antes do recorte, o alfa até 16 vai a 0, para limpar o ruído da imagem.

## Critérios de aceite

- [x] `GET /v1/species/browt`, `/eagrow` e `/sowingle` respondem 200, e `/v1/species/browt/evolutions` mostra a linha com os níveis 16 e 36.
- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` não aponta erro.
- [ ] Na escolha do inicial e na janela F1, o Browt aparece com o `front.png` novo, e as 4 Técnicas, com os dados do RF-06.
- [ ] Numa luta com um Sowingle, a Asa Semeadora pinta a fileira, e quem para no Espinheiro perde HP.
- [ ] O Browt aparece no Boreal à noite e não aparece de dia.
- [x] Lint, typecheck e testes de unidade do servidor passam.

## Desenho técnico

- **Banco:** um SQL numa transação só, rodado contra o banco do `server/.env`. Os ids seguem os maiores de hoje (Técnicas 57, `ground_effects` 3). Se o banco tiver ids maiores, use os próximos livres e atualize esta spec.
- **Testes:** os testes do servidor chamam o id 7 de `ELU`. A constante e os textos passam a dizer `BROWT`, sem mudar o que testam.
- **Arte:** recortar `art-source/browt/line.webp`, que tem 2000×667. As três aves estão nas colunas 97–416, 635–1161 e 1275–1989.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test
godot --headless -d --path client --quit-after 240
```

F5 no Godot: começar um jogo novo e ver o Browt na escolha do inicial. No F1, conferir as três espécies e as Técnicas. Lutar com um Sowingle pela batalha de teste e usar a Asa Semeadora.

## Tarefas

- [x] Recortar os três `front.png` e apagar as pastas antigas.
- [x] Espécies, Elementos, atributos e partes do dia.
- [x] Espinheiro, Técnicas e learnsets.
- [x] Testes, `CLAUDE.md`, README, glossário e a skill `creature-sprites`.
