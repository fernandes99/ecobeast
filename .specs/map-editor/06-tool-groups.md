# 06. As ferramentas em grupos

- **Status:** concluída (falta o dono usar)
- **Depende de:** [05-editor-ux](05-editor-ux.md) e [free-trails/04](../free-trails/04-path-tool.md)

## Contexto

Desde a [05](05-editor-ux.md), cada ferramenta é um botão numa coluna ao lado do painel. Com a Borracha (free-props/05) e o Caminho (free-trails/04), a coluna chegou a 12 botões. As teclas só iam de 1 a 9, então a Borracha, o Carimbo e o Caminho só abriam pelo botão. Em 2026-11-14, o dono pediu: "ta tendo muita opção no menu de ferramentas, deixe mais organizado, agrupe e crie subopções ou submenus para as ferramentas que são parecidas".

Claude propôs 4 grupos na coluna, com as subferramentas em abas no topo do painel. O dono aprovou ("Ok, pode seguir"). Os outros jeitos pensados foram:
- **um submenu que abre ao segurar o botão:** esconde demais;
- **grupos que abrem e fecham na própria coluna:** a coluna continua longa.

## Escopo

- A coluna com os 4 grupos.
- As abas das subferramentas no topo do painel.
- As teclas 1 a 4.

## Fora do escopo

- Mudar o que cada ferramenta faz ou o painel dela.
- Mudar o topo da janela (Ilhas, desfazer, Camadas, Salvar).

## Requisitos

- **RF-01:** a coluna tem 4 botões de grupo, cada um com um ícone e o número da tecla:

  | Tecla | Grupo | Ícone | Subferramentas, nesta ordem |
  | --- | --- | --- | --- |
  | 1 | Terreno | `biome` | Bioma, Altura, Pôr hexágono, Tirar hexágono |
  | 2 | Chão | `ground` | Chão, Caminho |
  | 3 | Peças | `object` | Peças, Carimbo, Borracha |
  | 4 | Jogo | `flag` | Chegada, Ação, Área |

  O botão mostra o nome do grupo embaixo do ícone (a coluna passou de 58 para 76 px), e a dica diz a tecla e as subferramentas dele.
- **RF-02:** o topo do painel mostra as abas do grupo escolhido, uma por subferramenta, com o ícone e o nome de hoje, e a escolhida marcada. Clicar numa aba escolhe a ferramenta.
- **RF-03:** o título do painel passa a ser "Tecla · Grupo · Ferramenta" (por exemplo, "1 · Terreno · Bioma"), sem repetir o nome quando os dois são iguais ("3 · Peças"), com a dica de hoje embaixo.
- **RF-04:** cada grupo lembra a última subferramenta escolhida nele. Ao abrir, o editor começa no Terreno, no Bioma.
- **RF-05:** as teclas:
  - **1 a 4:** escolhem o grupo, na subferramenta que ele lembra;
  - **a tecla do grupo que já está aberto:** passa para a próxima subferramenta dele e volta à primeira depois da última;
  - **5 a 9:** não fazem mais nada.

  As outras teclas não mudam: Shift+0 a 9, [ e ], H, Ctrl+Z e as da ferramenta escolhida.
- **RF-06:** tudo que hoje escolhe uma ferramenta por conta própria passa a escolher também o grupo dela. Por exemplo, a amostra de bioma leva ao Bioma, e a de chão leva ao Chão.
- **RF-07:** nada muda no que cada ferramenta faz, no painel dela, no nome do passo de desfazer nem na ordem interna (`EditorTools.Tool`).

## Critérios de aceite

- [x] A coluna tem 4 botões, e cada grupo mostra as abas certas.
- [x] As teclas 1 a 4 escolhem o grupo, a mesma tecla de novo passa à próxima aba, e a Borracha, o Carimbo e o Caminho abrem pelo teclado.
- [x] Um grupo lembra a última subferramenta.
- [x] A amostra de bioma ou de chão leva ao grupo e à aba certos.
- [ ] O dono usa o editor (F2) com os grupos.

## Desenho técnico

- `tools/map_editor/editor_tools.gd`:
  - `GROUPS`: o nome, o ícone e as ferramentas de cada grupo;
  - `group_of(tool)` e `_last_in_group`;
  - `set_group(index)` e `press_group_key(index)`, que passa à próxima subferramenta quando o grupo já está aberto;
  - a coluna com os 4 botões e as abas no topo do painel, refeitas no `_refresh`.
- `tools/map_editor/map_editor.gd`: as teclas 1 a 4 chamam `press_group_key`.

## Verificação

- **Teste sem janela** numa cena temporária, que falha antes e passa depois:
  - os 4 grupos cobrem as 12 ferramentas, cada uma uma vez só;
  - a tecla do grupo aberto passa à próxima subferramenta e volta à primeira;
  - o grupo lembra a última subferramenta;
  - a amostra de chão leva ao grupo Chão.
- **Print:** o editor com o grupo Peças aberto.
- **Projeto:** o jogo sem janela abre sem erros de script, com os mesmos avisos de antes.

## Tarefas

- [x] Spec.
- [x] Os grupos, as abas e as teclas.
- [x] Teste, print e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste sem janela** (uma cena temporária, já apagada): falhou antes (sem `GROUPS`) e passou depois, com 11 de 11:
  - os 4 grupos cobrem as 12 ferramentas, uma vez cada, e a coluna tem 4 botões;
  - o editor começa no Terreno, no Bioma;
  - a tecla do grupo aberto passa à próxima subferramenta e volta à primeira;
  - a Borracha e o Caminho abrem pelo teclado;
  - o grupo lembra a última subferramenta;
  - a amostra de chão leva ao grupo Chão, que tem 2 abas.
- **Prints** (na conversa): a janela do editor com o grupo Peças e com o Terreno. No primeiro print, a coluna só mostrava o número e o título repetia "Peças · Peças". Os botões passaram a mostrar o nome do grupo, e o título, a tecla.
- **Projeto:** o jogo sem janela abre sem erros de script, com os mesmos avisos de antes. A variável `group` nova fazia três parâmetros antigos (`group: ButtonGroup`) darem aviso; eles viraram `button_group`.
- **Falta o dono:** usar o editor (F2) com os grupos.
