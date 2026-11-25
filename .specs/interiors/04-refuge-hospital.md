# 04. O hospital do Refúgio

- **Status:** concluída (falta o dono conferir no F5 e no F2)
- **Depende de:** [01](01-interior-data.md), [02](02-interior-screen.md), [03](03-interior-editor.md), [village-pack](../village-pack/)

## Contexto

A sala 1, "Refúgio", é o quarto de exemplo do pacote Main Characters Home convertido ([01](01-interior-data.md)): uma casa de madeira, sem cara de hospital, e a cura viria de um NPC no balcão, que ninguém pôs. O prédio do Refúgio (peça 22) já leva a ela em duas ilhas.

O dono pediu: "Crie um interior que vai ser o refugio", com o tileset do Fantasy Dreamland Reborn (o mesmo pacote das casas da vila), "parecido com um hospital para ecobeast com algum tipo de maquina para curar os ecobeast (não será um NPC que vai curá-los)". Nas perguntas, ele escolheu a máquina que cura na hora, sem abrir a tela de cura, e trocar a sala 1 pelo hospital.

O pacote tem, em `Tilesets/`, a folha `Interior/Sprites/FDR_Interior.png` (paredes listradas em 5 cores, pisos, molduras do teto, tapetes, móveis, sofás e plantas) e a `Laboratory/Sprites/FDR_Laboratory_Tiles.png` (piso xadrez azul e branco, armários com a cruz verde e a vermelha, cápsulas de vidro, uma com a cruz branca, macas e consoles). Muitos móveis estão deslocados meio tile (8 px) na folha, e a sala recorta a folha de 16 em 16 px.

## Escopo

- Uma folha nova das salas, `refuge`, montada por um script com as peças das duas folhas do pacote, alinhadas aos 16 px.
- A sala 1 refeita como um hospital, por um script, na migration.
- O objeto da sala com ação (`interior_objects.action_type_id`), escolhido no F2.
- A máquina de cura: o objeto com a ação `refuge` cura a equipe na hora, com o brilho e o som.

## Fora do escopo

- Mudar a cura do servidor (`POST /v1/me/heal`), que segue de graça e sem conferir onde o Domador está.
- As animações dos consoles do pacote (as folhas `Animated Tiles`): a sala usa o primeiro quadro.
- Um NPC na sala; o dono pode pôr um no F2 para enfeitar.

## Requisitos

### A folha

- **RF-01:** O `client/assets/interiors/fdr/make_refuge_sheet.py <pasta Tilesets do pacote>` lê as duas folhas do pacote e grava `client/assets/interiors/fdr/refuge.png`, 16 tiles de largura, com cada peça escolhida copiada sem mudar os pixels: os pisos, a parede rosa listrada, o teto escuro com a moldura creme (a moldura 3×3 do pacote e os 4 cantos de dentro, os tiles em volta do quadradinho dela), o estrado (as 9 partes da plataforma em cruz do laboratório), o tapete, o capacho, as placas da cruz, os armários, as cápsulas, as macas, os consoles, as plantas, os sofás e o tapete. Cada móvel fica no menor retângulo de tiles que o cabe, com o pé na borda de baixo e centrado na largura. Rodar de novo dá a mesma imagem.
- **RF-02:** A folha entra no `InteriorTiles.SHEETS` depois das 3 do Main Characters Home (o id da fonte das outras não muda), com o caminho de cada folha numa tabela, e aparece na paleta do F2. Os créditos do pacote vão para `client/assets/interiors/CREDITOS.md`.

### A sala

- **RF-03:** O `client/assets/interiors/fdr/make_refuge_room.py` monta a sala "Refúgio" com a folha `refuge` e escreve o SQL que troca a sala 1 (apaga os tiles, os objetos, os bloqueios e os NPCs dela e insere os novos, mantendo o id 1) e uma prévia em PNG. A sala é um hospital de 19×14 quadrados:
  - o teto escuro com a moldura creme em volta, a parede rosa de 2 quadrados no alto e o piso xadrez azul e branco;
  - no fundo, a máquina de cura: três cápsulas de vidro, a do meio com a cruz, num estrado azul, com a placa da cruz verde na parede e um armário de remédios de cada lado;
  - à esquerda, a enfermaria, com 4 macas e um suporte de soro ao lado de cada par; à direita, a espera, com os sofás, as plantas e o tapete;
  - a porta no meio da linha de baixo, com o capacho, e o caminho livre da porta até a máquina.
