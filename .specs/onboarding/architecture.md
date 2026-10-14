# Arquitetura

O estado do jogador, os serviços que o alteram e as regras usadas para criar o inicial. Base para as duas fases desta iniciativa e para o [Hub](../hub/).

## Peças

```
telas ──> Session (autoload) ──> GameService ──────────────> PlayerRepository
            player, sinais         │ LocalGameService (MVP)      │ LocalPlayerRepository (MVP: user://save.json)
                                   │ ApiGameService (futuro)     │ ApiPlayerRepository (futuro)
                                   ▼
                            domain/rules: CreatureFactory, StatCalculator, XpCurve
                            GameData.catalog (espécies, learnset, temperamentos…)
```

- **Telas falam só com o `Session`.** Nunca criam `GameService` nem leem `user://`.
- **`Session`** (autoload `res://core/autoload/session.gd`): no `_ready` cria `LocalPlayerRepository` e `LocalGameService` (com o repositório e `GameData.catalog`). Guarda o último `Player` recebido em `player: Player` (ou `null`) e emite `player_changed` quando ele muda. Métodos: `load_player()`, `create_player(name)`, `choose_starter(species_id)`, `reset_progress()` — cada um chama o método de mesmo nome do `GameService` com `await`, atualiza `player` quando dá certo e devolve o `Result`.
- **`GameService`** (`@abstract`): os mesmos quatro métodos, todos devolvendo `Result`. É o contrato que a API vai cumprir.
- **`LocalGameService`**: implementa as regras no cliente. Cada método começa com `await (Engine.get_main_loop() as SceneTree).process_frame`, para ser de fato assíncrono como uma chamada de rede (e o `await` das telas não ser redundante).
- **`PlayerRepository`** (`@abstract`): `load_player() -> Result` (`data`: `Player` ou `null`), `save_player(player: Player) -> Result`, `clear_player() -> Result`. (Não `load`/`save`: `load` é função global do GDScript.)

## Contrato do `GameService`

| Método                             | Sucesso (`data`)                         | Falhas (`error`)                                                                                   |
| ---------------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `get_player()`                     | `Player` ou `null` se não existe          | "Não foi possível carregar seu progresso."                                                         |
| `create_player(name: String)`      | `Player` novo, sem equipe                 | "Use de 2 a 16 letras, números ou espaços." · "Você já tem um Domador."                             |
| `choose_starter(species_id: int)`  | `Player` com a criatura no slot 1 da equipe | "Crie seu Domador primeiro." · "Você já escolheu seu Ecobeast." · "Esse Ecobeast não pode ser escolhido." |
| `reset_progress()`                 | `null`                                    | "Não foi possível apagar o progresso."                                                             |

Falha ao gravar o arquivo em qualquer método que salva: "Não foi possível salvar. Tente de novo." (o estado anterior continua valendo).

No futuro: `get_player` = `GET /me`, `create_player` = `POST /players`, `choose_starter` = `POST /me/starter` — a forma exata fica para a iniciativa `backend-api`.

## Modelos (`res://domain/models/`)

Formato JSON de cada modelo = o formato que a API vai devolver. Cada modelo tem `to_dict() -> Dictionary` e `static func from_dict(d: Dictionary) -> <Classe>`; ausente ou `null` no JSON vira o valor indicado.

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
| current_hp          | int                |                                                                  |
| stats               | StatBlock          | **Calculado**, enviado pelo servidor; não é gravado no save local |
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

`stats` existe no modelo porque a tela precisa do HP máximo e não pode calcular regras: hoje o `LocalGameService` preenche `stats` toda vez que devolve um `Player`; amanhã o servidor manda pronto.

## Save local

