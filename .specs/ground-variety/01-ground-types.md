# 01. Os 12 tipos novos de chão

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [free-trails/01](../free-trails/01-ground-types.md) e [free-trails/04](../free-trails/04-path-tool.md)

## Contexto

O dono quer mais chãos e caminhos para montar cenários no F2 ([README](README.md#contexto)). O catálogo e a máscara de chão já aceitam tipos novos sem mudar o desenho: cada um é uma linha em `ground_types` e uma textura em `client/assets/terrain/grounds/<slug>.png`.

## Escopo

- Os 12 tipos em `ground_types` (ids 9 a 20).
- As 12 texturas, geradas pelo `make_grounds.gd`.

## Fora do escopo

- Mudar o shader, a máscara ou as ferramentas do F2.
- Mudar as 8 texturas de hoje.

## Requisitos

- **RF-01:** a migration `ground_variety`, escrita à mão e aplicada com `migrate deploy`, põe os tipos 9 a 20 com os valores da tabela do [README](README.md#decisões) e acerta a sequência dos ids. A foto `prisma/seed-data/ground_types.json` e o teste do banco que lista os tipos levam os 20.
- **RF-02:** o `make_grounds.gd` gera as 12 texturas em pixel art no estilo das de hoje (poucos tons por textura, sem degradê, 512×512, emendando nas quatro bordas), em 1 pixel de textura por pixel do mapa:
  - **Tábuas de madeira:** tábuas horizontais de 6 px de altura e comprimentos variados, com a fresta escura, o veio e os pregos.
  - **Tijolos:** tijolos vermelhos de 10×5 em fiadas desencontradas, com a argamassa clara e o tom variando por tijolo.
  - **Lajotas:** lajotas quase quadradas de cerca de 16 px, em fileiras desencontradas, de pedra bege e cinza, com brilho em cima e sombra embaixo.
  - **Mármore:** placas grandes de 32×32, brancas e cinza-claro, com veios finos cinza e juntas retas.
  - **Pedra com musgo:** as pedras da trilha de pedra com manchas de musgo verde por cima e entre elas.
  - **Basalto rachado:** placas escuras de basalto, cinza quase preto, com rachaduras finas e um pouco de vermelho escuro nas juntas.
  - **Conchas:** areia batida coberta de conchinhas brancas, rosadas e bege, algumas em leque.
  - **Terra arada:** fileiras horizontais de terra, com o sulco escuro e a leira clara a cada 8 px.
  - **Palha:** fios de palha dourada em várias direções, sobre um fundo amarelo-palha.
  - **Lama:** terra marrom escura e úmida, com poças cinza-azuladas com brilho e marcas de pegada.
  - **Folhas secas:** folhas caídas laranja, marrons e amarelas, com o chão entre elas transparente (aparece o bioma, como nos Pisantes).
  - **Neve pisada:** neve branca azulada com sulcos e pegadas.
- **RF-03:** as ferramentas Chão e Caminho do F2 mostram os 20 tipos na ordem do id, sem mudança no código delas.

## Critérios de aceite

- [x] O catálogo baixado tem os 20 tipos, com a dureza, e o `CatalogValidator` aceita.
- [x] As 12 texturas emendam nas quatro bordas, sem linha visível numa trilha longa.
- [x] As Folhas secas mostram o bioma entre as folhas.
- [x] Os 12 tipos são desenhados pelo mapa do jogo, como piso e como traço.
- [ ] O dono vê os tipos novos no editor (F2).

## Desenho técnico

- **Servidor:** a migration, a foto do `seed-data` (o e2e do catálogo compara as colunas com ela) e o teste do banco que lista os tipos de chão.
- **Cliente:** só os geradores novos no `assets/terrain/grounds/make_grounds.gd` e as 12 texturas. O `HexGrounds` monta o `Texture2DArray` pelo catálogo, e as ferramentas leem os tipos dele.

## Verificação

- **Servidor:** lint, typecheck, os testes de unidade e a suíte e2e inteira antes do commit.
- **Cliente:** uma folha de conferência com as 12 texturas repetidas 2×2 (para ver a emenda) e um print de uma ilha de teste no F2 com cada tipo novo.
- **Projeto:** o jogo sem janela abre sem erros de script.

## Tarefas

- [x] Servidor: a migration, a foto e o teste do banco.
- [x] Arte: os 12 geradores e as texturas.
- [x] Conferência: a folha das texturas e o print do mapa.
- [x] Testes e documentação.

## Resultado da verificação

Em 2026-11-22:

- **Medidas que mudaram na arte:** as tábuas têm 8 px de altura e o tijolo ocupa 16×8 com a junta, em vez de 6 px e 10×5. Com essas medidas, a textura emenda certinho nos 512 px.
- **Servidor:**
  - A migration `20270207000000_ground_variety` foi aplicada com `migrate deploy`.
  - O lint e o typecheck passaram.
  - Nos testes de unidade, o `catalog-tables.spec.ts` esperava os 8 tipos: atualizado, passou (54 de 54). O "a Colina fica de 5% a 15% da terra" estourou os 5 s com a máquina carregada e passou rodando sozinho; ele não lê o chão.
  - Na suíte e2e, 735 de 737 passaram, com o banco e o catálogo dos 20 tipos. Falharam o `species_day_phases` e o `species_skills` do `seed.e2e-spec.ts`: o banco difere da foto do `seed-data` dessas duas tabelas, que esta fase não toca e que não mudam no git há muitos commits.
- **Arte:** o `make_grounds.gd` gerou as 20 texturas. As 8 de antes saíram iguais, byte a byte. A Terra arada (que parecia madeira) e as Folhas secas (que pareciam gravetos) foram refeitas depois da primeira folha de conferência.
- **Print** (na conversa): uma ilha de teste numa cena temporária (já apagada), desenhada pelo `HexMapView` com o catálogo do servidor local, com os pisos pintados em hexágonos e as trilhas como traço de largura 34.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** ver os tipos novos nas ferramentas Chão e Caminho do F2.
