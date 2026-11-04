# 13. Menu de depuração do mapa

- **Status:** concluída
- **Depende de:** [12-plant-wind](12-plant-wind.md)

## Contexto

Com a skill `creature-sprites`, cada Ecobeast ganha as folhas `idle.png` e `walk.png`, mas nenhuma tela as mostra. O dono quer validar cada Ecobeast no mapa, sem depender de encontro nem de batalha. O botão de ver o mapa inteiro passa para um menu de depuração, junto com o spawn.

O Ecobeast do spawn é só para olhar: não passa pelo servidor, não bloqueia caminho e não inicia batalha. Os Ecobeasts de verdade no mapa são outra iniciativa.

## Escopo

- Um botão "Debug" que abre e fecha o menu de ações.
- Ver o mapa inteiro, dentro do menu.
- Spawn de qualquer Ecobeast do catálogo que tenha folhas, em um hexágono vizinho do Domador.
- Passeio dentro do hexágono, parado e andando.
- Remover todos os Ecobeasts do spawn.
- Depois, a [progression/04](../progression/04-evolution-and-skills-screens.md) mudou o menu: veja "Mudanças depois", no fim.

## Fora do escopo

- Encontro, batalha ou qualquer efeito de jogo a partir de um Ecobeast do mapa.
- Mudar de hexágono.
- Escolher animação ou ângulo à mão.
- Guardar os Ecobeasts do spawn: eles somem ao sair da tela do mapa.
- Plano dentro do hexágono: veja as decisões.

## Requisitos

**Menu**

- **RF-01:** Só quando `OS.is_debug_build()`, depois que o mapa aparece, os controles mostram o botão "Debug". Na versão publicada, nem ele nem o menu existem para o jogador.
- **RF-02:** Tocar em "Debug" abre o menu no topo da tela, por cima do mapa, sem cobrir o Domador nem os vizinhos dele, e tocar de novo fecha. Com o menu fechado, os controles ficam iguais aos de antes, sem o botão de ver o mapa.
- **RF-03:** O menu tem o botão de ver o mapa inteiro, que continua seguindo a [03](03-exploration-screen.md) e fecha o menu ao ser tocado.

**Spawn**

- **RF-04:** O menu lista os 9 Ecobeasts do catálogo, em ordem de id. Quem não tem `idle.png` e `walk.png` em `assets/creatures/<slug>/` fica desativado.
- **RF-05:** Um Ecobeast com folhas novas fica ativo sozinho, sem mudar código.
- **RF-06:** Tocar em um Ecobeast o coloca em um hexágono vizinho do Domador, e o menu continua aberto, para colocar outros. Cada spawn vai para o vizinho seguinte, em ordem, para eles não caírem juntos.
- **RF-07:** Pode haver vários ao mesmo tempo, inclusive da mesma espécie.
- **RF-08:** Um botão remove todos. Ele fica desativado quando não há nenhum.

**No mapa**

- **RF-09:** O Ecobeast fica parado por um tempo e depois anda até um ponto sorteado do mesmo hexágono, repetindo. Ele nunca sai do hexágono em que nasceu.
- **RF-10:** Parado, ele usa `idle`; andando, `walk`. A linha da folha e o espelhamento seguem a direção do movimento, nos 5 ângulos e nos dois lados.
- **RF-11:** A posição fica em pixels inteiros da arte, com a mesma densidade do Domador, na altura do hexágono.
- **RF-12:** Ele fica no plano da linha do hexágono, como o Domador ([11](11-depth-planes.md)): cobre o que está atrás e é coberto pelas linhas da frente.
- **RF-13:** No mapa inteiro, ele continua sobre o hexágono dele e não encolhe.
- **RF-14:** Andar, tocar, a batalha e voltar dela continuam iguais. Depois da luta, os Ecobeasts continuam onde estavam.

## Critérios de aceite

