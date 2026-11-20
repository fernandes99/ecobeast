# 01. A regra nova de altura

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** nada

## Contexto

A altura de um Ecobeast no mapa vem do `height_in_pixels` de `.claude/skills/creature-sprites/scripts/spritekit.py`, que hoje é `round(height_m × 25 / 1,70)`. A conferência (`check_sheets.py`) compara essa conta com a folha, mas lê as alturas do `server/prisma/seed-data/species.json`. Essa carga inicial é uma foto antiga: o Seedlet, o Grovequill, o Arbornix e os ids de 10 em diante não estão nela, e as folhas deles saem como "fora do catálogo, sem conferir".

A [README](README.md) traz a regra nova, de hoje mais 4 pixels, entre 6 e 32, e o acabamento pedido, o dos animais do pacote Fantasy Dreamland Reborn.

## Escopo

- A regra nova no `spritekit.py`.
- O `check_sheets.py` lendo as alturas do catálogo do servidor.
- As regras de desenho da skill `creature-sprites` com o acabamento do pacote.
- Os documentos que citam a escala antiga.

## Fora do escopo

- Redesenhar as folhas: são as fases [02](02-small-sheets.md), [03](03-medium-sheets.md) e [04](04-large-sheets.md). Até a 04, as folhas de hoje falham na conferência de altura, e isso é esperado.

## Requisitos

- **RF-01:** `height_in_pixels(height_m)` devolve `round(height_m × 25 / 1,70 + 4)`, preso entre `MIN_PX = 6` e `MAX_PX = 32`. A soma fica numa constante, `EXTRA_PX = 4`.
- **RF-02:** O `check_sheets.py` lê a altura da espécie no `GET /v1/catalog` (tabela `species`, coluna `height_m`) do servidor em `http://localhost:3100`, ou no endereço da variável de ambiente `ECOBEAST_API_URL`. Com o servidor fora do ar, ele para com a mensagem "o servidor precisa estar no ar para ler as alturas do catálogo" e sai com código 1.
- **RF-03:** Uma pasta cujo slug não está no catálogo continua passando sem conferir a altura, como hoje.
- **RF-04:** A conferência continua aceitando 1 pixel de diferença na altura e barrando folhas com mais de 32 cores.
- **RF-05:** A skill `creature-sprites` (`SKILL.md`) traz:
  - a regra nova;
  - a tabela de alturas da [README](README.md);
  - a largura máxima de 32 pixels: a criatura larga fica mais compacta, nunca cortada;
  - a nota de que, a partir de uns 1,90 m, tudo tem 32 pixels;
  - o acabamento novo, que vale para todos os tamanhos (RF-06).
- **RF-06:** O acabamento novo, no lugar das seções "Até uns 12 pixels de altura" e "Acima disso":
  - contorno de 1 pixel em toda a silhueta, escuro e puxado para a cor de cada parte, nunca preto puro;
  - cada material com até 3 tons (luz, base e sombra), a luz vindo de cima;
  - até 16 cores por folha, de preferência;
  - até uns 14 pixels, cada olho é 1 pixel escuro (2 de altura nos maiores desse grupo), e acima disso entra o brilho;
  - o pacote é só a referência de tamanho e acabamento: nenhum pixel dele entra numa folha, como a skill já exige;
  - a regra antiga de "abaixo de 7 pixels a cabeça nem desce" passa a valer abaixo de 10 pixels.
- **RF-07:** Os textos que citam a escala antiga passam a citar a regra nova e esta iniciativa:
  - `client/CLAUDE.md` (o trecho das folhas animadas dos Ecobeasts);
  - `.specs/wild-battle/architecture.md` (a seção "Escala"), com uma nota de que a regra mudou nesta iniciativa;
  - `.specs/island-npcs/architecture.md` (a coluna `sprite`);
  - a docstring do `spritekit.py`.

## Critérios de aceite

- [x] `height_in_pixels` devolve 6 para 0,1 m, 8 para 0,3 m, 10 para 0,4 m, 11 para 0,5 m, 19 para 1,0 m, 28 para 1,6 m e 32 para 2,0 m e 2,5 m.
- [x] Com o servidor no ar, `python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/seedlet/explore` mostra "altura pedida pelo catálogo: 10 pixels" e falha na altura, porque a folha de hoje tem 6.
- [x] Com o servidor fora do ar, o mesmo comando para com a mensagem do RF-02 e sai com código 1.
- [x] A `SKILL.md` não fala mais em `height_m × 25 / 1,70` sem o `+ 4`, nem em tirar o contorno das criaturas pequenas.

## Desenho técnico

- `.claude/skills/creature-sprites/scripts/spritekit.py`: `MIN_PX`, `MAX_PX`, `EXTRA_PX` e o `height_in_pixels` novo. `TAMER_HEIGHT_M` e `TAMER_HEIGHT_PX` ficam, porque a regra continua partindo da escala do Domador.
- `.claude/skills/creature-sprites/scripts/check_sheets.py`: troca o `SEED` por uma leitura do catálogo com `urllib.request`, da biblioteca padrão, porque a skill não usa pacotes de fora. O resto do script não muda.
- `.claude/skills/creature-sprites/SKILL.md`: a linha "Altura" da seção "Formato", as seções de desenho e o passo 2 ("Calcule a altura"). Na seção "O que deu errado no Ruvo", o item "Fora de escala" passa a dizer "calcule pela regra".
- Os textos do RF-07.

### O que entrou a mais na implementação

- `outlined` e o parâmetro `outline` do `build`, no `spritekit.py`: o contorno de 1 pixel por fora da silhueta, com a cor escura escolhida por parte (`{"*": "o", "F": "q"}`), lendo os 4 vizinhos. Com ele, o desenho fica entre as linhas e colunas 1 e 30, e a folha fica 2 pixels mais alta que o desenho. Entrou porque desenhar a borda à mão em cada quadro dos pequenos multiplicava o trabalho e errava fácil. Sem o parâmetro, a folha sai como antes.
- `stretched(desenho, rows, cols)`, no `spritekit.py`: repete as linhas e as colunas escolhidas de uma parte. As fases 03 e 04 usam para crescer os médios e os grandes, que já tinham contorno e sombreado no acabamento pedido, sem ampliar os pixels nem trocar o desenho aprovado.

## Verificação

```bash
cd server && npm run start:dev
python -I -c "import sys; sys.path.insert(0, '.claude/skills/creature-sprites/scripts'); from spritekit import height_in_pixels as h; print([h(m) for m in (0.1, 0.3, 0.4, 0.5, 1.0, 1.6, 2.0, 2.5)])"
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/seedlet/explore
```

A primeira linha do Python deve mostrar `[6, 8, 10, 11, 19, 28, 32, 32]`.

## Tarefas

- [x] `spritekit.py`: a regra nova.
- [x] `check_sheets.py`: as alturas do catálogo do servidor.
- [x] `SKILL.md`: a regra, a tabela, a largura e o acabamento novo.
- [x] Os textos do RF-07.
- [x] Rodar a verificação e marcar a fase como concluída aqui, na [README](README.md), no `.specs/README.md` e no `.specs/roadmap.md`.
