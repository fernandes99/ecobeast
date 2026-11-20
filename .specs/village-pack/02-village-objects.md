# 02. Os objetos da vila

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [01](01-village-houses.md) (os ids continuam depois das casas)

## Contexto

O dono quer o máximo de objetos do tileset Village ([README](README.md#contexto)). Cada objeto é um tile ou um grupo de tiles colados na folha; os parecidos viram um tipo, e as formas, as variantes.

## Escopo

- O script `client/assets/props/make_village_objects.py` e a arte `assets/props/village_<objeto>/`.
- Os tipos de peça 112 a 128, com o bloqueio e a luz da lanterna, na migração `20270111000001_village_objects`.
- A lanterna no `LUZES.md`, e os créditos em `CREDITOS.md`.

## Requisitos

- **RF-01:** `python -I make_village_objects.py <FDR_Village.png> [--sheet <arquivo.png>]`, de dentro de `client/assets/props`, recorta cada variante de um retângulo da folha, recorta pelos pixels e grava `village_<objeto>/<variante>.png`, sem mudar os pixels. Três variantes colam dois pedaços da folha: a fonte grande com a estátua (a estátua do tile de água, sem a água), a placa de loja com cada ícone (o ícone por cima da placa lisa do braço) e a pilha de lenha (só o pedaço ligado ao pé, sem a parede vizinha). O pé fica no meio da borda de baixo, e a sombra do pacote, quando há, conta como parte do desenho. Com `--sheet`, grava só uma folha de conferência com as variantes numeradas.
- **RF-02:** Os tipos, com as variantes na ordem da coluna:

  | id | slug | Nome | Variantes | Bloqueia |
  | --- | --- | --- | --- | --- |
  | 112 | `village_fountain` | Fonte da vila | 4: grande, grande com estátua, pequena, pequena com estátua | todas, a arte toda |
  | 113 | `village_well` | Poço de pedra | 4: com água, com água baixa, seco, com escada | todas (variante 0) |
  | 114 | `village_tank` | Tanque de tábuas | 2: com água, vazio | todas, a base de 16 px |
  | 115 | `village_trough` | Cocho | 2: vazio, com água | todas |
  | 116 | `village_crate` | Caixote | 7: de tábuas, fechado, aberto, pequeno de tábuas, pequeno aberto, pilha, pilha alta | as pilhas |
  | 117 | `village_bench` | Banco da vila | 5: de frente, de frente liso, duplo, de lado (esquerda), de lado (direita) | o duplo |
  | 118 | `village_table` | Mesa da vila | 4: quadrada, quadrada de tábuas, pequena, de pé central | não |
  | 119 | `village_chair` | Cadeira | 7: de frente, de frente com encosto, de costas, de costas com encosto, de lado (esquerda), de lado (direita), banquinho | não |
  | 120 | `village_signpost` | Placa de direção | 4: as 4 setas do pacote | não |
  | 121 | `village_board` | Placa de madeira | 6: as 4 placas em estaca e as 2 setas pequenas | não |
  | 122 | `village_shop_sign` | Placa de loja | 10: o braço com a placa lisa, com cada um dos 8 ícones e o braço vazio | não |
  | 123 | `village_lantern` | Lanterna pendurada | 2: acesa, apagada | não |
  | 124 | `village_ladder` | Escada de mão | 3: curta, média, longa | não |
  | 125 | `village_firewood` | Lenha | 4: tronco em pé, feixe, pilha grande, tronco deitado | a pilha |
  | 126 | `village_wheat` | Trigo | 3: canteiro de trigo, fileira, feixe | o canteiro |
  | 127 | `village_garden_bed` | Canteiro de terra | 3: comprido, pequeno, pequeno liso | não |
  | 128 | `village_flower` | Flor da vila | 5: broto e as 4 flores | não |

  O braço da placa de loja e da lanterna vem nas duas mãos do pacote; a variante usa a da esquerda (o poste à esquerda), e o espelho da peça dá a outra.
- **RF-03:** O bloqueio padrão é o retângulo fechado da base, de 2 px dentro de cada lado da arte, de 2 px acima do pé até a altura da base: a arte toda (menos 2 px) nas peças vistas de cima (fonte, poço, cocho e canteiro de trigo), 16 px no tanque e 12 a 14 px nas outras. A variante 0 vale quando todas as variantes têm o mesmo retângulo (no poço, o da variante 1, 2 px mais baixo que o da escada); senão, cada variante que bloqueia tem a sua linha. O script imprime as caixas.
- **RF-04:** A lanterna acesa (variante 1) acende à noite, com a luz posta à mão na migração, no meio da chama: (5, −14), raio 18, cor `ffd890`. A apagada não tem luz. O `find_lights.py` não lista a lanterna, porque as duas variantes têm a mesma silhueta e ele daria a luz da acesa à apagada.
- **RF-05:** Os créditos são os da [01](01-village-houses.md#requisitos) (RF-07).

## Critérios de aceite

- [ ] A ferramenta Peças do editor mostra os 17 tipos, com as variantes pelas teclas ← →.
- [ ] O Domador para nos objetos que bloqueiam e anda livre pelos outros, passando atrás deles pela ordem do pé.
- [ ] À noite, a lanterna acesa ilumina.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script, e os testes do servidor passam.
