# 03. Biomas, Itens, Traços, Temperamentos e Estados

- **Status:** rascunho
- **Depende de:** [02-skills-and-elements](02-skills-and-elements.md)

## Contexto

As fases [01](01-viewer-window.md) e [02](02-skills-and-elements.md) criaram a janela e as abas Resumo, Ecobeasts, Técnicas e Elementos. O dono pediu os biomas ("quais sprites existentes deles") e aceitou as abas de Itens, Traços, Temperamentos e Estados. O algoritmo do mapa fica de fora, a pedido dele ([README](README.md)).

O que esta fase encontra hoje:

- **Biomas:** o catálogo tem 7 (Planície, Boreal, Pedra, Colina, Montanha, Água rasa e Água profunda). O mapa desenha cada bioma com a superfície `res://assets/terrain/surfaces/<slug>.png`. Colina e Montanha são biomas no catálogo, mas o gerador do mapa (`server/src/domain/exploration/map-generator.ts`) as trata como formas do terreno, com as peças `surfaces/hill.png` e `surfaces/mont.png`, que valem para qualquer bioma. A janela mostra o que encontra e não corrige isso.
- **Ecobeasts por bioma:** todos os 7 biomas têm algum Ecobeast.
- **Peças soltas de terreno:** `res://assets/terrain/` tem hexágonos `<nome>_<forma>_NN.png` (como `boreal_flat_01.png`), de um pacote antigo, que nenhuma tela usa hoje. Quatro nomes (desert, snow, swamp e warm) não são biomas do catálogo.
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
- **RF-02:** O detalhe do bioma tem: o nome e a descrição; **Ecobeasts que nascem aqui**, com o nome (link) e a taxa do `species_biomes`, da maior para a menor (sem nenhum, "Nenhum Ecobeast nasce aqui."); **Superfície**, o preview de `surfaces/<slug>.png` (ou o tracejado com o caminho); e **Peças soltas, não usadas pelo jogo**, os previews dos arquivos `<slug>_<forma>_NN.png` que existirem, agrupados por forma (plano, colina e montanha). Sem nenhuma, o bloco não aparece.
- **RF-03:** O detalhe de **Peças comuns** mostra os previews das peças que o mapa usa para todos os biomas: `surfaces/hill.png`, `mont.png`, `cliff.png`, `side.png`, `contour.png` e `highlight.png`, `decorations/decorations.png`, `transitions/transitions.png` e `transitions/drips.png`, cada um com o nome do arquivo.
- **RF-04:** A aba "Itens (N)" lista os itens pela ordem de `sort_order`, com o ícone pequeno à esquerda e o nome da categoria à direita. O detalhe tem o ícone grande (ou o tracejado), o nome, a categoria, o preço em moedas, a descrição e **O que faz**: "Bônus de captura ×N" quando há `capture_bonus`, "Cura N de HP" quando há `heal_amount` e "Tira um Estado que dura depois da luta" quando `cures_status`.
- **RF-05:** A aba "Traços (N)" lista os Traços pela ordem do `id`, com quantos Ecobeasts o têm à direita. O detalhe tem o nome, a descrição e os Ecobeasts que o têm (links), com "(oculto)" onde é oculto. Sem nenhum, "Nenhum Ecobeast tem este Traço.".
- **RF-06:** A aba "Temperamentos (N)" é uma tabela só, sem detalhe: o nome, o stat que aumenta (+10%) e o que diminui (−10%), um por linha, na ordem do `id`. Os neutros (o mesmo stat nos dois) mostram "neutro" nas duas colunas, em cinza.
- **RF-07:** A aba "Estados (N)" lista os Estados pela ordem do `id` e, depois deles, as marcas no chão (`ground_effects`) com "marca" à direita. O detalhe do Estado tem o nome, se é **só na luta** (`is_volatile`) ou **continua depois da luta**, os Elementos imunes (selos que são links), as Técnicas que o causam (links, com a chance do efeito), as marcas no chão que o causam e os itens que o tiram. Um grupo vazio mostra "—". O detalhe da marca tem o nome, a cor num quadrado, o dano por turno em %, o Estado que causa (link, ou "—") e as Técnicas que a deixam (links, com os turnos).
- **RF-08:** Os links novos: no Ecobeast, os Traços e os biomas; na Técnica, o Estado de um efeito e a marca no chão; no Elemento, os Estados das imunidades.
- **RF-09:** O Resumo ganha: "Biomas com superfície" ("N de 7"), "Itens com ícone" ("N de 6"), a lista "Peças de terreno fora do catálogo" com os nomes de `<nome>_<forma>_NN.png` que não são biomas (hoje desert, snow, swamp e warm) e "Biomas sem Ecobeast", com os nomes. As listas sem nenhum nome não aparecem.

