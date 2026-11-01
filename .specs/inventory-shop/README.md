# Inventory shop

O jogador compra itens na Loja, guarda na Mochila e usa no mapa ou na luta. Quem cobra, guarda e aplica o efeito é sempre o servidor; o jogo só pede e mostra o resultado.

## Contexto

O Domador nasce com 1.000 moedas, e nada as gasta. A tabela `inventory_items` existe desde o `backend-api`, mas fica vazia, porque ainda não há tabela `items`. Os cards "Loja" e "Mochila" do Hub abrem placeholders, e o botão Itens da batalha está desativado desde a [battle-screen](../battle-screen/).

As Esferas de Vínculo entram aqui para que a [`capture`](../roadmap.md) as encontre prontas. Até lá, elas podem ser compradas, mas não usadas.

## Quem usa

- O jogador, entre uma luta e outra e durante elas.
- A futura iniciativa `capture`, que lê o `capture_bonus` das Esferas.

## Objetivos

1. O jogador compra um item na Loja, com o desconto das moedas feito pelo servidor.
2. O jogador cura um Ecobeast pela Mochila, a partir do Hub ou do mapa.
3. Na luta, usar um item gasta a rodada do jogador.
4. O preço e o efeito de cada item ficam no catálogo, editáveis pelo painel do Supabase.

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| A Loja começa com 6 itens: 3 Esferas e 3 de cura, com os preços de [architecture.md](architecture.md#conteúdo-inicial) | Aprovados pelo dono; os valores continuam _a revisar_ |
| Só duas abas na Loja: Esferas e Cura | Item segurado e Ascensão por item ainda não têm regra |
| A Mochila abre também no mapa, e lá o jogador cura um Ecobeast | Pedido do dono |
| Na luta, usar um item gasta a rodada | Pedido do dono |
| Comprar mostra "Item comprado!", põe o item na Mochila e mantém o jogador na Loja | Pedido do dono, que vai refinar esse comportamento depois |
| A renda de moedas fica para depois | Vão existir vários cenários de ganho; hoje as 1.000 moedas iniciais são tudo o que existe |
| Os itens usam uma forma provisória até o dono mandar as imagens | Pedido do dono |
| Na luta, o item faz efeito primeiro, e depois o inimigo ataca | Confirmado pelo dono |
| O alvo é qualquer Ecobeast da equipe, dentro e fora da luta | Confirmado pelo dono |
| Tônico não funciona em Ecobeast com 0 HP, que só volta no Refúgio | Confirmado pelo dono |
| Item sem efeito não é gasto nem perde a rodada; o jogo avisa "Não teria efeito." | Confirmado pelo dono |
| Com quantidade zero, o item some da Mochila | Confirmado pelo dono |
| A Mochila abre pelo Hub e pelo mapa; a Loja, pelo Hub (botão e aba inferior) | Confirmado pelo dono |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| Cada toque em Comprar compra 1 unidade, sem janela de quantidade | É o caso mais simples do pedido do dono, que vai refinar a compra depois |
| Comprar fica desativado quando as moedas não bastam | A tela evita um toque que o servidor recusaria |
| Nomes próprios para as Esferas e os itens de cura | Vários nomes do GDD eram iguais ou muito parecidos com os da referência; o GDD foi atualizado |
| Um único Bálsamo Puro para todos os status principais | O jogador não precisa de um item por status |
| Um item usado na luta só sai do banco no fim dela | A batalha já grava tudo no fim; assim, largar a luta no meio não perde o item nem a cura |
| Usar um item fora da luta descarta a batalha aberta | Pelo mesmo motivo do Refúgio: uma luta deixada para trás gravaria o HP antigo por cima |
| Sem limite de quantidade por item | Com a renda de hoje, o limite nunca seria alcançado |
| A carga inicial passa a preencher só as tabelas vazias | Ela recusava rodar num catálogo parcial, e tabelas novas entram num banco já em uso |

## Fora do escopo

- Ganhar moedas.
- Usar Esferas de Vínculo e a fórmula de captura (`capture`).
- Itens segurados, de Ascensão e de Treino, e as abas deles.
- Item que revive ou que recupera PP.
- Vender itens, comprar vários de uma vez, promoções e limite de quantidade.
- Curar Confuso, Amedrontado ou Preso, que só existem durante a luta.
- Sons (`audio`).
- Imagens finais dos itens: entram por arquivo, sem código.
- Cobrar moedas no Refúgio.

## Pré-requisitos

- [battle-screen](../battle-screen/), [heal-station](../heal-station/) e [wild-battle](../wild-battle/) concluídas.

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01-item-catalog](01-item-catalog.md) | Tabelas dos itens, os 6 itens no banco e a Mochila na resposta do jogador | concluída |
| [02-shop](02-shop.md) | Rota de compra e tela da Loja | concluída |
| [03-bag](03-bag.md) | Rota de uso e tela da Mochila, abrindo pelo Hub e pelo mapa | concluída |
| [04-battle-items](04-battle-items.md) | Ação de usar item na batalha e o botão Itens | rascunho |