`user://save.json` (no Windows, em `%APPDATA%\Godot\app_userdata\Ecobeast\`):

```json
{
  "schema_version": 1,
  "player": {
    "id": "…", "name": "Ana", "level": 1, "coins": 1000, "created_at": "2026-10-14T12:00:00Z",
    "party": [
      {
        "uid": "…", "species_id": 1, "nickname": "", "level": 5, "current_xp": 125, "current_hp": 20,
        "genes": { "hp": 12, "atk": 30, "def": 4, "sp_atk": 19, "sp_def": 27, "spd": 8 },
        "training_points": { "hp": 0, "atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "spd": 0 },
        "temperament_id": 3, "trait_id": 1, "gender": "male", "is_prismatic": false, "bond": 70,
        "skills": [ { "skill_id": 1, "current_pp": 35 }, { "skill_id": 2, "current_pp": 30 } ],
        "status_condition_id": null, "held_item_id": null,
        "original_player_id": "…", "caught_at": "2026-10-14T12:01:00Z", "caught_zone_id": null
      }
    ]
  }
}
```

- Sem arquivo: não há jogador.
- Arquivo ilegível (JSON inválido, sem `player`, `schema_version` diferente de 1): `push_warning`, renomear para `user://save.corrupted.json` (substituindo um anterior) e tratar como "não há jogador".
- Gravar: escrever em `user://save.tmp.json` e renomear para `save.json`, para um fechamento no meio da escrita não corromper o save.

## Regras (`res://domain/rules/`, fase 02)

Funções estáticas, sem estado, que recebem tudo por parâmetro.

**`XpCurve.total_xp_for_level(xp_multiplier: float, level: int) -> int`** = `floor(xp_multiplier · level³)`. Médio no nível 5 = 125.

**`StatCalculator.calculate(base: StatBlock, genes: StatBlock, training: StatBlock, level: int, temperament: Temperament) -> StatBlock`**, com as fórmulas do GDD:

- HP = `floor((2·base + genes + floor(treino/4)) · nível / 100) + nível + 10`
- Outros = `floor((floor((2·base + genes + floor(treino/4)) · nível / 100) + 5) · T)`, com T = 1,1 no stat aumentado, 0,9 no diminuído, 1,0 nos demais (neutros: 1,0 em todos). O `floor` final é do planejamento: stats são inteiros.

Exemplo (Fagulho, nível 5, Genes e Treino 0, neutro): HP 19, Atq 10, Def 9, Atq.E 11, Def.E 9, Vel 11.

**`CreatureFactory.create(params: Dictionary) -> CreatureInstance`**, com `params`: `species: CreatureSpecies`, `level: int`, `uid: String`, `owner_id: String`, `now: String`, `learnset: Array[LearnsetEntry]`, `max_pp_by_skill: Dictionary` (id → PP), `trait_ids: Array[int]` (traços normais da espécie), `temperaments: Array[Temperament]`, `xp_multiplier: float`, `rng: RandomNumberGenerator`.

1. Genes: cada stat `rng.randi_range(0, 31)`. Treino: tudo 0.
2. Temperamento: um dos 25, sorteado. Traço: um dos `trait_ids`, sorteado.
3. Gênero: `none` se `gender_ratio < 0`; senão `male` se `rng.randf() < gender_ratio`, `female` caso contrário.
4. Técnicas: entradas `level_up` com nível ≤ `level`, por nível crescente (empate: ordem do learnset); ficam as 4 últimas, cada uma com `current_pp` = PP máximo.
5. `current_xp` = `XpCurve.total_xp_for_level(xp_multiplier, level)`.
6. `stats` = `StatCalculator.calculate(...)`; `current_hp` = `stats.hp`.
7. `is_prismatic` = false; `bond` = 70; `nickname` = ""; status, item e zona = −1; `original_player_id` = `owner_id`; `caught_at` = `now`.

O sorteio usa o `rng` recebido: com a mesma semente, o resultado é o mesmo.

**`Uuid.v4() -> String`** (`res://core/util/uuid.gd`): 16 bytes de `Crypto.generate_random_bytes`, com os bits de versão (4) e variante, no formato `8-4-4-4-12` em hexadecimal minúsculo. Fica em `core/` porque usa a API do motor; o domínio recebe o uid pronto.

## Boot

Depois de carregar o catálogo, `main.gd` faz `await Session.load_player()`:

| Resultado                      | Tela                                    |
| ------------------------------ | --------------------------------------- |
| Falhou                         | Mensagem de erro com "Tentar de novo"   |
| `player == null`               | `title`                                 |
| `not player.has_starter()`     | `starter_select`                        |
| `player.has_starter()`         | `hub`                                   |

Até as telas `starter_select` e `hub` existirem, essas linhas abrem o `placeholder` com o título da tela que falta ("Escolha do inicial", "Hub").
