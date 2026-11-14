# 04. Os carimbos

- **Status:** concluída (falta o dono usar no editor)
- **Depende de:** [03](03-pieces-tool.md)

## Contexto

O [README](README.md) decidiu que o conjunto pronto é um **carimbo**: um modelo que, ao ser posto, vira objetos, peças soltas e chão comuns, que o dono ajusta depois. Ele vive só no editor, como arquivo; o jogo e o servidor nunca o veem. A praça da referência do dono tem uma fonte, e não existe arte de fonte.

## Escopo

- A ferramenta Carimbo no editor: escolher uma área, guardá-la como carimbo e pôr um carimbo, espelhado ou não.
- O objeto Fonte, com arte provisória.
- Os dois primeiros carimbos: a casa com quintal e a praça com a Fonte.

## Fora do escopo

- Apagar ou renomear um carimbo pelo editor: é um arquivo, e o dono apaga na pasta.
- O bioma e a altura no carimbo (veja RF-02).
- O pincel e as trilhas contínuas.

## Requisitos

- **RF-01:** A ferramenta 10 se chama "Carimbo" (só pelo botão: as teclas 1 a 9 continuam nas 9 de antes). O painel tem dois modos: **Pôr** e **Escolher área**.
- **RF-02:** Em Escolher área, o pincel marca hexágonos da ilha com o botão esquerdo e desmarca com o direito, com o tamanho do pincel. A área marcada fica contornada. Com um nome (de 1 a 40 caracteres) e "Guardar carimbo", o editor grava `client/tools/map_editor/stamps/<slug>.json` com, a partir do hexágono marcado mais perto do meio da área (o de apoio):
  - o chão de cada hexágono marcado (trilha, piso ou nenhum);
  - os objetos com todos os hexágonos dentro da área;
  - as peças soltas com o pé num hexágono marcado.

  O carimbo não leva bioma nem altura: posto, ele fica por cima do terreno de onde for posto. Decisão de Claude. Um nome que já existe troca o carimbo de antes. O nome do arquivo é o nome sem acento, em minúsculas, com `_` no lugar do resto (`Stamp.slug_of`).
- **RF-03:** Em Pôr, o painel lista os carimbos da pasta. Com um escolhido, o contorno sob o ponteiro mostra os hexágonos dele, com o de apoio no ponteiro: verde se todos são da ilha, amarelo se algum não é. O clique esquerdo põe:
  - nos hexágonos dele que são da ilha, o chão do carimbo troca o chão (mesmo vazio), e os objetos que ocupam algum deles saem;
  - entram os objetos do carimbo com todos os hexágonos na ilha e as peças com o pé num hexágono da ilha;
  - as peças soltas que já estavam ficam.

  Tudo é um passo só de desfazer. As peças postas não ficam escolhidas. Uma peça espelhada com o pé bem na divisa de dois hexágonos anda 1 pixel para dentro do dela, porque a divisa desempata pelo lado e o espelho cairia no vizinho.
- **RF-04:** M espelha o carimbo antes de pôr: os hexágonos, os objetos e as peças viram na horizontal em volta do de apoio, e cada objeto e peça troca o próprio espelho.
- **RF-05:** O tipo de objeto Fonte (`fountain`, id 40, 1 hexágono, bloqueia, 1 variante) entra no catálogo, com arte do `make_town.gd` no estilo do [guia](../town-art/style-guide.md).
- **RF-06:** A pasta traz dois carimbos, montados por Claude no editor com a arte que já existe: `casa_com_quintal` (uma casa média da cidade, uma horta, flores, arbustos e o chão de terra na frente) e `praca_com_fonte` (7 hexágonos de piso de pedra, a Fonte no meio, bancos, postes e canteiros).

## Critérios de aceite

- [x] Guardar uma área com chão, um objeto dentro, um objeto metade fora e peças: o carimbo leva o chão, o objeto de dentro e as peças.
- [x] Pôr esse carimbo em outro lugar, espelhado e não: o chão, os objetos e as peças aparecem na posição certa; um objeto que estava lá sai; as peças de antes ficam; Ctrl+Z desfaz tudo de uma vez.
- [x] Pôr na beira da ilha: só entra o que cabe.
- [x] Os dois carimbos aparecem na lista e se põem numa ilha.
- [ ] O dono põe os carimbos numa ilha e vê com F5.

