# 03. Biomas, Itens, Traços, Temperamentos e Estados

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [02-skills-and-elements](02-skills-and-elements.md)

## Contexto

As fases [01](01-viewer-window.md) e [02](02-skills-and-elements.md) criaram a janela e as abas Resumo, Ecobeasts, Técnicas e Elementos. O dono pediu os biomas ("quais sprites existentes deles") e aceitou as abas de Itens, Traços, Temperamentos e Estados. O algoritmo do mapa fica de fora, a pedido dele ([README](README.md)).

O que esta fase encontra hoje:

- **Biomas:** o catálogo tem 7 (Planície, Boreal, Pedra, Colina, Montanha, Água rasa e Água profunda). O mapa desenha cada hexágono com a superfície `res://assets/terrain/surfaces/<nome>.png` e o enfeita com as decorações da receita desse nome (`HexDecorations.RECIPES`). O nome é o do bioma, menos nas formas colina e montanha (`HexTile.surface()`): ali o mapa usa `hill` e `mont`. Colina e Montanha são biomas no catálogo e formas no gerador do mapa (`server/src/domain/exploration/map-generator.ts`); a Colina tem o slug `hill`, igual ao da forma, e a Montanha tem `mountain`, que o mapa chama de `mont`. A janela usa o nome do mapa e não corrige o catálogo.
- **Ecobeasts por bioma:** todos os 7 biomas têm algum Ecobeast.
- **Peças soltas de terreno:** `res://assets/terrain/` tinha 108 hexágonos `<nome>_<forma>_NN.png` (como `boreal_flat_01.png`), de um pacote antigo, que nenhuma tela usava; quatro nomes (desert, snow, swamp e warm) nem eram biomas do catálogo. Depois de vê-los no visualizador, o dono pediu para apagá-los ("nao vou mais usar elas pode exlcuir"), e eles saíram do projeto. O visualizador não os mostra mais.
- 6 itens, todos com ícone; 6 Traços; 25 Temperamentos; 8 Estados e 1 marca no chão ("Chão em chamas").

## Escopo

- As abas Biomas, Itens, Traços, Temperamentos e Estados, nesta ordem, depois de Elementos.
- Os links novos: Traços e biomas no Ecobeast, Estados nos efeitos das Técnicas e nas imunidades dos Elementos.
- Os blocos novos do Resumo.

## Fora do escopo

- O algoritmo e os parâmetros do mapa.
- Corrigir Colina e Montanha no catálogo ou no gerador: se o dono quiser, é outra entrega.
- Mostrar as transições e decorações recortadas peça por peça: elas aparecem como a folha inteira.

## Requisitos

