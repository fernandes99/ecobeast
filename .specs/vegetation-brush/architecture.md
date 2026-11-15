# vegetation-brush: desenho compartilhado

## Os objetos que ficam

| id | slug | Nome |
| --- | --- | --- |
| 21 | `refuge_building` | Prédio do Refúgio |
| 22 | `shop_building` | Prédio da Loja |
| 24 | `town_house` | Casa (cidade) |
| 25 | `town_house_medium` | Casa média (cidade) |
| 26 | `town_house_large` | Casa grande (cidade) |
| 29 | `town_fence` | Cerca (cidade) |

Os ids não mudam, porque as ilhas guardam o id. O resto de `map_object_types` sai por uma migration, junto com os hexágonos de cada tipo (`map_object_type_tiles`) e com os objetos desses tipos nas ilhas (`island_objects`, que leva os `island_object_tiles` junto).

Sai também tudo que só servia a eles:

- a arte de cada um em `client/assets/map_objects/<slug>/`;
- o gerador `make_objects.gd`, que só fazia os objetos antigos, e a parte do `make_town.gd` que fazia os apagados;
- o objeto Vegetação (`plants`), que punha decorações num hexágono, e o código dele em `HexDecorations` e `HexMapView`;
- as animações do Moinho, da Árvore e do Santuário de runas no `MapObjectSprite`;
- a cerca antiga (`fence`) no `HexFences`, que fica só com a da cidade.

## O hash das ilhas

O `content_hash` de cada versão foi feito com os objetos de antes, e a migration não o refaz. Enquanto ninguém salva, o rascunho e a publicada continuam com o mesmo hash, e a ilha continua "publicada". Depois de salvar o rascunho, a ilha passa a mostrar mudanças a publicar, e publicar de novo acerta o hash.

## Os grupos

O pincel usa os tipos de `prop_types` pelo slug. A tabela mora no cliente (`VegetationPanel.GROUPS`), porque só o editor a usa:

| Grupo | Tipos | Peças por hexágono na Média |
| --- | --- | --- |
| Árvores | `tree`, `pine` | 1 |
| Arbustos | `bush`, `dark_bush`, `dry_shrub`, `fern` | 2 |
| Gramas | `tuft`, `dry_tuft`, `moss` | 4 |
| Flores | `flowers` | 3 |
| Pedras pequenas | `pebbles` | 2 |
| Pedras médias | `rock`, `mossy_rock`, `brown_rock` | 1 |
| Pedras grandes | `boulder`, `rock_pile`, `spire` | 1 |

Os 6 grupos "(pacote)", com a arte da craftpix.net, vêm depois destes ([vegetation-packs](../vegetation-packs/architecture.md#os-grupos-do-pincel)).

A densidade multiplica o número da tabela: Pouca × 0,5, Média × 1 e Muita × 2. Uma parte quebrada vira uma chance: 0,5 peça é uma peça em metade dos hexágonos.

## Onde o pincel põe uma peça

Em cada hexágono do pincel, uma vez por pincelada, o pincel tenta pôr o número de peças da densidade. Cada peça:

- tem um tipo sorteado entre os marcados do grupo, uma variante sorteada e o espelho sorteado;
- procura um ponto com o mesmo sorteio e a mesma regra das decorações naturais (`HexDecorations`):
  - até 8 tentativas;
  - o ponto fica dentro do hexágono e longe do centro pelo raio do tipo;
  - o ponto fica longe das outras peças pelo maior dos dois raios.

  Se nenhuma tentativa der certo, a peça não nasce;
- conta como ocupados os pontos das peças soltas que já estão no hexágono e das decorações naturais dele (quando o hexágono não tem a marca `bare`);
- só nasce onde o chão embaixo do pé deixa aquele tipo (`HexGrounds.allows_on`): numa trilha, só os pequenos; num piso, nenhum.

O pincel não põe peça:

- em hexágono com objeto;
- fora da ilha;
- em hexágono que o corte de altura esconde.

O sorteio usa o gerador da pincelada, e não uma seed fixa: pintar duas vezes no mesmo lugar dá pontos diferentes.

## Os limites

| O quê | Antes | Agora |
| --- | --- | --- |
| Peças por ilha (`MAX_PROPS`, servidor) | 6.000 | 20.000 |

O editor para de pôr peças ao chegar no limite e avisa uma vez por pincelada, como o Pôr hexágono faz com os hexágonos.
