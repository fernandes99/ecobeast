# 34. As Técnicas de rastro

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-skill-areas.md) e [02](02-board-engine.md) (as áreas e a luta no tabuleiro), e as marcas da [field-effects](../field-effects/README.md)

## Contexto

Em 2026-11-20, o dono pediu "novas habilidades que utilizam a mecanica de rastro de um projetil", de elementos diferentes. Claude mostrou três grupos de ideias: com as marcas que já existem, com marcas novas e com regras novas. O dono escolheu o primeiro: "Vamos com o grupo A faça todos da lista".

O rastro já existe no motor: uma Técnica de Linha reta que **não atravessa** e tem marca no chão pinta os hexágonos do caminho até o primeiro inimigo, o dele incluído, ou até o fim do alcance se não houver inimigo (`lineArea` e `placeMarks`). As 7 Técnicas de linha com marca que havia (Poça d'Água, Lama Grudenta, Areia Movediça, Chão de Geada, Poça Tóxica, Maré Elétrica e Asa Semeadora) atravessam e pintam a fileira inteira. Estas são as primeiras que deixam só o rastro.

Como a marca age em quem está nela depois de cada vez, dos dois lados, o alvo que fica parado já sofre a marca no fim da vez de quem usou, mesmo que o golpe erre. É por isso que a Faísca Rastejante e o Dardo Gotejante têm Poder baixo e countdown alto: o Paralisado e o Envenenado vêm quase sempre.

## Escopo

- A migração `20270125000000_trail_skills`, com as Técnicas 89 a 97, o efeito 62 e os learnsets.

## Fora do escopo

- O ícone, o efeito e o som das Técnicas novas: vêm quando o dono mandar os ícones, e até lá a luta usa o efeito padrão.
- Marcas novas e regras novas no motor (os grupos B e C das ideias).

## Requisitos

- **RF-01:** Nove Técnicas, todas com alvo Inimigo, Linha reta, sem atravessar, sem contato, prioridade 0, crítico 0 e um golpe (_a revisar_ todos os números):

  | id | slug | name | Elemento | Categoria | Poder | Prec | PP | Alcance | Marca (vezes) | Cooldown |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 89 | `cometa_de_brasa` | Cometa de Brasa | Fogo | Especial | 60 | 95 | 15 | 4 | Chão em chamas (4) | 2 |
  | 90 | `jato_gotejante` | Jato Gotejante | Água | Especial | 45 | 100 | 20 | 4 | Poça d'Água (4) | 1 |
  | 91 | `faisca_rastejante` | Faísca Rastejante | Volt | Especial | 40 | 100 | 10 | 3 | Maré Elétrica (3) | 4 |
  | 92 | `semente_saltitante` | Semente Saltitante | Flora | Físico | 45 | 100 | 20 | 3 | Espinheiro (4) | 1 |
  | 93 | `cometa_de_polen` | Cometa de Pólen | Flora | Especial | 40 | 100 | 10 | 4 | Jardim (4) | 3 |
  | 94 | `bola_de_lama` | Bola de Lama | Terra | Especial | 55 | 95 | 15 | 3 | Lamaçal (4) | 1 |
  | 95 | `estaca_de_gelo` | Estaca de Gelo | Gelo | Físico | 65 | 95 | 15 | 4 | Geada (4) | 2 |
  | 96 | `dardo_gotejante` | Dardo Gotejante | Toxina | Físico | 35 | 100 | 15 | 3 | Poça Tóxica (4) | 3 |
  | 97 | `pena_riscante` | Pena Riscante | Vento | Especial | 45 | 100 | 20 | 4 | Penas no ar (3) | 1 |

- **RF-02:** As descrições (Bestiário e F1):
  - **Cometa de Brasa:** "Lança um cometa de brasa no primeiro da linha, a até 4 hexágonos, e deixa o chão em chamas por onde passou. Pode deixar o alvo Queimado."
  - **Jato Gotejante:** "Dispara um jato que vai pingando até o primeiro da linha, a até 4 hexágonos. Quem para nas gotas fica Encharcado."
  - **Faísca Rastejante:** "Uma faísca corre rente ao chão até o primeiro da linha, a até 3 hexágonos, e deixa o caminho eletrificado. Quem para nele fica Paralisado, menos quem é de Volt."
  - **Semente Saltitante:** "Atira uma semente que quica até o primeiro da linha, a até 3 hexágonos, e deixa espinhos brotando por onde passou."
  - **Cometa de Pólen:** "Lança um cometa de pólen no primeiro da linha, a até 4 hexágonos. Por onde ele passa nasce um jardim, que cura quem para nele, até o inimigo."
  - **Bola de Lama:** "Arremessa uma bola de lama no primeiro da linha, a até 3 hexágonos, que respinga pelo caminho. Quem para no lamaçal fica mais lento."
  - **Estaca de Gelo:** "Atira uma estaca de gelo no primeiro da linha, a até 4 hexágonos, que deixa geada por onde passou. Quem para nela escorrega e perde Evasão."
  - **Dardo Gotejante:** "Atira um dardo que pinga veneno até o primeiro da linha, a até 3 hexágonos. Quem para nas gotas fica Envenenado."
  - **Pena Riscante:** "Atira uma pena que risca o ar até o primeiro da linha, a até 4 hexágonos, e deixa penas soltas no caminho. Quem para nelas perde Precisão e Evasão."
- **RF-03:** O efeito (`skill_effects` 62): o Cometa de Brasa tem um `apply_status` de 10% de Queimado no alvo. As outras não têm efeito próprio: o que fazem vem da marca.
- **RF-04:** Os learnsets, todos por nível (`level_up`), em níveis que a espécie ainda não usava:

  | Técnica | Quem aprende (nível) |
  | --- | --- |
  | Cometa de Brasa | Ruvo, Ruvak e Ruvaroth (22) |
  | Jato Gotejante | Nilu, Nilgar e Nilgorr (22); Tidebud, Kelpcoil e Tempestide (20) |
  | Faísca Rastejante | Kelpcoil e Tempestide (32) |
  | Semente Saltitante | Seedlet, Grovequill e Arbornix (27) |
  | Cometa de Pólen | Grovequill e Arbornix (44) |
  | Bola de Lama | Clod, Crag e Ingot (14) |
  | Estaca de Gelo | Hushling e Echofrost (30) |
  | Dardo Gotejante | Snekit e Venomaw (22) |
  | Pena Riscante | Puffcoo e Galecrest (15); Lume, Owlume e Noclume (26) |

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| A Lança de Gelo da lista virou Estaca de Gelo | Já existe a Lança de Cristal, de Gelo |
| Poder baixo e countdown alto na Faísca Rastejante e no Dardo Gotejante | O alvo parado fica na marca e ganha o estado mesmo se o golpe errar |
| Marcas de 3 a 4 vezes, mais curtas que as da fileira (6 a 8) | O rastro é a sobra do ataque, não a Técnica inteira |
| A Pena Riscante também na linha do Lume | A coruja já luta com penas (Pena Afiada, Nuvem de Penas) |

## Critérios de aceite

- [x] As rotas `/v1/skills/<slug>` das 9 Técnicas respondem 200, e o `GET /v1/catalog` traz o efeito 62 e os learnsets.
- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` aceita o catálogo.
- [x] Unidade (`board-engine.spec.ts`): a linha sem atravessar com marca acerta só o primeiro inimigo e pinta só até ele, o hexágono dele incluído, e o alvo sofre a marca no fim da vez.
- [x] Lint, typecheck e testes do servidor passam (a fase não muda código do jogo).
- [ ] No jogo, pelo Testar técnica do F1, cada Técnica pinta os hexágonos até o primeiro inimigo, e não a fileira inteira.

## Desenho técnico

- A migração `server/prisma/migrations/20270125000000_trail_skills/`, com `skills`, `skill_effects` e `species_skills`, e `migrate deploy`. Sem código novo; só o teste de unidade do rastro.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test
godot --headless -d --path client --quit-after 240
```

## Resultado da verificação

Em 2026-11-20, com a migração aplicada e o servidor no ar, as 9 rotas `/v1/skills/<slug>` responderam 200, e o `GET /v1/catalog` trouxe 97 Técnicas, o efeito 62 (10% de Queimado no Cometa de Brasa) e as 28 linhas de learnset novas. O teste novo do `board-engine.spec.ts` passou, junto com os 1082 de antes, o lint e o typecheck. O jogo sem janela abriu com o `CatalogValidator` aceitando o catálogo, só com os avisos que já existiam. Falta o dono testar as Técnicas no jogo.
