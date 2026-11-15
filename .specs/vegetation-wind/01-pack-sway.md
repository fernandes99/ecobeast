# 01. O vento nos arbustos dos pacotes

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [vegetation-packs/01](../vegetation-packs/01-pack-props.md)

## Contexto

O dono quer as plantas dos pacotes animadas ([README](README.md#contexto)).

## Escopo

- A força do vento por tipo de peça.
- A folga na malha da peça e o corte da folga no shader.

## Requisitos

- **RF-01:** `HexMapView.PROP_SWAY` diz quantos pixels o topo de cada tipo anda:

  | Tipos | Topo |
  | --- | --- |
  | Os arbustos, flores e samambaias: 40 a 47 e 50 a 52 | 1 px |

  As árvores (28 a 38) ficam fora: o dono quer para elas algo melhor que o balanço do shader.

  Um tipo fora da tabela fica parado.
- **RF-02:** A peça que balança manda ao shader o pé, a força (negativa na espelhada) e a altura da arte, como a decoração do bioma.
- **RF-03:** A malha dessa peça tem uma folga do tamanho da força em cada lado. O shader deixa transparente o que cai fora da arte quando a peça balança, em vez de repetir a textura.
- **RF-04:** A malha que não balança desenha igual a antes.

## Critérios de aceite

- [x] Sem janela, o mapa monta as peças dos pacotes com o vento certo por tipo, e as pedras com o vento zerado.
- [x] Um GIF desenhado pelo jogo mostra os arbustos balançando, sem corte e sem risco na borda, e as pedras paradas.
- [ ] No jogo (F5) e no editor (F2), as plantas balançam junto com as do bioma.

## Desenho técnico

**Alterar:**
- `client/ui/components/hex_map_view.gd`: `PROP_SWAY` e `_add_file_props`, com a folga e o vento.
- `client/ui/components/plant_wind.gdshader`: o corte fora da arte quando `plant.z` não é 0.

## Verificação

```bash
godot --headless --path client --quit-after 30
```

À mão: andar numa ilha com as plantas dos pacotes (F5) e abrir o editor (F2).
