# 03. Os NPCs no jogo: passeio, conversa e ação

- **Status:** concluída
- **Depende de:** [01-npc-records](01-npc-records.md), [npc-tamers](../npc-tamers/), [wild-battle/15](../wild-battle/15-free-walk.md)

## Contexto

O mapa de Explorar numa ilha já traz os NPCs ([01](01-npc-records.md)). Esta fase os mostra e faz o Domador conversar com eles.

## Escopo

- Os NPCs no mapa, parados ou passeando.
- O toque no NPC, a conversa e a ação.

## Fora do escopo

- Escolhas no diálogo e tipos novos de ação.

## Requisitos

- **RF-01:** Cada NPC aparece no hexágono onde nasce, com as folhas de explorar do sprite dele, na escala do Domador. Parado, fica nele com a animação parada, de frente.
- **RF-02:** Passeando, ele fica parado de 2 a 5 s, escolhe um hexágono do passeio (o de nascimento incluído) diferente do atual e anda até ele, de centro em centro, pelo caminho mais curto sem bloqueados, com a animação de andar, virado para onde vai. Sem caminho, escolhe de novo depois da pausa.
- **RF-03:** O NPC não bloqueia o Domador nem os toques no mapa, a não ser o toque na figura dele.
- **RF-04:** Tocar na figura do NPC, com o Domador a até 1 hexágono do hexágono do NPC, abre a conversa. De mais longe, o Domador anda até o hexágono do NPC ou um vizinho livre, o mais perto, e a conversa abre ao chegar. Um toque no meio do caminho troca o destino, como hoje.
- **RF-05:** Na conversa, o NPC para e vira para o Domador, o mapa trava como na fala de um Domador NPC, e a caixa mostra "<nome>: <fala>". Cada parágrafo do diálogo (separado por linha em branco) é uma fala; o toque mostra a fala inteira e, depois, passa à próxima.
- **RF-06:** Depois da última fala, a caixa fecha, o mapa destrava, o NPC volta a passear, e a ação roda, se houver, como a de um hexágono (`ACTION_SCREENS` pelo `slug`). Sem diálogo, o toque roda a ação direto. Sem nenhum dos dois, o toque não faz nada.

## Critérios de aceite

- [x] Na ilha, o NPC parado fica no hexágono, e o que passeia anda entre os hexágonos marcados.
- [x] Tocar perto abre as falas uma a uma; de longe, o Domador vai até ele e a conversa abre.
- [x] Com a ação Refúgio, a tela do Refúgio abre depois da última fala.

## Desenho técnico

- `domain/models/map_npc.gd` (novo, `MapNpc`): `id`, `npc_id`, `coord`, `still`, `tiles`, `dialogue`, `action_type_id` e `lines()`.
- `exploration_map.gd`: `npcs`.
- `core/autoload/game_data.gd`: `get_npc(id)`. Um NPC cujo sprite não tem as folhas não é desenhado.
- `ui/components/npc_sprite.gd` (novo, `NpcSprite`): um `CreatureSprite` que passeia pelos hexágonos (`place_on(view, map)`; sem mapa, no editor, fica parado), muda de linha no `HexMapView` ao andar, `hold()` para a conversa e `hits(point)` para o toque.
- `screens/exploration/exploration_screen.gd`: os NPCs, o toque, a conversa (`_talk`) e a ação por tipo.
