# 03. A escolha do Explorar e a tela do Arquipélago

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-unlock-config](01-unlock-config.md), [hub-start](../hub-start/)

## Contexto

A [01](01-unlock-config.md) pôs no servidor a ordem das ilhas e as ilhas abertas, com o `GET /v1/me/archipelago`. A [02](README.md#fases) está adiada, e o mapa aleatório continua como está. Esta fase é a primeira que o jogador vê: o Explorar do Hub passa a abrir duas opções, e o Arquipélago mostra as ilhas.

Hoje:

- O botão Explorar da Home (`screens/hub/hub_screen.gd`, `_explore`) faz `Router.go_to(&"exploration")`, o mapa aleatório. Ele fica desligado sem equipe.
- Sair de uma exploração, numa ilha ou no mapa aleatório, ou perder uma luta, volta ao Hub pelo `Home.go()`.
- A tela Viagem (`screens/travel/`) tem o jeito das listas de destino: cartões `TapPanel` com `SectionPanel`, o título em `BoldLabel` e o subtítulo em `SecondaryLabel`. Ela continua sem entrada.

## Escopo

- A tela `explore_menu`, aberta pelo Explorar da Home, com as duas opções.
- A tela `archipelago`, com as ilhas em ordem, entrando nas abertas.
- O `ArchipelagoIsland` no `domain/models/`, a leitura no `GameService` e no `ApiGameService` e o `Session.load_archipelago`.
- Só nas versões de depuração, o botão que abre a próxima ilha pela rota de depuração da 01.
- O ícone do cadeado (`ui/icons/lock.svg`).

## Fora do escopo

- O aviso de "Ilha nova aberta": a primeira ilha que abre sozinha é a da [04](README.md#fases), e o aviso vai junto com ela.
- A lista do que falta em cada ilha ("3/5 Domadores…"), que precisa das condições das fases 4 a 6.
- O quadro das missões extras (fase 7).
- Arte nova: a tela usa o tema e os cartões de hoje.

## Onde ficou

- As telas: `client/screens/explore_menu/` e `client/screens/archipelago/`, registradas no `Router.SCREENS`. O Explorar da Home faz o `push` da escolha.
- O modelo `ArchipelagoIsland` (`client/domain/models/`), o `load_archipelago` e o `unlock_island` no `GameService` e no `ApiGameService`, e os dois no `Session`.
- O cadeado: `client/ui/icons/lock.svg`.
- Conferido sem janela: os scripts e as cenas compilam, e as duas telas foram fotografadas com ilhas de exemplo. Entrar em Liora, o voltar do aparelho e o "Abrir (depuração)" com o servidor ficam para o dono conferir no jogo.

## Requisitos

- **RF-01:** o Explorar da Home faz `Router.push(&"explore_menu")`. Ele continua desligado sem equipe, como hoje.
- **RF-02:** a `explore_menu` tem o título "Explorar", dois cartões e o Voltar:
  - **Explorar randomicamente**, com o subtítulo "Um mapa novo a cada vez.", faz `Router.go_to(&"exploration")`, como o Explorar de antes;
  - **Arquipélago Auralis**, com o subtítulo "Abra as ilhas uma a uma.", faz `Router.push(&"archipelago")`.
- **RF-03:** a `archipelago` tem o título "Arquipélago Auralis". Ela carrega o `Session.load_archipelago()`, mostrando "Carregando ilhas..." enquanto isso e o erro se falhar. Com a lista vazia, mostra "Nenhuma ilha no Arquipélago ainda.".
- **RF-04:** cada ilha é um cartão, em ordem:
  - **aberta:** o nome em `BoldLabel` e "Toque para explorar." em `SecondaryLabel`. O toque faz `Router.go_to(&"exploration", {"island_id": id})`;
  - **próxima:** o cadeado, o nome e "Complete a ilha anterior para abrir.", sem toque;
  - **escondida:** o cadeado, "???" e "Ilha desconhecida.", sem toque.
- **RF-05:** só com `OS.is_debug_build()`, o cartão da próxima ilha ganha o botão "Abrir (depuração)", que chama o `Session.unlock_island(id)` (`PUT /v1/me/archipelago/:id/unlock`) e recarrega a lista. Um erro fica na mensagem da tela.
- **RF-06:** o voltar do aparelho e o Voltar das duas telas fazem `Router.back`. Na `archipelago`, enquanto carrega, o voltar não faz nada (`handle_back` devolve `true`), como na Viagem.

## Critérios de aceite

- [ ] Na Home, tocar em Explorar abre as duas opções. O Explorar randomicamente abre o mapa sorteado de sempre.
- [ ] O Arquipélago Auralis mostra Liora aberta e, se houver mais ilhas no Arquipélago, a próxima com o nome e o cadeado e as outras como "???".
- [ ] Tocar em Liora entra nela. Sair do mapa volta ao Hub.
- [ ] Na versão de depuração, "Abrir (depuração)" abre a próxima, e a lista recarrega com ela aberta.
- [ ] O voltar do aparelho volta uma tela de cada vez até a Home.
- [x] O jogo abre sem erro de script (`godot --headless -d --path client --quit-after 60`).
