# Glossário

O vocabulário que o jogador vê e o nome que cada conceito tem no código e nos dados. Definido pelo dono do projeto (nomes no jogo) e ajustado no planejamento (nomes no código, marcados com \*).

O jogador nunca vê a coluna "Referência": ela só existe para quem implementa entender de onde o conceito veio.

| Referência          | Termo no jogo                    | Nome no código                         | Tabela / arquivo                                  |
| ------------------- | -------------------------------- | -------------------------------------- | ------------------------------------------------- |
| Pokémon             | Ecobeast                         | `CreatureSpecies` / `CreatureInstance` | `species` / `creature_instances`                  |
| Treinador           | Domador (Tamer)                  | `Player`\*                             | `players`                                         |
| Treinador NPC       | Domador (NPC)                    | `NpcTamer`\*                           | `npc_tamer_names`, `npc_tamer_greetings`; `npc_tamers` na equipe fixa |
| Pokébola            | Esfera de Vínculo (Bond Sphere)  | `CaptureItem`                          | `items` (categoria captura)                       |
| Poção               | Tônico                           | `Item`\*                               | `items` (categoria cura)                          |
| Mochila             | Mochila                          | `InventorySlot`\*                      | `inventory_items`                                 |
| Pokédex             | Bestiário (Codex)                | `Codex`                                | `codex_entries` (estado do jogador) + `species`   |
| Tipo                | Afinidade / Elemento             | `Element`\*                            | `elements`, `element_efficacy`                    |
| Golpe / Move        | Técnica                          | `Skill`                                | `skills`, `skill_effects`, `species_skills`       |
| Habilidade          | Traço                            | `CreatureTrait`\*                      | `traits`, `species_traits`                        |
| Natureza            | Temperamento                     | `Temperament`                          | `temperaments`                                    |
| IV                  | Genes                            | `genes`                                | `creature_instance_stats.genes`                   |
| EV                  | Treino                           | `training_points`                      | `creature_instance_stats.training_points`         |
| PC (caixas)         | Santuário                        | `Storage`                              | `creature_instances.location = storage`           |
| Ginásio / Líder     | Arena / Mestre de Arena          | `Arena` / `ArenaBoss`                  | `arenas`                                          |
| Shiny               | Prismático                       | `is_prismatic`                         | `creature_instances.is_prismatic`                 |
| Lendário            | Ancestral                        | raridade `ancestral`                   | `rarities.slug = "ancestral"`                     |
| Evolução            | Evolução (evoluir)               | `Evolution` / `EvolutionRule`\*        | `evolutions`                                      |
| Centro Pokémon      | Refúgio                          | `HealStation`                          | —                                                 |
| Inicial             | Ecobeast inicial                 | starter                                | `starter_options`                                 |

## Por que alguns nomes mudaram

- **`Player` em vez de `Trainer`:** o humano que joga é sempre `Player`; Domadores controlados pelo jogo são `NpcTamer`. Assim nenhuma classe mistura os dois.
- **`Element` em vez de `ElementType`:** os elementos são linhas de uma tabela (`elements`), não um enum fixo no código. Os ids são estáveis (Fogo = 1 … Arcano = 14).
- **`CreatureTrait` em vez de `Trait`:** evita conflito com uma possível palavra reservada `trait` em versões futuras do GDScript.
- **`EvolutionRule`:** cada linha de `evolutions` é uma regra (de qual espécie, para qual, por qual gatilho).
- **Evolução no jogo:** até a [progression](progression/), o termo no jogo era "Ascensão". O dono trocou por "Evolução" e "evoluir", palavras comuns, em 03/11/2026. As specs concluídas antes disso ainda dizem "Ascensão".

## Outros termos

- **Equipe:** as até 6 criaturas ativas do Domador (`creature_instances.location = party`).
- **Catálogo:** todos os dados de design (espécies, técnicas, elementos…), iguais para todos os jogadores. Ver [game-data](game-data/).
- **Estado do jogador:** tudo que é de um Domador (nome, moedas, criaturas). Ver [onboarding/architecture.md](onboarding/architecture.md).
- **Hub:** a tela principal do jogo (TELAS.md chama de Home).
- **Som do Ecobeast:** o som característico de cada espécie, no arquivo `call.wav` da pasta dela. Não se chama `cry`, o termo do Pokémon. Ver [creature-sounds](creature-sounds/).
- **Mapa de exploração:** a região hexagonal gerada a cada Explorar zona (`ExplorationMap`). Ver [wild-battle](wild-battle/).
- **Bioma:** o tipo de terreno de um hexágono (`biome`), como `temperate` ou `boreal`. Mais tarde, ele decide o Campo.
- **Bioma de encontro:** um dos 7 da tabela `biomes`, que recebem as taxas de `species_biomes`. São os 5 biomas de terreno, em hexágono plano, mais `hill` e `mountain`, que valem para qualquer colina ou montanha.
