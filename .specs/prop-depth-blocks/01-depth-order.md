# 01. A ordem de desenho pelo pé

- **Status:** concluída (falta o dono jogar)
- **Depende de:** [free-props/02](../free-props/02-props-in-game.md)

## Contexto

Uma peça da linha de baixo cobre o Domador mesmo com o pé atrás do dele ([README](README.md#contexto)).

## Escopo

- As fatias e as 6 faixas de 7 px do `HexMapView`, e a passagem para a linha de baixo ([arquitetura](architecture.md#a-ordem-de-desenho)).
- Os Ecobeasts e os NPCs que passeiam entrando pelo pé.

## Fora do escopo

- O bloqueio ([02](02-variant-blocks.md)).

## Requisitos

- **RF-01:** Peças soltas, decorações naturais e pedaços de cerca são desenhados na fatia e na faixa do pé, pela regra da [arquitetura](architecture.md#a-ordem-de-desenho).
- **RF-02:** `set_actor_depth` põe o ator pela fatia e pela faixa do pé, com a mesma regra da passagem.
- **RF-03:** Os Ecobeasts do mapa (`WanderingSprite`) e os NPCs (`NpcSprite`) chamam `set_actor_depth` com o pé no chão plano a cada passo. O nó só se move quando a fatia ou a faixa muda.
- **RF-04:** Num hexágono com um vizinho de baixo mais alto, a peça na ponta de baixo continua coberta pelo paredão dele.

## Critérios de aceite

- [x] Sem janela, um ator com o pé 2 px abaixo do pé de uma peça da linha de baixo fica depois dela na árvore de nós, e com o pé 2 px acima fica antes.
- [x] Sem janela, a peça na ponta de baixo de um hexágono com o vizinho de baixo mais alto fica na própria linha.
- [x] Uma prévia desenhada pelo jogo mostra o Domador na frente da árvore do caso do dono.
- [ ] Na ilha "Teste dos pacotes" (F5), o Domador passa na frente e atrás das árvores sem trocar de camada errado.

## Desenho técnico

**Alterar:**
- `res://ui/components/hex_map_view.gd`: `DEPTH_BANDS = 6`, `BAND_HEIGHT = 7.0`, a fatia, a passagem e o `set_actor_depth`.
- `res://ui/components/wandering_sprite.gd` e `res://ui/components/npc_sprite.gd`: o pé a cada passo.
- `res://screens/exploration/exploration_screen.gd`: os Ecobeasts entram pelo pé.

## Verificação

```bash
godot --headless --path client --quit-after 30
```

À mão (F5): na ilha "Teste dos pacotes", andar em volta das árvores grandes.

## Tarefas

- [x] A fatia, as faixas e a passagem.
- [x] Os atores pelo pé.
- [x] A cena temporária e a prévia.
- [ ] O passo à mão, com o dono.

## Resultado da verificação

Em 2026-11-15:

- **Cena temporária sem janela** (apagada), com o `HexMapView` de verdade:
  - um ator 2 px na frente do pé de uma árvore da linha de baixo fica depois dela, e 2 px atrás fica antes;
  - o pé dele passa para a linha de baixo;
  - com o vizinho de baixo 3 níveis mais alto, o pé fica na própria linha.
- **Prévia desenhada pelo jogo:** o Domador na ponta de baixo do hexágono de cima aparece na frente do tronco, o caso do print do dono.
- **Compilação:** o jogo, o editor e a luta no tabuleiro abrem sem erros de script nem avisos novos.
- **Escolhas na implementação:**
  - `set_actor_row` e `MIDDLE_BAND` saíram: o NPC parado do editor também entra pelo pé.
  - `follow_depth` guarda a última linha e divisa no nó (`depth_place`) e só move o nó quando elas mudam.
- **Falta o dono:** andar em volta das árvores na ilha "Teste dos pacotes" (F5).
