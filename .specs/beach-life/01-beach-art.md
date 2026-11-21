# 01. A arte da Praia

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [nature-variety/01](../nature-variety/01-nature-art.md), [coast-rivers](../coast-rivers/)

## Contexto

As decorações moram na folha `client/assets/terrain/decorations/decorations.png`, uma linha de 48×64 por tipo, 4 variantes, com o pé em (24, 60). As linhas 0 a 63 já existem (as 51 a 63 são da [sea-life](../sea-life/)).

## Escopo

- O `client/assets/terrain/make_beach_life.py`, que desenha as linhas 64 e 65 (a tabela do [README](README.md#os-tipos-linhas-64-e-65-da-folha-peças-152-e-153)).
- Os tipos em `HexDecorations.KIND_ROWS`, `KIND_RADIUS` e `KIND_SWAY`.

## Requisitos

- **RF-01:** O `make_beach_life.py` usa as funções do `make_nature.py` (o contorno escuro de 1 px, a luz de cima à esquerda, o pontilhado e a sombra no pé) e regrava só as linhas 64 e 65, cortando a folha depois delas. Rodar duas vezes dá a mesma folha. `--preview <arquivo>` grava a prévia sobre a areia, ampliada 3 vezes.
- **RF-02:** O coqueiro tem o tronco anelado e curvo (a curva para um lado em cada variante), as folhas em arco com os folíolos em pente, cada folha com o próprio contorno, e os cocos embaixo da copa. O coqueiro novo usa o mesmo desenho, com o tronco de 13 a 17 px e as folhas de 11 a 13 px.
- **RF-03:** `KIND_RADIUS` de 12 no coqueiro e 10 no coqueiro novo, e `KIND_SWAY` nos dois.

## Critérios de aceite

- [x] A prévia dos 2 tipos sobre a areia.
- [ ] O dono aprova a arte.
- [x] `godot --headless --path client --quit-after 30` sem erro de script.
