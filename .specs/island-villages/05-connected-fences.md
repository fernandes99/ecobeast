# 05. Cerca que se liga sozinha

- **Status:** concluída
- **Depende de:** [04-plants-and-animations](04-plants-and-animations.md)

## Contexto

Hoje a Cerca (id 8) é uma peça reta no meio do hexágono, e uma fileira delas não fecha um cercado nas diagonais. O dono pediu, em 2026-11-12, uma cerca com os lados: ela se liga às vizinhas como a trilha, de madeira e de pedra, e substitui a de hoje.

## Escopo

- A Cerca desenhada pelos lados ligados, nas duas variantes (madeira e pedra).
- A folha de peças de cada variante, gerada pelo `make_objects.gd`.

## Fora do escopo

- Servidor e banco: o tipo, as variantes e o bloqueio já existem, e a ligação é só desenho.
- Ligar a cerca a um vizinho de outra altura (o braço subindo o degrau).
- Portão.

## Decisões

| Decisão | De quem | Motivo |
| --- | --- | --- |
| A cerca nova substitui a de hoje, com o mesmo tipo e as mesmas variantes | Dono | As cercas já postas nas ilhas passam a se ligar |
| Liga sozinha, como a trilha | Dono | Pintar uma fileira fecha o cercado |
| Bloqueia por padrão | Dono | Como a de hoje |
| Sem vizinho ligado, é a peça reta de hoje, da esquerda para a direita | Planejamento | As cercas sozinhas das ilhas não viram postes soltos |
| Madeira e pedra se ligam, cada metade no material do próprio hexágono | Planejamento | O cercado fecha com os dois materiais |
| Liga só com vizinho na mesma altura | Planejamento | O braço que sobe o degrau é bem mais trabalho; o bloqueio é por hexágono e o cercado prende do mesmo jeito |
| O espelho não muda a cerca | Planejamento | Ela é simétrica pelos lados ligados |

## Requisitos

- **RF-01:** Um lado de um hexágono com Cerca está ligado quando o vizinho daquele lado também tem uma Cerca, de qualquer variante, na mesma altura.
- **RF-02:** A cerca de um hexágono é um poste no centro e um braço do centro até o meio de cada lado ligado. Sem lado ligado, ela tem os braços da esquerda e da direita.
- **RF-03:** A arte é uma folha por variante, `res://assets/map_objects/fence/parts_<variante>.png`, com 7 células de 96×72 lado a lado: o poste do centro e os braços dos lados 0 a 5, na ordem de `HexGrounds.EDGE_NEIGHBORS` (cima à direita, direita, baixo à direita, baixo à esquerda, esquerda, cima à esquerda). Em cada célula, o centro do hexágono fica em (48, 43), e o pé da célula é 29 px abaixo dele, como nos outros objetos.
- **RF-04:** O jogo monta a cerca de cada hexágono juntando as células: os braços de trás, os dos lados, os da frente e o poste por último. Cada combinação de variante e lados é montada uma vez e reaproveitada.
- **RF-05:** O `fence/<variante>.png` continua como prévia do editor, com a peça reta, montada com as mesmas células.
- **RF-06:** No editor, pôr, tirar, trocar a variante de uma cerca ou mudar a altura de um hexágono redesenha as cercas vizinhas na hora.
- **RF-07:** O toque na arte da cerca vale como nos outros objetos, pelos pixels da arte montada.

## Critérios de aceite

- [x] Uma fileira de cercas, reta e em diagonal, aparece emendada, e um anel de 6 cercas em volta de um hexágono fecha o cercado.
- [x] Uma cerca sozinha aparece como a peça reta de hoje.
- [x] Madeira e pedra lado a lado se emendam no meio do lado.
- [x] Com o vizinho numa altura diferente, o braço daquele lado não sai.
- [ ] No editor, pôr e tirar uma cerca redesenha as vizinhas (com o dono, no F2).

## Verificação

```bash
godot --headless -s res://assets/map_objects/make_objects.gd -- <pasta do pacote>
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
```

Mais uma cena temporária, apagada depois, com cercas em fileira, em diagonal, em anel, de materiais misturados e num degrau, salva numa imagem.

Feita em 2026-11-12:
- **Arte:** as folhas `parts_1.png` e `parts_2.png` saíram com 672×72 (7 células de 96×72), e as prévias `1.png` e `2.png` foram montadas com elas.
- **Mapa:** numa cena temporária, já apagada, uma fileira de madeira e pedra emendou no meio do lado, um anel de 6 cercas (3 de madeira e 3 de pedra) em volta de um hexágono fechou o cercado, a cerca sozinha saiu reta, e duas cercas vizinhas, uma numa altura acima, ficaram retas e soltas.
- **Projeto:** abre sem erro de script; com `-d`, os avisos são os de antes.
- **Editor:** pôr, tirar e trocar a variante passam pelo `set_objects`, que monta todas as cercas de novo; mudar a altura passa pelo `update_tiles`, que refaz a arte de cada cerca. Falta o dono conferir no F2.

## Tarefas

- [x] Gerar as folhas de peças no `make_objects.gd`.
- [x] `HexFences`: os lados ligados e a arte montada.
- [x] `MapObjectSprite` e `HexMapView` com a cerca ligada, e o redesenho ao mudar a altura.
- [x] Conferir numa imagem e atualizar o README, o `architecture.md` e o `client/CLAUDE.md`.
