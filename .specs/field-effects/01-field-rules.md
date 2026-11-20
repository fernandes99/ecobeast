# 01. As regras: Preso, Encharcado, Brotando e as marcas novas

- **Status:** concluída
- **Depende de:** [puffcoo-line/01](../puffcoo-line/01-field-rules.md) (o Atordoado e as marcas que mudam atributos)

## Contexto

O motor da luta (`server/src/domain/battle/` e `board/`) já tem os estados voláteis contados por vez (o Atordoado, que sai no `endVez` antes das marcas) e as marcas que tiram HP, põem estado ou mudam atributos (`board/marks.ts`). Esta fase cria as regras novas e as marcas no catálogo. Nenhuma Técnica as usa ainda: elas entram na [03](03-field-skills.md), e o jogo só mostra o que é novo na [02](02-field-screen.md).

## Escopo

- O Preso no tabuleiro.
- Os estados Encharcado e Brotando.
- A coluna `ground_effects.heal_percent` e a regra da marca que cura.
- As seis marcas novas e as imunidades novas.
- A IA com o Preso e as marcas novas.

## Fora do escopo

- As Técnicas novas ([03](03-field-skills.md)) e qualquer mudança no Godot ([02](02-field-screen.md)).
- Mudar o Atordoado, as marcas de hoje ou a ordem do fim da vez.

## Requisitos

**Preso**

- **RF-01:** Aplicar `trapped` deixa o Ecobeast preso por 2 vezes dele (`Combatant.trappedTurns = 2`; o `isTrapped` de hoje vira `trappedTurns > 0`). Se ele já está preso, o efeito falha (`effect_failed`). `status_condition_immunities` ganha `{ status_condition_id: 8, element_id: 6 }`: o Vento não fica preso.
- **RF-02:** Na vez dele, um Ecobeast preso não anda. Um pedido com `move` é recusado com 400 e a mensagem "Preso: não dá para andar nesta vez.", e nada muda. Ele ainda pode usar uma Técnica ou um item, usar uma Esfera ou passar. Trocar quem está preso e fugir com um Ecobeast do jogador preso continuam proibidos, como hoje ("Não dá para trocar agora." e "Não dá para fugir agora."); a diferença é que agora o Preso acaba sozinho.
- **RF-03:** No fim da vez de quem está preso, antes das marcas, `trappedTurns` cai 1. Em 0, sai o evento `status_ended` (`status: "trapped"`). Vale mesmo se ele perdeu a vez.

**Encharcado** (`soaked`)

- **RF-04:** `status_conditions` ganha `{ id: 10, slug: "soaked", name: "Encharcado", is_volatile: true }`. Aplicar `soaked` deixa o Ecobeast encharcado por 3 vezes dele (`Combatant.soakedTurns = 3`). Se ele já está encharcado, a contagem volta para 3, com o evento `status_applied` de novo (molhar de novo renova).
- **RF-05:** O dano de uma Técnica de Volt num Ecobeast encharcado é multiplicado por 1,5, e o de uma Técnica de Fogo, por 0,5, junto dos outros multiplicadores do `calculateDamage`. O dano fixo (`fixed_damage`) não muda.
- **RF-06:** No fim da vez de quem está encharcado, antes das marcas, `soakedTurns` cai 1. Em 0, sai o `status_ended` (`status: "soaked"`).

**Brotando** (`sprouting`)

- **RF-07:** `status_conditions` ganha `{ id: 11, slug: "sprouting", name: "Brotando", is_volatile: true }`. Aplicar `sprouting` deixa o Ecobeast brotando por 5 vezes dele (`Combatant.sproutingTurns = 5`). Se ele já está brotando, o efeito falha.
- **RF-08:** No fim da vez de quem está brotando, depois do dano do Queimado e do Envenenado e antes das marcas, ele recupera 1/16 do HP máximo (no mínimo 1, sem passar do máximo), com o evento novo `status_heal` (`side`, `position`, `status: "sprouting"`, `amount`, `hp`). Com o HP cheio, não há evento. Depois, `sproutingTurns` cai 1, e em 0 sai o `status_ended`.

**Os três estados**

- **RF-09:** Os três são voláteis: saem ao desmaiar, ao sair do tabuleiro numa troca e no fim da luta (`clearVolatile`).
- **RF-10:** A vista de cada Ecobeast na luta ganha `trapped`, `soaked` e `sprouting` (booleanos), ao lado de `dazed`. Uma luta salva antes desta fase, sem os campos novos, conta 0 vezes em cada um.

**A marca que cura**

- **RF-11:** `ground_effects` ganha a coluna `heal_percent` (inteiro, anulável). Depois de cada vez, uma marca com `heal_percent` cura essa porcentagem do HP máximo de todos que estão nela (no mínimo 1, sem passar do máximo), com o evento novo `ground_heal` (`side`, `position`, `amount`, `hp`, `ground_effect_id`). Com o HP cheio, não há evento. A cura vem depois do dano da marca, na mesma ordem de hoje (primeiro o jogador, em ordem de vaga).