- **RF-04:** O teto e a parede bloqueiam por não terem chão; os bloqueios marcados são o pé de cada móvel em pé (a linha de baixo) e as macas inteiras, deitadas no chão. A máquina tem a ação `refuge` (id 1).
- **RF-05:** A migration `refuge_hospital` adiciona a coluna e troca a sala 1 com o SQL do script. As peças que levam à sala 1 seguem levando.

### O objeto com ação

- **RF-06:** `interior_objects.action_type_id`: int, nulo, FK `action_types` com `on delete restrict`. As rotas da sala o devolvem em cada objeto, e o `PUT` do editor o grava; um tipo que não existe dá 400 "O objeto tem uma ação que não existe.".
- **RF-07:** No jogo, o `InteriorObject` ganha o `action_type_id` (0 sem ação). No F2, com a ferramenta Objeto e um objeto escolhido, a linha "Ação" mostra a ação dele (Nenhuma ou os tipos do catálogo) e a troca, com o desfazer.

### A máquina de cura

- **RF-08:** Tocar na arte de um objeto com ação anda até o quadrado livre ao lado dele (cima, baixo, esquerda ou direita de um quadrado do objeto) de caminho mais curto, como o toque no NPC. Encostado, o Domador vira para o objeto e a ação acontece. Sem quadrado alcançável, nada acontece.
- **RF-09:** O objeto com a ação `refuge` é uma máquina de cura: sem equipe, a barra mostra "Você ainda não tem Ecobeasts para cuidar."; com equipe, a máquina pisca (3 pulsos de brilho em 1,2 s), toca o som da cura no canal `Sfx` e chama o `Session.heal_team()`. Com sucesso, a caixa de fala mostra "Sua equipe está curada!" com a voz da narração; com erro, a barra mostra o erro. Enquanto ela cura, o toque e o voltar não fazem nada. As outras ações de um objeto abrem a tela do tipo pelo `ActionScreens.open`, como no NPC.
- **RF-10:** O som da cura (`client/assets/sounds/refuge/heal.wav`) é um arpejo curto e subindo de videogame antigo, gerado pelo `make_heal_sound.py` da mesma pasta.

## Critérios de aceite

- [x] `GET /v1/interiors/1` devolve o hospital, com a máquina com `action_type_id` 1.
- [x] O `PUT` do editor grava o `action_type_id` de um objeto; com um id que não existe, dá 400.
- [ ] No F5, entrar no Refúgio abre o hospital com o Domador na porta, e ele anda até a máquina sem atravessar os móveis.
- [ ] Tocar na máquina leva o Domador até ela, a máquina pisca, o som toca, e a equipe sai curada, com a fala na caixa.
- [ ] Sem equipe, tocar na máquina mostra a frase na barra.
- [ ] No F2, a sala aparece montada, a folha `refuge` está na paleta e a linha Ação muda a ação de um objeto.
- [x] Rodar os dois scripts de novo dá a mesma folha e o mesmo SQL.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Criar:**
  - `client/assets/interiors/fdr/make_refuge_sheet.py`, `refuge.png` e `make_refuge_room.py`
  - `client/assets/sounds/refuge/make_heal_sound.py` e `heal.wav`
  - `server/prisma/migrations/<data>_refuge_hospital/migration.sql`
- **Alterar:**
  - `server/prisma/schema.prisma`, `server/src/domain/interiors/interior-body.ts` e o `.spec.ts`, `server/src/interiors/interiors.dto.ts` e `.service.ts`, `server/src/editor/interiors-editor.service.ts` e `server/test/interiors.e2e-spec.ts`
  - `client/ui/components/interior_tiles.gd` (as folhas numa tabela) e `interior_view.gd` (o sprite de cada objeto, para piscar)
  - `client/domain/models/interior_object.gd`
  - `client/screens/interior/interior_screen.gd` (o toque no objeto e a máquina)
  - `client/tools/interior_editor/interior_editor.gd` e `interior_draft.gd` (a linha Ação)
  - `client/assets/interiors/CREDITOS.md`, a [architecture](architecture.md) e o [README](README.md)

## Verificação

- `npm run lint`, `npm run typecheck`, `npm test` e o `interiors.e2e` no `server/`.
- `godot --headless --path client --quit-after 30`.
- Os dois scripts rodados duas vezes, com a saída comparada, e a prévia da sala olhada.
- Uma cena temporária em `client/zz_tmp_check` (apagada no fim) que abre a tela com a sala do script na memória, toca na máquina e confere a caminhada até ela e o pedido de cura.

## Tarefas

- [x] A folha `refuge` e os créditos.
- [x] A sala, a prévia e a migration.
- [x] O `action_type_id` do objeto no servidor e no F2.
- [x] A máquina de cura na tela e o som.
