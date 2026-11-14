# 05. As decorações naturais de volta

- **Status:** concluída (falta o dono usar no editor e no jogo)
- **Depende de:** [04](04-stamps.md) e [terrain-height/03](../terrain-height/03-height-visibility.md)

## Contexto

O [README](README.md) decidiu que as ilhas deixariam de ter decorações sorteadas e mostrariam só o que o dono põe. Em 2026-11-14, o dono mostrou uma ilha pintada no editor, só com grama, e pediu as decorações de volta:

- **No gerador e na pintura:** "eu quero que seja gerado as decorações também! Pelo menos aquelas que são só visuais e naturais", e "toda vez que eu for também preencher manualmente um bioma, eu quero que seja criado também automaticamente as decorações naturais daquela bioma, como estava antes".
- **Para apagar:** uma ferramenta "que seja rápida, como um pincel e não ir selecionando uma por uma".

Claude mostrou dois jeitos:

- **A:** o sorteio de antes, com uma marca por hexágono que a borracha desliga.
- **B:** cada decoração vira uma peça solta guardada no banco.

Na B, uma ilha de 1.200 hexágonos teria uns 4.500 itens, perto do limite de 6.000 peças, e uma ilha grande passaria das dezenas de milhares. O dono escolheu a A.

Hoje:

- O `HexDecorations.decorations_of(tile, seed)` sorteia as decorações de um hexágono pelo bioma, sempre iguais para a mesma seed e o mesmo hexágono.
- O `HexMapView` não sorteia quando `random_decorations` é falso. O jogo deixa assim nas ilhas, e o editor sempre.
- Hexágono com objeto não ganha decoração, e trilha ou piso só deixam as que cabem neles (`HexGrounds.allows_decoration`).
- A seed de uma ilha é o id dela, no jogo e no editor.

## Escopo

- A marca "sem decorações" em cada hexágono, no banco, no contrato do editor e de Explorar, e no jogo.
- As decorações naturais sorteadas de volta nas ilhas, no jogo e no editor.
- A ferramenta Borracha no editor.
- O Bioma, o Pôr hexágono e o carimbo cuidando da marca.

## Fora do escopo

- Guardar cada decoração sorteada, para mover ou apagar uma só (a opção B). Para isso, o dono apaga o hexágono com a Borracha e põe peças soltas.
- Sortear de novo as decorações de um hexágono sem trocar o bioma.
- Mudar as receitas de cada bioma (`HexDecorations.RECIPES`).
- O mapa sorteado de Explorar zona, que continua como está.

## Requisitos

- **RF-01:** Cada hexágono de ilha tem a marca `bare` (sem decorações naturais), falsa por padrão.
  - **No banco:** a coluna `bare boolean NOT NULL DEFAULT false` em `island_tiles`.
  - **No contrato:** o editor manda e recebe `bare: true` só nos hexágonos marcados, e o hexágono sem o campo vale falso. A resposta de Explorar numa ilha manda o campo do mesmo jeito.
  - **No hash:** o `content_hash` leva a marca só quando ela é verdadeira, então uma ilha sem marcas tem o mesmo hash de antes.
- **RF-02:** No jogo e no editor, um hexágono de ilha sem a marca mostra as decorações sorteadas do bioma dele, como no mapa sorteado, com a seed da ilha. As regras de antes continuam:
  - hexágono com objeto não tem decoração;
  - trilha e piso só deixam as que cabem neles.

  Com a marca, o hexágono não tem decoração sorteada. As peças soltas aparecem sempre, com ou sem a marca. Uma ilha nova ainda não salva tem o id 0, então as decorações dela mudam uma vez, ao salvar pela primeira vez.
- **RF-03:** Os hexágonos que nascem no editor vêm sem a marca: os da ilha em branco, os do gerador e os de Pôr hexágono. O Bioma tira a marca de todo hexágono que pinta, mesmo que o bioma seja o mesmo, e as decorações sorteadas passam a ser as do bioma dele. As peças soltas do hexágono ficam.
- **RF-04:** A ferramenta 11 se chama "Borracha" e funciona só pelo botão, como o Carimbo, com o pincel e o tamanho dele.
  - **O botão esquerdo** põe a marca nos hexágonos do pincel e apaga as peças soltas com o pé neles.
  - **O botão direito** tira a marca e devolve as decorações sorteadas, sem trazer de volta as peças apagadas.
  - **Não apaga:** objetos, chão, bioma nem altura.
  - **Com o corte de altura:** respeita o corte da [terrain-height/03](../terrain-height/03-height-visibility.md).
  - **Desfazer:** cada pincelada é um passo de desfazer, com a marca e as peças.
- **RF-05:** O carimbo guarda a marca de cada hexágono (`bare`) e, ao ser posto, a escreve nos hexágonos dele. Os carimbos sem o campo, como os dois que já existem, entram com a marca, porque foram montados numa ilha sem decorações.
- **RF-06:** O `IslandDraft` leva a marca no `snapshot` e no `restore`, para o desfazer de qualquer ferramenta.

## Critérios de aceite

