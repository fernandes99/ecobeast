# 04. As cenas da introdução

- **Status:** concluída (falta o dono pôr no mapa os NPCs, o Refúgio e a casa, e conferir)
- **Depende de:** [02](02-person-npcs.md), [03](03-intro-steps.md), o mapa de Liora desenhado pelo dono

## Contexto

O dono escreveu o roteiro da introdução em 7 partes: a natureza de Liora, a criação do Domador, o avô, o caminho até a Vila Raiz, a Mira, o convite e o primeiro vínculo. Decidiu também que eu (a IA) escrevo as cenas a partir dele, e que ele ajusta o resultado no F2 ([README](README.md#decisões)). Esta fase escreve as cenas em `res://story/scenes/`, com os passos das fases anteriores.

## Pré-requisito: o mapa de Liora

Antes desta fase, o dono desenha Liora no F2 e:

- publica a ilha e marca "Casa do jogador" ([home-island/01](../home-island/01-home-and-travel-data.md));
- põe o ponto de início no campo onde a introdução começa, com espaço livre em volta;
- desenha o caminho do campo até a Vila Raiz, a praça, a casa do avô, o Refúgio, a Loja e o cais (a ação Viagem);
- põe os NPCs da ilha: o Avô (`grandpa`) perto da casa dele, a Mira (`mira`) na praça e o Responsável do Refúgio (`refuge_keeper`) na porta do Refúgio, todos parados.

Com isso, eu leio a ilha publicada e escolho o resto dos hexágonos das cenas: os pontos da câmera no campo, onde o Puffcoo está, de onde o avô chega, as áreas do caminho, a entrada da vila e por onde o avô sai. O dono ajusta depois no F2.

### Os hexágonos escolhidos

As cenas foram escritas com o mapa de Liora ainda sem os NPCs, o Refúgio, a Loja, o cais e a marca de casa (ilha 1199, publicada em 17/11/2026, com 10.116 hexágonos). O que já estava no mapa: o início em (-22, -1), no campo; a trilha de areia de (-13, -4) até a vila; a praça de pedra em volta de (0, 0); e 7 casas, com a casinha de pedra (-7, 3) na entrada da vila, que virou a casa do avô.

| O que | Hexágono |
| --- | --- |
| O Domador na abertura | (-22, -1), o início, e o passo até (-21, -1) |
| O Puffcoo | (-20, -2), fugindo para (-18, -5) |
| A câmera da abertura | o lago (-14, 3) e o alto (-12, -9) |
| De onde o avô chega | (-15, -1) |
| O avô ao lado do Domador (`avo_chega` e `avo_segue`) | (-22, 0), vizinho do início e de (-21, -1) |
| A área do `caminho_conversa_1` | a coluna q = -17, de r = -8 a 2 |
| A área do `caminho_conversa_2` | a coluna q = -14, de r = -8 a 1 |
| A área da `vila_chegada` | a coluna q = -9, de r = -6 a 6 |
| Por onde o avô sai | (-6, 4), na porta da casinha de pedra (-7, 3) |

Cada área é uma coluna inteira de hexágonos, para o Domador passar por ela de qualquer jeito vindo do oeste. Para o reencontro e o vínculo, falta o dono pôr no mapa:

- o Avô (`grandpa`) parado em (-6, 4), onde o avô da cena some;
- a Mira (`mira`) parada na praça, perto de (0, 0);
- o Refúgio e o Responsável do Refúgio (`refuge_keeper`) na porta dele;
- a Loja e o cais (a ação Viagem);
- a marca "Casa do jogador", sem a qual o jogo recusa as cenas com `create_tamer` e `choose_starter`.

As cenas `exemplo_conversa` e `exemplo_chegada`, da [story](../story/), também eram da ilha 1199. O dono as apagou depois das cenas de Liora, e o que elas mostravam continua descrito nas fases 02 e 03 da story.

## Escopo

- As 9 cenas abaixo, na ilha casa.
- O NPC de Ecobeast do campo.

## Fora do escopo

- Música, som, retratos e pular cena ([story](../story/README.md#fora-do-escopo)).
- A Pradaria Serena (a Mira só fala dela).
- Os diálogos fixos dos NPCs da ilha depois da introdução (o dono escreve na ferramenta NPC).

## Requisitos

- **RF-01:** O catálogo ganha o NPC 6, `liora_puffcoo`, "Puffcoo", "O Ecobeast que o Domador observa no campo.", com o sprite `puffcoo` (seed e migration). _A revisar_: a espécie.
- **RF-02:** As cenas são as da tabela, com o gatilho, os Marcos e os atores indicados. Os hexágonos vêm do mapa de Liora (ver o pré-requisito).
- **RF-03:** As falas seguem o roteiro do dono. As que eu escrevi para ligar as partes (as opções de resposta, a narração da anotação e a dica de andar) ficam marcadas _a revisar_ na descrição da cena, no campo `name`, e na lista abaixo.
- **RF-04:** Toda fala sobre o Domador que muda com o corpo usa `{forma masculina|forma feminina}`.
- **RF-05:** O `StoryValidator` aceita as 9 cenas, e a Linha da história as mostra em ordem, sem aviso além do `introducao_pulada` sem dono ([architecture](architecture.md#as-contas-antigas)).
- **RF-06:** Na ilha casa, os hexágonos a até 30 do ponto de início (`HOME_KNOWN_RADIUS` em `exploration_screen.gd`, _a revisar_) já entram descobertos, a cada entrada e depois do "Esquecer ilha" do Debug, e vão para o servidor como as outras descobertas. O raio cobre o campo da abertura e a vila (a casa mais longe fica a 29); o resto da ilha continua na névoa para explorar.
- **RF-07:** Durante qualquer cena, a névoa some, para a câmera mostrar o mapa onde passar; ao fim da cena, ela volta como estava. O que a câmera mostrou não conta como descoberto.

### As cenas

| Ordem | `slug` | Gatilho | Precisa de | Não pode ter | Atores |
| --- | --- | --- | --- | --- | --- |
| 1 | `liora_abertura` | `auto` | — | `introducao_pulada` | `puffcoo` (NPC 6, ao lado do início) |
| 2 | `avo_chega` | `auto` | `liora_abertura` | — | `avo` (NPC 3, novo, longe no caminho) |
| 3 | `avo_segue` (repetível) | `auto` | `avo_chega` | `vila_chegada` | `avo` (NPC 3, novo, ao lado do início) |
| 4 | `caminho_conversa_1` | `area` (no começo do caminho) | `avo_chega` | `vila_chegada` | `avo` (da ilha) |
| 5 | `caminho_conversa_2` | `area` (no meio do caminho) | `avo_chega` | `vila_chegada` | `avo` (da ilha) |
| 6 | `vila_chegada` | `area` (a entrada da vila) | `avo_chega` | — | `avo` (da ilha) |
| 7 | `mira_reencontro` | `npc` (Mira) | `vila_chegada` | — | `mira` (da ilha) |
| 8 | `primeiro_vinculo` | `npc` (Responsável do Refúgio) | `mira_reencontro` | — | `responsavel` (da ilha) |
| 9 | `mira_depois` | `npc` (Mira) | `primeiro_vinculo` | — | `mira` (da ilha) |

"Da ilha" é o ator com `island_npc: true`. Ele pega primeiro quem está seguindo o Domador, e depois o NPC posto no mapa.

**Por que o `avo_segue`.** Quem segue o Domador some quando ele sai da ilha ([story](../story/architecture.md#os-passos)), e reabrir o app põe o Domador no ponto de início. O `avo_chega` termina com o avô ao lado do início, e o `avo_segue` (repetível) põe o avô ali e o faz seguir. Ele roda logo depois do `avo_chega` e uma vez a cada entrada até a chegada à vila (uma `auto` repetível roda uma vez por entrada, [03](03-intro-steps.md), RF-16), para o avô nunca faltar no caminho.

**Por que a Mira não vai junto ao Refúgio.** A Mira é a da praça, e quem a segue também sumiria ao fechar o app. Em vez disso, ela manda o Domador ao Refúgio e espera a volta dele ("Depois me conta qual escolheu!"), na cena 9.

### O conteúdo

1. **`liora_abertura`**: começa no escuro, clareia com a câmera no campo, e a narração diz as três frases do roteiro ("Em Auralis, cada ilha guarda...", "Para alguns, esses lugares são apenas o lar...", "E existem aqueles que nunca conseguem...") enquanto a câmera passa por dois pontos do campo e volta ao Domador, que está virado para o Puffcoo. Depois vêm `create_tamer`, o Domador dando um passo para o Puffcoo, o Puffcoo correndo para o mato e sumindo, e a narração "{nome} sorri e faz uma anotação no caderno." _a revisar_.
2. **`avo_chega`**: o avô aparece longe e a câmera vai até ele: "Ei! Já estava imaginando que encontraria você por aqui!". Ele anda até o lado do início e diz as falas do roteiro (o talento para desaparecer, "O que estava observando dessa vez?"). Uma escolha de resposta _a revisar_ ("Um Puffcoo! Quase cheguei perto." e "Nada de mais, só um Ecobeast curioso."), a narração "O avô dá uma risada." e a notícia ("Uma velha amiga sua voltou para a Vila Raiz..."). Outra escolha _a revisar_ ("Uma velha amiga?" e "Quem?"), e então "Não vai me dizer que já esqueceu da Mira?" e "Vamos, ela deve estar na vila. Não seria muito educado deixar uma velha amiga esperando, não acha?".
3. **`avo_segue`**: o avô segue o Domador, e a narração "Toque no chão para andar." _a revisar_.
4. **`caminho_conversa_1`**: "Faz alguns anos desde que vocês dois se viram, não é?" e "Lembro de quando passavam tardes inteiras explorando esses campos.".
5. **`caminho_conversa_2`**: "Você sempre voltava com alguma história sobre uma criatura que tinha encontrado." e "E a Mira voltava com o caderno cheio de anotações!".
6. **`vila_chegada`**: "Bom, chegamos. Tenho algumas coisas para resolver, então vou deixar você procurar sua amiga.". O avô para de seguir, anda para longe da entrada e some.
7. **`mira_reencontro`**: as falas do roteiro ("Espera... Não acredito!", "É você mesmo?!", o tempo longe, o Instituto Meridian, o caderno, "Continua explorando todos os cantinhos de Liora?"), com uma escolha de reação _a revisar_ no começo e outra na pergunta. Depois, a vontade de explorar junto, a pesquisa de campo na Pradaria Serena, o Refúgio com o responsável procurando Domadores para Ecobeasts jovens e "Passa lá! Depois me conta qual escolheu." _a revisar_.
8. **`primeiro_vinculo`**: o responsável recebe o Domador, conta dos Ecobeasts jovens que precisam de alguém _a revisar_, `choose_starter`, uma fala de despedida _a revisar_ e `set_mark` `introducao_concluida`.
9. **`mira_depois`**: a Mira reage ao Ecobeast escolhido e combina a ida à Pradaria Serena _a revisar_. É a última cena da introdução.

## Critérios de aceite

- [ ] Uma conta nova joga a introdução inteira, do escuro inicial à conversa com a Mira depois do inicial, sem tela de menu antes do primeiro vínculo.
- [ ] Fechar o app no caminho e abrir de novo põe o avô ao lado do Domador, seguindo.
- [ ] Fechar o app no meio de qualquer cena e abrir de novo repete só aquela cena.
- [ ] Com corpo feminino, as falas usam a forma feminina.
- [ ] Uma conta que já tinha inicial cai em Liora sem nenhuma cena.
- [ ] O dono abre cada cena no F2, mexe e testa com o Testar daqui.

## Desenho técnico

- `client/story/scenes/*.json`: as 9 cenas, escritas como o F2 salva (`StoryScene.to_dict()`), para o F2 abrir e salvar sem diferença.
- `server/prisma/seed-data/npcs.json` e a migration do NPC 6.
- `client/story/scenes/exemplo_*.json`: continuam, na ilha de teste.

## Verificação

Checagem sem janela: o `Story.load_scenes()` sem erro e o `StoryGraph` com as 9 cenas em ordem.

Manual (F5, conta nova): os critérios de aceite.

## Tarefas

- [x] O NPC 6 (migration `liora_puffcoo`; o teste da carga inicial confere o sprite pelas folhas de explorar do jogo, porque o `species.json` só tem as 9 espécies da carga inicial).
- [x] Ler o mapa publicado e escolher os hexágonos.
- [x] As 9 cenas, geradas no formato do F2; o `Story.load_scenes()` as aceita, e a Linha da história as põe em ordem.
- [ ] Jogar a introdução inteira com uma conta nova: fica para o dono, depois de pôr os NPCs, o Refúgio e a casa no mapa.
