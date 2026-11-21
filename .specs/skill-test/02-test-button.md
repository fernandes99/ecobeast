# 02. O botão Testar técnica no F1

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-test-route](01-test-route.md)

## Contexto

O detalhe de uma Técnica no F1 (`client/tools/content_viewer/skills_tab.gd`) tem o botão **Editar**. Esta fase põe o **Testar técnica** ao lado dele e abre a luta da fase 1 na janela principal do jogo.

## Requisitos

- **RF-01:** Ao lado do **Editar**, o botão **Testar técnica** abre um painel embaixo do cabeçalho da Técnica, com:

  | Campo | Controle | Padrão |
  | --- | --- | --- |
  | Quem usa | lista de espécies: primeiro as que aprendem a Técnica, na ordem do id, e depois as outras | a primeira que aprende; sem ninguém, a espécie 1 |
  | Oponente | lista de todas as espécies | a última escolhida no F1 desde que o jogo abriu; na primeira vez, a espécie 1 |
  | Nível | número de 1 a 100 | 50 |
  | Oponente parado | caixa de marcar | marcada |

  O botão **Começar** abre a luta. **Testar técnica** é um botão de ligar: clicar de novo fecha o painel. O formulário de edição troca o detalhe inteiro e, com ele, o botão.

- **RF-02:** **Começar** faz a cobertura da luta (`BattleIntro.cover`) no centro da janela principal e abre a tela `board_battle` pelo `Router.push`, com os dados do teste no parâmetro `skill_test`. O F1 continua aberto. Sem o jogador carregado (antes do login), o painel mostra "Entre na sua conta primeiro."; com a janela principal numa luta de verdade (selvagem, de Domador ou a de teste do Debug), "Termine a luta aberta primeiro.". Nos dois casos, nada abre. Com um teste de Técnica já aberto, terminado ou não, o **Começar** troca a tela da luta pela do teste novo (`Router.replace`), e o servidor descarta o anterior, sem gravar nada; o dono pediu em 2026-11-20: "quero que termine ela e já inicie outra para testar aquela outra técnica". O aviso do editor de ilhas (F2) aberto ficou de fora: o F1 não enxerga o F2, e abrir a luta com ele aberto não atrapalha.

- **RF-03:** A tela da luta, com `skill_test`, começa pela rota da fase 1 (`Session.start_board_skill_test`, no `GameService` e no `ApiGameService`). Um erro do servidor aparece como o de hoje, com a saída.

- **RF-04:** No fim de uma luta de teste, a caixa do resultado tem **Testar de novo** e **Voltar** (o botão de sair de toda luta):
  - **Testar de novo** abre a mesma luta de teste outra vez, com os mesmos dados, trocando a tela da luta por uma nova (`Router.replace`), com a música da luta de novo.
  - **Voltar** volta para a tela de antes sem recarregar o jogador, porque nada mudou.

  Fugir no meio também termina a luta, com os mesmos dois botões.

## Escopo

- O botão e o painel no `skills_tab.gd`.
- O `skill_test` na tela da luta, no `Session` e no serviço.
- **Testar de novo** e **Voltar** no fim.
- `Router.replace` e `Router.current_id` no `router.gd`.

## Fora do escopo

- O botão nas outras abas do F1, como na de Ecobeasts.
- Guardar as escolhas do painel depois de fechar o jogo.

## Critérios de aceite

- [x] O jogo sem janela abre sem erros de script, e o `CatalogValidator` aceita o catálogo.
- [ ] No F1, **Testar técnica** numa Técnica abre a luta com ela no 1º ícone, e dá para usá-la em duas vezes seguidas.
- [ ] Com o oponente parado, ele só passa a vez. Sem marcar, ele luta.
- [ ] **Testar de novo** abre outra luta, e **Voltar** volta para a tela de antes.
- [ ] Com um teste aberto, o **Começar** de outra Técnica troca pelo teste novo, e numa luta de verdade aparece o aviso.
- [ ] Depois do teste, a equipe, a Mochila e o Bestiário estão como antes.
- [ ] Uma Técnica mudada pelo **Editar** já vale no próximo teste.

## Verificação

```bash
godot --headless -d --path client --quit-after 240
```

Numa cena temporária sem janela (apagada depois), em 2026-11-20:

- com um teste do Raio de Sol aberto no meio da abertura da câmera, o **Começar** do Golpe de Foice trocou a tela (a anterior foi liberada) e abriu o Prayling com as Técnicas 84, 59 e 11, sem erro de script;
- o F1 na Técnica 84 mostrou o **Testar técnica**; ligado, o painel listou os 4 aprendizes primeiro ("Prayling (aprende)") e o Ruvo como oponente, e o **Começar** sem jogador mostrou "Entre na sua conta primeiro.";
- com a conta do dono, a tela da luta com `skill_test` (Raio de Sol, Solantis contra Ruvo, nível 50, parado) abriu a luta de 1 Ecobeast, `uid` `skill-test`, com as Técnicas 87, 11 e 86, e o **Testar de novo** trocou a tela por uma luta nova.

O resto é com o dono, no jogo: F5, F1, aba Técnicas.

## Tarefas

- [x] O serviço e o `Session`.
- [x] O botão e o painel no F1.
- [x] A luta com `skill_test`, **Testar de novo** e **Voltar**.
- [x] O README da iniciativa, o índice das specs, o roadmap e o `CLAUDE.md`.
