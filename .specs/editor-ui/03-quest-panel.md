# 03. A ferramenta Missões

- **Status:** concluída
- **Depende de:** [auralis/07](../auralis/07-quest-editor.md) e [auralis/10](../auralis/10-quest-dialogues.md)

## Contexto

Em 2026-11-24, o dono pediu: "Agora a tela de editar missão eu quero melhorar, a usabilidade ta ruim lá, consegue deixar melhor a interface e o ux? Eu não tenho algo especifico, é mais geral." Claude listou o que pesa, e o dono respondeu: "Pode seguir direto".

Os problemas da ferramenta Missões (o `QuestPanel` e o `QuestDialogueEditor`), na coluna de 430 px do F2:

- **Tudo numa coluna só.** O número de missões que abrem a próxima ilha, a lista, o formulário, as conversas e o Salvar ficam um embaixo do outro. Numa missão com conversa, o Salvar fica lá no fim, a muitas rolagens do topo.
- **Todo botão tem o mesmo peso.** Cada fala e cada escolha tem ↑, ↓ e ✕ grandes e azuis, iguais ao Salvar. A opção de uma escolha tem só 14 px de recuo, e não se vê onde ela termina.
- **A fala ocupa o espaço errado.** A lista de quem fala ocupa a linha toda, a caixa do texto é pequena, e não se vê o limite de 300 letras nem em quantas caixas a fala vai virar (auralis/10, a regra dos parágrafos).
- **Pouca informação à vista.** A lista mostra só "1. Derrote 1 Puffcoo"; a recompensa só aparece ao passar o mouse, e as abas Início, Durante e Fim não dizem qual tem conversa.
- **Perder o que foi editado.** Cancelar joga fora as mudanças sem perguntar.
- **Rótulos desalinhados.** "Item de recompensa" não cabe nos 120 px do rótulo, e o campo dele começa mais à direita que os outros.

## Escopo

- O `QuestPanel` (`client/tools/map_editor/quest_panel.gd`) e o `QuestDialogueEditor` (`client/tools/map_editor/quest_dialogue_editor.gd`).
- Nada muda no servidor, nas rotas, nos limites nem no que a missão faz no jogo.

## Requisitos

### A lista

- **RF-01:** Sem missão aberta, a ferramenta mostra só a lista. No topo, a linha "Para abrir a próxima ilha" com o número, o "de N" (N = as missões que contam) e um Salvar pequeno, com a dica "0 = todas as que contam".
- **RF-02:** As missões ficam agrupadas pelo NPC que dá. O cabeçalho de cada grupo tem o nome, "fora do mapa" quando ele só está numa sala e o botão "+ Missão", que abre uma missão nova já com esse NPC. O "Nova missão" de baixo continua.
- **RF-03:** Cada missão é um cartão: na primeira linha, o número e o título, que abrem a missão, e o ↑ e o ↓ pequenos; na segunda, em cinza, o tipo, a recompensa ("50 moedas · 1× Tônico Leve", ou "só o XP"), as conversas escritas ("conversa: Início, Fim") e "não conta" quando ela não conta para abrir a próxima ilha.

### O formulário

- **RF-04:** Com uma missão aberta, a lista some e o formulário começa no topo. A primeira linha tem o "← Missões", que volta à lista, e o Salvar; a segunda, o título ("Missão 160" ou "Nova missão") e, em amarelo, "não salva" enquanto há mudança.
- **RF-05:** O formulário fica em 3 cartões:
  - **Objetivo:** NPC (o "Quem dá" de antes), Tipo, com a descrição do tipo em cinza embaixo (`quest_types.description`), os campos do tipo e o Título;
  - **Recompensa:** Moedas, Item e a quantidade dele na mesma linha (a quantidade só com item), e "Conta para abrir a próxima ilha";
  - **Conversas:** o `QuestDialogueEditor`.
