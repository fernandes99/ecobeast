# free-fences: arquitetura

## As paredes de uma ilha

Uma **parede** é uma linha de pontos com um tipo. A cerca de madeira e o muro de pedra são paredes com arte; a parede invisível só bloqueia. Todas bloqueiam do mesmo jeito.

| Camada | Onde fica | Preso a | Bloqueia |
| --- | --- | --- | --- |
| Objetos (casas, Refúgio, Loja) | `island_objects` (de hoje) | hexágonos | o hexágono inteiro, pelo `blocks` |
| **Paredes** | `island_walls` (fase 1) | pontos em pixels do chão plano | a linha, a menos de `WALL_REACH` |

## O catálogo: `wall_types` (fase 1)

| id | slug | name | visible |
| --- | --- | --- | --- |
| 1 | `wood_fence` | Cerca de madeira | true |
| 2 | `stone_fence` | Muro de pedra | true |
| 3 | `invisible_wall` | Parede invisível | false |

- Os ids são estáveis. O `seed-data` ganha `wall_types.json`, e o catálogo (`GET /v1/catalog`) manda a tabela.
- **A arte** de um tipo visível é `client/assets/walls/<slug>.png`, com 2 células de 96×72 e o pé em (48, 43), gerada pelo `make_town.gd` com o desenho da Cerca (cidade):
  - a célula 0 é o poste (madeira) ou o pilar (pedra);
  - a célula 1 é a travessa reta, de ponta a ponta, sem poste. As fatias usam as colunas 0 a 27 dela (`HexWalls.RAIL_SPAN`), que se repetem: o muro de pedra tem uma emenda a cada 7 px, e 28 fecha as duas cercas (revisto na fase 1; antes, as colunas 50 a 73 do braço da direita, que quebravam a emenda).
  - A fase 4 apaga as folhas antigas da Cerca (cidade).

## As paredes no banco: `island_walls` (fase 1)

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `island_map_id` | int | FK `island_maps`, `ON DELETE CASCADE` |
| `wall_type_id` | int | FK `wall_types` |
| `position` | int | a ordem na ilha, de 0 em diante, única por mapa |
| `points` | `integer[]` | `x0, y0, x1, y1, …`, em pixels inteiros da arte, no chão plano, a partir do centro plano do hexágono (0, 0), como `island_trails.points`; `CHECK` de tamanho par, entre 4 e 256 |

**Contrato** (editor e Explorar numa ilha), na ordem de `position`:

```json
"walls": [{ "type": "wood_fence", "points": [12, -40, 30, -8, 31, 40] }]
```

- O `type` é o `slug`.
- **O servidor confere:**
  - o tipo existe;
  - a parede tem de 2 a 128 pontos;
  - todo ponto cai num hexágono da ilha;
  - a ilha tem no máximo 2.000 paredes (`MAX_WALLS`).
- O `content_hash` leva as paredes, na ordem. Uma ilha sem paredes tem o hash de antes.
- O servidor só guarda, confere e devolve. Ele não usa as paredes em nenhuma regra.

**No cliente:**
- `MapWall` (`domain/models/`), com `type` e `points` (`PackedVector2Array` no chão plano, somando o `MapTrail.ORIGIN`, como o `MapTrail`), e `ExplorationMap.walls`.
- O `ExplorationMap` guarda também um índice: os trechos de parede que tocam cada hexágono, montado ao ler e ao mudar as paredes. Toda pergunta de bloqueio passa por ele.

## O desenho (fase 1)

Um `HexWalls` (`ui/components/`) monta os pedaços de cada parede visível, no chão plano:

- **As fatias:** em cada trecho, um passo de 1 px no eixo em que ele mais anda.
  - Cada passo é uma fatia de 1 px de largura com a coluna da faixa da travessa: a coluna `(distância percorrida) mod 24`.
  - O pé da fatia fica no ponto da linha.
- **Os postes:**
  - um em cada ponto clicado;
  - e, entre dois pontos, mais postes a espaços iguais, de cerca de 20 px (`POST_GAP`);
  - num trecho que anda mais na vertical que na horizontal da tela, a cerca de 10 px, para ele não virar um fio. A fase 1 confere numa imagem e ajusta.
- **A altura:** cada pedaço sobe a altura do hexágono embaixo do pé dele. Um trecho que cruza um degrau se parte ali, cada lado na sua altura.
- **A profundidade:** cada pedaço entra numa faixa de decoração, como uma peça solta ([free-props](../free-props/architecture.md)). Assim, o Domador fica na frente ou atrás pela posição. Dentro da faixa, o poste vai por cima das fatias do mesmo ponto.
  - **A linha:** a do hexágono mais à frente que a base do pedaço toca (5 px para cada lado do poste e 3 px abaixo do pé, `HexWalls.POST_HALF_WIDTH` e `ART_BELOW`). Na linha do pé, o chão da linha seguinte cortava a base dos postes perto da divisa (revisto na fase 1).
  - **A altura:** sempre a do hexágono do pé.
- **As malhas:** as fatias e os postes vão nas malhas das faixas, uma por textura, junto com as peças. No `HexMapView`, as paredes são guardadas por pedaço (`_walls_by_chunk`), como as peças. O `set_walls(walls, changed)` remonta os pedaços que as paredes mudadas tocavam e tocam.
- **No editor:**
  - a parede invisível é uma linha tracejada por cima do mapa (`EditorCanvas`), sempre à mostra;
  - as visíveis aparecem como no jogo;
  - a visão de cima (`IslandOverview`) mostra todas como linhas finas.
- **No mapa sorteado** não há paredes.

O teste descartável de 2026-11-14 montou isso numa imagem só, com as artes de hoje. O script ficou no histórico da conversa, não no repositório.

## O bloqueio (fase 2)

