# 09. Arremates entre biomas

- **Status:** concluída
- **Depende de:** [08-current-tile](08-current-tile.md)

## Contexto

Dois biomas vizinhos se encontram numa linha reta, a borda do hexágono. No Sandwalkers, a água termina em ondas na costa, a areia avança pelo campo com uma borda irregular, e a areia e o musgo escorrem pelos paredões. O dono quer esse detalhe em cada mudança de bioma e de altura, de forma sutil.

Como as decorações, o arremate é só enfeite e sai do cliente. Geometria e arquivos estão em [architecture.md](architecture.md#arremates).

## Escopo

- Uma folha de arremates, com uma coluna por borda do hexágono e uma linha por material e variante.
- `HexTransitions`, que escolhe os arremates de cada hexágono.
- O desenho dos arremates entre a superfície e o contorno.
- O escorrido: o bioma descendo pelo paredão, em uma folha própria.

## Fora do escopo

- Ondas animadas.
- Escorrido de pedra e de montanha: rocha não escorre.
- Mudar o terreno, o gerador ou o contrato.
- Trocar a grade: o contorno continua por cima de tudo.

## Requisitos

- **RF-01:** Toda divisa entre superfícies diferentes tem um arremate, de um lado só, exceto a divisa entre `wshallow` e `wdeep`, que fica reta: o hexágono de menor posição na ordem abaixo recebe o material do outro.
- **RF-02:** A ordem, de quem recebe para quem avança: água, `temperate`, `boreal`, `hill`, `stone`, `mont`.
- **RF-03:** Água ao lado de terra recebe espuma e ondas, em vez do material da terra.
- **RF-04:** Água rasa e funda não têm arremate entre si, a pedido do dono.
- **RF-05:** Cada material de terra tem um recorte próprio e discreto, sem linha nem sombra: grama em pontas curtas, solo seco irregular, e pedra e rocha em blocos baixos. A borda se desfaz em pontilhado.
- **RF-06:** O arremate fica dentro do hexágono que o recebe, junto da borda, e deixa o centro livre.
- **RF-07:** Terra com um vizinho mais alto na frente não recebe arremate nessa borda: a borda de cima dele já fecha a divisa. Água recebe, e a espuma sobe a diferença de altura, para encostar nela.
- **RF-08:** A borda do mapa não tem arremate.
- **RF-09:** A variante sai da seed do mapa, da coordenada e da borda, e a mesma seed repete os mesmos arremates.
- **RF-10:** Um hexágono de superfície desconhecida não quebra o mapa: ele só não entra na ordem.
- **RF-11:** Todo paredão de `temperate`, `boreal` e `hill` tem o bioma escorrendo de cima para baixo: musgo em tufos e fios, e areia em lóbulos com grãos soltos.
- **RF-12:** O escorrido nunca passa do pé do paredão. Um paredão baixo usa a versão curta.
- **RF-13:** O escorrido acompanha a inclinação da borda, e a face da direita continua mais escura.

## Critérios de aceite

- [x] A folha carrega, com 6 colunas e todas as linhas.
- [x] Cada material e cada borda têm pixels só dentro do hexágono, a até 9 px da borda.
- [x] A folha do escorrido carrega, e a versão curta cabe em um paredão de 8 px.
- [x] Campo, floresta e colina escorrem nos paredões, e pedra, montanha e água não.
- [x] O escorrido só muda pixels do paredão, nunca da superfície.
- [x] Água ao lado de terra recebe espuma, e a terra não recebe nada da água.
- [x] Cada par de superfícies diferentes tem exatamente um lado com arremate, e água rasa e funda não têm nenhum.
- [x] Hexágonos iguais e a borda do mapa não têm arremate.
- [x] Terra atrás de um vizinho mais alto não tem arremate nas duas bordas de baixo dela, e a água mantém a espuma.
- [x] A mesma seed repete os arremates, e outra seed muda.
- [x] Sem os arremates e as decorações, a tela continua igual às texturas, nos quatro tamanhos.
- [x] Com os arremates, o centro dos hexágonos continua igual às texturas.
- [x] A ordem na frente e atrás da montanha continua certa.
- [x] Na tela real, contra um servidor de teste, andar e tocar nos vizinhos continuam funcionando.
- [x] Montar uma linha continua abaixo de 16 ms no computador de desenvolvimento.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/assets/terrain/transitions/transitions.png` e `drips.png`, com `mipmaps/generate=true`.
- `client/ui/components/hex_transitions.gd`: `HexTransitions`, com `transitions_of(tile, map)` e `drip_cell(tile, edge, height, map_seed)`.

**Alterar**

- `client/ui/components/hex_map_view.gd`: uma malha de arremates por linha, antes do contorno, e uma de escorrido, depois dos paredões.
- `.specs/wild-battle/architecture.md`, `README.md` e `client/CLAUDE.md`.

**Reaproveitar**

A escolha pura e a folha da [06](06-vegetation.md). Como os arremates usam uma folha só, cada linha ganha uma malha, não uma por material.

## Verificação

A verificação da [08](08-current-tile.md) é repetida com os arremates, e a tela real também. Uma amostra das capturas é aberta e revisada.

Passos do dono no editor (F5) e no celular:

1. Andar pela costa e conferir as ondas.
2. Conferir as divisas entre campo, floresta, colina, pedra e montanha.
3. Conferir o escorrido nos paredões de campo, floresta e colina.
4. Dizer se algum arremate pesa ou esconde a grade.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Verificação temporária; ver falhar.
- [x] Folha de arremates (RF-03 a RF-06).
- [x] `HexTransitions` e o desenho na linha (RF-01, RF-02, RF-07 a RF-10).
- [x] Remover os arquivos temporários; atualizar `architecture.md`, o README da iniciativa e o `client/CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **Uma folha em vez de um recorte na textura do bioma:** mascarar a própria textura pediria um shader e uma malha por material em cada linha. Com a folha, cada linha ganha uma malha só, e a diferença não aparece no recorte estreito.
- **Sem arremate atrás de um hexágono mais alto:** o recorte subia junto com a borda do vizinho e ficava solto no chão de trás. O dono pediu para tirar. A espuma ficou, porque é a água batendo na terra, e sem ela toda costa virada para o sul viraria uma linha reta.
- **Sem arremate entre água rasa e funda:** o dono pediu para tirar. A arte saiu da folha, e a água saiu da ordem, porque ela só recebe.
- **A primeira versão pesava:** tinha linha escura, sombra, espuma grossa e até 15 px de recorte. O dono achou forte demais, e o recorte caiu para cerca de um terço, sem linha nem sombra. A crista virou um contorno de 1 px, translúcido.
- **Escorrido na mesma fase:** ele nasceu do mesmo pedido, a referência da areia e do musgo caindo, e a fase ainda não tinha sido fechada.
- **Pedra e montanha não escorrem:** rocha não escorre, e o paredão delas já tem borda própria. Decisão do planejamento, fácil de mudar em `DRIP_ROWS`, com uma linha nova na folha.
- **Duas versões do escorrido:** um paredão de 8 px, o mais comum, cortaria o escorrido longo no pé. A versão curta cabe nele inteira.
- **Lóbulos por borda:** cada recorte afina até 1,5 px nos cantos. Duas bordas seguidas formam dois lóbulos, como na referência, sem linhas se cruzando.
- **`hill` avança sobre o campo e a floresta:** é o caso da areia sobre o verde, da referência. A ordem é _a revisar_.
- **A arte é provisória:** gerada por um script que não foi para o repositório, a partir das texturas do projeto, sem imagem de terceiros.
- **Conferência:** a verificação não compilou antes de `HexTransitions`. Depois, passou nos quatro tamanhos: todos os pares de superfícies nas seis bordas, nenhum pixel da folha fora do hexágono ou além de 9 px da borda, a tela igual às texturas sem os arremates, o centro livre com eles, e o escorrido só nos paredões.
- **Desempenho:** em um mapa de 10.000 hexágonos, no computador de desenvolvimento, com o computador livre, uma linha leva de 7 a 10 ms em média e de 9 a 14 ms na pior, a montagem inicial leva de 200 a 270 ms, e cada quadro, de 0,6 a 1,6 ms, com 187 chamadas de desenho. Uma medição logo depois de outra carga deu 16,5 ms na pior linha, e até a parte que não mudou ficou 33% mais lenta.
- **Tela real:** contra um servidor de teste, com o gerador de verdade, passou com 74 de 74 itens em 360×640 e 720×1061, com a arte final. Em 405×720 e 412×915, passou com 73 de 73 na versão anterior da arte, antes do escorrido, e não foi repetida.
- **Um toque "fora do mapa" pode cair em um vizinho:** uma rodada em 360×640 falhou nessa conferência, e duas repetições passaram. O mapa é sorteado, e a causa provável é um vizinho alto cobrindo o ponto tocado, o que é o comportamento certo. Nem o toque nem `coord_at` mudaram nesta fase, e a conferência passou a aceitar esse caso. O caso exato não foi reproduzido.
- **Falta do dono:** jogar no editor e no celular, dizer se algum arremate pesa e decidir se a arte fica. Nenhum celular foi testado.
