# 03. A ferramenta Bloqueios

- **Status:** concluída (falta o dono usar)
- **Depende de:** [02](02-variant-blocks.md)

## Contexto

Hoje o editor só edita o bloqueio da peça escolhida, pelo cadeado. O dono quer o controle de todos os bloqueios numa ferramenta ([README](README.md#decisões)).

## Escopo

- A ferramenta Bloqueios, com o painel dela, como na [arquitetura](architecture.md#a-ferramenta-bloqueios).

## Fora do escopo

- Desenhar o padrão de um tipo fora do mapa.

## Requisitos

- **RF-01:** A ferramenta **Bloqueios** entra no grupo Peças, depois de Vegetação, com o ícone `blocks`. A dica: "Edita as linhas de bloqueio de qualquer peça. Botão direito apaga um ponto."
- **RF-02:** Com ela, as linhas de todas as peças aparecem com os pontos, e o botão esquerdo, o direito e o Esc fazem o que a [arquitetura](architecture.md#a-ferramenta-bloqueios) diz.
- **RF-03:** O painel mostra a peça escolhida e os botões. Sem peça, mostra "Clique num ponto ou numa peça".
- **RF-04:** Cada mudança é um passo do desfazer, e salvar o padrão pergunta antes, como no cadeado.

## Critérios de aceite

- [x] Sem janela, arrastar o ponto de uma peça não escolhida a escolhe, a deixa ajustada e vira um passo do desfazer.
- [x] Sem janela, o botão direito apaga o ponto e clicar num trecho põe um.
- [ ] No editor aberto (F2), a ferramenta mostra os pontos e salva o padrão de uma variante.

## Desenho técnico

**Alterar:** `res://tools/map_editor/editor_tools.gd`, `object_panel.gd`, `editor_canvas.gd`, `map_editor.gd` e o ícone `res://tools/map_editor/icons/blocks.svg`.

## Verificação

```bash
godot --headless --path client --quit-after 30
```

À mão (F2): editar e salvar bloqueios com a ferramenta.

## Tarefas

- [x] A ferramenta e o painel.
- [x] A cena temporária.
- [ ] O passo à mão, com o dono.

## Resultado da verificação

Em 2026-11-15, numa cena temporária sem janela (apagada), com o `EditorTools`, o `ObjectPanel` e o `BlocksPanel` de verdade numa Pedra bege grande:

- **A ferramenta:** está no grupo Peças, depois de Vegetação. Sem peça escolhida, o painel mostra "Clique num ponto ou numa peça.".
- **Arrastar:** apertar um ponto escolhe a pedra e liga a edição. Arrastar deixa a pedra ajustada, com o ponto onde o ponteiro foi, e vira um passo do desfazer. O painel passa a mostrar "variante 1 · ajustada".
- **Pôr e tirar pontos:**
  - o botão direito apaga um ponto;
  - clicar no meio de um trecho põe um ponto;
  - "Usar o padrão" volta às linhas da variante.
- **Soltar:** clicar longe de linha e de peça solta a peça, e trocar de ferramenta desliga a edição.
- **Compilação:** o editor abre sem erros de script nem avisos novos.
- **Escolhas na implementação:**
  - A ferramenta procura a linha mais perto entre as peças a até 3 hexágonos do clique.
  - Clicar perto de um ponto o pega antes do trecho, como no cadeado. Num trecho de menos de 12 px, isso pega a ponta.
- **Falta o dono:** usar a ferramenta no editor aberto (F2).