O pé do Domador não chega a menos de `WALL_REACH` (3 px da arte, no chão plano) de uma parede.

- **A rota é refeita.** Hoje, o `WalkRoute.points` liga o ponto do Domador aos centros dos hexágonos do meio do caminho (sem o do próprio hexágono nem o do último) e ao ponto tocado, e aceita o próximo ponto sem conferir quando nenhuma reta está livre. Com paredes, cada trecho da rota precisa ser livre: a rota passa pelos centros que a busca usou (incluindo os das pontas, quando preciso), e o esticar só pula para um ponto à frente quando a reta até ele é livre.
- **`ExplorationMap.crosses_wall(from, to) -> bool`:** se o segmento de `from` a `to` passa a menos de `WALL_REACH` de algum trecho de parede. Ele procura pelo índice dos hexágonos que o segmento toca. Quem já está a menos de `WALL_REACH` de um trecho, sem cruzá-lo, pode se afastar dele (revisto na fase 2: o fim de uma rota cortada, ou a chegada da ilha rente a uma cerca, prendia o Domador). A busca só pergunta quando um dos dois hexágonos tem trecho no índice.
- **Andar em reta:** o `WalkRoute.is_clear` também recusa o segmento que cruza parede.
- **A busca de caminho:** o `path_to_any` (e quem o usa: o toque, o NPC que passeia, o toque num bloqueado) não passa de um hexágono a um vizinho quando a reta entre os centros cruza uma parede.
- **As pontas do caminho:**
  - **A saída:** o caminho sai do ponto do Domador, que nem sempre é o centro. Se a reta até o centro do próprio hexágono cruzar uma parede, a busca começa pelos vizinhos cujo centro ele alcança em reta.
  - **A chegada:** se o centro do hexágono tocado não for alcançável (uma parede passa por ele, como nas cercas convertidas), os objetivos da busca viram os vizinhos dele que alcançam o ponto tocado em reta (`approach_goals`), ou todos, sem nenhum. O último trecho vai do último centro alcançado até o ponto tocado; se cruzar uma parede, o Domador para antes da primeira, a `WALL_REACH` dela. Assim, tocar numa cerca leva o Domador até ela, como hoje tocar numa cerca leva ao lado livre.
  - **Sem caminho:** a mensagem de hoje ("sem caminho").
- **O NPC que passeia** anda de centro em centro pelo `path_to_any`, e por isso respeita as paredes sem mais nada.
- **Quem vaga dentro do hexágono:** os Ecobeasts e os Domadores NPC escolhem o ponto seguinte (`WanderingSprite.random_spot`) entre os que não cruzam parede a partir de onde estão; sem nenhum, ficam parados. É só desenho: o nascimento e o hexágono deles não mudam.
- **Ficam como hoje:** o nascimento dos Ecobeasts, Procurar, o desafio do Domador NPC (pelo hexágono) e o bloqueio por hexágono dos objetos.

## A ferramenta Cerca (fase 3)

Uma ferramenta nova na barra do editor, com um painel do tipo (os 3 de `wall_types`), no estilo do Caminho:

- **Desenhar:**
  - cada clique põe um ponto, e a prévia segue o mouse do último ponto;
  - Enter, clique duplo ou o botão direito terminam;
  - Esc cancela;
  - um ponto fora dos hexágonos editáveis não entra.
- **Selecionar:** um clique perto de uma parede (a poucos pixels) a escolhe. Com uma escolhida, o painel troca o tipo dela, e Delete a apaga.
- **Desfazer:** cada parede terminada, trocada ou apagada é um passo do histórico do editor (`EditorHistory`), como os traços.
- O `IslandDraft` guarda as paredes, e o salvar manda o contrato da fase 1.

## A conversão (fase 4)

A migration `free_fences_conversion`, em SQL escrito à mão, em cada `island_map` (rascunho e publicada):

1. **As cercas:** os objetos de tipo 29 (`town_fence`), com a altura de `island_tiles` no hexágono deles.
2. **As ligações:** pares de cercas vizinhas (os 6 vizinhos de `HexGrounds.EDGE_NEIGHBORS`) na mesma altura, como o `HexFences.links` faz hoje.
3. **As paredes novas:**
   - **Para cada par:** com a mesma variante, uma parede do centro de uma ao centro da outra. Com variantes diferentes, duas paredes, cada uma do centro da sua cerca até o meio do lado, no tipo da sua variante (1 vira `wood_fence`, 2 vira `stone_fence`).
   - **Para cada cerca sem ligação:** a peça reta de hoje, de (−30, 0) a (30, 0) a partir do centro dela. Os 2 px a menos de cada lado deixam as pontas dentro do hexágono dela, mesmo na beira da ilha, onde (±32, 0) cairia fora.
   - O centro plano de (q, r) a partir do (0, 0) é `(64q + 32r, 42r)`. O `position` segue a ordem dos objetos.
4. **A conferência:** toda parede convertida passa nas regras do contrato (pontos dentro da ilha, até 2.000 por ilha). A fase 4 confere isso no banco real antes de aplicar.
5. **A limpeza:** apaga os objetos de tipo 29 (os `island_object_tiles` vão junto) e o tipo 29 de `map_object_types` (os `map_object_type_tiles` vão junto).

O `content_hash` guardado não é recalculado: o rascunho e a publicada mudam igual, então a comparação entre eles continua a mesma até o próximo salvar.

No cliente saem:
- o `HexFences`;
- a arte de `town_fence`;
- a Cerca no `MapObjectSprite` e no `HexMapView`;
- no `make_town.gd`, só o tipo `town_fence`. O desenho das peças da cerca fica, porque é dele que sai a arte das paredes.

O `seed-data` fica sem o tipo 29, e os testes do servidor que o citam passam a usar outro tipo.