- **RF-01:** A aba "Biomas (N)" lista os biomas pela ordem do `id`, com quantos Ecobeasts nascem em cada um à direita. A última linha da lista é **Peças comuns**, que não é um bioma.
- **RF-02:** O detalhe do bioma tem: o nome e a descrição; **Ecobeasts que nascem aqui**, com o nome (link) e a taxa do `species_biomes`, da maior para a menor (sem nenhum, "Nenhum Ecobeast nasce aqui."); **Superfície**, o preview de `surfaces/<nome>.png` (ou o tracejado com o caminho), com o nome que o mapa usa (`mont` na Montanha); e **Decorações**, a pedido do dono ("tem como deixar a parte de decoração dentro de cada bioma? além de trazer todas as decorações ali"): cada tipo da receita do bioma, com o nome em português, a chance de aparecer num hexágono, quantas aparecem e se balança com o vento, e as 4 variantes recortadas da folha de decorações, ampliadas 2×. Sem receita (a água), "Nenhuma decoração.". (As peças soltas `<slug>_<forma>_NN.png` também apareciam aqui, até o dono apagá-las.)
- **RF-03:** O detalhe de **Peças comuns** mostra os previews das peças que o mapa usa para todos os biomas: `surfaces/cliff.png`, `side.png`, `contour.png` e `highlight.png`, `transitions/transitions.png` e `transitions/drips.png`, cada um com o nome do arquivo. As superfícies `hill.png` e `mont.png` e a folha de decorações ficam nos biomas.
- **RF-04:** A aba "Itens (N)" lista os itens pela ordem de `sort_order`, com o ícone pequeno à esquerda e o nome da categoria à direita. O detalhe tem o ícone grande (ou o tracejado), o nome, a categoria, o preço em moedas, a descrição e **O que faz**: "Bônus de captura ×N" quando há `capture_bonus`, "Cura N de HP" quando há `heal_amount` e "Tira um Estado que dura depois da luta" quando `cures_status`.
- **RF-05:** A aba "Traços (N)" lista os Traços pela ordem do `id`, com quantos Ecobeasts o têm à direita. O detalhe tem o nome, a descrição e os Ecobeasts que o têm (links), com "(oculto)" onde é oculto. Sem nenhum, "Nenhum Ecobeast tem este Traço.".
- **RF-06:** A aba "Temperamentos (N)" é uma tabela só, sem detalhe: o nome, o stat que aumenta (+10%) e o que diminui (−10%), um por linha, na ordem do `id`. Os neutros (o mesmo stat nos dois) mostram "neutro" nas duas colunas, em cinza.
- **RF-07:** A aba "Estados (N)" lista os Estados pela ordem do `id` e, depois deles, as marcas no chão (`ground_effects`) com "marca" à direita. O detalhe do Estado tem o nome, se é **só na luta** (`is_volatile`) ou **continua depois da luta**, os Elementos imunes (selos que são links), as Técnicas que o causam (links, com a chance do efeito), as marcas no chão que o causam e os itens que o tiram. Um grupo vazio mostra "—". O detalhe da marca tem o nome, a cor num quadrado, o dano por turno em %, o Estado que causa (link, ou "—") e as Técnicas que a deixam (links, com os turnos).
- **RF-08:** Os links novos: no Ecobeast, os Traços e os biomas; na Técnica, o Estado de um efeito e a marca no chão; no Elemento, os Estados das imunidades.
- **RF-09:** O Resumo ganha: "Biomas com superfície" ("N de 7"), "Itens com ícone" ("N de 6") e, dentro do cartão dos biomas, "Sem Ecobeast" com os nomes. Sem nenhum nome, a lista não aparece. (A lista "Peças de terreno fora do catálogo" saiu com as peças soltas.)

## Critérios de aceite

- [ ] A Planície mostra o Ruvo com taxa 60 e a superfície `temperate.png`.
- [ ] A Montanha mostra a superfície `mont.png` e as decorações pedra marrom e musgo; a Planície, as 6 decorações dela (árvore com 14% dos hexágonos, 1 a 2 por hexágono, balançando com o vento) com as 4 variantes de cada; a Água rasa, "Nenhuma decoração.".
- [ ] Peças comuns mostra as 6 peças.
- [ ] O Bálsamo Puro mostra 150 moedas e "Tira um Estado que dura depois da luta"; a Esfera Suprema, "Bônus de captura ×2".
- [ ] O Instinto mostra Ruvo, Ruvak e Ruvaroth, os três "(oculto)".
- [ ] A aba Temperamentos tem 25 linhas, com o Sereno neutro.
- [ ] Queimado mostra "continua depois da luta", o Fogo imune e o Bálsamo Puro; Confuso mostra "só na luta". O Chão em chamas mostra 6% por turno.
- [ ] O Resumo mostra "6 de 7" biomas com superfície e "6 de 6" itens com ícone.

## Desenho técnico

**Criar:** em `res://tools/content_viewer/`, `biomes_tab.gd`, `items_tab.gd`, `traits_tab.gd`, `temperaments_tab.gd` e `statuses_tab.gd`.

**Alterar:** `content_viewer.gd` (as 5 abas), `content_files.gd` (os caminhos do terreno e dos itens), `list_detail.gd` (o ícone pequeno na linha, para os itens), `species_tab.gd`, `skills_tab.gd` e `elements_tab.gd` (os links) e `summary_tab.gd` (os blocos novos).