## Desenho técnico

**Criar:**

- `client/tools/map_editor/stamp.gd` (`class_name Stamp`, funções estáticas): `capture(draft, coords, name)`, `targets(stamp, anchor, flip)`, `place(draft, stamp, anchor, flip)`, `list()` e `save(stamp)`.
- `client/tools/map_editor/stamp_panel.gd` (`class_name StampPanel`): os dois modos, a lista, o espelho, a área marcada, o nome e o guardar.
- `client/tools/map_editor/icons/stamp.svg` e `client/tools/map_editor/stamps/*.json`.
- A migration `free_props_fountain`, com a Fonte.

**Alterar:** `editor_tools.gd` (a ferramenta e o pôr como um passo), `editor_canvas.gd` (o contorno da área marcada), `map_editor.gd` (o pôr e as teclas), `make_town.gd` (a Fonte), a carga do catálogo e os testes que contam os objetos.

**Formato do carimbo:**

```json
{
  "name": "Praça com fonte",
  "tiles": [{ "dq": 0, "dr": 0, "ground": "cobble_floor" }],
  "objects": [{ "object_type_id": 40, "dq": 0, "dr": 0, "variant": 1, "mirrored": false, "tiles": [{ "dq": 0, "dr": 0, "blocks": true }] }],
  "props": [{ "prop_type_id": 21, "dq": 1, "dr": 0, "dx": 0, "dy": 6, "variant": 1, "mirrored": false }]
}
```

Os `dq` e `dr` são a partir do hexágono de apoio, e o `dx` e `dy` da peça a partir do centro do hexágono dela, como no rascunho.

## Verificação

- Um teste sem janela do `Stamp`: guardar (o que entra e o que fica de fora), pôr com e sem espelho, pôr na beira, e o passo de desfazer.
- Os e2e do catálogo com a Fonte.
- Um print do editor com os dois carimbos postos e o contorno de um carimbo sob o ponteiro, e um da ilha no jogo.
- O jogo sem janela abre sem erros de script.

## Tarefas

- [x] Spec.
- [x] A Fonte.
- [x] O `Stamp`, com o teste.
- [x] A ferramenta Carimbo.
- [x] Os dois carimbos.
- [x] Testes, prints e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste sem janela do `Stamp`** (uma cena temporária, já apagada, contra o servidor novo numa porta à parte): falhou antes (sem a classe) e passou depois, com 22 de 22. A Fonte está no catálogo com o id 40; guardar uma área de 5 hexágonos levou o chão de cada um (até o vazio), o objeto de dentro e não o que tinha um hexágono fora, e as 2 peças de dentro, com o apoio no do meio; pôr em outro lugar trocou o chão, tirou o objeto que estava lá, deixou o de longe e as peças de antes, e pôs a peça na posição certa; espelhado, o chão, o objeto e as peças foram para o outro lado, trocando o espelho; na beira, entraram só os 3 hexágonos e a peça que cabiam; e guardar e listar numa pasta deram o arquivo com o nome sem acento.
- **Os dois carimbos:** montados pela própria ferramenta, marcando a área no modo Escolher área e guardando: `praca_com_fonte` (7 hexágonos) e `casa_com_quintal` (6). Postos numa ilha nova pela ferramenta (a praça e duas casas, uma espelhada), com um passo de desfazer por carimbo (5 objetos, 3 desfeito o último, 5 refeito). Os prints, do editor com a lista e do mapa como o jogo desenha, com o Domador na praça, estão na conversa.
- **Servidor:** uma ilha com 20 carimbos postos, metade espelhados (9 objetos e 143 peças), foi aceita pelo servidor local e apagada. Os testes de unidade (804) e o lint passaram; a migration da Fonte foi aplicada, e o teste da carga do catálogo falhou antes dela e passou depois. A suíte e2e inteira passou: 495 de 495.
- **Projeto:** o jogo sem janela abre sem erros de script e com os mesmos 9 avisos de antes. Na primeira tentativa, o `StampPanel` ainda não estava no cache de classes e o projeto não abria; o `--import` resolveu.
- **Falta o dono:** pôr os carimbos numa ilha no editor (F2, ferramenta 10) e ver com F5.
