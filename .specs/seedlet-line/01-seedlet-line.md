# 01. Linha do Seedlet

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [browt-line](../browt-line/) (as regras da linha, que não mudam)

## Contexto

O dono trocou a arte e os nomes do inicial de Flora ([README](README.md#decisões)). A imagem fica em `art-source/seedlet/line.webp`:

- **Seedlet** é o da esquerda;
- **Grovequill** é o do meio;
- **Arbornix** é o da direita, com as folhas soltas em volta.

## Escopo

- A migração `20270104000000_seedlet_line`, que troca as linhas 7, 8 e 9 de `species` no lugar.
- A arte:
  - as pastas `client/assets/creatures/browt`, `eagrow` e `sowingle` saem;
  - entram `seedlet`, `grovequill` e `arbornix`, cada uma com `front.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`);
  - o recorte fica em `.claude/skills/creature-sprites/scripts/crop_line.py`.
- Os nomes nos testes do servidor, no `CLAUDE.md`, no `README.md`, no índice das specs e na skill `creature-sprites`.

## Requisitos

- **RF-01:** As três espécies trocam slug, nome e descrição, e o Seedlet e o Grovequill trocam também altura ou peso. O resto da espécie não muda.

  | id | slug | name | Elementos | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- |
  | 7 | `seedlet` | Seedlet | Flora | 0.4 | 3.2 |
  | 8 | `grovequill` | Grovequill | Flora / Vento | 1.0 | 14.0 |
  | 9 | `arbornix` | Arbornix | Flora / Vento | 1.8 | 36.0 |

  Descrições (Bestiário):
  - **Seedlet:** "Filhote de quatro patas com uma crista de folhas novas. Quando fica contente, a ponta da cauda se abre como um broto."
  - **Grovequill:** "Corre entre as árvores com o pescoço esticado. O vento que passa pelas folhas da cauda o deixa mais rápido a cada passo."
  - **Arbornix:** "Quando abre as asas de folhas, o bosque inteiro balança. Os losangos das penas brilham, e as folhas que ele solta voltam a brotar."

- **RF-02:** Os `front.png` são de 512×512, com fundo transparente, recortados como na [browt-line](../browt-line/01-browt-line.md#requisitos) (RF-10): o alfa até 16 é ruído, o lado maior fica com 480 px, centralizado, sem suavização. Cada forma é a peça maior da imagem na coluna dela. As peças menores, a partir de 100 pixels, vão para a forma de centro mais perto (as folhas soltas, para o Arbornix), e as menores que isso saem.
- **RF-03:** As folhas `idle.png` (128×160, 4 quadros) e `walk.png` (192×160, 6 quadros) seguem a skill `creature-sprites`, nas alturas do catálogo:
  - **Seedlet:** 6 pixels, de quatro patas, com a crista de folhas e a ponta da cauda em folha, que balançam;
  - **Grovequill:** 15 pixels, de duas pernas, com o pescoço longo, o bico, as garras escuras e a cauda de folhas para trás;
  - **Arbornix:** 26 pixels, em pé sobre as garras, com as asas de folhas abertas, que batem devagar, os chifres dourados e a cauda longa.
- **RF-04:** Nenhum código do jogo muda: a arte é achada pelo slug do catálogo.

## Critérios de aceite

- [x] `GET /v1/species/seedlet`, `/grovequill` e `/arbornix` respondem 200, e `/v1/species/seedlet/evolutions` mostra a linha com os níveis 16 e 36.
- [x] `check_sheets.py` passa nas três pastas.
- [x] Lint, typecheck e testes de unidade do servidor passam.
- [x] `godot --headless -d --path client --quit-after 240` roda sem erro de script.
- [ ] Na escolha do inicial e no F1, o Seedlet aparece com o `front.png` novo; no Bestiário, a linha mostra os três.
- [ ] No spawn de depuração de Explorar, as três formas andam e respiram com as folhas novas.

## Verificação

```bash
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/seedlet/line.webp seedlet grovequill arbornix
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/seedlet/explore
cd server && npm run lint && npm run typecheck && npm test
godot --headless -d --path client --quit-after 240
```

## Tarefas

- [x] Recortar os três `front.png` e apagar as pastas antigas.
- [x] A migração das espécies.
- [x] As folhas `idle` e `walk` das três formas.
- [x] Testes, `CLAUDE.md`, README, índice das specs e a skill `creature-sprites`.
