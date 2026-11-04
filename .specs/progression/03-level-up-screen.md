# 03. XP na luta e tela de comemoração

- **Status:** concluída
- **Depende de:** [01-xp-and-levels](01-xp-and-levels.md), [architecture.md](architecture.md)

## Contexto

Com a [01](01-xp-and-levels.md), o servidor devolve `xp_gained` e `progression`, e o jogo ainda ignora os dois. Esta fase mostra o XP no log, enche a barra de XP e abre a tela de comemoração de quem subiu de nível. O dono escolheu essa tela entre três esboços: o Ecobeast grande e animado, o nível antigo e o novo, os stats de antes e depois e o botão "Continuar".

## Escopo

- As linhas de XP no log da luta.
- A barra de XP do Ecobeast em campo enchendo até o valor novo.
- A tela de comemoração, por cima da batalha, uma para cada Ecobeast que subiu de nível.

## Fora do escopo

- As telas de evolução e de Técnica, que vêm na [04](04-evolution-and-skills-screens.md). Até lá, uma evolução oferecida volta no próximo nível, e as Técnicas pendentes se perdem, como se o jogador não as tivesse aprendido.
- Som e partículas.

## Requisitos

- **RF-01:** cada `xp_gained` vira uma linha no log, "<nome> recebeu <amount> de XP.", depois da linha que o log já mostra quando o inimigo desmaia e antes de "Você venceu!". O nome é o apelido, quando houver, e senão o da espécie.
- **RF-02:** se o Ecobeast em campo recebeu XP, a barra dele enche do valor antigo até o novo, com os campos da `progression`. Se ele subiu de nível, a barra vai até o fim, o nível ao lado do nome muda e a barra recomeça do zero até o valor novo. No nível 100, ela fica cheia.
- **RF-03:** depois do log, para cada item da `progression` com `level_after > level_before`, na ordem da lista, abre a tela de comemoração, por cima da batalha.
- **RF-04:** a tela mostra o título "Subiu de nível!", o retrato do Ecobeast em tamanho grande, o nome, "Nv. <antes> → Nv. <depois>" e as 6 linhas de stats no formato "Ataque 17 → 19 +2", com o nome de cada stat no catálogo (HP, Ataque, Defesa, Ataque Especial, Defesa Especial e Velocidade), nessa ordem. Na implementação, os nomes curtos do esboço deram lugar aos do catálogo, os mesmos do resto do jogo, e a linha mais longa ainda cabe em 360×640.
- **RF-05:** o retrato entra crescendo e depois pulsa, com um brilho em volta, enquanto a tela está aberta.
- **RF-06:** "Continuar" fecha a tela e abre a próxima. Depois da última, aparece o resultado da luta com o botão "Voltar", como hoje.
- **RF-07:** o "Voltar" recarrega o jogador antes de voltar ao mapa, como já faz quando a luta mudou a equipe.
- **RF-08:** nada da tela de comemoração aparece em derrota, fuga, captura ou vitória sem ninguém subindo de nível.

## Critérios de aceite

- [x] Vencendo sozinho, o log mostra "Ruvo recebeu 44 de XP." antes de "Você venceu!".
- [x] Com dois participantes, o log mostra uma linha para cada um.
- [x] A barra de XP do Ecobeast em campo enche, e, ao subir de nível, recomeça do zero com o nível novo ao lado do nome.
- [x] Quem subiu de nível vê a tela com o nível antigo e o novo e os 6 stats de antes e depois, e os números são os da resposta do servidor.
- [x] Dois Ecobeasts que subiram de nível na mesma luta abrem duas telas, uma depois da outra.
- [x] Depois do "Voltar", a Equipe e o Hub mostram o nível novo.
- [x] A tela cabe sem rolar em 720×1280, 405×720, 360×640 e 412×915.

O dono testou numa luta de verdade, junto com a [04](04-evolution-and-skills-screens.md) e a [05](05-wild-coins.md), e aprovou em 2026-11-03. A tela foi conferida sozinha, com dados de exemplo, nos quatro tamanhos.
- [x] O editor abre sem erros nem avisos de script.

## Desenho técnico

- **Criar** `client/domain/models/creature_progress.gd` (`class_name CreatureProgress`) com `from_dict`, espelhando o item da `progression`.
- **Alterar** `client/domain/models/battle_turn.gd`: lê `progression` e o evento `xp_gained`.
- **Criar** `client/screens/battle/level_up_overlay.tscn` e `level_up_overlay.gd`: um `Control` que cobre a tela, com o retrato (`res://ui/components/creature_portrait.tscn`), o texto e o botão. Ele emite o sinal `finished` no "Continuar". O pulso e o brilho são `Tween`s sobre `scale` e `modulate`, sem shader novo.
- **Alterar** `client/screens/battle/battle_screen.gd`:
  - As linhas de log.
  - A barra de XP (`_player_card.set_xp`), animada com `Tween`.
  - A sequência de telas antes do `_result_box`, uma por vez, esperando o `finished` com `await`.

> **Conceito do Godot:** um `Tween` anima uma propriedade de um nó ao longo do tempo, por exemplo `scale` de 0,6 até 1. Um sinal como `finished` avisa quem estiver ouvindo, e `await overlay.finished` faz o código parar ali até a tela fechar.

## Verificação

- Abra o editor e rode com F5. Explore, procure um Ecobeast e vença. Confira o log, a barra e a tela.
- Para subir de nível sem jogar muito, use um Ecobeast perto do próximo nível. Quem implementa diz como chegou nesse estado.
- Rode nos quatro tamanhos do critério de aceite.
- Ficam para o dono o teste no celular e a impressão da animação.

## Tarefas

- [x] `CreatureProgress` e a leitura no `BattleTurn`
- [x] Linhas de XP no log
- [x] Barra de XP animada
- [x] `LevelUpOverlay` e a sequência na tela de batalha
- [x] Teste nos quatro tamanhos, e status e tabelas atualizados
