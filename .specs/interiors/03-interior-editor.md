# 03. O modo Interiores do F2

- **Status:** concluída (falta o dono conferir no F2 e no F5)
- **Depende de:** [01](01-interior-data.md), [02](02-interior-screen.md)

## Contexto

As salas já moram no banco e o jogo já entra nelas ([01](01-interior-data.md), [02](02-interior-screen.md)), mas montar uma sala ainda pede mexer no banco. Esta fase dá ao F2 um modo Interiores, onde o dono cria e monta as salas com a folha do pacote como paleta, e põe na ferramenta Peças a escolha da sala de cada prédio.

## Escopo

- O botão Interiores no F2 e o `InteriorEditor`: a lista de salas, criar, renomear, mudar o tamanho, excluir e salvar.
- As ferramentas Chão, Detalhe do chão, Parede, Detalhe da parede, Objeto, Bloqueio, NPC e Porta, com a paleta das folhas.
- Desfazer e refazer.
- A sala da peça, na ferramenta Peças.

## Fora do escopo

- Testar a sala de dentro do editor.
- Copiar e colar pedaços de sala, ou carimbos de sala.
- Importar um `.tmx` pelo editor (o script da [01](01-interior-data.md) continua para isso).

## Requisitos

### A janela

- **RF-01:** A barra de cima do F2 ganha o botão Interiores, que troca o conteúdo da janela pelo `InteriorEditor`. O `InteriorEditor` tem o botão Ilhas, que volta para o editor de ilhas. Trocar com mudanças sem salvar pergunta, como o editor de ilhas pergunta ao trocar de ilha (Salvar, Descartar ou Cancelar). Fechar o F2 também.
- **RF-02:** A barra de cima do `InteriorEditor` tem:
  - o botão Salas, que abre a lista das salas (`GET /v1/editor/interiors`); tocar numa abre essa sala;
  - na lista, Nova sala (nome, largura e altura, `POST`) e Excluir na sala aberta (com confirmação; o 409 aparece na barra de mensagem);
  - o nome da sala, a largura e a altura, editáveis. Diminuir o tamanho tira o que fica de fora, e a porta que ficar de fora vai para o quadrado de dentro mais perto;
  - Salvar (e Ctrl+S), que manda o `PUT` e escreve "Sala salva." ou o erro na barra de mensagem;
  - um asterisco no nome quando há mudança sem salvar.
- **RF-03:** No meio, a sala é desenhada pelo `InteriorView` da [02](02-interior-screen.md), com:
  - zoom inteiro de 1 a 6 pela roda, em volta do mouse;
  - arrasto da vista pelo botão do meio ou com espaço + botão esquerdo;
  - a grade de 16 px e a borda da sala por cima;
  - o quadrado do mouse marcado, com a prévia do que a ferramenta põe nele.
- **RF-04:** As ferramentas ficam numa coluna à esquerda, com as teclas 1 a 8. O painel à direita muda com a ferramenta.

### Pintar

