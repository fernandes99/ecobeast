# 05. A vila vitrine

- **Status:** rascunho
- **Depende de:** [04-street-decorations](04-street-decorations.md)

## Contexto

A Vila da Fonte Azul (ilha 634, rascunho) foi montada em 2026-11-12 com a arte de antes: o Refúgio e a Loja são Casas grandes, e a Arena é um cercado de pedra com chão de terra. Com as fases 1 a 4 prontas, uma ilha nova, com o mesmo desenho, vira a vitrine do estilo novo. Por pedido do dono, a 634 continua como está.

## Escopo

- Uma ilha nova em rascunho, "Vila da Fonte Azul (cidade)", com o terreno, o rio, a mata, as trilhas e as áreas da 634. Nela:
  - o Refúgio é o `refuge_building`, com a ação Refúgio nos hexágonos dele;
  - a Loja é o `shop_building`, com a ação Loja;
  - a Arena é o `arena_building`, com a ação Arena, no lugar do cercado e do chão de terra;
  - cada casa e objeto de vila é a versão da cidade (`town_...`), na variante de cor mais parecida;
  - há postes em volta da praça e nos caminhos principais, placas nas entradas, canteiros perto das casas e bancos em volta da fonte.

## Fora do escopo

- Mudar a ilha 634 ou qualquer outra que exista.
- Publicar a ilha nova: quem publica é o dono, no F2.

## Requisitos

- **RF-01:** A ilha é criada pelo serviço do editor (`IslandsEditorService.create`), que confere o rascunho como o editor confere, por um script temporário em `server/prisma/`, apagado depois.
- **RF-02:** Toda construção-chave tem uma trilha da porta até a praça, e nenhum hexágono de chegada ou de caminho fica bloqueado.
- **RF-03:** Os postes e as placas não fecham nenhuma trilha: ficam ao lado dela.

## Critérios de aceite

- [ ] A ilha nova salva sem erro pelo serviço, e a 634 continua igual.
- [ ] Numa imagem da ilha desenhada pelo mapa do jogo, o Refúgio, a Loja e a Arena se reconhecem de longe.
- [ ] O dono abre a ilha no F2, anda até cada construção-chave e a ação acontece (a Arena não abre tela, como hoje).

## Verificação

Uma cena temporária com a ilha inteira, salva numa imagem e mandada ao dono, e o dono no F2.

## Tarefas

- [ ] O script temporário que cria a ilha.
- [ ] A imagem da ilha.
- [ ] Apagar o script e marcar a iniciativa como concluída.