- [x] Uma ilha gerada, uma em branco e um bioma pintado mostram as decorações do bioma, no editor e no jogo.
- [x] A Borracha apaga as decorações e as peças soltas dos hexágonos do pincel, e o botão direito devolve as decorações. Ctrl+Z desfaz a pincelada inteira.
- [x] Salvar e abrir de novo mantém a marca. O servidor recusa um `bare` que não seja booleano.
- [x] Um carimbo antigo entra sem decorações, e um guardado com hexágonos decorados as mantém.
- [ ] O dono pinta biomas e usa a Borracha no editor (F2) e vê a ilha com F5.

## Desenho técnico

**Servidor:**

- A migration `free_props_bare_tiles`, escrita à mão e aplicada com `migrate deploy`: a coluna `bare`. No `schema.prisma`, o campo `bare Boolean @default(false)` no `IslandTile`.
- `domain/islands/island-draft.ts`: `bare?: boolean` no hexágono, conferido como booleano, e no formato canônico só quando verdadeiro.
- `editor/islands-editor.dto.ts` e `.service.ts`: o campo opcional na entrada e na gravação.
- `islands/islands.service.ts` (leitura da versão), `exploration/exploration.dto.ts` e `.service.ts`: a marca na resposta, só quando verdadeira.
- Os testes: a validação (`island-draft.spec.ts`), o banco (`database.e2e-spec.ts`, se ele contar as colunas) e os e2e das ilhas e do editor.

**Cliente:**

- `domain/models/hex_tile.gd`: `bare`, lido do campo opcional.
- `ui/components/hex_map_view.gd`: some o `random_decorations`. O `_add_decorations` pula o sorteio num hexágono com a marca. O jogo e o editor deixam de desligar o sorteio.
- `tools/map_editor/island_draft.gd`: a marca no `to_dict`, no `_read_terrain`, no `snapshot` e no `restore`.
- `tools/map_editor/editor_tools.gd`: `Tool.ERASER`, o nome, o ícone (`icons/eraser.svg`) e a dica; o Bioma tira a marca; a Borracha no `_change`, com as peças do hexágono e o `props_before` do passo.
- `tools/map_editor/map_editor.gd`: a Borracha refaz os hexágonos e as peças.
- `tools/map_editor/stamp.gd`: a marca no `capture` e no `place`.

## Verificação

- **Servidor:** os testes de unidade da validação, vendo falhar antes, e a suíte e2e inteira antes do commit, porque o servidor muda.
- **Cliente, um teste sem janela** numa cena temporária, que falha antes e passa depois:
  - o hexágono com e sem a marca, nas decorações;
  - o Bioma tirando a marca;
  - a Borracha com os dois botões e o desfazer;
  - o carimbo antigo e o novo;
  - a ida e volta da marca pelo servidor local.
- **Prints:** o editor com uma ilha gerada decorada e uma faixa apagada pela Borracha, e o jogo na mesma ilha.
- **Projeto:** o jogo sem janela abre sem erros de script, com os mesmos avisos de antes.

## Tarefas

- [x] Spec.
- [x] Servidor: a coluna, o contrato e os testes.
- [x] Jogo: a marca e o sorteio de volta nas ilhas.
- [x] Editor: a Borracha, o Bioma, o desfazer e o carimbo.
- [x] Testes, prints e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Servidor:**
  - **Testes de unidade:** os da validação falharam antes (a marca não booleana passava, e o hash não mudava com ela) e passaram depois. Os de unidade inteiros deram 807 de 807, e o lint e o typecheck passaram.
  - **Banco:** a migration `20261122000000_free_props_bare_tiles` foi aplicada com `migrate deploy`, e o `migrate diff` saiu vazio.
  - **e2e das ilhas:** o editor salva e lê a marca só no hexágono marcado e recusa `bare: "sim"` com "bare precisa ser verdadeiro ou falso.". Explorar numa ilha manda a marca só no hexágono marcado. A suíte e2e inteira passou: 497 de 497.
- **Cliente, teste sem janela** (uma cena temporária, já apagada): falhou antes (sem `Tool.ERASER`) e passou depois, com 19 de 19.
  - **O hexágono e o mapa:** o hexágono lê a marca. A ilha sem marca desenha as decorações do bioma, e com a marca não desenha nenhuma.
  - **O rascunho:** manda a marca só quando é verdadeira e a lê de volta. O desfazer a leva, e a ilha em branco vem decorada.
  - **A Borracha:** marca os hexágonos do pincel e apaga as peças com o pé neles. Ctrl+Z desfaz a pincelada inteira, e refazer a volta. O botão direito devolve as decorações sem as peças, e o corte de altura é respeitado.
  - **O Bioma** tira a marca, mesmo com o mesmo bioma.
  - **O carimbo:** guarda a marca e a escreve ao ser posto, e um carimbo sem o campo entra sem decorações.
- **Print** (na conversa): uma ilha com Colina, Planície e Boreal, decorada, com uma faixa diagonal limpa pela Borracha.
- **Projeto:** o jogo sem janela abre sem erros de script e com os mesmos 9 avisos de antes.
- **Falta o dono:** pintar biomas e usar a Borracha no editor (F2, ferramenta 11) e ver a ilha com F5.
