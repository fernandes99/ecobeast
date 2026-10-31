# Arquitetura

O estado do jogador, os serviços que o alteram e as regras usadas para criar o inicial. Base para as duas fases desta iniciativa e para o [Hub](../hub/).

## Peças

```
telas ──> Session (autoload) ──> GameService
            player, sinais         │ ApiGameService ──> Api (autoload) ──> servidor (/v1/me)
```

- **Telas falam só com o `Session`.** Nunca criam `GameService` nem leem `user://`.
- **`Session`** (autoload `res://core/autoload/session.gd`): cria o `ApiGameService`. Guarda o último `Player` recebido em `player: Player` (ou `null`) e emite `player_changed` quando ele muda. Métodos: `load_player()`, `create_player(name)`, `choose_starter(species_id)`, `reset_progress()` — cada um chama o método de mesmo nome do `GameService` com `await`, atualiza `player` quando dá certo e devolve o `Result`.
- **`GameService`** (`@abstract`): os mesmos quatro métodos, todos devolvendo `Result`.
- **`ApiGameService`** ([auth-google/05](../auth-google/05-client-player.md)): chama as [rotas do jogador](../auth-google/architecture.md#rotas-do-jogador) com `Api.request(..., authenticated = true)`. As regras moram no servidor, e o progresso só existe no banco.

## Contrato do `GameService`

| Método                             | Sucesso (`data`)                         | Falhas (`error`)                                                                                   |
| ---------------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `get_player()`                     | `Player` ou `null` se não existe          | —                                                                                                  |
| `create_player(name: String)`      | `Player` novo, sem equipe                 | "Use de 2 a 16 letras, números ou espaços." · "Você já tem um Domador."                             |
| `choose_starter(species_id: int)`  | `Player` com a criatura no slot 1 da equipe | "Crie seu Domador primeiro." · "Você já escolheu seu Ecobeast." · "Esse Ecobeast não pode ser escolhido." |
| `reset_progress()`                 | `null`                                    | —                                                                                                  |

Quem escreve as mensagens acima é o servidor. Em qualquer método, sem resposta do servidor ou com erro 5xx, `error` traz a mensagem do `ApiResponse` ("Não foi possível conectar ao servidor." ou "O servidor teve um problema. Tente de novo."), e o estado anterior continua valendo.

Rotas: `get_player` = `GET /v1/me`, `create_player` = `POST /v1/me`, `choose_starter` = `POST /v1/me/starter`, `reset_progress` = `DELETE /v1/me`.

## Modelos (`res://domain/models/`)

Formato JSON de cada modelo = o formato que a API devolve. Cada modelo tem `static func from_dict(d: Dictionary) -> <Classe>`; ausente ou `null` no JSON vira o valor indicado.

**`Player`** (`player.gd`)

| Campo      | Tipo                       | Observação                               |
| ---------- | -------------------------- | ---------------------------------------- |
| id         | String                     | UUID v4                                  |
| name       | String                     | Já normalizado                           |
| level      | int                        | 1 no MVP                                 |
| coins      | int                        | 1000 ao criar                            |
| created_at | String                     | ISO 8601 em UTC (`2026-10-14T12:00:00Z`) |
| party      | Array[CreatureInstance]    | 0 a 6, na ordem dos slots                |

`has_starter() -> bool` = equipe não vazia.

**`CreatureInstance`** (`creature_instance.gd`)

| Campo               | Tipo               | Observação                                                       |
| ------------------- | ------------------ | ---------------------------------------------------------------- |
| uid                 | String             | UUID v4                                                          |
| species_id          | int                |                                                                  |
| nickname            | String             | `""` = sem apelido                                               |
| level               | int                | 1–100                                                            |
| current_xp          | int                | XP total acumulado                                               |
| level_xp            | int                | XP total para chegar ao nível atual                              |
| next_level_xp       | int                | XP total para chegar ao próximo nível; `null` no nível 100       |
| current_hp          | int                |                                                                  |
| stats               | StatBlock          | **Calculado** pelo servidor a cada resposta                       |
| genes               | StatBlock          | 0–31 cada                                                        |
| training_points     | StatBlock          | 0–252 cada, 510 no total                                         |
| temperament_id      | int                |                                                                  |
| trait_id            | int                |                                                                  |
| gender              | String             | `male`, `female` ou `none`                                       |
| is_prismatic        | bool               |                                                                  |
| bond                | int                | 0–255                                                            |
| skills              | Array[SkillSlot]   | 1 a 4                                                            |
| status_condition_id | int                | `-1` = nenhum (`null` no JSON)                                   |
| held_item_id        | int                | `-1` = nenhum (`null` no JSON)                                   |
| original_player_id  | String             |                                                                  |
| caught_at           | String             | ISO 8601 UTC                                                     |
| caught_zone_id      | int                | `-1` = sem zona (`null` no JSON); o inicial não tem zona         |

`display_name(species: CreatureSpecies) -> String` = apelido, ou o nome da espécie.

**`SkillSlot`** (`skill_slot.gd`): `skill_id: int`, `current_pp: int`.

`stats` existe no modelo porque a tela precisa do HP máximo e não pode calcular regras: o servidor manda pronto em toda resposta.

## Regras (no servidor)

Funções puras em `server/src/domain/rules/`, que recebem tudo por parâmetro ([auth-google/02](../auth-google/02-player-rules.md)). O cliente não tem nenhuma delas.

**XP total de um nível** = `floor(xp_multiplier · level³)`. Médio no nível 5 = 125.

**Stats**, com as fórmulas do GDD:

- HP = `floor((2·base + genes + floor(treino/4)) · nível / 100) + nível + 10`
- Outros = `floor((floor((2·base + genes + floor(treino/4)) · nível / 100) + 5) · T)`, com T = 1,1 no stat aumentado, 0,9 no diminuído, 1,0 nos demais (neutros: 1,0 em todos). O `floor` final é do planejamento: stats são inteiros.

Exemplo (Fagulho, nível 5, Genes e Treino 0, neutro): HP 19, Atq 10, Def 9, Atq.E 11, Def.E 9, Vel 11.

**Criar uma criatura:**

1. Genes: cada stat sorteado de 0 a 31. Treino: tudo 0.
2. Temperamento: um dos 25, sorteado. Traço: um dos normais da espécie, sorteado.
3. Gênero: `none` se `gender_ratio < 0`; senão `male` se um sorteio entre 0 e 1 der menos que `gender_ratio`, `female` caso contrário.
4. Técnicas: entradas `level_up` com nível ≤ `level`, por nível crescente (empate: ordem do learnset); ficam as 4 últimas, cada uma com `current_pp` = PP máximo.
5. `current_xp` = o XP total do nível.
6. `stats` pelas fórmulas acima; `current_hp` = `stats.hp`.
7. `is_prismatic` = false; `bond` = 70; `nickname` = ""; status, item e zona = −1; `original_player_id` = o Domador; `caught_at` = agora.

A fonte de sorteio vem por parâmetro: nos testes, o resultado é repetível.

## Boot

Depois de carregar o catálogo, `main.gd` faz `await Session.load_player()`:

| Resultado                      | Tela                                    |
| ------------------------------ | --------------------------------------- |
| Falhou                         | Mensagem de erro com "Tentar de novo"   |
| `player == null`               | `title`                                 |
| `not player.has_starter()`     | `starter_select`                        |
| `player.has_starter()`         | `hub`                                   |

Até as telas `starter_select` e `hub` existirem, essas linhas abrem o `placeholder` com o título da tela que falta ("Escolha do inicial", "Hub").
