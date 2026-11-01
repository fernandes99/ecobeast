# 02. Tela do Santuário

- **Status:** rascunho
- **Depende de:** [01-team-api](01-team-api.md)

## Contexto

O card "Santuário" do Hub abre um placeholder (TELAS.md #10). Esta fase cria a tela em grade, a opção A que o dono escolheu entre 2 mockups, com busca, filtro por Elemento, ordem por nível e o caminho até a equipe.

## Escopo

- A tela do Santuário, em grade.
- Busca, filtro e ordem.
- As ações de um Ecobeast: mover para a equipe, ver detalhes e voltar.
- A escolha de quem sai, com a equipe cheia.
- A tela de detalhes abrindo Ecobeasts do Santuário.

## Fora do escopo

- A tela Equipe ([03](03-team-screen.md)).
- Filtro de raridade.
- Soltar um Ecobeast e limite do Santuário.

## Requisitos

**Tela**

- **RF-01:** O card "Santuário" do Hub abre a tela, que lê o Santuário do servidor ao abrir.
- **RF-02:** O topo mostra "Santuário" e a quantidade de Ecobeasts.
- **RF-03:** A grade tem 3 colunas e rola. Cada célula mostra sprite, nome de exibição, nível e barra de HP.
- **RF-04:** Enquanto carrega, a tela avisa "Carregando...". Um erro aparece na tela, com "Tentar de novo".
- **RF-05:** Sem Ecobeasts, a tela mostra "Nenhum Ecobeast no Santuário."
- **RF-06:** O voltar fecha o painel aberto e, sem painel, volta à tela anterior.

**Busca, filtro e ordem**

- **RF-07:** A busca procura no apelido e no nome da espécie, sem diferenciar maiúsculas nem acentos.
- **RF-08:** Os filtros são "Todos" e um botão por Elemento presente no Santuário, numa faixa que rola para o lado.
- **RF-09:** A ordem começa em nível, do maior para o menor, e um toque em "Nível" inverte.
- **RF-10:** Busca, filtro e ordem valem juntos. A quantidade do topo continua sendo o total do Santuário.
- **RF-11:** Sem resultado, a tela mostra "Nenhum Ecobeast encontrado."

**Ações**

- **RF-12:** Tocar em uma célula abre um painel com sprite, nome, nível e as ações "Mover para a equipe", "Ver detalhes" e "Voltar".
- **RF-13:** "Ver detalhes" abre a tela de detalhes daquele Ecobeast, inclusive para dar apelido.
- **RF-14:** Com vaga na equipe, "Mover para a equipe" move sem perguntar, e a tela mostra "<Ecobeast> entrou na equipe."
- **RF-15:** Com a equipe cheia, abre "Trocar com quem?", com "<Ecobeast> entra na vaga do escolhido.", os 6 da equipe e "Cancelar".
- **RF-16:** Cada Ecobeast da escolha mostra sprite, nome, nível e HP.
- **RF-17:** Escolher troca os dois, e a tela mostra "<Ecobeast> entrou na equipe."
- **RF-18:** Depois de mover, a grade e a quantidade se atualizam, e a busca e o filtro continuam como estavam.
- **RF-19:** Um erro do servidor aparece no painel, e nada muda na tela.
- **RF-20:** Os botões ficam desativados enquanto o pedido vai e volta.

## Critérios de aceite

- [ ] O card "Santuário" abre a tela, e a aba de voltar retorna ao Hub.
- [ ] Sem Ecobeasts, aparece "Nenhum Ecobeast no Santuário."
- [ ] Com o servidor fora, aparece o erro, e "Tentar de novo" carrega a lista depois que ele volta.
- [ ] Buscar "fag" encontra Fagulho, e buscar "goticulo" encontra Gotículo.
- [ ] Buscar o apelido encontra o Ecobeast.
- [ ] Só aparecem filtros de Elementos presentes no Santuário.
- [ ] Um Ecobeast com dois Elementos aparece nos dois filtros.
- [ ] O toque em "Nível" inverte a ordem.
- [ ] Busca e filtro juntos sem resultado mostram "Nenhum Ecobeast encontrado."
- [ ] Com vaga, mover tira o Ecobeast da grade e o põe no Hub.
- [ ] Com a equipe cheia, a troca põe o Ecobeast na equipe e devolve o outro à grade.
- [ ] "Cancelar" não muda nada.
- [ ] Dar apelido a um Ecobeast do Santuário aparece na grade ao voltar.
- [ ] A tela de detalhes abre um Ecobeast do Santuário com os dados dele.
- [ ] Um toque rolando a grade não abre o painel.
- [ ] Com mais Ecobeasts do que cabem na tela, a grade rola até o fim.
- [ ] Em 360×640, 405×720, 412×915 e 720×1061, a grade e os painéis cabem.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/screens/storage/storage_screen.tscn` e `.gd`: a tela.
- `client/screens/storage/storage_cell.tscn` e `.gd`: a célula, estendendo `TapPanel`.
- `client/screens/storage/creature_actions_panel.tscn` e `.gd`: o painel de ações, que a [03](03-team-screen.md) também usa.
- `client/screens/storage/team_swap_panel.tscn` e `.gd`: "Trocar com quem?".

**Alterar**

- `client/core/services/game_service.gd`, `api_game_service.gd`: as quatro chamadas de [architecture.md](architecture.md#o-cliente).
- `client/core/autoload/session.gd`: `storage` e as chamadas.
- `client/core/autoload/router.gd`: `&"storage"`.
- `client/screens/hub/hub_screen.gd`: o destino do card.
- `client/screens/creature_details/creature_details_screen.gd`: procura também em `Session.storage`.

**Reaproveitar**

`SafeArea`, `TapPanel`, `CreaturePortrait`, `HpBar`, `ElementBadge`, as cores de `GameData.get_element` e `CreatureInstance.display_name`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 60
```

Uma cena temporária abre o Santuário contra um servidor de teste, com Ecobeasts criados no banco, usa os botões reais, confere os critérios automáticos e salva capturas de tela. As capturas abertas são citadas no relatório.

Passos do dono no editor (F5) e no celular:

1. Capturar Ecobeasts até a equipe encher.
2. Abrir o Santuário, buscar e filtrar.
3. Trazer um Ecobeast, trocando com um da equipe.
4. Conferir a troca no Hub.

## Tarefas

- [ ] Verificação temporária da tela; ver falhar.
- [ ] Serviços e `Session`.
- [ ] Grade e estados da tela (RF-01 a RF-06).
- [ ] Busca, filtro e ordem (RF-07 a RF-11).
- [ ] Ações e troca (RF-12 a RF-20).
- [ ] Remover os arquivos temporários; marcar esta spec e a tabela do README como `concluída`; commit `feat: tela do Santuário`.
