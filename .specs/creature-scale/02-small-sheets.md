# 02. As folhas dos pequenos

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-scale-rule](01-scale-rule.md)

## Contexto

Os pequenos são os que mais mudam: a Nilu passa de 4 para 8 pixels, e o Ruvo de 7 para 11. São eles que o dono comparou com o pintinho do pacote. A prévia aprovada (`art-source/creature-scale/preview.png`) tem a Nilu, o Seedlet e o Ruvo de frente, desenhados à mão em 8, 10 e 11 pixels. As grades deles estão em `art-source/creature-scale/front_drafts.py`, com as paletas.

## Escopo

As folhas `idle.png` e `walk.png` de Explorar destes seis, desenhadas de novo pelo `sprites.py` de cada um, com a skill `creature-sprites`:

| Ecobeast | Pasta | Altura | Hoje |
| --- | --- | --- | --- |
| Nilu | `client/assets/creatures/nilu/explore/` | 8 | 4 |
| Puffcoo | `client/assets/creatures/puffcoo/explore/` | 8 | 4 |
| Hushling | `client/assets/creatures/hushling/explore/` | 8 | 4 |
| Seedlet | `client/assets/creatures/seedlet/explore/` | 10 | 6 |
| Tidebud | `client/assets/creatures/tidebud/explore/` | 10 | 6 |
| Ruvo | `client/assets/creatures/ruvo/explore/` | 11 | 7 |

## Fora do escopo

- As folhas dos médios e dos grandes: as fases [03](03-medium-sheets.md) e [04](04-large-sheets.md).
- As folhas da luta (`battle/`).

## Requisitos

- **RF-01:** Cada folha tem a altura da regra nova, conferida pelo `check_sheets.py` da fase [01](01-scale-rule.md), no formato de hoje: 5 vistas, 4 quadros de idle e 6 de walk, na célula de 32×32, com os pés na última linha.
- **RF-02:** Cada folha segue o acabamento novo da skill: contorno tingido, até 3 tons por material e até 16 cores, de preferência.
- **RF-03:** As vistas de frente da Nilu, do Seedlet e do Ruvo partem das grades da prévia. Ajustá-las para as outras vistas e para a animação é permitido.
- **RF-04:** Cada criatura mantém o que a torna reconhecível no `front.png`:
  - na Nilu, a concha azul com a ponta clara, o rosto claro e as pinças;
  - no Puffcoo, a bolinha cinza, a barriga clara, o bico laranja e as asinhas que batem;
  - no Hushling, o corpo branco comprido, as orelhas rosadas, os cristais do pelo e a ponta azul da cauda;
  - no Seedlet, a crista e a cauda de folhas;
  - no Tidebud, flutuar em pé, com a cauda enrolada no chão;
  - no Ruvo, as orelhas, o focinho claro e a chama da cauda.

## Critérios de aceite

- [x] O `check_sheets.py` passa nas 6 pastas, com o servidor no ar.
- [x] Os GIFs de prévia (`idle.gif` e `walk.gif`, gerados pelo `sprites.py`) mostram as 5 vistas animadas, sem parte solta e sem o quarto quadro do idle repetindo o primeiro.
- [ ] No jogo (F5), o spawn do menu Debug de Explorar mostra os 6 ao lado do Domador, no tamanho da tabela.
- [ ] Em Liora, o Puffcoo do campo (NPC 6) aparece com 8 pixels.

## Desenho técnico

- `client/assets/creatures/<slug>/explore/sprites.py`: redesenhado. O `rig` e o resto do `spritekit` não mudam. Os números de movimento (`idle_head`, `walk_head`, `foot_reach` e os outros) mudam com o tamanho, pelas regras da skill.
- `client/assets/creatures/<slug>/explore/idle.png` e `walk.png`: gerados pelo `sprites.py`, com os `.import` refeitos por `godot --headless --path client --import`.
- Os 6 usam o contorno automático (`build(..., outline=...)`, da fase [01](01-scale-rule.md#o-que-entrou-a-mais-na-implementação)): o desenho tem a altura menos 2, e o contorno fecha a silhueta.
- Nenhum script do jogo muda.

## Verificação

```bash
cd server && npm run start:dev
python -I client/assets/creatures/nilu/explore/sprites.py <pasta das prévias>
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/nilu/explore
godot --headless --path client --import
```

Os dois comandos de Python rodam para cada um dos 6, e o Godot importa uma vez no fim. Depois, F5 no editor, Explorar e o spawn do menu Debug. O dono confere no jogo.

## Tarefas

- [x] Nilu.
- [x] Puffcoo.
- [x] Hushling.
- [x] Seedlet.
- [x] Tidebud.
- [x] Ruvo.
- [x] Importar no Godot (falta o dono conferir no spawn) e marcar a fase como concluída aqui, na [README](README.md), no `.specs/README.md` e no `.specs/roadmap.md`.
