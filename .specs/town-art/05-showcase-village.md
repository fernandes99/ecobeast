# 05. A Vila da Fonte Azul refeita

- **Status:** rascunho
- **Depende de:** [04-street-decorations](04-street-decorations.md)

## Contexto

A Vila da Fonte Azul (ilha 634, rascunho) foi montada em 2026-11-12 com a arte de antes: o Refúgio e a Loja são Casas grandes, e a Arena é um cercado de pedra com chão de terra. Com as fases 1 a 4 prontas, ela vira a vitrine do estilo novo. As casas e os objetos dela já mudam sozinhos de arte; falta trocar as construções-chave e pôr as decorações de rua.

## Escopo

- No rascunho da ilha 634:
  - o Refúgio vira o `refuge_building`, com a ação Refúgio nos hexágonos dele;
  - a Loja vira o `shop_building`, com a ação Loja;
  - a Arena cercada vira o `arena_building`, com a ação Arena, e o cercado e o chão de terra dela saem.
- Postes em volta da praça e nos caminhos principais, placas nas entradas, canteiros perto das casas e bancos em volta da fonte.

## Fora do escopo

- Publicar a ilha: quem publica é o dono, no F2.
- Mudar o terreno, o rio e a mata.

## Requisitos

- **RF-01:** A mudança é feita pelo serviço do editor (`IslandsEditorService`), que confere o rascunho como o editor confere, por um script temporário em `server/prisma/`, apagado depois.
- **RF-02:** Toda construção-chave tem uma trilha da porta até a praça, e nenhum hexágono de chegada ou de caminho fica bloqueado.
- **RF-03:** Os postes e as placas não fecham nenhuma trilha: ficam ao lado dela.

## Critérios de aceite

- [ ] O rascunho 634 salva sem erro pelo serviço.
- [ ] Numa imagem da ilha desenhada pelo mapa do jogo, o Refúgio, a Loja e a Arena se reconhecem de longe.
- [ ] O dono abre a ilha no F2, anda até cada construção-chave e a ação acontece (a Arena não abre tela, como hoje).

## Verificação

Uma cena temporária com a ilha inteira, salva numa imagem e mandada ao dono, e o dono no F2.

## Tarefas

- [ ] O script temporário que troca as construções e põe as decorações.
- [ ] A imagem da ilha.
- [ ] Apagar o script e marcar a iniciativa como concluída.
