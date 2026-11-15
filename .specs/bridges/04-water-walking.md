# 04. A água bloqueia e o corredor da ponte

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [03-bridge-tool](03-bridge-tool.md)

## Contexto

O dono decidiu que a água bloqueia nas ilhas e no mapa sorteado, e que a ponte é um corredor do tamanho do piso ([README](README.md#decisões)). O nado com um Ecobeast vem depois.

## Escopo

- O bloqueio da água no andar, na busca de caminho e em quem vaga.
- A ligação da ponte na busca de caminho e o Domador na altura do piso.
- O Procurar na água vizinha, a chegada do mapa sorteado em terra e o NPC fora da água.
- As specs antigas que dizem que a água é livre.

## Requisitos

- **RF-01:** `ExplorationMap.is_clear(from, to)` recusa o segmento que cruza parede ou passa por um ponto de água fora do piso de uma ponte, de 2 em 2 px. Quem já está num ponto bloqueado pode sair dele.
- **RF-02:** O `WalkRoute` e o esticar da rota usam o `is_clear`. Quem vaga dentro do hexágono não muda: o Ecobeast de água continua na água dele.
- **RF-03:** O `path_to_any` não entra em hexágono de água e ganha a ligação de cada ponte, como na [arquitetura](architecture.md#o-andar-fase-4). A rota que usa a ligação passa pelas duas pontas.
- **RF-04:** Tocar no piso leva o Domador até o ponto tocado pela ponte. Tocar na água fora do piso o leva até a margem, rente à água. Sem caminho, a mensagem de hoje.
- **RF-05:** Em cima do piso, o Domador usa a altura do piso (`ExplorationMap.rise_at`). Os NPC das ilhas que passeiam não usam as pontes.
- **RF-06:** O Procurar enfrenta um Ecobeast do hexágono do Domador ou, sem nenhum ali, o de um hexágono de água vizinho, o mais perto do pé.
- **RF-07:** O `startOf` do mapa sorteado nunca escolhe a água.
- **RF-08:** O servidor recusa um NPC, ou um hexágono de passeio dele, na água ("O NPC não pode ficar na água.").
- **RF-09:** As specs que dizem que a água é livre ganham uma nota apontando para esta: `wild-battle/03`, `08`, `13`, `14`, `island-villages/README`, `island-villages/02` e `town-art/README`.

## Critérios de aceite

- [x] Sem janela: a busca não atravessa a água, atravessa pela ponte, e a rota passa pelas pontas.
- [x] Sem janela: tocar na água para rente à margem, e tocar no piso para no ponto tocado.
- [x] Testes do servidor: a chegada do mapa sorteado em terra e a recusa do NPC na água.
- [ ] No jogo (F5), numa ilha com rio e ponte, o Domador atravessa pela ponte na altura do piso e enfrenta um Ecobeast de água pela margem.

## Desenho técnico

**Alterar:**
- `client/domain/models/exploration_map.gd`, `client/screens/exploration/walk_route.gd`, `client/screens/exploration/exploration_screen.gd`, `client/ui/components/wandering_sprite.gd`, `client/ui/components/npc_sprite.gd` e `client/ui/components/hex_map_view.gd` (`surface_center`).
- `server/src/domain/exploration/map-generator.ts` (`startOf`) e `server/src/domain/islands/island-draft.ts` (`npcsError`), com os testes.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```
