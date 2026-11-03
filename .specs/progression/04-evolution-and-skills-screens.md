# 04. Telas de evolução e de Técnica

- **Status:** rascunho
- **Depende de:** [02-skills-and-evolution](02-skills-and-evolution.md), [03-level-up-screen](03-level-up-screen.md), [architecture.md](architecture.md)

## Contexto

Com a [02](02-skills-and-evolution.md), o servidor oferece a evolução, ensina as Técnicas com vaga e guarda as que precisam de escolha. Com a [03](03-level-up-screen.md), a tela de comemoração já aparece depois da luta. Esta fase põe, depois dela, a tela da evolução, os avisos de Técnica aprendida e a escolha de qual Técnica esquecer.

## Escopo

- A tela da evolução, com o botão "Cancelar" durante a animação.
- O aviso "<nome> aprendeu <Técnica>!".
- A tela de escolher a Técnica, com as 4 atuais e "Não aprender".
- A ordem dessas telas e as chamadas às rotas da [02](02-skills-and-evolution.md).

## Fora do escopo

- Retomar uma escolha depois de fechar o jogo.
- A arte final da animação, que hoje usa o retrato (`front.png`) das duas espécies.

## Requisitos

- **RF-01:** para cada item da `progression` que subiu de nível, a ordem é: comemoração, evolução (se houver `evolution`), um aviso para cada Técnica aprendida e uma escolha para cada Técnica pendente. Depois vem o próximo item.
- **RF-02:** a tela da evolução mostra "<nome> está evoluindo!" e o retrato alternando entre a espécie atual e a nova, com um clarão branco, por cerca de 3 s. O botão "Cancelar" aparece durante esse tempo.
- **RF-03:** se o tempo acabar sem "Cancelar", o jogo envia `accept: true`, mostra o retrato da espécie nova e "<nome> evoluiu para <espécie nova>!", com "Continuar".
- **RF-04:** com "Cancelar", o jogo envia `accept: false`, mostra o retrato da espécie atual e "<nome> não evoluiu.", com "Continuar".
- **RF-05:** as Técnicas aprendidas e pendentes que aparecem depois da evolução são as da resposta da rota de evolução. Sem evolução, são as da `progression`.
- **RF-06:** o aviso de Técnica aprendida mostra "<nome> aprendeu <Técnica>!", com "Continuar".
- **RF-07:** a escolha mostra "<nome> quer aprender <Técnica>" e os dados dela: o Elemento, com a cor, a categoria, o poder, a precisão e o PP. Abaixo, "Ele já sabe 4 Técnicas. Qual esquecer?", as 4 atuais com a cor do Elemento e o botão "Não aprender <Técnica>".
- **RF-08:** tocar numa Técnica atual pede confirmação: "Esquecer <atual> e aprender <nova>?", com "Sim" e "Não". O "Sim" envia `forget_skill_id` e mostra "<nome> esqueceu <atual> e aprendeu <nova>!".
- **RF-09:** "Não aprender" pede confirmação: "Não aprender <nova>?". O "Sim" envia `forget_skill_id: null` e mostra "<nome> não aprendeu <nova>.".
- **RF-10:** depois da evolução, sem apelido, os textos usam o nome da espécie nova.
- **RF-11:** um 404 da rota mostra "Essa escolha não está mais disponível." e segue para a próxima tela.
- **RF-12:** outra falha, como a rede, mostra a mensagem do erro e "Tentar de novo", sem avançar.
- **RF-13:** o "Voltar" recarrega o jogador, e a Equipe, o Hub e os detalhes mostram a espécie, as Técnicas e o nível novos.

## Critérios de aceite

- [ ] Um Ruvo que chega ao nível 16 vê a comemoração e depois a evolução. Sem tocar em nada, ele vira Ruvak, e os detalhes mostram o Ruvak.
- [ ] Com "Cancelar", ele continua Ruvo. Ao subir de nível de novo, a evolução volta a aparecer.
- [ ] Um Ecobeast com vaga vê "aprendeu" e tem a Técnica nova nos detalhes.
- [ ] Um Ecobeast com 4 Técnicas vê a escolha. Esquecer uma põe a nova no lugar, e "Não aprender" mantém as 4.
- [ ] O "Não" das confirmações volta para a escolha.
- [ ] Com o servidor fora do ar no meio da escolha, aparece "Tentar de novo". Com o servidor de volta, a escolha conclui.
- [ ] As telas cabem sem rolar em 720×1280, 405×720, 360×640 e 412×915.
- [ ] O editor abre sem erros nem avisos de script.

## Desenho técnico

- **Alterar** `client/core/services/game_service.gd` e `api_game_service.gd`: `evolve(uid: String, accept: bool) -> Result` e `learn_skill(uid: String, skill_id: int, forget_skill_id: int) -> Result`, com `forget_skill_id` igual a 0 para não aprender, enviado como `null`.
- **Alterar** `client/core/autoload/session.gd`: `evolve` e `learn_skill`, que chamam o serviço.
- **Criar** em `client/screens/battle/` as telas `evolution_overlay.tscn`/`.gd` e `skill_learn_overlay.tscn`/`.gd`, no mesmo formato do `LevelUpOverlay`, com o sinal `finished`. A confirmação é um painel dentro da própria tela de Técnica.
- **Alterar** `client/screens/battle/battle_screen.gd`: a sequência do RF-01, com a lista de Técnicas vinda da evolução quando houver.
- Os dados das Técnicas vêm do catálogo (`GameData`), pelo `skill_id`.

## Verificação

- Rode com F5 e repita os critérios de aceite. Para chegar perto do nível 16, quem implementa diz como preparou o Ecobeast.
- Para a falha de rede, pare o servidor com a tela de escolha aberta e suba de novo.
- Rode nos quatro tamanhos.
- Fica para o dono o teste no celular.

## Tarefas

- [ ] `evolve` e `learn_skill` no serviço e na `Session`
- [ ] `EvolutionOverlay`
- [ ] `SkillLearnOverlay`, com a confirmação
- [ ] A sequência completa na tela de batalha
- [ ] Teste nos quatro tamanhos, e status e tabelas atualizados
