# 03. A tela Aparência

- **Status:** concluída
- **Depende de:** [02-layered-tamer](02-layered-tamer.md)

## Contexto

O Domador já é desenhado em camadas (fase 2), mas a aparência só muda pelo `/docs`. Esta fase dá ao jogador a tela para escolher o corpo, a pele, cada peça e a cor de cada uma, na entrada do jogo e depois, pelo Hub.

## Escopo

- A tela `appearance`, com o Domador grande no topo e as escolhas embaixo.
- O passo na entrada: depois do nome (`res://screens/title/title_screen.gd`), antes da escolha do inicial.
- O toque no avatar do Hub (`%AvatarInitial`, em `res://screens/hub/hub_screen.gd`) abre a tela.

## Fora do escopo

- Peças bloqueadas, preços e a Loja de roupas.
- O rosto do Domador no avatar do Hub.

## Requisitos

- **RF-01:** O topo mostra o Domador com a aparência sendo montada, em escala inteira (pixels nítidos), parado na animação `idle`.
- **RF-02:** Um botão gira o Domador pelas 5 direções e, depois, pelo lado espelhado.
- **RF-03:** Uma fileira de abas, uma por lugar do `appearance_slots` na ordem do `layer`, precedida de **Corpo** (o corpo e a pele).
- **RF-04:** Cada aba mostra as peças do lugar que servem no corpo escolhido, e mais **Nenhum** quando o lugar não é obrigatório. Tocar numa peça a veste na prévia na hora.
- **RF-05:** Quando o lugar tem `palette_kind`, a aba mostra embaixo as paletas desse tipo, cada uma como um quadrado com a cor do tom 2. Vestir uma peça sem cor escolhida usa a primeira paleta do tipo.
- **RF-06:** Trocar de corpo tira as peças que não servem no novo corpo e põe a primeira peça dos lugares obrigatórios que ficarem vazios.
- **RF-07:** **Salvar** manda a aparência pelo `PUT /v1/me/appearance`, com o botão desabilitado enquanto espera. Uma recusa mostra a mensagem do servidor e mantém a tela.
- **RF-08:** Na entrada, **Salvar** segue para a escolha do inicial, e não há Voltar. Pelo Hub, **Salvar** volta ao Hub, e Voltar sai sem salvar.
- **RF-09:** Quem fechar o jogo antes de salvar fica com a aparência padrão e volta direto para a escolha do inicial.

## Critérios de aceite

Conferido numa cena temporária com o catálogo de verdade: vestir, trocar de cor, trocar de corpo e girar mudam a prévia na hora. O resto passa pelo login e fica para o dono.

- [ ] Um Domador novo passa pela tela Aparência entre o nome e o inicial.
- [x] Vestir, trocar de cor e tirar uma peça muda a prévia na hora.
- [ ] Trocar de corpo tira a peça que só serve no outro (hoje, a Saia ao passar para o Masculino).
- [ ] Salvar pelo Hub e abrir Explorar zona mostra o Domador com a aparência nova.
- [ ] Voltar pelo Hub sem salvar não muda nada.

## Desenho técnico

- `res://screens/appearance/appearance_screen.tscn` e `.gd` (novos), registrados no `Router` (`res://core/autoload/router.gd`) como `&"appearance"`, com o parâmetro `onboarding`.
- A prévia é um `TamerSprite` (fase 2) em escala inteira (8×), dentro de um painel.
- As abas são uma faixa que rola para o lado, com os nomes inteiros, e as peças ficam em 2 colunas: em 4 e em 3 colunas, "Parte de baixo" e "Rabo de cavalo" saíam cortados.
- `res://core/autoload/session.gd`: `update_appearance(appearance)`, que chama a rota e troca o `Session.player`.
- `title_screen.gd`: depois de criar o Domador, `Router.go_to(&"appearance", {"onboarding": true})`.
- `hub_screen.gd`: o avatar vira botão para `&"appearance"`.
- `TELAS.md`: a tela nova.

## Verificação

- O projeto abre no editor sem erros nem avisos de script.
- Passos manuais (F5): os critérios de aceite, com uma conta nova e com uma que já tem Domador, e a tela num retrato estreito (360 px de largura) sem rolagem para os lados.

## Tarefas

- [x] `Session.update_appearance`.
- [x] A tela, com a prévia, o giro, as abas, as peças e as paletas.
- [x] O passo na entrada e o avatar do Hub.
- [x] Atualizar `TELAS.md`.