- **RF-05:** **A paleta.** Para as 4 ferramentas de tile e a Objeto, o painel mostra a folha escolhida em 3 abas (Chão e paredes, Móveis, Portas e janelas), ampliada em 2 vezes, com a grade. Um clique escolhe um tile, e arrastar escolhe um retângulo de tiles. A escolha fica marcada. Qualquer aba serve a qualquer ferramenta: os tapetes da aba Móveis vão pelo Detalhe do chão, para ficarem por baixo do Domador.
- **RF-06:** **Chão, Detalhe do chão, Parede e Detalhe da parede.**
  - O botão esquerdo põe a escolha na camada da ferramenta, com o canto de cima à esquerda no quadrado do mouse.
  - Arrastando, põe a escolha de novo a cada passo do tamanho dela, como um carimbo que se repete.
  - O botão direito apaga o tile da camada nos quadrados por onde passa.
  - O que passa da borda da sala é cortado.
  - Na Parede, cada tile sólido posto ([architecture](architecture.md#quando-um-quadrado-bloqueia)) marca o quadrado como bloqueado, e apagar um tile sólido da parede desmarca o quadrado.
- **RF-07:** **Objeto.**
  - O botão esquerdo num quadrado vazio põe o retângulo escolhido como um objeto, com o canto de cima à esquerda no quadrado.
  - O botão esquerdo num objeto o escolhe (o de pé mais baixo, se houver vários), e arrastar o move de quadrado em quadrado, sem sair da sala.
  - Delete, ou o botão direito, apaga o objeto.
  - Ao pôr um objeto, os quadrados da linha de baixo dele viram bloqueios à mão (a linha inteira, se ele tem 1 linha), pela regra do script da [01](01-interior-data.md). Arrastar o objeto leva junto os bloqueios da linha de baixo, e apagá-lo os tira, menos onde outro objeto ou uma parede sólida ainda bloqueia. Os bloqueios continuam editáveis na ferramenta Bloqueio.
- **RF-08:** **Bloqueio.** O botão esquerdo marca os quadrados como bloqueados à mão, e o direito desmarca. Com essa ferramenta, os bloqueios ficam à mostra: os à mão num vermelho translúcido com um X, e os que bloqueiam sozinhos (sem chão) num cinza translúcido. Fora dela, a chave Bloqueios da barra de cima mostra os mesmos.
- **RF-09:** **NPC.**
  - O painel tem o NPC (a lista do catálogo `npcs`), a fala (um texto de várias linhas; uma linha em branco separa os parágrafos, como nos NPCs da ilha) e a ação (Nenhuma ou um tipo de `action_types`).
  - O botão esquerdo num quadrado livre põe um NPC novo com o que está no painel; num NPC, o escolhe, e o painel passa a mostrar e editar o dele. Arrastar o move.
  - Delete, ou o botão direito, o apaga.
  - Um quadrado que bloqueia, a porta ou o quadrado de outro NPC não recebe NPC, e a barra de mensagem diz "O NPC precisa de um quadrado livre.".
- **RF-10:** **Porta.** O botão esquerdo põe a porta no quadrado, marcada com um contorno dourado (que aparece com qualquer ferramenta). Um quadrado sem chão ou bloqueado não recebe a porta, e a barra diz "A porta precisa estar num quadrado de chão, sem bloqueio.".
- **RF-11:** Ctrl+Z desfaz e Ctrl+Y (ou Ctrl+Shift+Z) refaz. Cada pincelada, do apertar ao soltar, e cada mudança no painel, no nome ou no tamanho é um passo.

### A sala da peça

- **RF-12:** Na ferramenta Peças, com uma peça escolhida, o painel ganha a lista Sala, embaixo da Ação: Nenhuma e as salas pelo nome. Escolher grava o `interior_id` da peça no rascunho, com desfazer, e o resto segue pelo salvar e publicar da ilha ([01](01-interior-data.md)).

## Critérios de aceite

- [ ] No F2, Interiores abre o Refúgio convertido, e Ilhas volta para a ilha aberta.
- [ ] Pintar o chão e a parede, pôr uma estante e um NPC com fala e a ação Refúgio, salvar, e o jogo mostra a mudança na próxima entrada.
- [ ] Os bloqueios aparecem e mudam na ferramenta Bloqueio, e a porta não vai para um quadrado bloqueado.
- [x] Desfazer e refazer voltam e repetem uma pincelada inteira.
- [ ] Trocar de sala ou voltar para Ilhas com mudança sem salvar pergunta antes.
- [ ] Ligar o prédio do Refúgio de Liora à sala na ferramenta Peças, salvar e publicar, e tocar nele no jogo abre a sala.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Criar** em `client/tools/interior_editor/`:
  - `interior_editor.gd` (`InteriorEditor`: a barra, a lista, o salvar e as teclas)
  - `interior_canvas.gd` (o mapa, o zoom, o arrasto, a grade e as marcas)
  - `interior_palette.gd` (as abas e a escolha na folha)
  - `interior_npc_panel.gd` (o painel do NPC)
  - `interior_draft.gd` (`InteriorDraft`: a sala em edição sobre o `Interior`, com as regras de pôr, mover e apagar, sem `Node`, para testar sozinha)
- **Alterar:**
  - `client/tools/map_editor/map_editor.gd` (o botão Interiores e a troca de conteúdo)
  - `client/tools/map_editor/editor_api.gd` (as 5 rotas da sala)
  - `client/tools/map_editor/object_panel.gd` (a lista Sala)
- **Reutilizar:** o `InteriorView` e o `InteriorTiles` da [02](02-interior-screen.md), o `UndoRedo` do Godot e a pergunta de mudanças sem salvar do `MapEditor`.

## Verificação

- `godot --headless --path client --quit-after 30`.
- Uma cena temporária em `client/zz_tmp_check` (apagada no fim) que confere o `InteriorDraft`: pintar e apagar por camada, o carimbo cortado na borda, o objeto com os bloqueios da linha de baixo, a parede sólida marcando o bloqueio e o contorno fino não, a porta recusada num bloqueio, o NPC recusado num bloqueio, o tamanho menor cortando o resto, e o `to_dict` igual ao corpo da [architecture](architecture.md#as-rotas).
- Uma cena temporária que cria uma sala pela rota local, salva uma mudança, lê de volta e a apaga, sem tocar na sala 1.
- F2 e F5: os critérios acima.

## Tarefas

- [x] O `InteriorDraft` e as rotas no `EditorApi`.
- [x] A janela, a lista, o salvar e a pergunta das mudanças.
- [x] O canvas, a paleta e as ferramentas de tile e de objeto.
- [x] Bloqueio, NPC, Porta e o desfazer.
- [x] A lista Sala na ferramenta Peças.
- [x] O `client/CLAUDE.md`, o `server/CLAUDE.md` e as tabelas das specs.
