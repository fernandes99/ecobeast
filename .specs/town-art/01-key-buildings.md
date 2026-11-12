# 01. O gerador da cidade e as construções-chave

- **Status:** rascunho
- **Depende de:** [island-villages](../island-villages/README.md) concluída

## Contexto

Hoje o Refúgio e a Loja de uma ilha são uma Casa grande de outra cor com a ação por cima, e a Arena é um cercado. Nada diz, só de olhar, o que cada uma é. Esta fase cria o gerador da arte da cidade, que segue o [guia de estilo](style-guide.md), e as três construções-chave como objetos novos.

## Escopo

- O gerador `res://assets/map_objects/make_town.gd`, com as peças comuns do guia (contorno, telhado, parede, janela, porta, emblema, sombra).
- Três tipos de objeto novos no catálogo, com a arte: o prédio do Refúgio, o da Loja e o da Arena.
- O formato novo de 5 hexágonos, para a Arena.

## Fora do escopo

- Pôr a ação junto com o objeto: o dono continua pintando a ação nos hexágonos, como hoje.
- A tela da Arena.
- Mudar as ilhas que já existem (a vitrine é a [05](05-showcase-village.md)).

## Requisitos

- **RF-01:** O catálogo ganha os tipos de objeto da tabela abaixo, todos com 1 variante e todos os hexágonos bloqueando por padrão:

  | id | slug | name | Formato `(dq, dr)` |
  | --- | --- | --- | --- |
  | 21 | `refuge_building` | Prédio do Refúgio | triângulo: `(0, 0)`, `(1, 0)`, `(1, -1)` |
  | 22 | `shop_building` | Prédio da Loja | triângulo: `(0, 0)`, `(1, 0)`, `(1, -1)` |
  | 23 | `arena_building` | Prédio da Arena | bloco: `(0, 0)`, `(1, 0)`, `(2, 0)`, `(1, -1)`, `(2, -1)` |

  O bloco tem 3 hexágonos na frente e 2 atrás, entre eles. _Os nomes e os formatos estão a revisar._
- **RF-02:** O gerador `make_town.gd` roda com `godot --headless -s res://assets/map_objects/make_town.gd`, sem argumento e sem pacote de fora, e grava `res://assets/map_objects/<slug>/<variante>.png` de cada tipo que ele desenha. Com o slug como argumento (`-- refuge_building`), grava só aquele tipo.
- **RF-03:** A arte de cada construção segue o guia: as cores das paletas, o contorno de 1 px, a luz de cima à esquerda, a sombra no chão e o emblema da tabela de [As construções-chave](style-guide.md#as-construções-chave).
- **RF-04:** As medidas, em pixels da arte, ficam em volta destas, _a revisar_: o Refúgio com 112×80, a Loja com 112×76 e a Arena com 176×104. O pé de cada uma fica no ponto de apoio do formato, como os outros objetos.
- **RF-05:** A porta de cada construção fica de frente para a linha da frente do formato: a do Refúgio e a da Loja sobre o hexágono `(1, 0)` ou entre `(0, 0)` e `(1, 0)`, e o portão da Arena sobre o `(1, 0)`, o do meio.
- **RF-06:** Os três tipos aparecem na barra de objetos do editor (F2), com a prévia, e podem ser postos, espelhados e ter o bloqueio ajustado como os outros.

## Critérios de aceite

- [ ] O gerador roda sem erro e grava `refuge_building/1.png`, `shop_building/1.png` e `arena_building/1.png`.
- [ ] Numa imagem do mapa (cena temporária), as três construções aparecem lado a lado com uma casa e o Domador, e cada uma se reconhece pela cor e pelo emblema.
- [ ] A porta das três é mais alta que a metade do Domador e cabe na largura dele.
- [ ] Nenhuma cor da arte fica fora das paletas do guia (o gerador só usa as constantes delas).
- [ ] O catálogo (`GET /v1/catalog`) traz os três tipos com os formatos do RF-01.
- [ ] No editor, os três tipos aparecem na barra e podem ser postos (com o dono, no F2).

## Desenho técnico

- **Servidor:** uma migração nova, `server/prisma/migrations/20261115000000_town_key_buildings/migration.sql`, no formato da `20261113000000_map_objects_revision`: os `INSERT` em `map_object_types` e `map_object_type_tiles` e o `setval` da sequência. As ilhas não mudam, e por isso não é preciso recalcular os hashes delas.
- **Specs:** a tabela de tipos do [architecture.md da island-villages](../island-villages/architecture.md#os-tipos-de-objeto) ganha as três linhas e o formato bloco, e a tabela de tamanhos ganha as medidas.
- **Gerador (`make_town.gd`):**
  - `extends SceneTree`, como o `make_objects.gd`. Não usa autoloads, porque no modo `-s` eles não carregam.
  - `TYPES` no mesmo formato do `make_objects.gd`: slug → formato, variantes e, nos animados, quadros.
  - As paletas do guia viram constantes com o mesmo nome da linha do guia (`ROOF_RED`, `ROOF_BLUE`, `PLASTER`, `WOOD`...), cada uma com os 4 tons.
  - As peças comuns são funções: `_roof`, `_wall`, `_window`, `_glass_door`, `_emblem`, `_outline` (1 px por fora, na cor dada), `_shadow` e `_stamp` (desenha um padrão de texto, uma letra por cor, para os símbolos).
  - O `_begin`, o `_put` e o cálculo do ponto de apoio são os do `make_objects.gd`, com o formato bloco acrescentado. Vale copiá-los, porque os dois geradores rodam sozinhos.
  - A amostra aprovada (refúgio, loja e arena) é o ponto de partida do desenho, em tamanho maior.
- **Jogo:** nada muda no código. O editor e o mapa leem os tipos do catálogo, e o `MapObjectSprite` desenha qualquer PNG que siga o formato.

## Verificação

```bash
godot --headless -s res://assets/map_objects/make_town.gd
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
cd server && npx prisma migrate deploy && npm run test:e2e
```

Uma cena temporária em `client/zz_tmp_check/`, apagada depois, com as três construções, uma casa de hoje e o Domador num pedaço de ilha, salva numa imagem e conferida pelos 4 passos de [Conferir uma arte nova](style-guide.md#conferir-uma-arte-nova).

## Tarefas

- [ ] A migração dos três tipos e a tabela do `architecture.md` da island-villages.
- [ ] O `make_town.gd` com as paletas e as peças comuns.
- [ ] A arte do Refúgio, da Loja e da Arena.
- [ ] Conferir numa imagem e no editor, e atualizar o `client/CLAUDE.md`.
