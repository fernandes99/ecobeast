# 02. A altura de 0 a 10

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [01](01-terrain-height.md)

## Contexto

Na [01](01-terrain-height.md), cada hexágono ganhou a altura, de 0 a 4, de 8 em 8 px da arte. Em 2026-11-13, o dono pediu mais níveis: "hoje a altura do terreno vai de 0 a 4, eu quero aumentar essas opções ir de 0 a 10".

Claude perguntou como ficam os níveis novos, e o dono escolheu o mesmo degrau: cada nível continua subindo 8 px, então o nível 10 fica a 80 px, e as ilhas que já existem não mudam na tela.

Os paredões (`side.png` e `cliff.png`) têm 64 px de altura e se repetem para baixo: um paredão mais alto que isso, que antes não existia, repetiria a borda clara de cima no meio dele.

## Escopo

- A altura de 0 a 10 no servidor (o banco, a validação e a documentação da API), no jogo e no editor.
- O paredão alto sem a borda repetida.

## Fora do escopo

- O gerador do mapa sorteado: a montanha continua no nível 4, e uma seed continua gerando o mesmo mapa.
- Regras de altura, como na [01](01-terrain-height.md).
- Mudar as ilhas que já existem.

## Requisitos

- **RF-01:** A altura de um hexágono vai de 0 a 10, inteira. O banco recusa fora disso (`island_tiles_height_check`), e a API do editor também, com a mensagem "vai de 0 a 10".
- **RF-02:** Cada nível sobe 8 px da arte: o nível `n` fica a `8 × n` px (`HexMapView.LEVEL_HEIGHTS`, de 0 a 80). Os níveis de 0 a 4 ficam como antes.
- **RF-03:** O gerador separa a altura da montanha (`MOUNTAIN_HEIGHT`, 4) da altura máxima (`MAX_HEIGHT`, 10).
- **RF-04:** Um paredão mais alto que a textura dele (64 px) mostra a textura inteira em cima, e o resto repete só a faixa de baixo dela (os últimos 32 px), sem repetir a borda clara.
- **RF-05:** O mapa monta uma linha a mais além da borda de baixo da tela (`ROW_MARGIN`, de 3 para 4), porque um hexágono de nível 10 sobe 80 px e uma árvore em cima dele aparece antes de a linha chegar à tela.
- **RF-06:** No editor, as ferramentas Altura e Bioma mostram os botões de 0 a 10 em duas linhas (no Bioma, o "Manter" fica numa linha só dele, em cima), e o atalho Shift+0 a Shift+9 escolhe as alturas de 0 a 9; o 10 é só pelo botão.

## Critérios de aceite

- [x] O banco e a API do editor aceitam a altura 10 e recusam a 11.
- [x] O gerador gera os mesmos mapas de antes.
- [x] No mapa, o nível 10 fica a 80 px, com o paredão sem a borda clara repetida.
- [ ] O dono pinta as alturas de 0 a 10 no editor (F2) e vê a ilha com F5.

## Desenho técnico

**Servidor:**

- `map-generator.ts`: `MAX_HEIGHT = 10` e `MOUNTAIN_HEIGHT = 4`, usado no `terrainOf`.
- A migration `20261119000000_terrain_height_ten`, à mão: troca o `CHECK` para `BETWEEN 0 AND 10`. No `schema.prisma`, o comentário `/// CHECK 0–10`.
- Os testes: a validação da ilha (`island-draft.spec.ts`), o do banco (`database.e2e-spec.ts`) e o do editor de ilhas (`islands-editor.e2e-spec.ts`).

**Cliente:**

- `HexTile.MAX_HEIGHT = 10`.
- `HexMapView`: `LEVEL_HEIGHTS` de 0 a 80, `ROW_MARGIN` 4 e o paredão do RF-04 no `_add_faces`.
- `editor_tools.gd` e `map_editor.gd`: os botões em grade e o atalho.

## Verificação

- Os testes do servidor e os e2e, vendo o da validação falhar antes.
- Um teste sem janela do `HexTile`, dos degraus e dos pedaços do paredão, e prints com janela de uma escada de alturas de 0 a 10 e do painel do editor.
- O jogo sem janela abre sem erros de script.

## Tarefas

- [x] Spec.
- [x] O servidor e a migration.
- [x] O cliente e o editor.
- [x] Os testes e o print.
- [ ] O dono ver no editor.

## Resultado da verificação

Em 2026-11-13:

- **Servidor:** o teste da validação falhou antes da mudança (a altura 10 recusada) e passou depois; os 778 testes de unidade passaram. A migration foi aplicada com `prisma migrate deploy`, e o `prisma migrate diff` não mostrou diferença entre o banco e o `schema.prisma`. O e2e do banco foi rodado só depois da migration, então não foi visto falhar antes: ele recusa 11 e −1 e aceita 10. A suíte e2e inteira pegou o teste do editor de ilhas que ainda esperava "acima de 4"; ele passou a usar 11, e os 486 testes passaram. O lint e o Prettier passaram.
- **Cliente:** o teste sem janela falhou antes (sem o nível 10 nem os pedaços do paredão) e passou depois, com 0 falhas: a altura 10 aceita e a 11 recusada, o nível 10 a 80 px e o paredão de 106 px em três pedaços, com os dois de baixo na metade de baixo da textura.
- **Prints com janela:** uma escada de alturas de 0 a 10 em Planície, Pedra e Montanha, com uma Boreal no nível 10 ao lado do nível 1: os paredões de até 72 px ficaram contínuos, sem a borda clara no meio. No painel do Bioma, o "Manter" na mesma grade dos números esticava o 5; ele passou para uma linha só dele.
- **Projeto:** o jogo sem janela, com o depurador, abre sem erros de script, com os mesmos 9 avisos de antes.
- **Falta o dono:** pintar as alturas novas no editor (F2) e ver uma ilha com elas no jogo.
