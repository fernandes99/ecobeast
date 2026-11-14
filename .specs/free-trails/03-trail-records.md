# 03. Os traços no banco e no jogo

- **Status:** concluída (falta o dono ver numa ilha publicada)
- **Depende de:** [02](02-ground-mask.md)

## Contexto

Com a [02](02-ground-mask.md), o chão por hexágono é desenhado pela máscara. Esta fase traz o traço: a tabela, o contrato do editor e de Explorar numa ilha, e o desenho dele na mesma máscara, por cima do chão por hexágono. A ferramenta que desenha traços é a [04](04-path-tool.md); até lá, os testes montam traços pelo contrato.

## Escopo

- A tabela `island_trails` e a validação.
- Os traços no salvar e no ler do editor, no publicar e na resposta de Explorar numa ilha.
- O `MapTrail`, o `ExplorationMap.trails` e o rascunho do editor com os traços.
- O desenho dos traços na máscara e as decorações embaixo deles.

## Fora do escopo

- A ferramenta Caminho ([04](04-path-tool.md)).
- Traços nos carimbos.

## Requisitos

- **RF-01:** a migration `free_trails_trails`, escrita à mão e aplicada com `migrate deploy`, cria `island_trails` como no [architecture.md](architecture.md#os-traços-no-banco-island_trails-fase-3), com os `CHECK`s. No `schema.prisma`, o modelo `IslandTrail`.
- **RF-02:** o rascunho do editor (`domain/islands/island-draft.ts`) tem `trails`, opcional, conferido como no architecture. As mensagens de erro são em pt-BR, no jeito das de hoje, por exemplo "O traço 3 tem um ponto fora da ilha." e "A ilha pode ter até 500 traços.". O formato canônico e o `content_hash` levam os traços só quando há algum.
- **RF-03:** salvar grava os traços na ordem recebida (`position`), ler os devolve na mesma ordem, e publicar os copia com a versão, como as peças soltas.
- **RF-04:** a resposta de Explorar numa ilha manda `trails`, na ordem, sempre presente (vazia sem traços). O mapa sorteado não manda o campo.
- **RF-05:** no cliente, o `MapTrail` lê `ground`, `width` e `points`; o `ExplorationMap.trails` guarda a lista. O `IslandDraft` do editor lê e manda os traços e os leva no desfazer como uma lista inteira.
- **RF-06:** o `HexMapView` desenha os traços na máscara, depois do chão por hexágono, do primeiro para o último, só nas páginas que eles tocam, e cobre com a malha de chão os hexágonos de terra que eles cortam. Sobre a água, o traço não aparece.
- **RF-07:** as decorações sorteadas embaixo de um traço seguem o tipo dele ([architecture.md](architecture.md#as-decorações-sorteadas)).
- **RF-08:** o `HexMapView.set_trails(trails)` troca os traços e redesenha só as páginas e as linhas que mudaram, para o editor da [04](04-path-tool.md).

## Critérios de aceite

- [x] O editor salva uma ilha com traços e, ao abrir de novo, os traços voltam iguais, na mesma ordem.
- [x] O servidor recusa um traço com tipo que não existe, largura fora de 8 a 64, um ponto só, mais de 256 pontos, um ponto fora da ilha ou mais de 500 traços, com a mensagem certa.
- [x] Uma ilha sem traços tem o mesmo `content_hash` de antes.
- [ ] Publicar e abrir a ilha em Ilhas (F5) mostra os traços, na altura do terreno, com a borda irregular e as emendas.
- [x] Um traço subindo reto na tela atravessa vários hexágonos sem degrau nem emenda, e um traço de cascalho cruzando uma trilha de terra por hexágono faz a emenda.

## Desenho técnico

**Servidor:**

- A migration e o `schema.prisma`.
- `domain/islands/island-draft.ts`: `DraftTrail`, a validação, o canônico e `MAX_TRAILS`, `MAX_TRAIL_POINTS`.
- `editor/islands-editor.dto.ts` e `.service.ts`: a entrada, a gravação e a leitura.
- `islands/islands.service.ts` (a versão publicada) e `exploration/exploration.dto.ts` e `.service.ts`: a resposta.
- Os testes: a validação (`island-draft.spec.ts`), o banco (`database.e2e-spec.ts`, se ele contar as tabelas) e os e2e das ilhas e do editor.

**Cliente:**

- `domain/models/map_trail.gd` (novo) e `exploration_map.gd`.
- `ui/components/hex_grounds.gd` e `hex_map_view.gd`: os traços na máscara, a cobertura e o `set_trails`.
- `screens/exploration/exploration_screen.gd`: passar os traços da ilha.
- `tools/map_editor/island_draft.gd` e `editor_canvas.gd`: ler, mandar e mostrar os traços.

## Verificação

- **Servidor:** os testes de unidade da validação, vendo falhar antes, e a suíte e2e inteira antes do commit, porque o servidor muda.
- **Cliente, teste com janela por poucos quadros**, numa cena temporária, que falha antes e passa depois: o `MapTrail` lendo o contrato, a página com o id do traço por cima do chão do hexágono, a ida e volta pelo servidor local, e uma decoração embaixo de um traço de piso sumindo.
- **Prints:** uma ilha com traços postos pelo contrato, no editor e no jogo.
- **Projeto:** o jogo sem janela abre sem erros de script, com os mesmos avisos de antes.

## Tarefas

- [x] Servidor: a tabela, o contrato e os testes.
- [x] Cliente: o modelo, o rascunho e a resposta de Explorar.
- [x] O desenho na máscara e as decorações.
- [x] Testes, prints e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Servidor:**
  - **Testes de unidade:** os 7 da validação dos traços falharam antes (6 deles; o de aceitar um traço já passava) e passaram depois.
  - **Banco:** a migration `20261124000000_free_trails_trails` foi aplicada com `migrate deploy`, e o `migrate diff` saiu vazio. O SQL foi escrito à mão, com o schema `ecobeasts` nos nomes, porque o gerado não o trazia.
  - **e2e:** o banco (`CHECK`s da largura e dos pontos, e as 54 tabelas), o editor (ida e volta na mesma ordem, ponto fora da ilha e pontos não inteiros) e Explorar (os traços numa ilha, vazio no mapa sorteado). Esses e2e foram escritos depois do código, então não foram vistos falhando.
  - **Suítes:** o lint, o typecheck, os testes de unidade (814 de 814) e a suíte e2e inteira (503 de 503) passaram.
- **Cliente, teste com janela** (uma cena temporária, já apagada), com 11 de 11:
  - o `MapTrail` lê e volta ao contrato, e o mapa lê os traços;
  - na página, o traço fica por cima do chão do hexágono, e o chão do hexágono fica fora dele;
  - a malha cobre o hexágono do traço, e um traço de piso tira as decorações;
  - a ida e volta pelo servidor local.

  O `MapTrail` foi escrito na fase 2, antes do teste; a ida e volta pelo servidor é a parte que não existia.
- **Prints:** os traços aparecem no editor (os da [04](04-path-tool.md)).
- **Não conferido:** publicar e abrir a ilha com F5.
- **Falta o dono:** ver os caminhos numa ilha publicada (F5).