## Critérios de aceite

- [ ] A Planície mostra o Ruvo com taxa 60, a superfície `temperate.png` e as peças soltas `temperate_flat`, `temperate_hill` e `temperate_mont`.
- [ ] A Montanha mostra a superfície tracejada com `res://assets/terrain/surfaces/mountain.png` (o arquivo da forma se chama `mont.png`), sem peças soltas.
- [ ] Peças comuns mostra as 9 peças.
- [ ] O Bálsamo Puro mostra 150 moedas e "Tira um Estado que dura depois da luta"; a Esfera Suprema, "Bônus de captura ×2".
- [ ] O Instinto mostra Ruvo, Ruvak e Ruvaroth, os três "(oculto)".
- [ ] A aba Temperamentos tem 25 linhas, com o Sereno neutro.
- [ ] Queimado mostra "continua depois da luta", o Fogo imune e o Bálsamo Puro; Confuso mostra "só na luta". O Chão em chamas mostra 6% por turno.
- [ ] O Resumo mostra desert, snow, swamp e warm nas peças fora do catálogo e "6 de 6" itens com ícone.

## Desenho técnico

**Criar:** em `res://tools/content_viewer/`, `biomes_tab.gd`, `items_tab.gd`, `traits_tab.gd`, `temperaments_tab.gd` e `statuses_tab.gd`.

**Alterar:** `content_viewer.gd` (as 5 abas), `content_files.gd` (os caminhos do terreno e a lista das peças soltas), `species_tab.gd`, `skills_tab.gd` e `elements_tab.gd` (os links) e `summary_tab.gd` (os blocos novos).

**Reutilizar:** `HexMapView.SURFACE_PATH`, `HexDecorations.TEXTURE_PATH` e `HexTransitions.TEXTURE_PATH` e `DRIP_TEXTURE_PATH` para os caminhos; `ItemIcon.SPRITE_PATH`; `GameData.get_items`, `get_item_categories`, `get_trait`, `get_temperaments`, `get_ground_effect` e `get_rows` para `biomes`, `species_biomes`, `species_traits`, `status_conditions`, `status_condition_immunities`, `skill_effects` e `ground_effects`.

## Verificação

- `godot --headless --path client --quit-after 30` sem erros nem avisos de script.
- O script sem janela das fases anteriores ganha: as 4 peças fora do catálogo, o "6 de 6" itens, as 25 linhas de Temperamentos, o Ruvo com 60 na Planície, os 3 Ecobeasts do Instinto e o "continua depois da luta" do Queimado.
- Manual, com F5: os critérios de aceite. Prints da Planície, de Peças comuns, de um item, de Temperamentos e de Queimado.

## Tarefas

- [ ] A aba Biomas, com Peças comuns.
- [ ] As abas Itens, Traços, Temperamentos e Estados.
- [ ] Os links novos.
- [ ] Os blocos novos do Resumo.
- [ ] Verificação sem janela e prints com janela.
- [ ] O dono ver com F5.
