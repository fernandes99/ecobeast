# 03. As dez Técnicas novas

- **Status:** concluída (falta o dono ver no jogo)
- **Depende de:** [01](01-field-rules.md) e [02](02-field-screen.md)

## Contexto

As regras e as marcas da [01](01-field-rules.md) só valem na luta quando uma Técnica as usa. Esta fase cria dez Técnicas, com as duas primeiras de Toxina, e as põe nos learnsets dos Ecobeasts que já existem ([README](README.md#decisões)).

## Escopo

- A migração com as Técnicas 66 a 75, os efeitos e os learnsets.

## Fora do escopo

- Ícone, efeito e som das dez Técnicas: vêm quando o dono mandar os ícones, e até lá a luta usa o efeito padrão.
- Mudar as Técnicas que já existem.

## Requisitos

- **RF-01:** As Técnicas novas, todas com prioridade 0, crítico 0 e um golpe. "Linha" é a linha reta; "atravessa" pega a fileira inteira (_a revisar_ todos os números):

  | id | slug | name | Elemento | Categoria | Poder | Prec | PP | Alvo | Forma | Alcance | Atravessa | Contato | Marca (vezes) | Cooldown |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 66 | `esguicho` | Esguicho | Água | Especial | 40 | 100 | 25 | Inimigo | linha | 3 | não | não | — | 0 |
  | 67 | `poca_d_agua` | Poça d'Água | Água | Suporte | 0 | 0 | 10 | Inimigo | linha | 3 | sim | não | Poça d'Água (6) | 3 |
  | 68 | `laco_de_raizes` | Laço de Raízes | Flora | Físico | 35 | 95 | 20 | Inimigo | um alvo | 1 | não | sim | — | 2 |
  | 69 | `brotar` | Brotar | Flora | Suporte | 0 | 0 | 15 | Meu time | um alvo | 2 | não | não | — | 3 |
  | 70 | `semear_jardim` | Semear Jardim | Flora | Suporte | 0 | 0 | 5 | Meu time | um alvo | 2 | não | não | Jardim (6) | 4 |
  | 71 | `lama_grudenta` | Lama Grudenta | Terra | Especial | 50 | 95 | 15 | Inimigo | linha | 3 | sim | não | Lamaçal (6) | 2 |
  | 72 | `areia_movedica` | Areia Movediça | Terra | Suporte | 0 | 0 | 5 | Inimigo | linha | 3 | sim | não | Areia Movediça (6) | 4 |
  | 73 | `chao_de_geada` | Chão de Geada | Gelo | Suporte | 0 | 0 | 10 | Inimigo | linha | 3 | sim | não | Geada (8) | 3 |
  | 74 | `espinho_venenoso` | Espinho Venenoso | Toxina | Físico | 40 | 100 | 25 | Inimigo | um alvo | 1 | não | sim | — | 0 |
  | 75 | `poca_toxica` | Poça Tóxica | Toxina | Suporte | 0 | 0 | 10 | Inimigo | linha | 3 | sim | não | Poça Tóxica (6) | 4 |

- **RF-02:** As descrições (Bestiário e F1):
  - **Esguicho:** "Esguicha água no primeiro da linha, a até 3 hexágonos, e o deixa Encharcado: ele sofre mais com Volt e menos com Fogo."
  - **Poça d'Água:** "Alaga uma fileira. Quem para na poça fica Encharcado."
  - **Laço de Raízes:** "Enrola o alvo em raízes. Ele fica Preso e não anda por duas vezes."
  - **Brotar:** "Faz brotar folhas num aliado, ou em si mesmo, que recupera um pouco de HP a cada vez."
  - **Semear Jardim:** "Semeia um jardim debaixo de um aliado, ou de si mesmo. Quem para nele recupera HP, até um inimigo."
  - **Lama Grudenta:** "Joga lama na fileira inteira. Quem para no lamaçal fica mais lento."
  - **Areia Movediça:** "Afofa o chão de uma fileira. Quem para na areia fica Preso, menos quem voa."
  - **Chão de Geada:** "Cobre uma fileira de geada. Quem para nela escorrega e perde Evasão."
  - **Espinho Venenoso:** "Espeta o alvo com um espinho venenoso. Pode deixá-lo Envenenado."
  - **Poça Tóxica:** "Derrama veneno numa fileira. Quem para na poça fica Envenenado."
- **RF-03:** Os efeitos (`skill_effects`, a partir do id 46), todos `apply_status`:

  | Técnica | Estado | Chance | Em quem |
  | --- | --- | --- | --- |
  | Esguicho | Encharcado | 100% | no alvo |
  | Laço de Raízes | Preso | 100% | no alvo |
  | Brotar | Brotando | 100% | no alvo (o aliado) |
  | Espinho Venenoso | Envenenado | 30% | no alvo |

- **RF-04:** Os learnsets, todos por nível (`level_up`):

  | Técnica | Quem aprende (nível) |
  | --- | --- |
  | Esguicho | Nilu, Nilgar e Nilgorr (16); Tidebud, Kelpcoil e Tempestide (7) |
  | Poça d'Água | Nilgar, Nilgorr, Kelpcoil e Tempestide (30) |
  | Laço de Raízes | Seedlet, Grovequill e Arbornix (16) |
  | Brotar | Seedlet, Grovequill e Arbornix (22) |
  | Semear Jardim | Grovequill e Arbornix (40) |
  | Lama Grudenta | Clod, Crag e Ingot (22) |
  | Areia Movediça | Crag e Ingot (36) |
  | Chão de Geada | Hushling e Echofrost (20) |
  | Espinho Venenoso | Seedlet, Grovequill e Arbornix (4) |
  | Poça Tóxica | Nilgorr (38) e Ingot (44) |

## Critérios de aceite

- [x] O learnset do Tidebud tem o Esguicho no nível 7, e `GET /v1/catalog` traz as Técnicas 66 a 75 com os efeitos.
- [x] Num teste temporário com o catálogo do banco, o Esguicho seguido da Corrente Viva tira 1,5× do dano sem o Esguicho; o Laço de Raízes deixa o alvo sem andar; a Poça Tóxica não envenena o Nilgorr.
- [x] O jogo abre com o `CatalogValidator` aceitando o catálogo.
- [ ] O F1 mostra as dez Técnicas (o dono confere com janela).
- [x] Lint, typecheck e testes do servidor passam.

## Desenho técnico

- A migração `server/prisma/migrations/20270110000000_field_skills/`, com `skills`, `skill_effects` e `species_skills`, e `migrate deploy`.
- As contagens dos testes de catálogo, se algum conta as Técnicas.
- O GDD e o índice das Técnicas por Elemento, se houver.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test
godot --headless -d --path client --quit-after 240
```

## Resultado da verificação

Em 2026-11-19, com a migração aplicada, um teste temporário (já apagado) leu o catálogo da luta do banco e mostrou:

- o Esguicho deixou o alvo Encharcado por 3 vezes, e a Corrente Viva tirou 63 de HP num alvo seco e 95 num encharcado (1,5×);
- o Laço de Raízes deixou o alvo Preso por 2 vezes, e o preso teve o `move` recusado;
- a Poça Tóxica envenenou um Ecobeast de Água e não envenenou um de Água/Metal, como o Nilgorr;
- o Brotar e o Semear Jardim, usados no próprio autor, curaram no fim da vez.

Com o servidor reiniciado, o `GET /v1/catalog` trouxe a coluna `heal_percent` (6 no Jardim), os estados 10 e 11, a imunidade do Vento ao Preso, as marcas 6 a 11, as Técnicas 66 a 75, os efeitos 46 a 49 e as 30 linhas de learnset, com o Esguicho do Tidebud no nível 7. O `GET /v1/species/tidebud` não lista Técnicas, então o learnset foi conferido no `species_skills` do catálogo. O jogo sem janela abriu com o `CatalogValidator` aceitando o catálogo. Falta o dono ver o F1 com janela.