- [x] Em build de debug, "Debug" abre e fecha o menu, e o botão de ver o mapa só existe dentro dele.
- [x] Aberto, o menu não cobre o Domador nem os vizinhos dele.
- [x] O mapa inteiro funciona a partir do menu, que fecha ao ser usado.
- [x] A lista tem os 9, com Ruvo ativo e os que não têm folhas desativados.
- [x] Spawnar coloca o Ecobeast em um vizinho, e dois spawns seguidos caem em vizinhos diferentes.
- [x] Remover tira todos do mapa e desativa o botão.
- [x] Em vários segundos de passeio, ele usa `idle` e `walk` e nunca sai do hexágono.
- [x] Cada direção escolhe a linha e o lado certos da folha.
- [x] Ele fica no plano da linha dele, e o Domador continua no dele.
- [x] No mapa inteiro, ele não encolhe. Depois da luta, ele continua lá.
- [x] A verificação das fases 04 a 12 continua passando.
- [ ] O menu não aparece na versão publicada (passo do dono, ao exportar).
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/ui/components/sheet_sprite.gd`: `class_name SheetSprite`, a base com as folhas e as direções, tirada do `TamerSprite`.
- `client/ui/components/creature_sprite.gd`: `class_name CreatureSprite`, um Ecobeast no mapa, com `has_sheets(slug)` e o passeio.

**Alterar**

- `client/ui/components/tamer_sprite.gd`: passa a estender `SheetSprite`.
- `client/screens/exploration/exploration_screen.tscn`: `DebugButton` e `DebugMenu`.
- `client/screens/exploration/exploration_screen.gd`: abrir e fechar o menu, spawn, remover e escala no mapa inteiro.
- [03-exploration-screen](03-exploration-screen.md), `architecture.md`, `README.md` e `client/CLAUDE.md`.

**Passeio:** a `CreatureSprite` guarda o centro do hexágono e sorteia pontos dentro dele, no mesmo limite das decorações (`HexDecorations`). A cada quadro, `_process` anda em direção ao ponto, e a posição mostrada é a exata arredondada para pixels da arte.

**Conceito do Godot**

`_process` é uma função que o Godot chama a cada quadro em todo nó que a tem. `ResourceLoader.exists` diz se um arquivo do projeto existe, sem carregá-lo: é ele que descobre quem tem folhas.

## Verificação

Uma verificação temporária confere a direção de cada ângulo e o passeio em uma cena isolada. A tela real, nos quatro tamanhos, contra um servidor de teste, usa o menu, faz spawn, espera o passeio e entra e sai da batalha.

Passos do dono no editor (F5):

1. Abrir "Debug" e spawnar o Ruvo várias vezes.
2. Olhar o idle e o walk em cada direção, e perto de árvores.
3. Remover todos e ver o mapa inteiro pelo menu.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Verificação temporária; ver falhar.
- [x] `SheetSprite`, `TamerSprite` e `CreatureSprite` (RF-09 a RF-13).
- [x] Menu e spawn na tela (RF-01 a RF-08, RF-14).
- [x] Tela real.
- [x] Remover os arquivos temporários; atualizar a [03](03-exploration-screen.md), `architecture.md`, o README da iniciativa e o `client/CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **Lista com os 9, com quem não tem folhas desativado:** decisão do dono. Ela mostra o que ainda falta desenhar.
- **Passeio no próprio hexágono:** decisão do dono. Assim, dá para ver o idle, o walk e os ângulos sem tocar em nada, e o Ecobeast não some de perto do Domador.
- **O menu fica no topo da tela:** na primeira versão, ele abria logo acima dos controles e cobria o Domador e os 6 vizinhos, justamente onde o Ecobeast nasce. Todos os testes passavam, e o problema só apareceu na captura. Agora a verificação confere que esses 7 hexágonos ficam livres.
- **`SheetSprite`, e não uma segunda cópia do `TamerSprite`:** as folhas têm o mesmo formato, e só o jeito de virar muda. No GDScript, o `_init` da base precisa de `super()` aqui: sem isso, as folhas ficavam sem `SpriteFrames`.
- **Plano por linha, e não por ponto:** o Ecobeast fica entre as decorações de cima e as de baixo da linha, como o Domador. Mas ele anda pelo hexágono, então pode aparecer na frente de uma planta que deveria cobri-lo, ou atrás de uma que não deveria. Dois personagens na mesma linha também não se ordenam entre si. Para validar as folhas, isso basta. Os Ecobeasts de verdade no mapa vão precisar de plano por ponto.
- **O spawn não olha o terreno:** o vizinho seguinte pode ser água, e o Ecobeast passeia em cima dela.
- **Conferência:** a verificação quebrou antes de `CreatureSprite` e, depois, antes de o menu sair do meio da tela, com 7 hexágonos cobertos. Por fim, nos quatro tamanhos: a tela real passou com 134 de 134, contra um servidor de teste, com o gerador de verdade, incluindo 360 quadros de passeio com 3 Ecobeasts sem sair do hexágono, o mapa inteiro pelo menu, remover e voltar da batalha. A verificação das fases 04 a 12 continua passando, com 155 itens por tamanho, e o projeto abre sem erros nem avisos. Duas capturas foram abertas e revisadas.
- **Um item da verificação mudou:** `_in_plane` exigia o Domador colado nas decorações da frente. Com um Ecobeast na mesma linha, ele pode ficar entre os dois. A regra agora é o Domador estar entre as duas partes das decorações, o que é mais exato.
- **O Ruvo foi redesenhado com 7 pixels:** ao ver o spawn, o dono pediu o tamanho proporcional à altura do catálogo, com o Domador em 1,70 m. A primeira versão tinha 24 pixels, quase a altura dele. Agora a escala está em [architecture.md](architecture.md#menu-de-depuração) e é conferida pela skill.
- **Os 9 ganharam folhas:** depois do Ruvo, os outros 8 foram desenhados com a skill, cada um na altura do catálogo, e todos ficaram ativos no spawn, sem mudar código. A verificação da tela real coloca os 9 juntos no mapa.
- **Falta do dono:** jogar no editor e conferir, ao exportar, que o menu não aparece. Nenhum celular foi testado.

## Mudanças depois (progression/04)

O dono pediu, durante a [progression/04](../progression/04-evolution-and-skills-screens.md), um menu mais curto e um modo God:

- **Menu em duas partes:** "Debug" abre só os botões "Debug: ver mapa inteiro", "Spawn", "God: desligado" e "Quase subir de nível". "Spawn" troca para a lista de Ecobeasts, e "Voltar" volta aos botões. O menu sempre abre na parte principal.
- **Spawn com retrato:** cada Ecobeast é um cartão com o `front.png` e o nome, em 5 colunas, numa área que rola com 2 linhas à vista, para o menu não crescer com o catálogo. Quem não tem folhas fica apagado e desativado, como antes. "Remover Ecobeasts" fica ao lado do "Voltar".
- **God:** liga e desliga sem fechar o menu, e o texto do botão mostra o estado. Com ele ligado, todo golpe do jogador que acerta derruba o inimigo de uma vez; o inimigo continua atacando normal, e os golpes ainda podem errar (escolha do planejamento, que o dono pode mudar). Vale para as lutas que começarem depois e some ao fechar o jogo (`Session.debug_god`). Quem decide é o servidor: a luta no mapa recebe `god: true`, e ele só vale com `ENABLE_TEST_BATTLE` ligada.
- **Quase subir de nível:** [progression/04](../progression/04-evolution-and-skills-screens.md), RF-14 e RF-15. Ele e o God passam pelo servidor, ao contrário do resto do menu.
- **Conferência:** o menu foi desenhado nas duas partes em 360×640, com o catálogo de um servidor de teste. A luta com o God ligado foi conferida pelos testes do servidor, e não na tela.

