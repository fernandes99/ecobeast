# 02. As casas no estilo novo

- **Status:** rascunho
- **Depende de:** [01-key-buildings](01-key-buildings.md)

## Contexto

As casas de hoje (Casa, Casa média e Casa grande) vêm do pacote Sunnyside, de traço terroso, e ficam diferentes das construções-chave da [01](01-key-buildings.md). Esta fase as redesenha no `make_town.gd`, com os mesmos ids e variantes, para as ilhas que já existem mudarem sozinhas.

## Escopo

- A arte nova de `house` (id 1), `house_medium` (18) e `house_large` (19), com o mesmo formato e o mesmo número de variantes de hoje.
- Esses três tipos saem do `make_objects.gd`.

## Fora do escopo

- Mudar o formato, o bloqueio ou o número de variantes no catálogo.
- O moinho e os outros objetos da vila (a [03](03-village-objects.md)).

## Requisitos

- **RF-01:** Cada tipo tem modelos (o desenho da casa) combinados com telhados (a cor). Os telhados são só os das casas no guia: laranja, marrom, verde, roxo, turquesa e mostarda. Nunca vermelho, azul nem ardósia. _A revisar:_

  | Tipo | Formato | Variantes | Modelos | Telhados, na ordem das variantes |
  | --- | --- | --- | --- | --- |
  | `house` | um | 9 | chalé, casa com chaminé, casa com varanda | laranja, verde, roxo |
  | `house_medium` | par | 11 | casa comprida, sobrado, casa com oficina | laranja, marrom, verde, turquesa |
  | `house_large` | triângulo | 10 | casarão com torre, sobrado de dois andares | laranja, marrom, mostarda, roxo, turquesa |

  A variante `v` de um tipo é o modelo `(v - 1) % modelos` com o telhado `(v - 1) / modelos` da lista, contando de 0. Na Casa média, a última cor só tem os 2 primeiros modelos (3 × 4 = 12, e o tipo tem 11). O `architecture.md` da island-villages descreve as variantes.
- **RF-02:** As casas seguem o guia e ficam menos chamativas que as construções-chave: sem emblema, sem faixa colorida na parede, e com detalhes de casa (chaminé, varanda, vasos de flor, cortina).
- **RF-03:** A largura cabe no formato, como diz o guia, e a altura da Casa (1 hexágono) não passa de 80 px.
- **RF-04:** O `make_objects.gd` não desenha mais `house`, `house_medium` nem `house_large`, para não apagar a arte nova se for rodado de novo.

## Critérios de aceite

- [ ] O gerador grava as 9, 11 e 10 variantes.
- [ ] Numa imagem com todas as variantes lado a lado, nenhuma tem telhado vermelho, azul ou ardósia, e nenhuma tem emblema.
- [ ] Numa imagem do mapa com uma casa de cada tipo ao lado do Refúgio e da Loja, o Refúgio e a Loja se destacam.
- [ ] Rodar o `make_objects.gd` depois não muda os PNGs das casas.
- [ ] Uma ilha que já tinha casas aparece com a arte nova, sem erro (com o dono, no F2).

## Desenho técnico

- `make_town.gd`: os três tipos no `TYPES`, as funções de desenho de cada modelo e a tabela de variantes.
- `make_objects.gd`: os três tipos e as funções `_draw_house`, `_draw_house_medium` e `_draw_house_large` saem, com as tabelas `HOUSES`, `MEDIUM_HOUSES` e `LARGE_HOUSES`.
- `.specs/island-villages/architecture.md`: a tabela de tipos descreve as variantes novas e diz que a arte vem do `make_town.gd`.

## Verificação

```bash
godot --headless -s res://assets/map_objects/make_town.gd -- house house_medium house_large
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
```

Uma cena temporária com todas as variantes e outra com uma casa de cada tipo ao lado do Refúgio, da Loja e do Domador, conferidas pelo guia.

## Tarefas

- [ ] Os modelos da Casa, da Casa média e da Casa grande.
- [ ] A tabela de variantes e a geração.
- [ ] Tirar as casas do `make_objects.gd`.
- [ ] Conferir nas imagens e atualizar o `architecture.md` da island-villages e o `client/CLAUDE.md`.
