# beach-life

A Praia ganha coqueiros, como decorações naturais, como uma zona do bioma (o Coqueiral) e como peças soltas do F2.

## Contexto

Em 2026-11-20, o dono pediu: "agora vamos criar mais objetos para a praia, vamos criar coqueiros (que vai entrar como zona também), e também vamos criar algas mortas (que também entram como zonas). Também tente criar outros objetos a mais que serão gerais, talvez mais conchas e tudo mais..."

Como é hoje:

- **A Praia** (bioma 10) só tem a Comum (`biome_zones` 10, `share` 100), com a receita `beach` em `HexDecorations.RECIPES`: `driftwood`, `beach_rock`, `dune_grass`, `shells` e `starfish` (linhas 47 a 50 da folha, do `make_beach.py`).
- **A [sea-life](../sea-life/)** veio logo antes: ela usa as linhas 51 a 63 da folha, as zonas 25 a 30, a categoria de peça 14 e os tipos de peça 139 a 151. Esta iniciativa começa nos números seguintes.

O dono pediu para seguir com tudo e revisar depois: "Pode seguir faça tudo depois eu reviso". Na revisão, antes do commit, ele tirou o resto:

- os 9 objetos gerais (cocos caídos, búzio, vieiras, ouriço, bolacha-do-mar, seixos, toca na areia, rasteira da praia e monte de conchas): "Remova todos os gerais, ficaram muito ruins";
- a Alga morta, a Faixa de algas e a zona Algas mortas: "As algas mortas pode remover", e, perguntado, escolheu tirar "Tudo de alga";
- e pediu o Coqueiro novo maior: "o coqueiro pequeno quero deixar ele um pouco maior tá muito pequeno do jeito que está".

Os ids que já tinham entrado no banco de desenvolvimento (as peças 154 a 164 e a zona 32) ficam sem uso.

## Objetivos

1. 2 tipos novos de decoração da Praia, desenhados por código pelo `client/assets/terrain/make_beach_life.py`, no traço do `make_nature.py`.
2. A zona **Coqueiral** na Praia.
3. O coqueiro novo também na Comum da Praia, raro.
4. Os 2 tipos como peças soltas no F2 e num grupo "Praia" do pincel Vegetação.

## Os tipos (linhas 64 e 65 da folha, peças 152 e 153)

| Linha | Peça | Slug | Nome | Como é |
| --- | --- | --- | --- | --- |
| 64 | 152 | `coconut_palm` | Coqueiro | Tronco curvo e anelado, copa de folhas compridas caídas, cocos embaixo da copa; quase a célula inteira de altura |
| 65 | 153 | `young_palm` | Coqueiro novo | Um coqueiro de tronco curto (13 a 17 px), mais ou menos da altura do Domador |

## As zonas (_a revisar_)

| Id | Slug | Nome | `share` | `sort_order` |
| --- | --- | --- | --- | --- |
| 10 | `beach` | Comum | 100 → 75 | 1 → 2 |
| 31 | `beach_palms` | Coqueiral | 25 | 1 |

Receitas, da maior decoração para a menor (o tipo novo no fim da `beach`, para não mudar o sorteio de antes):

| Receita | Tipos (chance, mínimo–máximo) |
| --- | --- |
| `beach` | as de hoje, mais young_palm 0.03 1–1 |
| `beach_palms` | coconut_palm 0.85 1–2, young_palm 0.4 1–1, dune_grass 0.3 1–1, shells 0.15 1–1 |

## Decisões

| Decisão | Motivo |
| --- | --- |
| O Coqueiral como zona | O pedido |
| Sem objetos gerais, sem algas mortas e sem a zona delas | O dono os tirou na revisão |
| O coqueiro como decoração (célula de 48×64), não como peça de pacote | Só decoração entra numa receita de zona; o `palm_tree` do pacote continua como peça |
| Os números depois da sea-life (linhas 64+, zona 31, peças 152+, migrations `20270120…`) | A sea-life foi feita logo antes, na mesma pasta |
| Nenhuma exceção de nascimento no Coqueiral | Ninguém nasce só na Praia hoje; a revisar quando houver |
| As peças na categoria 8 `beach` "Praia", que já existe | A categoria já guarda as conchas, a estrela-do-mar e o tronco à deriva |

## Fora do escopo

- Quem nasce no Coqueiral (nenhuma exceção em `species_biome_zones`).
- Os coqueiros bloquearem o andar.
- Arte nova da areia.
- Algas mortas, conchas, búzios, ouriços e outros objetos gerais da areia.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-beach-art](01-beach-art.md) | O `make_beach_life.py`, a prévia e os tipos em `HexDecorations` | concluída (falta o dono conferir) |
| 2 | [02-beach-zones](02-beach-zones.md) | A migration `beach_zones`, as receitas e o teste de `assignZones` | concluída (falta o dono conferir no jogo) |
| 3 | [03-beach-props](03-beach-props.md) | A migration `beach_props` (os 2 tipos na categoria Praia) e o grupo "Praia" do pincel | concluída (falta o dono conferir no F2) |
