# 01. A arte dos rostos

- **Status:** concluída
- **Depende de:** [creature-fronts](../creature-fronts/)

## Contexto

As decisões estão no [README](README.md). Esta fase gera um `face.png` por espécie, recortado do `front.png`, sem mudar nenhuma tela.

## Escopo

- `.claude/skills/creature-sprites/scripts/make_faces.py` (novo) e o `SKILL.md` da skill.
- `client/assets/creatures/faces.json` (novo): o quadrado do rosto de cada espécie.
- `client/assets/creatures/<slug>/face.png` (novos, com o `.import`).
- `art-source/creature-faces/faces_sheet.png` (nova): a folha para conferir, fora de `client/` para o Godot não a levar para o jogo.

## Requisitos

- **RF-01:** O `faces.json` guarda, por slug, o quadrado do rosto no `front.png`: `{"ruvo": [x, y, lado], ...}`, em pixels do front de 512.
- **RF-02:** O `make_faces.py` lê o `faces.json` e, para cada slug com `front.png`, recorta o quadrado e grava o `face.png` com 128×128, o fundo transparente e o alfa só em 0 ou 255, como o `crop_line.py`. Ele avisa, e não grava, quando o quadrado sai do front.
- **RF-03:** Para um slug sem quadrado no `faces.json`, o script calcula um quadrado inicial e o grava no arquivo: o lado é 45% da altura da figura (a caixa dos pixels opacos), com o topo 4 px acima do topo da figura e centrado no meio dos pixels do terço de cima. É só um ponto de partida: nas 37 espécies de hoje, ele pegou orelhas, cristais e asas na maioria, e os quadrados foram marcados à mão. Um quadrado já gravado nunca é trocado.
- **RF-04:** O script grava também a folha `art-source/creature-faces/faces_sheet.png`, só para conferir: todos os rostos numa grade, com o slug embaixo de cada um, para o dono ver de uma vez quais saíram tortos e corrigir o número no `faces.json`.
- **RF-05:** Os rostos de todas as 37 espécies de hoje são gerados e conferidos na folha. Os quadrados que o cálculo errar são corrigidos à mão no `faces.json`.
- **RF-06:** A skill `creature-sprites` passa a mandar rodar o `make_faces.py` depois do `crop_line.py`, numa linha nova.

## Fora do escopo

- Mostrar o rosto em alguma tela (a [fase 2](02-face-component.md)).

## Critérios de aceite

- [x] Toda espécie com `front.png` tem `face.png` de 128×128 e um quadrado no `faces.json`.
- [x] Na folha, cada rosto aparece inteiro e centrado.
- [x] Rodar o script de novo não muda nenhum quadrado nem nenhum rosto.

## Verificação

```bash
python -I .claude/skills/creature-sprites/scripts/make_faces.py
```

Depois, abrir a `faces_sheet.png` e conferir os 37 rostos.

## Tarefas

- [x] O `make_faces.py`, com o quadrado inicial e a folha.
- [x] Gerar os rostos e corrigir os quadrados tortos.
- [x] O passo novo no `SKILL.md`.
- [x] A verificação.
