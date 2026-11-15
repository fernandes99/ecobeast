# 02. A ponte no mapa

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [01-bridge-records](01-bridge-records.md)

## Contexto

Com as pontes guardadas, o mapa precisa desenhá-las em qualquer ângulo, sem girar a arte, na altura das margens e na ordem certa com o Domador ([arquitetura](architecture.md#o-desenho-fase-2)).

## Escopo

- `HexBridges`: os pedaços de cada ponte, deitada ou em pé.
- O `HexMapView` desenhando as pontes nas faixas, com a altura do piso.
- A visão de cima do editor.

## Requisitos

- **RF-01:** Uma ponte deitada é feita de colunas de 1 px da vista de lado, e uma em pé de linhas de 1 px da vista de cima, com as cabeceiras nas pontas e o meio repetindo.
- **RF-02:** A parte de trás da ponte deitada fica atrás de quem está no piso, e o corrimão da frente fica na frente dele. Na ponte em pé, quem está no piso fica por cima das linhas.
- **RF-03:** Cada pedaço sobe a altura do piso no ponto dele, em pixels inteiros.
- **RF-04:** Mudar uma ponte remonta só os pedaços de linhas que ela tocava e toca.
- **RF-05:** A visão de cima (`IslandOverview`) mostra cada ponte como uma faixa da largura do piso.

## Critérios de aceite

- [x] Uma prévia desenhada pelo jogo mostra todos os estilos em 0°, 20°, 45°, 70° e 90°, com o Domador na frente, atrás e em cima de cada ponte, sem buraco nem emenda no meio.
- [ ] Uma ponte entre margens de alturas diferentes sobe em rampa.

## Desenho técnico

**Criar:**
- `client/ui/components/hex_bridges.gd`.

**Alterar:**
- `client/ui/components/hex_map_view.gd`: `set_bridges` e `_bridges_by_chunk`, como as paredes.
- `client/tools/map_editor/island_overview.gd`.

## Verificação

```bash
godot --headless --path client --quit-after 30
```

A prévia do critério de aceite, numa cena temporária com janela.