- **RF-06:** Embaixo, o Salvar e o Cancelar à esquerda e o Apagar à direita, que pede a confirmação como hoje.
- **RF-07:** Com mudança não salva, o "← Missões" e o Cancelar pedem um segundo clique ("Descartar mudanças?") antes de fechar. Abrir outra missão pelo painel NPC com mudança não salva não troca: a barra de baixo diz "Salve ou descarte a missão aberta primeiro."
- **RF-08:** Os rótulos cabem nos 120 px: "NPC", "Tipo", "Título", "Moedas", "Item".

### As conversas

- **RF-09:** As abas mostram quantos passos cada conversa tem ("Início · 3"), e uma conversa vazia diz o que acontece sem ela: no Início, "Sem conversa nem cena: o NPC diz a fala padrão, e a missão é aceita no fim."; no Durante e no Fim, "Sem conversa: o NPC diz a fala padrão."
- **RF-10:** Cada fala é um bloco com a lista de quem fala estreita (NPC, Domador, Narração) e o ↑, o ↓ e o ✕ pequenos e sem fundo, o ✕ vermelho. A caixa do texto tem pelo menos 3 linhas e cresce com o texto. Embaixo, à direita, o contador "120/300 · 2 caixas", vermelho acima de 300 ou vazio.
- **RF-11:** A escolha é um bloco com uma barra colorida à esquerda (uma cor por nível, até 3) e o título "Escolha: o jogador responde". Cada opção tem o texto, o "Aceita", "Recusa" ou "Segue" (só no Início), com a Aceita em verde e a Recusa em vermelho, e o ✕ pequeno; as falas da opção ficam recuadas 18 px, embaixo dela.
- **RF-12:** "+ Fala", "+ Escolha" e "+ Opção" são botões de contorno (`OutlineButton`), mais leves que o Salvar.
- **RF-13:** Embaixo da conversa, "Passos: 12 de 40", vermelho acima de 40, contando as falas, as escolhas e as opções, como o servidor (`MAX_DIALOGUE_STEPS`).

## Fora do escopo

- Uma janela maior para as conversas, fora da coluna do F2.
- Arrastar para reordenar; o ↑ e o ↓ continuam.
- Desfazer dentro do formulário da missão (a missão se salva na hora, fora do desfazer da ilha).
- Conferir no F2 o que o servidor recusa (fala vazia, opção vazia): o servidor continua dizendo, na barra de baixo.

## Onde ficou

- `QuestEditorStyle` (`client/tools/map_editor/quest_editor_style.gd`): os cartões, o bloco da escolha com a barra do nível, o botão pequeno sem fundo (`mini`), o de contorno compacto (`outline`) e o texto cinza menor.
- `QuestPanel`: a lista e o formulário em `_build_list` e `_build_form`; o cartão da missão em `_quest_row` e `details`; a mudança não salva por `is_dirty` (o formulário em JSON comparado ao de quando abriu), com o segundo clique em `_leave`.
- `QuestDialogueEditor`: o sinal `edited`, as abas com o número (`count_steps`, que conta como o servidor), o aviso da conversa vazia, o contador de cada fala e o de passos.
- Na coluna de 430 px, os rótulos usam 18 px e os campos 16 px, e as listas cortam o texto (`clip_text`), senão o painel passava da largura.

## Critérios de aceite

- [x] Numa missão com conversa longa, o Salvar está na primeira linha do formulário.
- [x] Cancelar com mudança pede o segundo clique; sem mudança, fecha direto.
- [x] O contador da fala e o de passos batem com os limites do servidor.
- [x] Salvar, apagar, mover e abrir pelo painel NPC continuam funcionando (o dono conferiu no F2 em 2026-11-24: "Testei no F2 e funcionou").
- [x] O jogo abre sem erro de script.

Conferido numa cena temporária, com fotos do painel com uma missão de exemplo (a lista, o formulário e o "Descartar mudanças?"), sem o catálogo carregado; o F2 de verdade não foi aberto.