As marcas no chão ficam na mesma lista dos Estados, com o id da linha somado a 1000 (`StatusesTab.ground_row_id`), para não colidir com os ids dos Estados. Os itens que tiram um Estado são os de `cures_status`, e só para os Estados que duram depois da luta: é o que a descrição do Bálsamo Puro diz.

**Reutilizar:** `HexMapView.SURFACE_PATH`, `HexDecorations.TEXTURE_PATH` e `HexTransitions.TEXTURE_PATH` e `DRIP_TEXTURE_PATH` para os caminhos; `ItemIcon.SPRITE_PATH`; `GameData.get_items`, `get_item_categories`, `get_trait`, `get_temperaments`, `get_ground_effect` e `get_rows` para `biomes`, `species_biomes`, `species_traits`, `status_conditions`, `status_condition_immunities`, `skill_effects` e `ground_effects`.

## Verificação

- `godot --headless --path client --quit-after 30` sem erros nem avisos de script.
- O script sem janela das fases anteriores ganha: o "6 de 7" biomas com superfície, o "6 de 6" itens, as 25 linhas de Temperamentos, o Ruvo com 60 na Planície, os 3 Ecobeasts do Instinto e o "continua depois da luta" do Queimado.
- Manual, com F5: os critérios de aceite. Prints da Planície, de Peças comuns, de um item, de Temperamentos e de Queimado.

## Tarefas

- [x] A aba Biomas, com Peças comuns.
- [x] As abas Itens, Traços, Temperamentos e Estados.
- [x] Os links novos.
- [x] Os blocos novos do Resumo.
- [x] Verificação sem janela e prints com janela.
- [ ] O dono ver com F5.

## Resultado da verificação

Depois, o dono pediu as decorações dentro de cada bioma. Ao ler o `HexDecorations` e o `HexTile.surface()`, apareceu que o mapa desenha a Montanha com `mont.png`: o "falta" de `mountain.png` vinha só do slug do catálogo. O `ContentFiles.surface_name` passou a traduzir `mountain` para `mont`, e o Resumo foi para "7 de 7" biomas com superfície; `hill.png` e `mont.png` saíram das Peças comuns, que ficaram com 6. O script passou a 98 conferências, com as decorações da Planície e da Montanha, a água sem decoração e as 6 Peças comuns, e deu 0 falhas. Prints mostraram as decorações da Planície e da Montanha e as Peças comuns.

Antes disso, o dono pediu para apagar as peças soltas. Elas saíram (108 imagens e os 108 `.import`; nada no projeto apontava para elas, nem pelo caminho nem pelo uid), com o bloco delas no detalhe do bioma e a lista do Resumo. O script deixou de conferir as peças e passou a conferir que elas não aparecem mais.

Em 2026-11-06, o projeto importou sem erros, e o jogo sem janela abriu sem erros nem avisos de script. A checagem de carga seguiu com 0 falhas.

O script sem janela, com o catálogo da API, deu 0 falhas em 95 conferências (as das fases 01 e 02 e as desta): as 9 abas com os títulos "Biomas (7)", "Itens (6)", "Traços (6)", "Temperamentos (25)" e "Estados (8)"; no Resumo, "6 de 7" biomas com superfície, "6 de 6" itens com ícone, desert, snow, swamp e warm fora do catálogo e nenhum bioma sem Ecobeast; a Planície com o Ruvo em 60, a superfície e as peças soltas nas 3 formas; a Montanha com a superfície tracejada e sem peças soltas; as 9 Peças comuns; o Bálsamo Puro e a Esfera Suprema; o Instinto oculto no Ruvo, no Ruvak e no Ruvaroth; os 25 Temperamentos com 5 neutros; Queimado, Confuso e o Chão em chamas; e os links do Traço e do bioma no Ruvo, do Estado na Faísca Rápida, da marca na Chama Espiral e da imunidade no Fogo.

Prints com janela mostraram a Planície, as peças soltas, as Peças comuns, o Bálsamo Puro, o Instinto, os Temperamentos, o Queimado, o Chão em chamas e o fim do Resumo. Falta o dono ver com F5.
