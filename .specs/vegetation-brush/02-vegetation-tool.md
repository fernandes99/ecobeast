# 02. A ferramenta Vegetação

- **Status:** concluída (falta o dono usar)
- **Depende de:** [01](01-object-cleanup.md) e [map-editor/06](../map-editor/06-tool-groups.md)

## Contexto

Hoje a ferramenta Peças põe uma peça solta por clique, e encher uma ilha de árvores e de grama leva muito tempo. O dono pediu um pincel por grupo de vegetação, com os tipos do grupo que ele marcar ([README](README.md#contexto)).

## Escopo

- A ferramenta Vegetação no grupo Peças, com o painel dela.
- O limite de 20.000 peças no servidor.

## Fora do escopo

- Arte nova.
- Escolher pelo bioma.
- Mudar a ferramenta Peças ou a Borracha.

## Requisitos

- **RF-01:** A ferramenta **Vegetação** (`Tool.VEGETATION`, a última do `enum`, com o ícone `vegetation`) entra no grupo Peças logo depois de Peças. A ordem das abas passa a ser Peças, Vegetação, Carimbo e Borracha, e a tecla 3 passa por elas nessa ordem. A dica: "Pinta vegetação e pedras do grupo escolhido. Botão direito apaga as peças soltas."
- **RF-02:** O painel da Vegetação mostra:
  - **os 7 grupos** da tabela do [architecture.md](architecture.md#os-grupos), um botão cada, com o ícone do primeiro tipo e o nome, e o escolhido marcado. Começa em Árvores;
  - **os tipos do grupo escolhido**, um botão de liga e desliga cada, com o ícone e o nome. Todos começam ligados, e cada grupo lembra os seus. Com um tipo só ligado, ele não desliga;
  - **a densidade:** Pouca, Média e Muita, com a Média marcada no começo;
  - **o tamanho do pincel**, o mesmo das outras ferramentas.
- **RF-03:** **O botão esquerdo** põe peças soltas nos hexágonos do pincel, pela regra do [architecture.md](architecture.md#onde-o-pincel-põe-uma-peça), e cada hexágono recebe peças uma vez só por pincelada, mesmo que o pincel passe por ele de novo.
- **RF-04:** **O botão direito** apaga, nos hexágonos do pincel, todas as peças soltas com o pé neles, de qualquer tipo. Ele não mexe nas decorações naturais, nos objetos nem no chão.
- **RF-05:** Cada pincelada é um passo de desfazer, com o nome "Vegetação".
- **RF-06:** O pincel respeita o corte de altura como as outras ferramentas e, ao chegar a 20.000 peças, para e avisa: "A ilha chegou ao limite de 20.000 peças."
- **RF-07:** O servidor aceita até 20.000 peças por ilha (`MAX_PROPS`), e a mensagem passa a ser "A ilha pode ter até 20.000 peças."

## Critérios de aceite

- [x] O grupo Peças tem 4 abas, na ordem do RF-01.
- [x] Uma pincelada de Árvores só com Pinheiro ligado põe só pinheiros, sem dois pés mais perto que o raio deles.
- [x] O botão direito apaga as peças de qualquer grupo nos hexágonos do pincel.
- [x] Em trilha só nascem os tipos pequenos, em piso nenhum, e hexágono com objeto não recebe nada.
- [x] Um desfazer tira a pincelada inteira.
- [x] Uma ilha com 20.000 peças salva, e uma com 20.001 é recusada.
- [ ] O dono usa o pincel no editor (F2).

## Desenho técnico

- **`client/tools/map_editor/vegetation_panel.gd` (novo, `VegetationPanel`):**
  - `GROUPS` (o nome, os slugs e as peças por hexágono de cada grupo) e `DENSITIES`;
  - o grupo, os tipos ligados de cada grupo e a densidade;
  - `paint_tile(draft, coord, random, allows)`, que põe as peças de um hexágono e devolve quantas pôs;
  - `erase_tile(draft, coord)`.
- **`HexDecorations`:** a regra do ponto livre passa a aceitar uma lista de pontos ocupados, para o pincel e as decorações usarem a mesma.
- **`editor_tools.gd`:** a ferramenta nova no `Tool`, nos nomes, nos ícones, nas dicas e no grupo Peças, e o caminho dela no `paint`, com `props_before` na pincelada.
- **`map_editor.gd`:** a cada passo da Vegetação, `EditorCanvas.refresh_props_at` com os hexágonos tocados, que usa `HexMapView.replace_props` para trocar só as peças deles (revisto na verificação: refazer a lista toda pesava).
- **`icons/vegetation.svg`** (novo).
- **Servidor:** `MAX_PROPS` e a mensagem em `island-draft.ts`, e o teste dele.

## Verificação

- **Teste sem janela** numa cena temporária, que falha antes e passa depois, para cada critério de aceite que não precisa do dono.
- **Servidor:** os testes de unidade, o lint, o typecheck e a suíte e2e inteira.
- **Print:** o editor com o painel da Vegetação e uma área pintada.

## Tarefas

- [x] Spec.
- [x] O painel, a pincelada e o apagar.
- [x] O limite no servidor.
- [x] Teste, print e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste sem janela** (uma cena temporária, já apagada): falhou antes (sem a ferramenta nem o `VegetationPanel`) e passou depois, com 24 de 24:
  - o catálogo com só 6 objetos e o grupo Peças com as 4 abas na ordem;
  - Árvores começa com os 2 tipos ligados, e o último tipo ligado não desliga;
  - uma pincelada só com Pinheiro põe só pinheiros, sem dois pés mais perto que 12 px, e longe das decorações naturais;
  - um hexágono recebe peças uma vez por pincelada;
  - a trilha não recebe árvore e recebe grama, o piso não recebe nada, e o hexágono com objeto também não;
  - o botão direito apaga as peças de dois grupos, e um desfazer devolve tudo;
  - perto do limite, a pincelada para em 20.000 e avisa uma vez.
- **Servidor:** o teste do limite falhou antes (6.000) e passou depois; lint, typecheck, 812 testes de unidade e 503 e2e passando.
- **Desempenho:** numa ilha de 4.921 hexágonos com 15.000 peças, cada passo do pincel de raio 4 levava 130 ms, quase todo em refazer a lista de peças. Com o redesenho só dos hexágonos tocados, o passo caiu para 17 ms, e o quadro inteiro, com o redesenho, para uns 43 ms.
- **Print** (na conversa): o editor com o painel da Vegetação e uma ilha de teste com 5 pinceladas. Na primeira, os ícones das plantas pequenas saíam quase invisíveis, porque a célula da arte é quase toda vazia; o `VegetationPanel.kind_icon` passou a recortar o desenho.
- **Projeto:** o jogo sem janela abre sem erros de script, com os mesmos avisos de antes, e os scripts do editor não dão aviso novo.
- **Falta o dono:** usar o pincel no editor (F2).
