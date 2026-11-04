# 04. Telas de evolução e de Técnica

- **Status:** concluída
- **Depende de:** [02-skills-and-evolution](02-skills-and-evolution.md), [03-level-up-screen](03-level-up-screen.md), [architecture.md](architecture.md)

## Contexto

Com a [02](02-skills-and-evolution.md), o servidor oferece a evolução, ensina as Técnicas com vaga e guarda as que precisam de escolha. Com a [03](03-level-up-screen.md), a tela de comemoração já aparece depois da luta. Esta fase põe, depois dela, a tela da evolução, os avisos de Técnica aprendida e a escolha de qual Técnica esquecer.

## Escopo

- A tela da evolução, com o botão "Cancelar" durante a animação.
- O aviso "<nome> aprendeu <Técnica>!".
- A tela de escolher a Técnica, com as 4 atuais e "Não aprender".
- A ordem dessas telas e as chamadas às rotas da [02](02-skills-and-evolution.md).
- Uma ferramenta de teste, pedida pelo dono: no menu de depuração do mapa, "Quase subir de nível" deixa a equipe a 1 XP do próximo nível.

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

**Ferramenta de teste**

- **RF-14:** `POST /v1/me/debug/xp` deixa cada Ecobeast da equipe abaixo do nível 100 com o XP total do próximo nível menos 1, e devolve o jogador. Ela só existe com `ENABLE_TEST_BATTLE` ligada, como a batalha de teste, e sem ela dá 404. Sem Domador, dá 409.
- **RF-15:** o menu de depuração do mapa ([wild-battle/13](../wild-battle/13-debug-menu.md)) ganha o botão "Quase subir de nível". Ele chama a rota, fecha o menu e mostra "A equipe está a 1 XP do próximo nível." ou o erro.
- **RF-16:** o menu ganha também o modo God e passa a ter duas partes, com o Spawn em cartões com retrato. O desenho está em [wild-battle/13](../wild-battle/13-debug-menu.md#mudanças-depois-progression04).

## Critérios de aceite

- [x] Um Ruvo que chega ao nível 16 vê a comemoração e depois a evolução. Sem tocar em nada, ele vira Ruvak, e os detalhes mostram o Ruvak.
- [x] Com "Cancelar", ele continua Ruvo. Ao subir de nível de novo, a evolução volta a aparecer.
- [x] Um Ecobeast com vaga vê "aprendeu" e tem a Técnica nova nos detalhes.
- [x] Um Ecobeast com 4 Técnicas vê a escolha. Esquecer uma põe a nova no lugar, e "Não aprender" mantém as 4.
- [x] O "Não" das confirmações volta para a escolha.
- [x] Com o servidor fora do ar no meio da escolha, aparece "Tentar de novo". Com o servidor de volta, a escolha conclui.
- [x] As telas cabem sem rolar em 720×1280, 405×720, 360×640 e 412×915.
- [x] O editor abre sem erros nem avisos de script.

## Desenho técnico

- **Alterar** `client/core/services/game_service.gd` e `api_game_service.gd`: `evolve(uid: String, accept: bool) -> Result` e `learn_skill(uid: String, skill_id: int, forget_skill_id: int) -> Result`, com `forget_skill_id` igual a -1 para não aprender, enviado como `null`, como os outros ids ausentes do cliente. Os dois devolvem um `ProgressChoice` (`res://domain/models/progress_choice.gd`), ou `null` no 404.
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

- [x] `evolve` e `learn_skill` no serviço e na `Session`
- [x] `EvolutionOverlay`
- [x] `SkillLearnOverlay`, com a confirmação
- [x] A sequência completa na tela de batalha
- [x] Teste nos quatro tamanhos, e status e tabelas atualizados
