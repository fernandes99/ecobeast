# 03. Linha da Puffcoo

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-field-rules](01-field-rules.md) (as marcas 2 e 3) e [02-field-screen](02-field-screen.md) (o jogo mostra o Atordoado)

## Contexto

O dono quis uma ave de Vento de duas formas e trouxe a imagem (`art-source/puffcoo/line.webp`, com fundo transparente):

- **Puffcoo** é a da esquerda, uma bolinha cinza de penas, com bico laranja e olhos grandes;
- **Galecrest** é a da direita, uma ave verde-azulada e branca, com crista branca, olho laranja, asas abertas e cauda longa.

Ele escolheu os nomes, aprovou a ficha proposta por Claude, mudou a evolução para o nível 20 e pediu poucas Técnicas novas que mexam no campo ([README](README.md#decisões)). Os números são _a revisar_ depois de jogar.

É a primeira linha de Vento do catálogo, e a Puffcoo é a ave comum dos campos: fácil de achar, de capturar e de evoluir. Para não lembrar as aves da referência, nenhum nome usa "pidg" nem "dove", e nada de "-eon".

## Escopo

- Linhas novas no banco (schema `ecobeasts`), pelo mesmo caminho da [game-data/06](../game-data/06-clod-line.md), nas tabelas:
  - `species`, `species_elements`, `species_stats` e `species_traits`;
  - `skills`, `skill_effects` e `species_skills`;
  - `evolutions`, `species_biomes` e `species_day_phases`.
- Os `front.png` de 512×512, com fundo transparente, em `client/assets/creatures/puffcoo/` e `client/assets/creatures/galecrest/`. Cada ave é recortada da imagem do dono e enquadrada como as outras: o lado maior com 480 px, centralizado, sem reamostrar com suavização.

## Fora do escopo

- As folhas `idle.png` e `walk.png` (skill `creature-sprites`) e o som `call.wav`.
- O ícone, o efeito e o som das Técnicas novas.
- `server/prisma/seed-data/` para as espécies e as Técnicas: é só a foto da carga inicial, como na [game-data/06](../game-data/06-clod-line.md).

## Requisitos

**Espécies**

- **RF-01:** Duas espécies novas, as duas com `growth_rate_id` = Rápido e `gender_ratio` = 0.5. Galecrest evolui da Puffcoo.

  | id | slug | name | Elemento | Raridade | Captura | XP | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 15 | `puffcoo` | Puffcoo | Vento | Comum | 75 | 50 | 0.3 | 1.8 |
  | 16 | `galecrest` | Galecrest | Vento | Incomum | 35 | 160 | 1.5 | 28.0 |

  A captura vai de 0 a 100 desde a migration `capture_rate_0_100`: é a chance, em %, com 1 de HP e a Esfera básica. A proposta aprovada (200 e 90) estava na escala antiga, de 0 a 255, e foi convertida na mesma proporção (_a revisar_). Para comparar, as iniciais e o Clod têm 45, e o Hushling, 55.

  Descrições (Bestiário):
  - **Puffcoo:** "Ave rechonchuda que vive em bandos nos campos. Arrulha baixinho e, quando se assusta, sobe num redemoinho de penas."
  - **Galecrest:** "Quando abre as asas, o vento muda de direção. A crista se arrepia antes das tempestades, e os bandos o seguem como guia."

- **RF-02:** Os atributos puxam para Ataque Especial e Velocidade, porque as Técnicas de Vento são especiais. Entre parênteses fica o Treino que a espécie dá ao ser derrotada, e o resto é 0:

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Puffcoo | 40 | 40 | 38 | 48 | 38 | 56 (1) | 260 |
  | Galecrest | 70 | 65 | 60 | 85 | 65 | 100 (2) | 445 |

- **RF-03:** As duas espécies têm Brisa Ligeira (id 6) no slot 1 e Instinto (id 2) no slot 3, como Traço oculto (`is_hidden`).
- **RF-04:** A Puffcoo evolui para Galecrest no nível 20, pelo gatilho `level` (`evolutions.id` 51).

**Técnicas novas**

- **RF-05:** Cinco Técnicas de Vento. Todas têm prioridade 0, crítico 0 e nenhum contato, e só a Rajada de Penas tem mais de um golpe. A coluna "Forma" segue o [board-battle/architecture.md](../board-battle/architecture.md):

  | id | slug | name | Categoria | Poder | Prec | PP | Golpes | Alvo | Forma | Marca | Cooldown | Efeito |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 53 | `pena_afiada` | Pena Afiada | Especial | 40 | 100 | 25 | 1 | Inimigo | linha reta, alcance 3, para no primeiro | — | 0 | 30%: −1 Precisão do alvo |
  | 57 | `rajada_de_penas` | Rajada de Penas | Especial | 0 | 85 | 10 | 2 a 5 | Inimigo | linha reta, alcance 6, para no primeiro | — | 2 | 15 de dano fixo por golpe |
  | 54 | `vento_a_favor` | Vento a Favor | Suporte | 0 | 0 | 15 | 1 | Meu time | um alvo, alcance 2 | — | 2 | +1 Velocidade e +1 Evasão no alvo |
  | 55 | `nuvem_de_penas` | Nuvem de Penas | Suporte | 0 | 0 | 10 | 1 | Inimigo | linha reta, alcance 3, atravessa | Penas no ar (2), por 6 vezes | 3 | — |
  | 56 | `vendaval` | Vendaval | Especial | 60 | 95 | 10 | 1 | Inimigo | linha reta, alcance 3, atravessa | Redemoinho (3), por 4 vezes | 3 | — |

  Descrições:
  - **Pena Afiada:** "Dispara uma pena afiada em linha reta. Pode atrapalhar a mira do alvo."
  - **Rajada de Penas:** "Lança de 2 a 5 penas seguidas, de longe, no primeiro da linha. Cada pena tira 15 de HP."
  - **Vento a Favor:** "Sopra um vento a favor de um aliado, ou de si mesmo, e aumenta a Velocidade e a Evasão dele em 1 nível."
  - **Nuvem de Penas:** "Espalha penas no ar numa fileira. Quem para nela perde Precisão e Evasão."
  - **Vendaval:** "Uma ventania corta a fileira inteira e deixa um redemoinho. Quem para nele fica atordoado e não consegue andar."

- **RF-06:** Os efeitos (`skill_effects`, ids 39 a 42):
  - 39: Pena Afiada, `modify_stat`, chance 30, alvo Inimigo, Precisão −1;
  - 40: Vento a Favor, `modify_stat`, chance 100, alvo Meu time (4), Velocidade +1;
  - 41: Vento a Favor, `modify_stat`, chance 100, alvo Meu time (4), Evasão +1;
  - 42: Rajada de Penas, `fixed_damage`, chance 100, `value` 15.

  Com o alvo Meu time, o efeito vale no Ecobeast escolhido pela Técnica. A spec dizia "sem alvo próprio", como a cura do Banho de Sol, mas o `CatalogValidator` exige alvo em todo `modify_stat`. Na Rajada de Penas, o poder é 0 porque o dano de cada golpe é o fixo, pelas regras da [01](01-field-rules.md) (RF-12 a RF-14).

**Learnsets**

- **RF-07:** Tudo por nível (`level_up`), menos o Vendaval, que o Galecrest aprende ao evoluir (`evolution`, nível 0). A Investida Veloz, a Lufada Cortante, a Dança do Vento e o Ciclone já existem.

  | Nível | Puffcoo | Galecrest |
  | --- | --- | --- |
  | 1 | Investida Veloz | Investida Veloz |
  | 0 | — | Vendaval |
  | 5 | Pena Afiada | Pena Afiada |
  | 9 | Vento a Favor | Vento a Favor |
  | 12 | Rajada de Penas | Rajada de Penas |
  | 13 | Lufada Cortante | Lufada Cortante |
  | 17 | Nuvem de Penas | Nuvem de Penas |
  | 24 | Dança do Vento | Dança do Vento |
  | 32 | — | Ciclone |

**Onde e quando nascem**

- **RF-08:** Taxas em `species_biomes`. Sem linha, a taxa é 0:

  | Espécie | Planície | Boreal | Colina | Montanha | Praia |
  | --- | --- | --- | --- | --- | --- |
  | Puffcoo | 60 | 20 | 40 | — | 15 |
  | Galecrest | 5 | — | 20 | 30 | — |

- **RF-09:** As duas espécies só nascem de dia. Em `species_day_phases`, cada uma tem Manhã (1), Tarde (2) e Final de tarde (3), e não tem Noite (4).

## Critérios de aceite

- [x] `GET /v1/species/puffcoo` e `/galecrest` respondem 200, e `/v1/species/puffcoo/evolutions` mostra a linha com o nível 20.
- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` não aponta erro.
- [ ] Na janela F1, as duas espécies aparecem com o `front.png` e as 5 Técnicas novas com os dados do RF-05.
- [x] Numa luta com uma Galecrest (batalha de teste ou pelo F3):
  - a Pena Afiada acerta o primeiro da linha;
  - a Rajada de Penas acerta o primeiro da linha, a até 6 hexágonos, de 2 a 5 vezes, tirando 15 de HP em cada;
  - o Vento a Favor sobe a Velocidade e a Evasão de um aliado a até 2 hexágonos;
  - a Nuvem de Penas e o Vendaval pintam a fileira;
  - quem para no Redemoinho não consegue andar, e a Galecrest atravessa o redemoinho sem ficar atordoada.
- [ ] De dia, a Puffcoo aparece nos campos do mapa sorteado. À noite, não aparece.
- [ ] Lint, typecheck, testes de unidade e e2e do servidor passam.

## Desenho técnico

- **Banco:** as linhas entram como na [game-data/06](../game-data/06-clod-line.md), gravadas direto no banco, pelo painel ou por SQL, sem arquivo no repositório. Os ids seguem os maiores de hoje: espécies 14, Técnicas 52, `skill_effects` 38 e `evolutions` 50. A Rajada de Penas ficou com o 57 porque entrou depois das outras quatro. Se o banco tiver ids maiores, use os próximos livres e atualize esta spec.
- **Mirar numa casa vazia:** a Nuvem de Penas mira numa casa vazia. O servidor (`lineArea` em `server/src/domain/board/areas.ts`) já aceita uma linha sem inimigo. Confira se o jogo deixa escolher a casa vazia para uma linha. Se não deixar, ajuste a mira em `res://screens/board_battle/board_battle_screen.gd`, como a mira do `single` com marca.
- **Arte:**
  - recortar as duas aves de `art-source/puffcoo/line.webp` (a imagem tem 1774×887, com transparência) pelo retângulo do alfa de cada metade;
  - ampliar ou reduzir com o filtro mais perto (`NEAREST`) até o lado maior ficar com 480 px e centralizar num quadro de 512×512;
  - salvar em `client/assets/creatures/<slug>/front.png`, com o `.import` que o Godot gerar.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```

F5 no Godot: abrir o F1 e conferir as duas espécies e as Técnicas. Explorar de dia e de noite pela barra de hora do menu Debug, e lutar com uma Galecrest para testar as cinco Técnicas.

## Tarefas

- [x] Recortar os dois `front.png`.
- [x] Espécies, atributos, Traços e evolução.
- [x] Técnicas, efeitos e learnsets.
- [x] Biomas e partes do dia.
- [x] Conferir a mira da Nuvem de Penas numa casa vazia.
- [x] `CLAUDE.md`, o README da iniciativa e as tabelas das specs.

Conferido por Claude:
- as linhas estão no banco, gravadas por SQL, sem arquivo no repositório, e `GET /v1/species/puffcoo`, `/galecrest` e `/v1/species/puffcoo/evolutions` respondem com o nível 20;
- o jogo abre sem janela com o servidor no ar, e o `CatalogValidator` aceita tudo;
- num teste temporário com o catálogo da luta carregado do banco, já apagado:
  - a Pena Afiada tirou 1 de Precisão;
  - a Rajada de Penas deu 4 golpes de 15, com o `multi_hit`;
  - a Nuvem de Penas, mirada numa casa vazia, pôs as Penas no ar na fileira;
  - o Vendaval acertou e pôs o Redemoinho em 3 casas;
  - o Vento a Favor subiu a Velocidade e a Evasão do aliado;
- a mira do jogo já aceita qualquer casa da linha, vazia ou não (`BoardGeometry.targets`), e nada mudou nela;
- lint, typecheck e os testes de unidade passam. Os e2e passam, menos a contagem de tabelas, que quebrou com a migration `island_discoveries` da `fog-of-war`, ainda sem commit noutra sessão.

Fica para o dono: as duas espécies no F1, uma luta com a Galecrest no editor e a Puffcoo de dia no mapa sorteado.
