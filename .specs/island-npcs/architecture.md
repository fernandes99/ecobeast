# island-npcs: arquitetura

## O catálogo: `npcs`

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `slug` | text | `^[a-z0-9_]+$`, único |
| `name` | text | pt-BR, o que a caixa de fala mostra |
| `description` | text | pt-BR, só para o editor |
| `sprite` | text | `^[a-z0-9_]+$`: a pasta `assets/creatures/<sprite>/explore/`, com `idle.png` e `walk.png` (as folhas do `CreatureSprite`, na escala do Domador: 1,70 m são 25 px) |

Os primeiros, para testar (o dono troca e cria os dele pelo painel):

| id | slug | name | description | sprite |
| --- | --- | --- | --- | --- |
| 1 | `village_ruvo` | Ruvo da vila | Mora na vila e conhece todo mundo. | `ruvo` |
| 2 | `guard_ruvak` | Ruvak, o guardião | Vigia a entrada da vila. | `ruvak` |

O editor mostra desligado o NPC cujo sprite não tem as duas folhas, e o jogo não o desenha. Hoje 11 Ecobeasts as têm.

## As tabelas da ilha

**`island_npcs`**, um NPC posto numa versão de ilha:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `island_map_id` | int | FK `island_maps`, apaga junto |
| `npc_id` | int | FK `npcs`, `Restrict` |
| `q`, `r` | int | o hexágono onde ele nasce |
| `still` | bool | parado; com `true`, o passeio é ignorado |
| `dialogue` | text | vazio é sem diálogo; até 2.000 caracteres |
| `action_type_id` | int, opcional | FK `action_types`, `Restrict`; nulo é sem ação |

**`island_npc_tiles`**, os hexágonos do passeio (`island_npc_id` FK que apaga junto, `q`, `r`, chave `(island_npc_id, q, r)`). O hexágono onde ele nasce sempre faz parte do passeio e não é guardado aqui.

## O rascunho

O rascunho ([map-editor](../map-editor/architecture.md#o-rascunho)) ganha `npcs`, opcional:

```json
{
  "npcs": [
    {
      "npc_id": 1,
      "q": 3,
      "r": -1,
      "still": false,
      "tiles": [{ "q": 4, "r": -1 }, { "q": 5, "r": -2 }],
      "dialogue": "Bem-vindo!\n\nO Refúgio fica ali.",
      "action_type_id": 1
    }
  ]
}
```

- `tiles` e `dialogue` podem faltar (vazios); `action_type_id` pode ser `null` ou faltar.
- Salvar recusa (`400`) com a mensagem do primeiro NPC errado, numerado de 1 em diante:
  - "O NPC 2 não existe no catálogo.";
  - "O NPC 2 fica em (3, 1), que não é da ilha.";
  - "O NPC 2 passeia por (4, 1), que não é da ilha.";
  - "O NPC 2 repete o hexágono (4, 1) no passeio." (o de nascimento também conta);
  - "O NPC 2 passeia por mais de 40 hexágonos.";
  - "O diálogo do NPC 2 passa de 2.000 caracteres.";
  - "O NPC 2 tem uma ação que não existe.";
  - "A ilha pode ter até 200 NPCs.".
- O `content_hash` inclui os NPCs só quando há algum (uma ilha sem NPC tem o hash de antes), em ordem de `(r, q, npc_id)`, com os hexágonos do passeio em ordem de `(r, q)`.

## O mapa de Explorar numa ilha

`POST /v1/me/exploration` com `island_id` devolve `map.npcs`, no mesmo formato do rascunho, mais o `id` (de 1 em diante, na ordem da versão). No mapa sorteado, `npcs` é `[]`.

## No jogo

- `GameData.get_npc(id)` lê o catálogo; `MapNpc` (`domain/models/map_npc.gd`) é o NPC do mapa, também usado pelo `IslandDraft` do editor.
- O sprite é o `NpcSprite`, um `CreatureSprite` do slug (o mesmo dos selvagens) com o passeio entre hexágonos: escolhe um hexágono do passeio, pede o caminho ao `ExplorationMap.path_to_any` e anda pelos centros, com as animações de andar e parado.
- A conversa usa o `TamerGreetingPanel`, com o nome do NPC, uma fala por parágrafo, e a ação pelo `slug` do tipo (`ACTION_SCREENS`).