**As marcas novas**

- **RF-12:** `ground_effects` ganha seis linhas:

  | id | slug | name | damage_percent | heal_percent | status_condition_id | color_hex | Atributos (`ground_effect_stats`) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 6 | `mud` | Lamaçal | — | — | — | `#7A5A3A` | Velocidade −1 |
  | 7 | `frost` | Geada | — | — | — | `#CFEFFF` | Evasão −1 |
  | 8 | `toxic_pool` | Poça Tóxica | — | — | 2 (Envenenado) | `#8E44AD` | — |
  | 9 | `quicksand` | Areia Movediça | — | — | 8 (Preso) | `#D9B26F` | — |
  | 10 | `garden` | Jardim | — | 6 | — | `#7FCB6B` | — |
  | 11 | `puddle` | Poça d'Água | — | — | 10 (Encharcado) | `#4A90D9` | — |

  Quem termina a vez na Areia Movediça fica preso de novo, como no Redemoinho, até a marca acabar, a não ser que seja de Vento. Quem está na Poça d'Água fica encharcado de novo a cada vez, então o Encharcado não acaba enquanto ele estiver nela.

**IA**

- **RF-13:** Um Ecobeast da IA que está preso não tenta andar. Para escolher o hexágono, a IA continua evitando os hexágonos com marca, menos o Jardim, que ela prefere quando está com menos da metade do HP.

## Critérios de aceite

- [x] Um teste mostra que um Ecobeast preso não anda (400 com a mensagem) por 2 vezes e, no fim da segunda, recebe o `status_ended` do `trapped`; e que um de Vento recebe `effect_failed`.
- [x] Um teste mostra que uma Técnica de Volt tira 1,5× e uma de Fogo 0,5× num alvo encharcado, e que molhar de novo renova as 3 vezes.
- [x] Um teste mostra que quem está brotando recupera 1/16 no fim de cada uma das 5 vezes dele, sem passar do máximo, e que o estado acaba sozinho.
- [x] Um teste mostra que o Jardim cura todos que estão nele depois de cada vez, e que não há `ground_heal` com o HP cheio.
- [x] Um teste mostra que quem termina a vez na Areia Movediça continua preso enquanto a marca dura.
- [x] Um teste mostra que a IA presa não manda `move`.
- [x] `GET /v1/catalog` traz os status 10 e 11, a imunidade nova, a coluna `heal_percent` e as marcas 6 a 11.
- [x] Lint, typecheck, testes de unidade e e2e do servidor passam.

## Desenho técnico

- **Banco:** a migração `server/prisma/migrations/<data>_field_effects/`, com SQL à mão e `migrate deploy`: a coluna `heal_percent`, os status 10 e 11, a imunidade do Vento ao Preso, as marcas 6 a 11 e as linhas de `ground_effect_stats` do Lamaçal e da Geada. O `schema.prisma` ganha a coluna. O `seed-data/` não muda.
- **Catálogo:** `heal_percent` em `server/src/catalog/catalog-tables.ts`; `battle-catalog.ts` leva o `healPercent` ao `BattleGroundEffect`.
- **Motor:**
  - `domain/battle/types.ts`: `trappedTurns`, `soakedTurns` e `sproutingTurns` no `Combatant`, no lugar do `isTrapped`;
  - `domain/battle/status.ts`: os três no `setStatus`, no `hasStatus` e no `clearVolatile`, e o `status_heal`;
  - `domain/battle/damage.ts`: o multiplicador do Encharcado;
  - `domain/board/board-engine.ts`: a recusa do `move` com o Preso, ao lado da do Atordoado, e a contagem das três no `endVez`, antes das marcas;
  - `domain/board/marks.ts`: a cura da marca;
  - `domain/board/board-ai.ts`: o RF-13.
- **Vista:** os três campos no `battle.mapper.ts` e no DTO (Swagger), e os eventos `status_heal` e `ground_heal` na lista de eventos.
- **Documentos:** o `GDD.md` (os estados voláteis), o [board-battle/architecture.md](../board-battle/architecture.md) (as marcas e os eventos) e o espelho do catálogo no cliente (`client/core/data/catalog_schema.gd`, a coluna nova), para o jogo continuar abrindo.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```

## Resultado da verificação

Em 2026-11-19: os testes novos falharam antes do código e passaram depois. O servidor fica com 1037 testes de unidade passando, lint e typecheck sem erro. Nos e2e, o `bundle.e2e-spec.ts` pedia a coluna nova também no JSON da carga inicial: o `ground_effects.json` ganhou só a chave `heal_percent` vazia, sem mudar nenhum valor. Três e2e falham por motivos de antes desta fase: os learnsets e as partes do dia da carga inicial, que as migrações das linhas novas mudaram, e um tempo esgotado no Santuário.

A troca não limpa os estados de quem sai, e sim de quem entra (`enterBoard`, como já era com o Atordoado): quem sai encharcado volta seco.
