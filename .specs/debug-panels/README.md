# debug-panels

Os dois painéis de depuração do jogo ficam organizados em abas: o botão **Debug** de Explorar e o **F3** da luta no tabuleiro. Nenhuma regra muda; só a arrumação.

## Contexto

Em 2026-11-20, o dono pediu: "Vamos melhorar a interface de debug do explorar e a interface de debug do f3 na luta, deixe mais organizado tudo". Ele aprovou a proposta de abas ("Pode seguir").

O que existia:

- **Explorar:** uma coluna só, com uns 17 botões de 56 px, misturando mapa, luta, visual e hora, uns com "Debug:" no nome e outros não, e os de ligar e desligar com o estado escrito no texto ("Contorno: desligado"). O Spawn e as Cenas trocavam a coluna por uma lista com o próprio Voltar.
- **F3:** uma faixa embaixo com Estados, Atributos e Chão empilhados; os 11 tipos de Chão numa fileira que passava da largura da tela, e os Atributos dois por linha.

## Objetivos

1. Achar cada ferramenta pelo assunto, sem rolar uma lista comprida.
2. Ver na hora o que está ligado.
3. O F3 não crescer por cima do tabuleiro.

## Decisões

| Decisão | Motivo |
| --- | --- |
| Abas nos dois painéis, com título e botão de fechar | Do dono ("Pode seguir") |
| Os de ligar e desligar viram chaves (`CheckButton`) | O estado aparece na chave, e o rótulo fica curto |
| Sem o prefixo "Debug:" nos rótulos | O painel inteiro já é o de depuração |

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| O Spawn virou uma aba própria, em vez de ficar dentro da Luta | A grade de espécies é alta e deixaria a aba Luta comprida |
| As Cenas da ilha ficam na aba Mapa, numa lista que rola | São da ilha aberta, como o Esquecer ilha |
| A aba escolhida fica lembrada enquanto o jogo está aberto | Quem testa a mesma coisa várias vezes não precisa trocar de aba toda vez |
| As abas usam os estilos `TabButton` e `CurrentTabButton` do tema, os da barra do Hub | O jogo já tem esse visual de aba |

## Fora do escopo

- Ferramentas novas de depuração.
- O F1 e o F2, que são janelas à parte.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-tabbed-panels](01-tabbed-panels.md) | Jogo: o Debug de Explorar e o F3 da luta em abas | concluída (falta o dono conferir no jogo) |
