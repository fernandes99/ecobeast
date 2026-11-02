# 07. Rochas no mapa

- **Status:** concluída
- **Depende de:** [06-vegetation](06-vegetation.md)

## Contexto

O mapa já tem plantas, mas nenhuma pedra, e o bioma `stone` quase não tem decoração. O dono quer algumas rochas no mapa, e rochas próprias para o bioma de pedra.

Como as plantas, as rochas são só enfeite, saem do cliente e não mudam regra nenhuma. Elas entram na mesma folha, porque precisam se ordenar com as plantas da mesma linha. Geometria e arquivos estão em [architecture.md](architecture.md#decorações).

## Escopo

- Sete tipos de rocha na folha de decorações.
- As rochas nas receitas de cada superfície.
- A folha passa a se chamar `decorations.png`, e o código passa a falar em decorações.

## Fora do escopo

- Rochas como obstáculo: elas não bloqueiam o jogador.
- Construções, marcos e pontos de interesse.
- Rochas na água.

## Requisitos

- **RF-01:** A folha passa a ser `res://assets/terrain/decorations/decorations.png`, com as mesmas células, e as 10 linhas das plantas não mudam de lugar.
- **RF-02:** Entram 7 linhas, com 4 variantes cada: `pebbles`, `rock`, `mossy_rock`, `brown_rock`, `boulder`, `rock_pile` e `spire`.
- **RF-03:** `temperate` e `hill` ganham `rock` e `pebbles`. `boreal` ganha `mossy_rock` e `pebbles`. `mont` ganha `brown_rock`.
- **RF-04:** `stone` ganha `boulder`, `rock_pile` e `spire`, que só aparecem nele.
- **RF-05:** Rochas seguem as regras das plantas: dependem só da seed, ficam dentro do hexágono, e as grandes deixam livre o centro.
- **RF-06:** Rochas e plantas de uma linha se ordenam juntas, da mais de trás para a mais da frente.
- **RF-07:** `HexDecorations.decorations_of` substitui `plants_of`, e `Decoration` substitui `Plant`.

## Critérios de aceite

- [x] A folha carrega, com 17 linhas e 4 colunas.
- [x] As 10 linhas das plantas continuam iguais à folha anterior, pixel a pixel.
- [x] Cada superfície usa só os tipos da receita dela, e todos eles aparecem.
- [x] `boulder`, `rock_pile` e `spire` só aparecem em `stone`.
- [x] Água continua sem decoração, e parte dos hexágonos de terra fica vazia.
- [x] A ordem na frente e atrás da montanha continua certa.
- [x] Sem as decorações, a tela continua igual às texturas, nos quatro tamanhos.
- [x] Na tela real, contra um servidor de teste, andar e tocar nos vizinhos continuam funcionando.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Alterar**

- `client/assets/terrain/decorations/`: `vegetation.png` vira `decorations.png`.
- `client/ui/components/hex_decorations.gd`: tipos, receitas e o novo nome da classe interna.
- `client/ui/components/hex_map_view.gd`: os novos nomes.
- `.specs/wild-battle/architecture.md`, `README.md` e `client/CLAUDE.md`.

**Reaproveitar**

Toda a escolha e o desenho da [06](06-vegetation.md). A receita de cada superfície continua indo da decoração maior para a menor, para a grande achar lugar.

## Verificação

A verificação da [06](06-vegetation.md) é repetida com os tipos novos, e a tela real também. Uma amostra das capturas é aberta e revisada.

Passos do dono no editor (F5) e no celular:

1. Andar até uma região de pedra e conferir as agulhas, os pedregulhos e os montes.
2. Conferir a quantidade de rochas em cada bioma.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Rochas na folha (RF-01, RF-02).
- [x] Verificação temporária; ver falhar.
- [x] Receitas e novos nomes (RF-03 a RF-07).
- [x] Remover os arquivos temporários; atualizar `architecture.md`, o README da iniciativa e o `client/CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **`mont` ganhou rocha marrom, e não a azulada:** a superfície da montanha é marrom, e a rocha de pedra destoaria.
- **`pebbles` ficou fora do bioma de pedra:** o pedregulho comum é bege, e o bioma tem rochas próprias, azuladas.
- **A folha mudou de nome:** ela deixou de ser só de plantas. Como a ordem das 10 primeiras linhas não mudou, as plantas continuam iguais, conferidas pixel a pixel contra a folha anterior.
- **As rochas são provisórias:** geradas pelo mesmo script da [06](06-vegetation.md), que não foi para o repositório, sem imagem de terceiros.
- **Conferência:** a verificação não compilou antes dos novos nomes. Depois, passou nos quatro tamanhos: 4.000 hexágonos de cada superfície conferidos nas receitas e nos limites, a tela igual às texturas sem as decorações, e a ordem na frente e atrás da montanha.
- **Tela real:** contra um servidor de teste, com o gerador de verdade, passou com 70 de 70 itens nos quatro tamanhos. Uma rodada adicional passou também por uma região de pedra, em 405×720 e 720×1061.
- **Falta do dono:** jogar no editor e no celular, conferir a quantidade de rochas e decidir se as artes ficam. Nenhum celular foi testado.
